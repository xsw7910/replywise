import asyncio
from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient

from app.api.v1.entitlement import get_revenuecat_service
from app.database import AsyncSessionLocal
from app.main import app
from app.models.subscription import SubscriptionCache
from app.models.usage import UsageSummary
from app.services.revenuecat_service import (
    RevenueCatService,
    RevenueCatUnavailable,
    VerifiedEntitlement,
)


def _auth(client: TestClient, suffix: str) -> tuple[dict[str, str], int, str]:
    app_user_id = f"subscription-{suffix}"
    response = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": app_user_id,
            "deviceId": f"device-{suffix}",
            "platform": "android",
        },
    )
    body = response.json()
    return (
        {"Authorization": f"Bearer {body['accessToken']}"},
        body["me"]["userId"],
        app_user_id,
    )


class _FakeRevenueCat(RevenueCatService):
    def __init__(self, entitlement: VerifiedEntitlement) -> None:
        self.entitlement = entitlement
        self.seen_app_user_id: str | None = None

    async def verify(self, app_user_id: str) -> VerifiedEntitlement:
        self.seen_app_user_id = app_user_id
        return self.entitlement


class _UnavailableRevenueCat(RevenueCatService):
    async def verify(self, app_user_id: str) -> VerifiedEntitlement:
        raise RevenueCatUnavailable("offline")


def _reply(client: TestClient, auth: dict[str, str], key: str):
    return client.post(
        "/v1/reply",
        json={"incoming": "Hello", "guidance": "Reply warmly"},
        headers={**auth, "X-Idempotency-Key": key},
    )


def test_sync_is_token_bound_and_returns_premium_usage(client: TestClient) -> None:
    auth, _, app_user_id = _auth(client, "active")
    fake = _FakeRevenueCat(
        VerifiedEntitlement(
            is_premium=True,
            entitlement_id="premium",
            product_identifier="reply_premium_monthly",
            expires_at=datetime.now(timezone.utc) + timedelta(days=3),
        )
    )
    app.dependency_overrides[get_revenuecat_service] = lambda: fake
    try:
        response = client.post(
            "/v1/entitlement/sync",
            json={"isPremium": True, "appUserId": "forged-user"},
            headers=auth,
        )
    finally:
        app.dependency_overrides.pop(get_revenuecat_service, None)

    assert response.status_code == 200
    assert fake.seen_app_user_id == app_user_id
    assert response.json()["isPremium"] is True
    assert response.json()["freeUsesLeft"] is None


def test_premium_reply_and_polish_do_not_change_balances(client: TestClient) -> None:
    auth, user_id, _ = _auth(client, "no-deduct")

    async def seed() -> None:
        async with AsyncSessionLocal() as db:
            summary = await db.get(UsageSummary, user_id)
            summary.free_uses_used = 2
            summary.paid_credits = 7
            db.add(
                SubscriptionCache(
                    user_id=user_id,
                    entitlement_id="premium",
                    is_premium=True,
                    product_identifier="reply_premium_monthly",
                    expires_at=datetime.now(timezone.utc) + timedelta(days=1),
                )
            )
            await db.commit()

    asyncio.run(seed())
    response = _reply(client, auth, "premium-generation")
    assert response.status_code == 200
    usage = response.json()["usage"]
    assert usage["isPremium"] is True
    assert usage["freeUsesLeft"] is None
    assert usage["creditsUsed"] == 0
    assert usage["source"] is None

    polish = client.post(
        "/v1/polish",
        json={"draft": "Hello there", "direction": "natural"},
        headers={**auth, "X-Idempotency-Key": "premium-polish"},
    )
    assert polish.status_code == 200
    assert polish.json()["usage"]["creditsUsed"] == 0
    assert polish.json()["usage"]["source"] is None

    me = client.get("/v1/me", headers=auth).json()
    assert me["freeUsesUsed"] == 2
    assert me["paidCredits"] == 7


def test_inactive_sync_restores_factual_free_semantics(client: TestClient) -> None:
    auth, _, _ = _auth(client, "inactive")
    fake = _FakeRevenueCat(VerifiedEntitlement(False, "premium"))
    app.dependency_overrides[get_revenuecat_service] = lambda: fake
    try:
        response = client.post("/v1/entitlement/sync", headers=auth)
    finally:
        app.dependency_overrides.pop(get_revenuecat_service, None)
    assert response.status_code == 200
    assert response.json()["isPremium"] is False
    assert response.json()["freeUsesLeft"] == 5


def test_sync_unavailability_does_not_grant_access(client: TestClient) -> None:
    auth, _, _ = _auth(client, "unavailable")
    app.dependency_overrides[get_revenuecat_service] = _UnavailableRevenueCat
    try:
        response = client.post("/v1/entitlement/sync", headers=auth)
    finally:
        app.dependency_overrides.pop(get_revenuecat_service, None)
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "ENTITLEMENT_SYNC_FAILED"
    assert client.get("/v1/me", headers=auth).json()["isPremium"] is False


def test_entitlement_sync_requires_authentication(client: TestClient) -> None:
    assert client.post("/v1/entitlement/sync").status_code == 401
