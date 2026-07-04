import asyncio

from fastapi.testclient import TestClient
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.api.v1.ai import get_ai_service
from app.config import settings
from app.database import AsyncSessionLocal, Base
from app.errors import ApiException
from app.main import app
from app.models.subscription import SubscriptionCache
from app.models.usage import DeviceUsage, IdempotencyKey, UsageEvent, UsageSummary
from app.models.user import User
from app.services.ai_service import AIService
from app.services.usage_service import begin_generation


def _auth_device(client: TestClient, app_user_id: str, device_id: str) -> tuple[dict[str, str], int]:
    """Authenticate with an explicit app_user_id and device_id pair.

    Unlike _auth(), this lets a test pin two different app_user_ids to the same
    device_id to simulate an anonymous reinstall.
    """
    response = client.post('/v1/auth/anonymous', json={
        'appUserId': app_user_id, 'deviceId': device_id, 'platform': 'android'
    })
    body = response.json()
    return {'Authorization': f"Bearer {body['accessToken']}"}, body['me']['userId']


def _auth(client: TestClient, suffix: str) -> tuple[dict[str, str], int]:
    response = client.post('/v1/auth/anonymous', json={
        'appUserId': f'usage-{suffix}', 'deviceId': f'device-{suffix}', 'platform': 'android'
    })
    body = response.json()
    return {'Authorization': f"Bearer {body['accessToken']}"}, body['me']['userId']


def _reply(client: TestClient, auth: dict[str, str], key: str, incoming: str = 'Hello'):
    return client.post('/v1/reply', json={
        'incoming': incoming, 'guidance': 'Reply warmly', 'audience': {'mode': 'auto'}
    }, headers={**auth, 'X-Idempotency-Key': key})


def _polish(client: TestClient, auth: dict[str, str], key: str, draft: str = 'Hello there.'):
    return client.post('/v1/polish', json={
        'draft': draft, 'direction': 'natural', 'guidanceLang': 'en'
    }, headers={**auth, 'X-Idempotency-Key': key})


def _seed_successful_free_events(user_id: int, count: int) -> None:
    async def seed() -> None:
        async with AsyncSessionLocal() as db:
            for index in range(count):
                db.add(UsageEvent(
                    user_id=user_id,
                    endpoint='reply',
                    credits_used=1,
                    source='free',
                    prompt_version=f'seed-{index}',
                    success=True,
                ))
            await db.commit()

    asyncio.run(seed())


def _isolated_database(tmp_path, filename: str):
    database_path = (tmp_path / filename).as_posix()
    engine = create_async_engine(
        f'sqlite+aiosqlite:///{database_path}',
        connect_args={'timeout': 5},
    )
    return engine, async_sessionmaker(engine, expire_on_commit=False)


async def _attempt_generation(
    sessions,
    *,
    user_id: int,
    device_hash: str,
    key: str,
) -> tuple[str, str]:
    async with sessions() as db:
        try:
            source, _ = await begin_generation(
                db=db,
                user_id=user_id,
                device_hash=device_hash,
                endpoint='reply',
                key=key,
                request_hash=f'hash-{key}',
            )
        except ApiException as error:
            return 'error', error.code
        return 'success', source or ''


def test_free_deduction_and_paywall_after_five_uses(client: TestClient) -> None:
    auth, _ = _auth(client, 'free')
    for index in range(5):
        response = _reply(client, auth, f'free-{index}')
        assert response.status_code == 200
        assert response.json()['usage']['freeUsesLeft'] == 4 - index
    blocked = _reply(client, auth, 'free-sixth')
    assert blocked.status_code == 402
    assert blocked.json()['error']['code'] == 'PAYWALL_REQUIRED'


