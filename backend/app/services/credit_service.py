from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.credit import CreditPurchase
from app.models.usage import UsageSummary
from app.services.revenuecat_service import RevenueCatService
from app.services.usage_service import ensure_summary

# Safe in-code defaults keyed by Google Play store identifier. RevenueCat API
# v2 purchases may instead report internal product ids (e.g. "prod733d52bcdd");
# those are NOT hardcoded here — configure them via REVENUECAT_CREDIT_PRODUCT_MAP
# so each environment can map its own internal ids.
DEFAULT_CREDIT_PRODUCT_GRANTS: dict[str, int] = {
    "credits_10": 10,
    "credits_50": 50,
    "credits_100": 100,
}


def credit_product_grants() -> dict[str, int]:
    """Merged product_id -> credits map.

    In-code store defaults first, then REVENUECAT_CREDIT_PRODUCT_MAP overrides
    or adds entries (env wins on conflict).
    """
    return {**DEFAULT_CREDIT_PRODUCT_GRANTS, **settings.credit_product_map}


def _purchase_keys(
    transaction_id: str,
    alternate_transaction_ids: tuple[str, ...] = (),
) -> tuple[str, ...]:
    seen: set[str] = set()
    result: list[str] = []
    for value in (transaction_id, *alternate_transaction_ids):
        text = value.strip()
        if not text or text in seen:
            continue
        seen.add(text)
        result.append(text)
    return tuple(result)


async def grant_credit_purchase_once(
    db: AsyncSession,
    user_id: int,
    *,
    transaction_id: str,
    product_id: str,
    credits: int,
    alternate_transaction_ids: tuple[str, ...] = (),
) -> int:
    """Persist and grant one purchased-credit transaction exactly once.

    The primary key is the canonical RevenueCat/store transaction id. Alternate
    IDs are checked for backward compatibility with rows previously recorded
    under RevenueCat's purchase id instead of the store purchase identifier.
    """
    keys = _purchase_keys(transaction_id, alternate_transaction_ids)
    if not keys:
        return 0

    await ensure_summary(db, user_id)

    existing = await db.scalar(
        select(CreditPurchase.transaction_id).where(
            CreditPurchase.transaction_id.in_(keys)
        )
    )
    if existing is not None:
        return 0

    try:
        async with db.begin_nested():  # savepoint per transaction
            db.add(
                CreditPurchase(
                    transaction_id=keys[0],
                    user_id=user_id,
                    product_id=product_id,
                    credits_granted=credits,
                )
            )
            await db.flush()  # surface IntegrityError before the UPDATE
            await db.execute(
                update(UsageSummary)
                .where(UsageSummary.user_id == user_id)
                .values(paid_credits=UsageSummary.paid_credits + credits)
            )
    except IntegrityError:
        return 0
    return credits


async def sync_credits(
    db: AsyncSession,
    user_id: int,
    app_user_id: str,
    verifier: RevenueCatService,
) -> int:
    """Grant credits for each verified RevenueCat transaction not yet recorded.

    The shared grant helper handles savepoints and duplicate transaction IDs.
    Returns total credits granted in this call (0 when all transactions were
    already processed).
    """
    await ensure_summary(db, user_id)
    transactions = await verifier.fetch_consumable_transactions(app_user_id)
    grants = credit_product_grants()

    granted_this_sync = 0
    for txn in transactions:
        credits = grants.get(txn.product_id)
        if credits is None:
            continue  # Unknown product — skip safely

        granted_this_sync += await grant_credit_purchase_once(
            db,
            user_id,
            transaction_id=txn.transaction_id,
            product_id=txn.product_id,
            credits=credits,
            alternate_transaction_ids=txn.alternate_transaction_ids,
        )

    await db.commit()
    return granted_this_sync
