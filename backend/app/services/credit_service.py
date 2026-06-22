from sqlalchemy import update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.credit import CreditPurchase
from app.models.usage import UsageSummary
from app.services.revenuecat_service import RevenueCatService
from app.services.usage_service import ensure_summary

# Exact product-to-credit mapping. Unknown product IDs are silently skipped.
CREDIT_PRODUCT_GRANTS: dict[str, int] = {
    "credits_10": 10,
    "credits_50": 50,
    "credits_100": 100,
}


async def sync_credits(
    db: AsyncSession,
    user_id: int,
    app_user_id: str,
    verifier: RevenueCatService,
) -> int:
    """Grant credits for each verified RevenueCat transaction not yet recorded.

    Uses savepoints so that a duplicate transaction_id (IntegrityError) skips
    that entry without aborting the entire batch. Returns total credits granted
    in this call (0 when all transactions were already processed).
    """
    await ensure_summary(db, user_id)
    transactions = await verifier.fetch_consumable_transactions(app_user_id)

    granted_this_sync = 0
    for txn in transactions:
        credits = CREDIT_PRODUCT_GRANTS.get(txn.product_id)
        if credits is None:
            continue  # Unknown product — skip safely

        try:
            async with db.begin_nested():  # savepoint per transaction
                db.add(
                    CreditPurchase(
                        transaction_id=txn.transaction_id,
                        user_id=user_id,
                        product_id=txn.product_id,
                        credits_granted=credits,
                    )
                )
                await db.flush()  # surface IntegrityError before the UPDATE
                await db.execute(
                    update(UsageSummary)
                    .where(UsageSummary.user_id == user_id)
                    .values(paid_credits=UsageSummary.paid_credits + credits)
                )
                granted_this_sync += credits
        except IntegrityError:
            pass  # Already granted — idempotent skip

    await db.commit()
    return granted_this_sync
