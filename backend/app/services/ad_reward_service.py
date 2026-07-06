from datetime import datetime, timedelta, timezone

from sqlalchemy import delete, func, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.errors import ApiException
from app.models.ad_reward import AdReward
from app.models.usage import UsageSummary
from app.services.usage_service import ensure_summary

# Only rewarded-ad views are creditable, and each completed view is worth this
# many credits. The value is decided server-side; the client only reports that
# an ad finished and can never influence the amount granted.
REWARD_TYPE = "admob_rewarded"
REWARD_AMOUNT = 2

# Rolling 24h window keeps the cap abuse-resistant (no midnight refill gaming)
# while still meaning "per day" for the user.
_DAILY_WINDOW = timedelta(hours=24)


async def _daily_count(db: AsyncSession, user_id: int, now: datetime) -> int:
    count = await db.scalar(
        select(func.count(AdReward.id)).where(
            AdReward.user_id == user_id,
            AdReward.created_at >= now - _DAILY_WINDOW,
        )
    )
    return int(count or 0)


def _result(credits: int, awarded: int, daily_count: int) -> dict:
    remaining = max(0, settings.ad_reward_daily_limit - daily_count)
    return {"credits": credits, "awarded": awarded, "dailyRemaining": remaining}


async def _compensate(
    db: AsyncSession, user_id: int, reward_id: int, now: datetime
) -> None:
    """Undo a reward that lost a post-commit race.

    Deletes the just-inserted row and refunds the credit it added, so a burst of
    concurrent claims can never leave more than the cap credited. Committed as
    its own transaction so the rollback is durable before we raise.
    """
    await db.execute(delete(AdReward).where(AdReward.id == reward_id))
    await db.execute(
        update(UsageSummary)
        .where(
            UsageSummary.user_id == user_id,
            UsageSummary.paid_credits >= REWARD_AMOUNT,
        )
        .values(
            paid_credits=UsageSummary.paid_credits - REWARD_AMOUNT,
            updated_at=now,
        )
    )
    await db.commit()


async def grant_ad_reward(
    db: AsyncSession,
    user_id: int,
    idempotency_key: str,
) -> dict:
    """Grant the ad-reward credits (``REWARD_AMOUNT``) to *user_id*, enforcing
    all abuse controls.

    Race-safe design (insert-first, enforce-after-commit):

      1. Idempotent replay is resolved first, so a retried key never re-inserts
         and never trips the cooldown.
      2. The reward row and the credit are inserted and committed *up front*.
      3. The daily cap is enforced by re-counting committed rows in the window;
         if this row pushed the total over the cap it lost the race and is
         compensated (row deleted, credit refunded) before raising.
      4. The cooldown is enforced by checking for any *other* committed reward
         within a symmetric cooldown window around this row; if one exists this
         request is compensated and raises.

    Enforcing after the commit (instead of check-then-act before the insert)
    closes the window where concurrent requests with distinct idempotency keys
    each pass a pre-check and then all insert. The daily count-vs-limit and the
    symmetric cooldown window each guarantee — via the commit→re-read
    happens-before ordering — that at most the allowed number of a concurrent
    batch can survive. Under heavy contention this is fail-closed (it may reject
    a borderline claim rather than over-grant), matching
    ``usage_service.begin_generation``.
    """
    now = datetime.now(timezone.utc)
    summary = await ensure_summary(db, user_id)

    # 1. Idempotent replay — return the stored outcome without adding again.
    existing = await db.scalar(
        select(AdReward).where(
            AdReward.user_id == user_id,
            AdReward.idempotency_key == idempotency_key,
        )
    )
    if existing is not None:
        return _result(
            summary.paid_credits,
            existing.amount,
            await _daily_count(db, user_id, now),
        )

    # 2. Insert the reward + credit and commit so the row is durable and visible
    #    to the post-commit re-checks. The savepoint makes a concurrent
    #    duplicate key (IntegrityError) neither double-credit nor half-commit.
    reward = AdReward(
        user_id=user_id,
        idempotency_key=idempotency_key,
        reward_type=REWARD_TYPE,
        amount=REWARD_AMOUNT,
        created_at=now,
    )
    try:
        async with db.begin_nested():
            db.add(reward)
            await db.flush()  # surface IntegrityError before the UPDATE
            await db.execute(
                update(UsageSummary)
                .where(UsageSummary.user_id == user_id)
                .values(
                    paid_credits=UsageSummary.paid_credits + REWARD_AMOUNT,
                    updated_at=now,
                )
            )
    except IntegrityError:
        # Concurrent request already recorded this key — treat as a replay.
        await db.rollback()
        summary = await ensure_summary(db, user_id)
        return _result(
            summary.paid_credits,
            REWARD_AMOUNT,
            await _daily_count(db, user_id, now),
        )

    await db.commit()

    # 3. Daily cap (race-safe). The count includes the row just committed, so if
    #    it now exceeds the cap this request lost the race and must roll back.
    if await _daily_count(db, user_id, now) > settings.ad_reward_daily_limit:
        await _compensate(db, user_id, reward.id, now)
        raise ApiException(
            "AD_REWARD_LIMIT",
            "Daily ad reward limit reached.",
            429,
        )

    # 4. Cooldown (race-safe). Any *other* committed reward within a symmetric
    #    cooldown window means two rewards landed too close together; the
    #    symmetric window guarantees at most one of a concurrent pair survives.
    cooldown = settings.ad_reward_cooldown_seconds
    if cooldown > 0:
        window = timedelta(seconds=cooldown)
        conflicts = await db.scalar(
            select(func.count(AdReward.id)).where(
                AdReward.user_id == user_id,
                AdReward.id != reward.id,
                AdReward.created_at > now - window,
                AdReward.created_at < now + window,
            )
        )
        if int(conflicts or 0) > 0:
            await _compensate(db, user_id, reward.id, now)
            raise ApiException(
                "AD_REWARD_COOLDOWN",
                "Please wait a moment before watching another ad.",
                429,
            )

    await db.refresh(summary)
    return _result(
        summary.paid_credits,
        REWARD_AMOUNT,
        await _daily_count(db, user_id, now),
    )