def test_paid_credits_are_used_after_free_allowance(client: TestClient) -> None:
    auth, user_id = _auth(client, 'credits')

    async def seed() -> None:
        # Free usage is device-scoped; exhaust the device allowance.
        async with AsyncSessionLocal() as db:
            user = await db.get(User, user_id)
            device = await db.get(DeviceUsage, user.device_hash)
            device.free_uses_used = device.free_uses_limit
            summary = await db.get(UsageSummary, user_id)
            summary.paid_credits = 2
            await db.commit()
    asyncio.run(seed())

    response = _reply(client, auth, 'credit-use')
    assert response.status_code == 200
    assert response.json()['usage']['source'] == 'credit'
    assert response.json()['usage']['paidCredits'] == 1


def test_concurrent_requests_cannot_overdraw_last_paid_credit(
    tmp_path,
) -> None:
    """Two independent transactions cannot overdraw one remaining credit."""

    async def run_race() -> tuple[list[tuple[str, str]], int]:
        engine, sessions = _isolated_database(
            tmp_path,
            'paid-credit-race.db',
        )
        user_id = 1
        device_hash = 'last-paid-credit-device'

        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)

            async with sessions() as db:
                db.add(
                    User(
                        id=user_id,
                        app_user_id='last-paid-credit-user',
                        device_hash=device_hash,
                        platform='test',
                    )
                )
                db.add(
                    DeviceUsage(
                        device_hash=device_hash,
                        free_uses_limit=5,
                        free_uses_used=5,
                    )
                )
                db.add(UsageSummary(user_id=user_id, paid_credits=1))
                await db.commit()

            results = await asyncio.gather(
                _attempt_generation(
                    sessions,
                    user_id=user_id,
                    device_hash=device_hash,
                    key='last-paid-credit-1',
                ),
                _attempt_generation(
                    sessions,
                    user_id=user_id,
                    device_hash=device_hash,
                    key='last-paid-credit-2',
                ),
            )

            async with sessions() as db:
                summary = await db.get(UsageSummary, user_id)
                remaining = summary.paid_credits
            return results, remaining
        finally:
            await engine.dispose()

    results, remaining = asyncio.run(run_race())

    assert results.count(('success', 'credit')) == 1, results
    assert results.count(('error', 'PAYWALL_REQUIRED')) == 1, results
    assert remaining == 0
    assert remaining >= 0


def test_paid_credit_idempotent_replay_deducts_once(
    client: TestClient,
) -> None:
    """Replay returns the stored response; a changed payload conflicts."""
    auth, user_id = _auth(client, 'paid-idempotency')

    async def seed_paid_credits() -> None:
        async with AsyncSessionLocal() as db:
            user = await db.get(User, user_id)
            device = await db.get(DeviceUsage, user.device_hash)
            device.free_uses_used = device.free_uses_limit
            summary = await db.get(UsageSummary, user_id)
            summary.paid_credits = 2
            await db.commit()

    asyncio.run(seed_paid_credits())

    first = _reply(client, auth, 'paid-idempotency-key')
    replay = _reply(client, auth, 'paid-idempotency-key')
    conflict = _reply(
        client,
        auth,
        'paid-idempotency-key',
        incoming='Different payload',
    )

    assert first.status_code == 200
    assert first.json()['usage']['source'] == 'credit'
    assert first.json()['usage']['paidCredits'] == 1
    assert replay.status_code == 200
    assert replay.json() == first.json()
    assert conflict.status_code == 409
    assert conflict.json()['error']['code'] == 'IDEMPOTENCY_CONFLICT'

    async def paid_credit_balance() -> int:
        async with AsyncSessionLocal() as db:
            summary = await db.get(UsageSummary, user_id)
            return summary.paid_credits

    assert asyncio.run(paid_credit_balance()) == 1


def test_idempotent_replay_and_conflict(client: TestClient) -> None:
    auth, _ = _auth(client, 'idem')
    first = _reply(client, auth, 'same-key')
    replay = _reply(client, auth, 'same-key')
    conflict = _reply(client, auth, 'same-key', incoming='Different')
    assert replay.status_code == 200
    assert replay.json() == first.json()
    assert conflict.status_code == 409
    assert conflict.json()['error']['code'] == 'IDEMPOTENCY_CONFLICT'
    assert client.get('/v1/me', headers=auth).json()['freeUsesUsed'] == 1


