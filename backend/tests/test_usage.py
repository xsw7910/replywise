import asyncio
import threading

from fastapi.testclient import TestClient
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.api.v1.ai import get_ai_service
from app.config import settings
from app.database import AsyncSessionLocal
from app.main import app
from app.models.usage import IdempotencyKey, UsageSummary
from app.models.user import User
from app.services.ai_service import AIService


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
        async with AsyncSessionLocal() as db:
            summary = await db.get(UsageSummary, user_id)
            summary.free_uses_used = summary.free_uses_limit
            summary.paid_credits = 2
            await db.commit()
    asyncio.run(seed())

    response = _reply(client, auth, 'credit-use')
    assert response.status_code == 200
    assert response.json()['usage']['source'] == 'credit'
    assert response.json()['usage']['paidCredits'] == 1


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


def test_concurrent_no_overdraw(client: TestClient) -> None:
    """Two concurrent requests must not consume more free uses than succeed."""
    auth, _ = _auth(client, 'conc-no-overdraw')
    results: list[int] = []
    lock = threading.Lock()
    barrier = threading.Barrier(2)

    def make_request(key: str) -> None:
        barrier.wait(timeout=5)
        r = _reply(client, auth, key)
        with lock:
            results.append(r.status_code)

    threads = [
        threading.Thread(target=make_request, args=(f'conc-no-{i}',))
        for i in range(2)
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    success_count = results.count(200)
    me = client.get('/v1/me', headers=auth).json()
    assert me['freeUsesUsed'] == success_count, (
        f"freeUsesUsed={me['freeUsesUsed']} does not match success_count={success_count}"
    )


def test_concurrent_rate_limit(client: TestClient, monkeypatch) -> None:
    """With rate_limit=1, two concurrent requests cannot both return 200."""
    monkeypatch.setattr(settings, 'generation_rate_per_minute', 1)
    auth, _ = _auth(client, 'conc-rate')
    results: list[int] = []
    lock = threading.Lock()
    barrier = threading.Barrier(2)

    def make_request(key: str) -> None:
        barrier.wait(timeout=5)
        r = _reply(client, auth, key)
        with lock:
            results.append(r.status_code)

    threads = [
        threading.Thread(target=make_request, args=(f'conc-rate-{i}',))
        for i in range(2)
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert results.count(200) < 2, f"Both concurrent requests succeeded; statuses={results}"
