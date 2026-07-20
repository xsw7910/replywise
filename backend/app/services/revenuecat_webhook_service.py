import hashlib
import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.revenuecat_event import RevenueCatEvent
from app.models.subscription import SubscriptionCache
from app.models.user import User
from app.services.credit_service import (
    credit_product_grants,
    grant_credit_purchase_once,
)

logger = logging.getLogger(__name__)

ACTIVE_SUBSCRIPTION_EVENTS = {
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "PRODUCT_CHANGE",
}
INACTIVE_SUBSCRIPTION_EVENTS = {
    "EXPIRATION",
    "CANCELLATION",
    "BILLING_ISSUE",
    "REFUND",
}
CREDIT_EVENT = "NON_RENEWING_PURCHASE"


@dataclass(frozen=True)
class WebhookResult:
    status: str
    credits_granted: int = 0


def event_hash(event: dict[str, Any]) -> str:
    canonical = json.dumps(
        event,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
        default=str,
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _optional_string(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _expiration(event: dict[str, Any]) -> datetime | None:
    milliseconds = event.get("expiration_at_ms")
    if milliseconds is not None:
        try:
            return datetime.fromtimestamp(float(milliseconds) / 1000, tz=timezone.utc)
        except (TypeError, ValueError, OSError):
            logger.warning("RevenueCat event has an invalid expiration timestamp")

    raw = _optional_string(event.get("expiration_at"))
    if raw:
        try:
            parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            logger.warning("RevenueCat event has an invalid expiration date")
    return None


def _transaction_ids(event: dict[str, Any], event_id: str) -> tuple[str, tuple[str, ...]]:
    seen: set[str] = set()
    result: list[str] = []
    for key in (
        "store_transaction_id",
        "store_purchase_identifier",
        "transaction_id",
        "original_transaction_id",
    ):
        value = _optional_string(event.get(key))
        if value and value not in seen:
            seen.add(value)
            result.append(value)
    if not result:
        result.append(event_id)
    return result[0], tuple(result[1:])


def _transaction_id(event: dict[str, Any], event_id: str) -> str:
    return _transaction_ids(event, event_id)[0]


def _entitlement_id(event: dict[str, Any]) -> str:
    direct = _optional_string(event.get("entitlement_id"))
    if direct:
        return direct
    entitlement_ids = event.get("entitlement_ids")
    if isinstance(entitlement_ids, list) and entitlement_ids:
        first = _optional_string(entitlement_ids[0])
        if first:
            return first
    return settings.revenuecat_entitlement_id


async def _set_subscription(
    db: AsyncSession,
    user_id: int,
    event: dict[str, Any],
    *,
    active: bool,
) -> None:
    cache = await db.get(SubscriptionCache, user_id)
    if cache is None:
        cache = SubscriptionCache(
            user_id=user_id,
            entitlement_id=_entitlement_id(event),
        )
        db.add(cache)

    cache.entitlement_id = _entitlement_id(event)
    cache.is_premium = active
    cache.product_identifier = _optional_string(event.get("product_id"))
    cache.expires_at = _expiration(event)
    cache.verified_at = datetime.now(timezone.utc)


async def _grant_credits(
    db: AsyncSession,
    user_id: int,
    event_id: str,
    event: dict[str, Any],
) -> int:
    product_id = _optional_string(event.get("product_id"))
    credits = credit_product_grants().get(product_id or "")
    if credits is None:
        logger.warning(
            "Ignoring RevenueCat credit event %s with unknown product_id",
            event_id,
        )
        return 0

    transaction_id, alternate_transaction_ids = _transaction_ids(event, event_id)
    granted = await grant_credit_purchase_once(
        db,
        user_id,
        transaction_id=transaction_id,
        product_id=product_id,
        credits=credits,
        alternate_transaction_ids=alternate_transaction_ids,
    )
    if granted == 0:
        logger.info(
            "RevenueCat purchase transaction was already granted for event %s",
            event_id,
        )
    return granted


async def process_revenuecat_event(
    db: AsyncSession,
    event: dict[str, Any],
) -> WebhookResult:
    event_id = str(event["id"]).strip()
    event_type = str(event["type"]).strip().upper()
    app_user_id = str(event["app_user_id"]).strip()
    product_id = _optional_string(event.get("product_id"))
    transaction_id = (
        _transaction_id(event, event_id) if event_type == CREDIT_EVENT else None
    )
    raw_hash = event_hash(event)

    existing = await db.get(RevenueCatEvent, event_id)
    if existing is not None:
        if existing.raw_event_hash != raw_hash:
            logger.warning(
                "RevenueCat event %s was replayed with different content",
                event_id,
            )
        return WebhookResult(status="duplicate")

    try:
        async with db.begin_nested():
            db.add(
                RevenueCatEvent(
                    event_id=event_id,
                    app_user_id=app_user_id,
                    event_type=event_type,
                    product_id=product_id,
                    transaction_id=transaction_id,
                    raw_event_hash=raw_hash,
                )
            )
            await db.flush()
    except IntegrityError:
        await db.rollback()
        return WebhookResult(status="duplicate")

    user = await db.scalar(select(User).where(User.app_user_id == app_user_id))
    if user is None:
        logger.warning(
            "Ignoring RevenueCat event %s because its app user is unknown",
            event_id,
        )
        await db.commit()
        return WebhookResult(status="ignored_user")

    credits_granted = 0
    if event_type in ACTIVE_SUBSCRIPTION_EVENTS:
        await _set_subscription(db, user.id, event, active=True)
    elif event_type in INACTIVE_SUBSCRIPTION_EVENTS:
        await _set_subscription(db, user.id, event, active=False)
    elif event_type == CREDIT_EVENT:
        credits_granted = await _grant_credits(db, user.id, event_id, event)
    else:
        logger.warning(
            "Ignoring unsupported RevenueCat event type %s for event %s",
            event_type,
            event_id,
        )

    await db.commit()
    return WebhookResult(
        status="processed" if event_type in (
            ACTIVE_SUBSCRIPTION_EVENTS
            | INACTIVE_SUBSCRIPTION_EVENTS
            | {CREDIT_EVENT}
        ) else "ignored_type",
        credits_granted=credits_granted,
    )
