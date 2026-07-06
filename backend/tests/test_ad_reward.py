import asyncio

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.config import settings
from app.database import AsyncSessionLocal, Base
from app.errors import ApiException
from app.models.ad_reward import AdReward
from app.models.usage import UsageSummary
from app.models.user import User
from app.services.ad_reward_service import grant_ad_reward


# ── Helpers ──────────────────────────────────────────────────────────────────

def _auth(client: TestClient, suffix: str) -> tuple[dict[str, str], int]:
    resp = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": f"ad-{suffix}",
            "deviceId": f"device-{suffix}",
            "platform": "android",
        },
    )
    body = resp.json()
    return {"Authorization": f"Bearer {body['accessToken']}"}, body["me"]["userId"]


def _claim(
    client: TestClient,
    auth: dict[str, str],
    key: str,
    *,
    reward_type: str = "admob_rewarded",
    amount: int = 1,
):
    return client.post(
        "/v1/credits/ad-reward",
        json={
            "idempotencyKey": key,
            "rewardType": reward_type,
            "amount": amount,
        },
        headers=auth,
    )


def _paid_credits(client: TestClient, auth: dict[str, str]) -> int:
    return client.get("/v1/me", headers=auth).json()["paidCredits"]


# ── Tests ─────────────────────────────────────────────────────────────────────

def test_ad_reward_requires_authentication(client: TestClient) -> None:
    resp = client.post(
        "/v1/credits/ad-reward",
        json={"idempotencyKey": "k1", "rewardType": "admob_rewarded", "amount": 1},
    )
    assert resp.status_code == 401


def test_successful_reward_adds_one_credit(client: TestClient) -> None:
    auth, _ = _auth(client, "success")
    resp = _claim(client, auth, "success-key-1")
    assert resp.status_code == 200
    body = resp.json()
    assert body["credits"] == 1
    assert body["awarded"] == 1
    assert body["dailyRemaining"] == 4
    # Balance is reflected server-side, not just in the response.
    assert _paid_credits(client, auth) == 1


def test_duplicate_idempotency_key_does_not_double_add(client: TestClient) -> None:
    auth, user_id = _auth(client, "dup")
    first = _claim(client, auth, "dup-key")
    assert first.status_code == 200
    assert first.json()["credits"] == 1

    # Same key replays without adding a second credit and without tripping the
    # cooldown that a genuinely new claim would hit this quickly.
    replay = _claim(client, auth, "dup-key")
    assert replay.status_code == 200
    assert replay.json()["credits"] == 1
    assert replay.json()["awarded"] == 1
    assert _paid_credits(client, auth) == 1

    async def row_count() -> int:
        async with AsyncSessionLocal() as db:
            return await db.scalar(
                select(func.count(AdReward.id)).where(AdReward.user_id == user_id)
            ) or 0

    assert asyncio.run(row_count()) == 1


def test_daily_limit_blocks_after_five(client: TestClient, monkeypatch) -> None:
    # Remove the cooldown so five successful rewards can be earned back-to-back;
    # the daily cap must still stop the sixth.
    monkeypatch.setattr(settings, "ad_reward_cooldown_seconds", 0)
    auth, _ = _auth(client, "daily")

    for index in range(5):
        resp = _claim(client, auth, f"daily-{index}")
        assert resp.status_code == 200, resp.json()
        assert resp.json()["dailyRemaining"] == 4 - index

    blocked = _claim(client, auth, "daily-6")
    assert blocked.status_code == 429
    assert blocked.json()["error"]["code"] == "AD_REWARD_LIMIT"
    assert _paid_credits(client, auth) == 5


def test_cooldown_blocks_rapid_repeated_rewards(client: TestClient) -> None:
    auth, _ = _auth(client, "cooldown")
    first = _claim(client, auth, "cooldown-1")
    assert first.status_code == 200

    # A different key immediately after is a genuine new claim, blocked by the
    # 60s cooldown rather than idempotency.
    rapid = _claim(client, auth, "cooldown-2")
    assert rapid.status_code == 429
    assert rapid.json()["error"]["code"] == "AD_REWARD_COOLDOWN"
    assert _paid_credits(client, auth) == 1


def test_invalid_amount_rejected(client: TestClient) -> None:
    auth, _ = _auth(client, "bad-amount")
    resp = _claim(client, auth, "bad-amount-key", amount=2)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "VALIDATION_ERROR"
    assert _paid_credits(client, auth) == 0


