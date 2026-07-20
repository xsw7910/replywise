import logging

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.credit import CreditPurchase
from app.models.usage import UsageSummary
from app.services.revenuecat_service import RevenueCatService
from app.services.usage_service import ensure_summary

logger = logging.getLogger(__name__)

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
    revenuecat_purchase_id: str | None = None,
    store: str | None = None,
    source: str = "unknown",
) -> int:
    """Persist and grant one purchased-credit transaction exactly once.

    ``transaction_id`` MUST be the canonical, store-level transaction id (the
    Google Play order id on Android) so every delivery path — webhook and
    ``/v1/credits/sync`` — keys the ledger on the same value. ``alternate``
    ids and ``revenuecat_purchase_id`` are only checked for backward
    compatibility with rows previously recorded under RevenueCat's purchase id.
    Both idempotency guarantees are enforced by the database (PK on
    ``transaction_id`` and the unique index on ``revenuecat_purchase_id``).
    """
    alternates = tuple(
        value for value in (*alternate_transaction_ids, revenuecat_purchase_id or "") if value
    )
    keys = _purchase_keys(transaction_id, alternates)
    if not keys:
        return 0

    summary = await ensure_summary(db, user_id)
    balance_before = summary.paid_credits

    existing = await db.scalar(
        select(CreditPurchase.transaction_id).where(
            CreditPurchase.transaction_id.in_(keys)
        )
    )
    # A previously stored row that recorded this RevenueCat purchase id (but
    # under a different canonical transaction id) is also a duplicate.
    if existing is None and revenuecat_purchase_id:
        existing = await db.scalar(
            select(CreditPurchase.transaction_id).where(
                CreditPurchase.revenuecat_purchase_id == revenuecat_purchase_id
            )
        )
    if existing is not None:
        _trace(
            "duplicate_ignored",
            source=source,
            canonical_transaction_id=keys[0],
            revenuecat_purchase_id=revenuecat_purchase_id,
            store=store,
            product_id=product_id,
            credits=credits,
            balance_before=balance_before,
            balance_after=balance_before,
            applied=False,
        )
        return 0

    try:
        async with db.begin_nested():  # savepoint per transaction
            db.add(
                CreditPurchase(
                    transaction_id=keys[0],
                    user_id=user_id,
                    product_id=product_id,
                    credits_granted=credits,
                    revenuecat_purchase_id=revenuecat_purchase_id,
                    store=store,
                    source=source,
                )
            )
            await db.flush()  # surface IntegrityError before the UPDATE
            await db.execute(
                update(UsageSummary)
                .where(UsageSummary.user_id == user_id)
                .values(paid_credits=UsageSummary.paid_credits + credits)
            )
    except IntegrityError:
        # Lost a concurrency race (PK or revenuecat_purchase_id uniqueness):
        # the savepoint rolled back, so no balance change happened.
        _trace(
            "duplicate_ignored",
            source=source,
            canonical_transaction_id=keys[0],
            revenuecat_purchase_id=revenuecat_purchase_id,
            store=store,
            product_id=product_id,
            credits=credits,
            balance_before=balance_before,
            balance_after=balance_before,
            applied=False,
        )
        return 0

    _trace(
        "purchase_row_inserted",
        source=source,
        canonical_transaction_id=keys[0],
        revenuecat_purchase_id=revenuecat_purchase_id,
        store=store,
        product_id=product_id,
        credits=credits,
        balance_before=balance_before,
        balance_after=balance_before + credits,
        applied=True,
    )
    return credits


def _trace(stage: str, **fields: object) -> None:
    """Structured, non-sensitive credit-grant trace for production forensics."""
    parts = " ".join(f"{key}={value}" for key, value in fields.items())
    logger.info("CREDIT_GRANT_TRACE stage=%s %s", stage, parts)


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
            revenuecat_purchase_id=txn.revenuecat_purchase_id,
            store=txn.store,
            source="sync",
        )

    await db.commit()
    return granted_this_sync
