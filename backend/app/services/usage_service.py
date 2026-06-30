import hashlib
import json
from datetime import datetime, timedelta, timezone

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.config import settings
from app.errors import ApiException
from app.models.usage import DeviceUsage, IdempotencyKey, UsageEvent, UsageSummary
from app.models.user import User


def canonicalize(model) -> tuple[str, str]:
    raw = model.model_dump(mode="json")
    clean = _clean(raw)
    clean.setdefault("output_lang", "en")
    if isinstance(clean.get("audience"), dict):
        clean["audience"].setdefault("mode", "auto")
        clean["audience"].setdefault("formality", 50)
    canonical = json.dumps(clean, separators=(",", ":"), sort_keys=True, ensure_ascii=False)
    return canonical, hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _clean(value):
    if isinstance(value, dict):
        return {key: _clean(item) for key, item in value.items() if item is not None}
    if isinstance(value, list):
        return [_clean(item) for item in value]
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return value


async def ensure_summary(db: AsyncSession, user_id: int) -> UsageSummary:
    summary = await db.get(UsageSummary, user_id)
    if summary is None:
        summary = UsageSummary(user_id=user_id, free_uses_limit=settings.free_lifetime_limit)
        db.add(summary)
        await db.commit()
        await db.refresh(summary)
    return summary


async def ensure_device_usage(db: AsyncSession, device_hash: str) -> DeviceUsage:
    """Get-or-create the device-scoped free-use row for *device_hash*.

    On first creation the consumed count is seeded from the largest
    free_uses_used among existing users that share this device. This carries
    a partially-consumed allowance across the move to device-scoped tracking
    (and across anonymous reinstalls), so the lifetime free quota is never
    reset by minting a new app_user_id. For a brand-new device the seed is 0.
    """
    device = await db.get(DeviceUsage, device_hash)
    if device is not None:
        return device

    seeded_used = await db.scalar(
        select(func.max(UsageSummary.free_uses_used))
        .join(User, User.id == UsageSummary.user_id)
        .where(User.device_hash == device_hash)
    )
    limit = settings.free_lifetime_limit
    device = DeviceUsage(
        device_hash=device_hash,
        free_uses_limit=limit,
        free_uses_used=min(seeded_used or 0, limit),
    )
    db.add(device)
    try:
        await db.commit()
    except IntegrityError:
        # Concurrent creation: adopt the row the other request committed.
        await db.rollback()
        device = await db.get(DeviceUsage, device_hash)
        if device is None:
            raise
        return device
    await db.refresh(device)
    return device


def usage_dict(
    free_uses_limit: int,
    free_uses_used: int,
    paid_credits: int,
    is_premium: bool = False,
) -> dict:
    left = None if is_premium else max(0, free_uses_limit - free_uses_used)
    return {
        "isPremium": is_premium,
        "freeUsesLimit": free_uses_limit,
        "freeUsesUsed": free_uses_used,
        "freeUsesLeft": left,
        "paidCredits": paid_credits,
        "upgradeRequired": not is_premium and left == 0 and paid_credits == 0,
    }


def summary_view(
    device: DeviceUsage, summary: UsageSummary, is_premium: bool = False
) -> dict:
    """Combine device-scoped free usage with per-user paid credits."""
    return usage_dict(
        device.free_uses_limit,
        device.free_uses_used,
        summary.paid_credits,
        is_premium=is_premium,
    )


async def cleanup_expired(db: AsyncSession) -> None:
    await db.execute(delete(IdempotencyKey).where(IdempotencyKey.expires_at < datetime.now(timezone.utc)))
    await db.commit()


