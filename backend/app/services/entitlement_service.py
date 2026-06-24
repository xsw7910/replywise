from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.subscription import SubscriptionCache
from app.services.revenuecat_service import RevenueCatService, VerifiedEntitlement


def _utc(value: datetime) -> datetime:
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def cache_is_premium(cache: SubscriptionCache | None) -> bool:
    if cache is None or not cache.is_premium:
        return False
    if cache.product_identifier == "dev_premium_override":
        if not settings.dev_tools_enabled or not settings.is_dev_or_test:
            return False
    return cache.expires_at is None or _utc(cache.expires_at) > datetime.now(timezone.utc)


async def is_user_premium(db: AsyncSession, user_id: int) -> bool:
    return cache_is_premium(await db.get(SubscriptionCache, user_id))


async def sync_entitlement(
    db: AsyncSession,
    user_id: int,
    app_user_id: str,
    verifier: RevenueCatService,
) -> bool:
    verified: VerifiedEntitlement = await verifier.verify(app_user_id)
    cache = await db.get(SubscriptionCache, user_id)
    if cache is None:
        cache = SubscriptionCache(
            user_id=user_id,
            entitlement_id=verified.entitlement_id,
        )
        db.add(cache)
    cache.entitlement_id = verified.entitlement_id
    cache.is_premium = verified.is_premium
    cache.product_identifier = verified.product_identifier
    cache.expires_at = verified.expires_at
    cache.verified_at = datetime.now(timezone.utc)
    await db.commit()
    return cache_is_premium(cache)