class _Unavailable:
    async def complete(self, system_prompt: str, payload: dict) -> str:
        raise TimeoutError('down')


def test_model_failure_rolls_back_usage(client: TestClient) -> None:
    auth, _ = _auth(client, 'rollback')
    app.dependency_overrides[get_ai_service] = lambda: AIService(_Unavailable())
    try:
        response = _reply(client, auth, 'rollback-key')
    finally:
        app.dependency_overrides.pop(get_ai_service, None)
    assert response.status_code == 503
    assert client.get('/v1/me', headers=auth).json()['freeUsesUsed'] == 0


def test_explain_is_free_and_rate_limited(client: TestClient, monkeypatch) -> None:
    from app.config import settings
    monkeypatch.setattr(settings, 'explain_daily_limit', 1)
    auth, _ = _auth(client, 'explain-free')
    assert client.post('/v1/explain', json={'text': 'Hello'}, headers=auth).status_code == 200
    limited = client.post('/v1/explain', json={'text': 'Again'}, headers=auth)
    assert limited.status_code == 429
    assert limited.json()['error']['code'] == 'RATE_LIMITED'
    assert client.get('/v1/me', headers=auth).json()['freeUsesUsed'] == 0


def test_generation_database_rate_limit(client: TestClient, monkeypatch) -> None:
    from app.config import settings
    monkeypatch.setattr(settings, 'generation_rate_per_minute', 1)
    auth, _ = _auth(client, 'rate')
    assert _reply(client, auth, 'rate-1').status_code == 200
    limited = _reply(client, auth, 'rate-2')
    assert limited.status_code == 429
    assert limited.json()['error']['code'] == 'RATE_LIMITED'


def test_expired_idempotency_keys_are_cleaned(client: TestClient) -> None:
    auth, user_id = _auth(client, 'cleanup')

    async def seed_and_check() -> None:
        async with AsyncSessionLocal() as db:
            db.add(IdempotencyKey(
                key='expired-key', user_id=user_id, endpoint='reply',
                request_hash='old', status='failed',
                expires_at=datetime.now(timezone.utc) - timedelta(seconds=1),
            ))
            await db.commit()
    asyncio.run(seed_and_check())

    assert _reply(client, auth, 'cleanup-trigger').status_code == 200

    async def is_gone() -> bool:
        async with AsyncSessionLocal() as db:
            return await db.get(IdempotencyKey, 'expired-key') is None
    assert asyncio.run(is_gone())


def test_polish_deduction_matches_reply(client: TestClient) -> None:
    """Polish and Reply both consume one free use from the same pool."""
    auth, _ = _auth(client, 'polish-deduct')

    reply_resp = _reply(client, auth, 'polish-deduct-reply')
    assert reply_resp.status_code == 200
    assert reply_resp.json()['usage']['source'] == 'free'
    assert reply_resp.json()['usage']['freeUsesLeft'] == 4

    polish_resp = _polish(client, auth, 'polish-deduct-polish')
    assert polish_resp.status_code == 200
    assert polish_resp.json()['usage']['source'] == 'free'
    assert polish_resp.json()['usage']['freeUsesLeft'] == 3

    me = client.get('/v1/me', headers=auth).json()
    assert me['freeUsesUsed'] == 2
    assert me['freeUsesLeft'] == 3