async def begin_generation(
    db: AsyncSession,
    user_id: int,
    device_hash: str,
    endpoint: str,
    key: str,
    request_hash: str,
    is_premium: bool = False,
) -> tuple[str | None, dict | None]:
    await cleanup_expired(db)

    # Idempotency check
    existing = await db.get(IdempotencyKey, key)
    if existing is not None:
        if existing.user_id != user_id or existing.endpoint != endpoint or existing.request_hash != request_hash:
            raise ApiException("IDEMPOTENCY_CONFLICT", "Idempotency key was reused.", 409)
        if existing.status == "succeeded":
            return None, json.loads(existing.response_json or "{}")
        if existing.status == "processing":
            raise ApiException("IDEMPOTENCY_CONFLICT", "Request is still processing.", 409)
        # "failed" — allow retry with same key
        await db.delete(existing)
        await db.commit()

    # Premium still participates in idempotency and rate limiting, but not billing.
    await ensure_summary(db, user_id)
    now = datetime.now(timezone.utc)
    source = None
    if not is_premium:
        # Free allowance is shared by all users on the same device.
        await ensure_device_usage(db, device_hash)
        free = await db.execute(
            update(DeviceUsage)
            .where(
                DeviceUsage.device_hash == device_hash,
                DeviceUsage.free_uses_used < DeviceUsage.free_uses_limit,
            )
            .values(free_uses_used=DeviceUsage.free_uses_used + 1, updated_at=now)
        )
        source = "free" if free.rowcount == 1 else None
        if source is None:
            credit = await db.execute(
                update(UsageSummary)
                .where(UsageSummary.user_id == user_id, UsageSummary.paid_credits > 0)
                .values(paid_credits=UsageSummary.paid_credits - 1, updated_at=now)
            )
            source = "credit" if credit.rowcount == 1 else None
        if source is None:
            await db.rollback()
            raise ApiException("PAYWALL_REQUIRED", "No AI uses remaining.", 402)

    # Commit deduction + processing key in one transaction
    db.add(
        IdempotencyKey(
            key=key,
            user_id=user_id,
            endpoint=endpoint,
            request_hash=request_hash,
            status="processing",
            source=source,
            expires_at=now + timedelta(seconds=settings.idempotency_ttl_seconds),
        )
    )
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        existing = await db.get(IdempotencyKey, key)
        if existing is None:
            raise
        if existing.user_id != user_id or existing.endpoint != endpoint or existing.request_hash != request_hash:
            raise ApiException("IDEMPOTENCY_CONFLICT", "Idempotency key was reused.", 409)
        if existing.status == "succeeded":
            return None, json.loads(existing.response_json or "{}")
        raise ApiException("IDEMPOTENCY_CONFLICT", "Request is still processing.", 409)

    # Post-commit rate check using committed idempotency keys.
    # Checking AFTER commit means concurrent requests that both commit will both be visible
    # here, preventing both from reaching the model when over the limit.
    since = datetime.now(timezone.utc) - timedelta(minutes=1)
    rate_count = await db.scalar(
        select(func.count(IdempotencyKey.key)).where(
            IdempotencyKey.user_id == user_id,
            IdempotencyKey.endpoint.in_(["reply", "polish"]),
            IdempotencyKey.created_at >= since,
        )
    )
    if (rate_count or 0) > settings.generation_rate_per_minute:
        await rollback_generation(db, user_id, device_hash, endpoint, key, source, "RATE_LIMITED")
        raise ApiException("RATE_LIMITED", "Too many requests. Please try again shortly.", 429)

    return source, None


async def finish_generation(
    db: AsyncSession,
    user_id: int,
    device_hash: str,
    endpoint: str,
    key: str,
    source: str | None,
    response: dict,
) -> dict:
    device = await ensure_device_usage(db, device_hash)
    summary = await ensure_summary(db, user_id)
    is_premium = source is None
    usage = {
        **summary_view(device, summary, is_premium=is_premium),
        "creditsUsed": 0 if is_premium else 1,
        "source": source,
    }
    combined = {**response, "usage": usage}
    idem = await db.get(IdempotencyKey, key)
    idem.status = "succeeded"
    idem.response_json = json.dumps(combined, ensure_ascii=False)
    db.add(UsageEvent(
        user_id=user_id,
        endpoint=endpoint,
        credits_used=0 if is_premium else 1,
        source=source,
        prompt_version=f"{endpoint}_v1",
        success=True,
    ))
    await db.commit()
    return combined


async def rollback_generation(
    db: AsyncSession,
    user_id: int,
    device_hash: str,
    endpoint: str,
    key: str,
    source: str | None,
    error_code: str,
) -> None:
    if source == "free":
        await db.execute(
            update(DeviceUsage)
            .where(DeviceUsage.device_hash == device_hash, DeviceUsage.free_uses_used > 0)
            .values(free_uses_used=DeviceUsage.free_uses_used - 1)
        )
    elif source == "credit":
        await db.execute(
            update(UsageSummary)
            .where(UsageSummary.user_id == user_id)
            .values(paid_credits=UsageSummary.paid_credits + 1)
        )
    idem = await db.get(IdempotencyKey, key)
    if idem:
        idem.status = "failed"
        idem.error_code = error_code
    db.add(UsageEvent(
        user_id=user_id,
        endpoint=endpoint,
        credits_used=0,
        source=source,
        prompt_version=f"{endpoint}_v1",
        success=False,
        error_code=error_code,
    ))
    await db.commit()