def test_invalid_reward_type_rejected(client: TestClient) -> None:
    auth, _ = _auth(client, "bad-type")
    resp = _claim(client, auth, "bad-type-key", reward_type="banner")
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "VALIDATION_ERROR"
    assert _paid_credits(client, auth) == 0


# ── Concurrency (race-safety of the daily cap and cooldown) ────────────────────
#
# The API-level tests above cover the sequential contract. These drive
# grant_ad_reward directly with independent sessions racing on a shared on-disk
# SQLite database (the same pattern as test_usage.py's concurrency tests) to
# prove that distinct idempotency keys arriving together cannot bypass the
# post-commit enforcement. Both caps are fail-closed, so the assertions bound
# the survivors from above (never more than allowed) rather than pinning an
# exact count.

def _isolated_database(tmp_path, filename: str):
    database_path = (tmp_path / filename).as_posix()
    engine = create_async_engine(
        f"sqlite+aiosqlite:///{database_path}",
        connect_args={"timeout": 10},
    )
    return engine, async_sessionmaker(engine, expire_on_commit=False)


async def _attempt_reward(sessions, *, user_id: int, key: str) -> tuple[str, str]:
    async with sessions() as db:
        try:
            result = await grant_ad_reward(db, user_id, key)
        except ApiException as error:
            return ("error", error.code)
        return ("ok", str(result["credits"]))


async def _seed_user(sessions, user_id: int, suffix: str) -> None:
    async with sessions() as db:
        db.add(
            User(
                id=user_id,
                app_user_id=f"ad-race-{suffix}",
                device_hash=f"ad-race-dev-{suffix}",
                platform="test",
            )
        )
        db.add(UsageSummary(user_id=user_id, paid_credits=0))
        await db.commit()


async def _reward_state(sessions, user_id: int) -> tuple[int, int]:
    async with sessions() as db:
        kept = await db.scalar(
            select(func.count(AdReward.id)).where(AdReward.user_id == user_id)
        )
        summary = await db.get(UsageSummary, user_id)
        return int(kept or 0), summary.paid_credits


def test_concurrent_distinct_keys_cannot_exceed_daily_limit(
    tmp_path, monkeypatch
) -> None:
    monkeypatch.setattr(settings, "ad_reward_daily_limit", 3)
    monkeypatch.setattr(settings, "ad_reward_cooldown_seconds", 0)

    async def run_race() -> tuple[list[tuple[str, str]], int, int]:
        engine, sessions = _isolated_database(tmp_path, "ad-daily-race.db")
        user_id = 1
        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)
            await _seed_user(sessions, user_id, "daily")

            results = await asyncio.gather(
                *[
                    _attempt_reward(
                        sessions, user_id=user_id, key=f"daily-race-{index}"
                    )
                    for index in range(6)
                ]
            )
            kept, credits = await _reward_state(sessions, user_id)
            return results, kept, credits
        finally:
            await engine.dispose()

    results, kept, credits = asyncio.run(run_race())
    successes = [r for r in results if r[0] == "ok"]

    assert kept <= 3, results  # never more than the cap survives
    assert credits == kept  # credits and surviving rows stay in lockstep
    assert len(successes) == kept
    assert all(
        r[0] == "ok" or r[1] == "AD_REWARD_LIMIT" for r in results
    ), results


def test_concurrent_distinct_keys_cannot_bypass_cooldown(
    tmp_path, monkeypatch
) -> None:
    monkeypatch.setattr(settings, "ad_reward_daily_limit", 5)
    monkeypatch.setattr(settings, "ad_reward_cooldown_seconds", 60)

    async def run_race() -> tuple[list[tuple[str, str]], int, int]:
        engine, sessions = _isolated_database(tmp_path, "ad-cooldown-race.db")
        user_id = 1
        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)
            await _seed_user(sessions, user_id, "cooldown")

            results = await asyncio.gather(
                *[
                    _attempt_reward(
                        sessions, user_id=user_id, key=f"cooldown-race-{index}"
                    )
                    for index in range(4)
                ]
            )
            kept, credits = await _reward_state(sessions, user_id)
            return results, kept, credits
        finally:
            await engine.dispose()

    results, kept, credits = asyncio.run(run_race())
    successes = [r for r in results if r[0] == "ok"]

    assert kept <= 1, results  # cooldown lets at most one of a burst through
    assert credits == kept
    assert len(successes) == kept
    assert all(
        r[0] == "ok" or r[1] == "AD_REWARD_COOLDOWN" for r in results
    ), results