def test_concurrent_no_overdraw(tmp_path) -> None:
    """Concurrent free deductions do not lose updates."""

    async def run_race() -> tuple[list[tuple[str, str]], int]:
        engine, sessions = _isolated_database(tmp_path, 'free-usage-race.db')
        user_id = 1
        device_hash = 'free-usage-race-device'

        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)

            async with sessions() as db:
                db.add(
                    User(
                        id=user_id,
                        app_user_id='free-usage-race-user',
                        device_hash=device_hash,
                        platform='test',
                    )
                )
                db.add(
                    DeviceUsage(
                        device_hash=device_hash,
                        free_uses_limit=5,
                        free_uses_used=0,
                    )
                )
                db.add(UsageSummary(user_id=user_id, paid_credits=0))
                await db.commit()

            results = await asyncio.gather(
                _attempt_generation(
                    sessions,
                    user_id=user_id,
                    device_hash=device_hash,
                    key='free-usage-race-1',
                ),
                _attempt_generation(
                    sessions,
                    user_id=user_id,
                    device_hash=device_hash,
                    key='free-usage-race-2',
                ),
            )

            async with sessions() as db:
                device = await db.get(DeviceUsage, device_hash)
                free_uses_used = device.free_uses_used
            return results, free_uses_used
        finally:
            await engine.dispose()

    results, free_uses_used = asyncio.run(run_race())
    assert results.count(('success', 'free')) == 2, results
    assert free_uses_used == 2


def test_free_quota_shared_by_device_across_reinstall(client: TestClient) -> None:
    """Free uses are limited per device_hash, so an anonymous reinstall — a new
    app_user_id on the same device — does not refill the free allowance, while a
    genuinely different device still gets its own fresh allowance."""
    device_x = 'shared-device-x'

    # User A on device X exhausts all 5 free uses.
    auth_a, _ = _auth_device(client, 'reinstall-user-a', device_x)
    for index in range(5):
        response = _reply(client, auth_a, f'a-{index}')
        assert response.status_code == 200
        assert response.json()['usage']['freeUsesLeft'] == 4 - index

    # Reinstall: User B is a brand-new app_user_id on the SAME device X.
    auth_b, user_id_b = _auth_device(client, 'reinstall-user-b', device_x)
    assert user_id_b  # B is a distinct user row

    # B inherits the device's exhausted allowance: 0 free uses remaining.
    me_b = client.get('/v1/me', headers=auth_b).json()
    assert me_b['freeUsesUsed'] == 5
    assert me_b['freeUsesLeft'] == 0
    assert me_b['upgradeRequired'] is True

    # B is blocked by the paywall when attempting another free request.
    blocked = _reply(client, auth_b, 'b-blocked')
    assert blocked.status_code == 402
    assert blocked.json()['error']['code'] == 'PAYWALL_REQUIRED'

    # User C on a DIFFERENT device Y still gets a fresh 5 free uses.
    auth_c, _ = _auth_device(client, 'reinstall-user-c', 'different-device-y')
    me_c = client.get('/v1/me', headers=auth_c).json()
    assert me_c['freeUsesUsed'] == 0
    assert me_c['freeUsesLeft'] == 5
    first_c = _reply(client, auth_c, 'c-0')
    assert first_c.status_code == 200
    assert first_c.json()['usage']['freeUsesLeft'] == 4


def test_me_aggregates_successful_free_events_across_same_device_users(
    client: TestClient,
) -> None:
    device = 'event-aggregate-device'
    auth_a, user_a = _auth_device(client, 'event-user-a', device)
    auth_b, user_b = _auth_device(client, 'event-user-b', device)
    auth_c, _ = _auth_device(client, 'event-user-c', device)

    _seed_successful_free_events(user_a, 2)
    _seed_successful_free_events(user_b, 1)

    me_b = client.get('/v1/me', headers=auth_b).json()
    assert me_b['freeUsesUsed'] == 3
    assert me_b['freeUsesLeft'] == 2

    me_c = client.get('/v1/me', headers=auth_c).json()
    assert me_c['freeUsesUsed'] == 3
    assert me_c['freeUsesLeft'] == 2

    # The user that owns two events observes the same device total.
    me_a = client.get('/v1/me', headers=auth_a).json()
    assert me_a['freeUsesUsed'] == 3


