import hashlib
import json
from datetime import datetime, timedelta, timezone

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.config import settings
from app.errors import ApiException
from app.models.usage import IdempotencyKey, UsageEvent, UsageSummary


def canonicalize(model) -> tuple[str, str]:
    raw = model.model_dump(mode="json")
    clean = _clean(raw)
    clean.setdefault("output_lang", "en")
    if "audience" in clean:
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


def summary_dict(summary: UsageSummary, is_premium: bool = False) -> dict:
    left = None if is_premium else max(0, summary.free_uses_limit - summary.free_uses_used)
    return {
        "isPremium": is_premium,
        "freeUsesLimit": summary.free_uses_limit,
        "freeUsesUsed": summary.free_uses_used,
        "freeUsesLeft": left,
        "paidCredits": summary.paid_credits,
        "upgradeRequired": not is_premium and left == 0 and summary.paid_credits == 0,
    }


async def cleanup_expired(db: AsyncSession) -> None:
    await db.execute(delete(IdempotencyKey).where(IdempotencyKey.expires_at < datetime.now(timezone.utc)))
    await db.commit()


async def begin_generation(
    db: AsyncSession, user_id: int, endpoint: str, key: str, request_hash: str
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

    # Atomic deduction: free first, then paid credits
    await ensure_summary(db, user_id)
    now = datetime.now(timezone.utc)
    free = await db.execute(
        update(UsageSummary)
        .where(UsageSummary.user_id == user_id, UsageSummary.free_uses_used < UsageSummary.free_uses_limit)
        .values(free_uses_used=UsageSummary.free_uses_used + 1, updated_at=now)
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
        await rollback_generation(db, user_id, endpoint, key, source, "RATE_LIMITED")
        raise ApiException("RATE_LIMITED", "Too many requests. Please try again shortly.", 429)

    return source, None


async def finish_generation(
    db: AsyncSession, user_id: int, endpoint: str, key: str, source: str, response: dict
) -> dict:
    summary = await ensure_summary(db, user_id)
    usage = {**summary_dict(summary), "creditsUsed": 1, "source": source}
    combined = {**response, "usage": usage}
    idem = await db.get(IdempotencyKey, key)
    idem.status = "succeeded"
    idem.response_json = json.dumps(combined, ensure_ascii=False)
    db.add(UsageEvent(
        user_id=user_id,
        endpoint=endpoint,
        credits_used=1,
        source=source,
        prompt_version=f"{endpoint}_v1",
        success=True,
    ))
    await db.commit()
    return combined


async def rollback_generation(
    db: AsyncSession, user_id: int, endpoint: str, key: str, source: str, error_code: str
) -> None:
    if source == "free":
        await db.execute(
            update(UsageSummary)
            .where(UsageSummary.user_id == user_id, UsageSummary.free_uses_used > 0)
            .values(free_uses_used=UsageSummary.free_uses_used - 1)
        )
    else:
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
