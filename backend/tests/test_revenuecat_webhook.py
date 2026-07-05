import asyncio
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import func, select

from app.api.v1.credits import get_revenuecat_service
from app.config import settings
from app.database import AsyncSessionLocal
from app.main import app
from app.models.credit import CreditPurchase
from app.models.revenuecat_event import RevenueCatEvent
from app.models.subscription import SubscriptionCache
from app.models.usage import UsageSummary
from app.services.revenuecat_service import ConsumableTransaction, RevenueCatService

WEBHOOK_SECRET = "test-revenuecat-webhook-secret"


class _FakeRevenueCat(RevenueCatService):
    def __init__(self, transaction_id: str, product_id: str) -> None:
        self.transaction = ConsumableTransaction(transaction_id, product_id)

    async def fetch_consumable_transactions(
        self,
        app_user_id: str,
    ) -> list[ConsumableTransaction]:
        return [self.transaction]


def _create_user(client: TestClient, label: str) -> tuple[int, str]:
    suffix = f"{label}-{uuid4().hex}"
    app_user_id = f"webhook-{suffix}"
    response = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": app_user_id,
            "deviceId": f"device-{suffix}",
            "platform": "android",
        },
    )
    assert response.status_code == 200
    return response.json()["me"]["userId"], app_user_id


def _event(app_user_id: str, event_type: str, **overrides) -> dict:
    event = {
        "id": f"event-{uuid4().hex}",
        "type": event_type,
        "app_user_id": app_user_id,
        "product_id": "premium_yearly:yearly",
        "expiration_at_ms": int(
            (datetime.now(timezone.utc) + timedelta(days=30)).timestamp() * 1000
        ),
    }
    event.update(overrides)
    return event


def _post(client: TestClient, event: dict, secret: str = WEBHOOK_SECRET):
    return client.post(
        "/v1/webhooks/revenuecat",
        headers={"Authorization": f"Bearer {secret}"},
        json={"api_version": "1.0", "event": event},
    )


@pytest.fixture(autouse=True)
def webhook_settings(monkeypatch):
    monkeypatch.setattr(settings, "revenuecat_webhook_secret", WEBHOOK_SECRET)
    monkeypatch.setattr(
        settings,
        "revenuecat_credit_product_map",
        "credits_webhook_10:10",
    )


def test_webhook_rejects_wrong_secret(client: TestClient) -> None:
    response = _post(
        client,
        _event("does-not-matter", "RENEWAL"),
        secret="wrong-secret",
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "WEBHOOK_UNAUTHORIZED"


@pytest.mark.parametrize("event_type", ["INITIAL_PURCHASE", "RENEWAL"])
def test_subscription_purchase_or_renewal_sets_premium_active(
    client: TestClient,
    event_type: str,
) -> None:
    user_id, app_user_id = _create_user(client, event_type.lower())
    response = _post(client, _event(app_user_id, event_type))

    assert response.status_code == 200
    assert response.json()["status"] == "processed"

    async def read_cache() -> SubscriptionCache | None:
        async with AsyncSessionLocal() as db:
            return await db.get(SubscriptionCache, user_id)

    cache = asyncio.run(read_cache())
    assert cache is not None
    assert cache.is_premium is True
    assert cache.product_identifier == "premium_yearly:yearly"


@pytest.mark.parametrize(
    "event_type",
    ["EXPIRATION", "REFUND", "CANCELLATION", "BILLING_ISSUE"],
)
def test_subscription_end_event_sets_premium_inactive(
    client: TestClient,
    event_type: str,
) -> None:
    user_id, app_user_id = _create_user(client, event_type.lower())
    assert _post(client, _event(app_user_id, "RENEWAL")).status_code == 200

    response = _post(client, _event(app_user_id, event_type))
    assert response.status_code == 200

    async def is_active() -> bool:
        async with AsyncSessionLocal() as db:
            cache = await db.get(SubscriptionCache, user_id)
            return bool(cache and cache.is_premium)

    assert asyncio.run(is_active()) is False


def test_credit_purchase_grants_once_when_event_is_replayed(
    client: TestClient,
) -> None:
    user_id, app_user_id = _create_user(client, "credit-replay")
    event = _event(
        app_user_id,
        "NON_RENEWING_PURCHASE",
        product_id="credits_webhook_10",
        transaction_id=f"transaction-{uuid4().hex}",
    )

    first = _post(client, event)
    second = _post(client, event)
    assert first.status_code == 200
    assert first.json() == {"status": "processed", "credits_granted": 10}
    assert second.status_code == 200
    assert second.json() == {"status": "duplicate", "credits_granted": 0}

    async def balances() -> tuple[int, int, int]:
        async with AsyncSessionLocal() as db:
            summary = await db.get(UsageSummary, user_id)
            event_count = await db.scalar(
                select(func.count(RevenueCatEvent.event_id)).where(
                    RevenueCatEvent.event_id == event["id"]
                )
            )
            purchase_count = await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.transaction_id == event["transaction_id"]
                )
            )
            return summary.paid_credits, int(event_count or 0), int(purchase_count or 0)

    assert asyncio.run(balances()) == (10, 1, 1)


def test_existing_credit_sync_does_not_regrant_webhook_transaction(
    client: TestClient,
) -> None:
    suffix = uuid4().hex
    app_user_id = f"webhook-cross-sync-{suffix}"
    auth_response = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": app_user_id,
            "deviceId": f"device-cross-sync-{suffix}",
            "platform": "android",
        },
    )
    auth = {"Authorization": f"Bearer {auth_response.json()['accessToken']}"}
    transaction_id = f"transaction-{uuid4().hex}"
    product_id = "credits_webhook_10"

    webhook_response = _post(
        client,
        _event(
            app_user_id,
            "NON_RENEWING_PURCHASE",
            product_id=product_id,
            transaction_id=transaction_id,
        ),
    )
    assert webhook_response.json()["credits_granted"] == 10

    app.dependency_overrides[get_revenuecat_service] = lambda: _FakeRevenueCat(
        transaction_id,
        product_id,
    )
    try:
        sync_response = client.post("/v1/credits/sync", headers=auth)
    finally:
        app.dependency_overrides.pop(get_revenuecat_service, None)

    assert sync_response.status_code == 200
    assert sync_response.json()["grantedThisSync"] == 0
    assert sync_response.json()["paidCredits"] == 10


def test_unknown_credit_product_does_not_grant_credits(
    client: TestClient,
) -> None:
    user_id, app_user_id = _create_user(client, "unknown-credit")
    response = _post(
        client,
        _event(
            app_user_id,
            "NON_RENEWING_PURCHASE",
            product_id="credits_not_configured",
        ),
    )
    assert response.status_code == 200
    assert response.json()["credits_granted"] == 0

    async def paid_credits() -> int:
        async with AsyncSessionLocal() as db:
            summary = await db.get(UsageSummary, user_id)
            return summary.paid_credits

    assert asyncio.run(paid_credits()) == 0


def test_unknown_event_type_is_recorded_without_crashing(
    client: TestClient,
) -> None:
    _, app_user_id = _create_user(client, "unknown-type")
    event = _event(app_user_id, "SOME_FUTURE_REVENUECAT_EVENT")
    response = _post(client, event)

    assert response.status_code == 200
    assert response.json()["status"] == "ignored_type"

    async def stored_type() -> str | None:
        async with AsyncSessionLocal() as db:
            stored = await db.get(RevenueCatEvent, event["id"])
            return stored.event_type if stored else None

    assert asyncio.run(stored_type()) == "SOME_FUTURE_REVENUECAT_EVENT"