def test_event_exhausted_shared_device_blocks_reply_and_polish(
    client: TestClient,
) -> None:
    device = 'event-exhausted-device'
    _, user_a = _auth_device(client, 'event-exhaust-a', device)
    _seed_successful_free_events(user_a, 5)

    auth_new, _ = _auth_device(client, 'event-exhaust-new', device)
    me = client.get('/v1/me', headers=auth_new).json()
    assert me['freeUsesUsed'] == 5
    assert me['freeUsesLeft'] == 0
    assert me['upgradeRequired'] is True

    reply = _reply(client, auth_new, 'event-exhaust-reply')
    assert reply.status_code == 402
    assert reply.json()['error']['code'] == 'PAYWALL_REQUIRED'

    polish = _polish(client, auth_new, 'event-exhaust-polish')
    assert polish.status_code == 402
    assert polish.json()['error']['code'] == 'PAYWALL_REQUIRED'

    auth_other, _ = _auth_device(
        client, 'event-exhaust-other', 'event-exhaust-different-device'
    )
    other_me = client.get('/v1/me', headers=auth_other).json()
    assert other_me['freeUsesUsed'] == 0
    assert other_me['freeUsesLeft'] == 5


def test_paid_credits_remain_user_scoped_on_shared_exhausted_device(
    client: TestClient,
) -> None:
    device = 'user-scoped-credit-device'
    auth_a, user_a = _auth_device(client, 'credit-owner-a', device)
    auth_b, _ = _auth_device(client, 'credit-owner-b', device)
    _seed_successful_free_events(user_a, 5)

    async def grant_only_a() -> None:
        async with AsyncSessionLocal() as db:
            summary_a = await db.get(UsageSummary, user_a)
            summary_a.paid_credits = 1
            await db.commit()

    asyncio.run(grant_only_a())

    blocked_b = _reply(client, auth_b, 'credit-owner-b-blocked')
    assert blocked_b.status_code == 402
    assert client.get('/v1/me', headers=auth_b).json()['paidCredits'] == 0

    allowed_a = _reply(client, auth_a, 'credit-owner-a-allowed')
    assert allowed_a.status_code == 200
    assert allowed_a.json()['usage']['source'] == 'credit'
    assert allowed_a.json()['usage']['paidCredits'] == 0


def test_concurrent_same_device_requests_cannot_exceed_last_free_use(
    tmp_path,
) -> None:
    async def run_race() -> tuple[list[tuple[str, str]], int]:
        engine, sessions = _isolated_database(tmp_path, 'last-free-use-race.db')
        device_hash = 'shared-last-free-device'

        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)

            async with sessions() as db:
                db.add_all(
                    [
                        User(
                            id=1,
                            app_user_id='shared-last-free-user-1',
                            device_hash=device_hash,
                            platform='test',
                        ),
                        User(
                            id=2,
                            app_user_id='shared-last-free-user-2',
                            device_hash=device_hash,
                            platform='test',
                        ),
                        DeviceUsage(
                            device_hash=device_hash,
                            free_uses_limit=5,
                            free_uses_used=4,
                        ),
                        UsageSummary(user_id=1, paid_credits=0),
                        UsageSummary(user_id=2, paid_credits=0),
                    ]
                )
                await db.commit()

            results = await asyncio.gather(
                _attempt_generation(
                    sessions,
                    user_id=1,
                    device_hash=device_hash,
                    key='shared-last-free-1',
                ),
                _attempt_generation(
                    sessions,
                    user_id=2,
                    device_hash=device_hash,
                    key='shared-last-free-2',
                ),
            )

            async with sessions() as db:
                device = await db.get(DeviceUsage, device_hash)
                free_uses_used = device.free_uses_used
            return results, free_uses_used
        finally:
            await engine.dispose()

    results, free_uses_used = asyncio.run(run_race())
    assert results.count(('success', 'free')) == 1, results
    assert results.count(('error', 'PAYWALL_REQUIRED')) == 1, results
    assert free_uses_used == 5


def test_premium_user_bypasses_exhausted_device_quota(client: TestClient) -> None:
    """A premium user on a device whose shared free quota is already exhausted
    still generates normally (premium is per-user, not gated by the device)."""
    device = 'premium-shared-device'
    auth_a, _ = _auth_device(client, 'premium-share-a', device)
    for index in range(5):
        assert _reply(client, auth_a, f'pa-{index}').status_code == 200

    auth_b, user_id_b = _auth_device(client, 'premium-share-b', device)

    async def make_premium() -> None:
        async with AsyncSessionLocal() as db:
            db.add(SubscriptionCache(
                user_id=user_id_b,
                entitlement_id='premium',
                is_premium=True,
                product_identifier='premium_yearly:yearly',
                expires_at=datetime.now(timezone.utc) + timedelta(days=3),
            ))
            await db.commit()
    asyncio.run(make_premium())

    response = _reply(client, auth_b, 'pb-0')
    assert response.status_code == 200
    assert response.json()['usage']['isPremium'] is True
    assert response.json()['usage']['source'] is None  # premium is not billed


def test_credit_user_on_exhausted_device_consumes_credit(client: TestClient) -> None:
    """A user with paid credits on a device whose shared free quota is exhausted
    spends a credit instead of being blocked (credits are per-user)."""
    device = 'credit-shared-device'
    auth_a, _ = _auth_device(client, 'credit-share-a', device)
    for index in range(5):
        assert _reply(client, auth_a, f'ca-{index}').status_code == 200

    auth_b, user_id_b = _auth_device(client, 'credit-share-b', device)

    async def grant_credits() -> None:
        async with AsyncSessionLocal() as db:
            summary = await db.get(UsageSummary, user_id_b)
            summary.paid_credits = 3
            await db.commit()
    asyncio.run(grant_credits())

    response = _reply(client, auth_b, 'cb-0')
    assert response.status_code == 200
    assert response.json()['usage']['source'] == 'credit'
    assert response.json()['usage']['paidCredits'] == 2


def test_concurrent_rate_limit(tmp_path, monkeypatch) -> None:
    """With rate_limit=1, two concurrent requests cannot both return 200."""
    monkeypatch.setattr(settings, 'generation_rate_per_minute', 1)

    async def run_race() -> tuple[list[tuple[str, str]], int]:
        engine, sessions = _isolated_database(tmp_path, 'rate-limit-race.db')
        user_id = 1
        device_hash = 'rate-limit-race-device'

        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)

            async with sessions() as db:
                db.add(
                    User(
                        id=user_id,
                        app_user_id='rate-limit-race-user',
                        device_hash=device_hash,
                        platform='test',
                    )
                )
                db.add(
                    DeviceUsage(
                        device_hash=device_hash,
                        free_uses_limit=5,
                        free_uses_used=0,
                    )
                )
                db.add(UsageSummary(user_id=user_id, paid_credits=0))
                await db.commit()

            results = await asyncio.gather(
                _attempt_generation(
                    sessions,
                    user_id=user_id,
                    device_hash=device_hash,
                    key='rate-limit-race-1',
                ),
                _attempt_generation(
                    sessions,
                    user_id=user_id,
                    device_hash=device_hash,
                    key='rate-limit-race-2',
                ),
            )

            async with sessions() as db:
                device = await db.get(DeviceUsage, device_hash)
                free_uses_used = device.free_uses_used
            return results, free_uses_used
        finally:
            await engine.dispose()

    results, free_uses_used = asyncio.run(run_race())
    success_count = results.count(('success', 'free'))
    assert success_count < 2, results
    assert all(
        result == ('success', 'free') or result == ('error', 'RATE_LIMITED')
        for result in results
    ), results
    assert free_uses_used == success_count
