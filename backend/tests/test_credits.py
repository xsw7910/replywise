import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import func, select

from app.api.v1.credits import get_revenuecat_service
from app.config import settings
from app.database import AsyncSessionLocal
from app.main import app
from app.models.credit import CreditPurchase
from app.models.subscription import SubscriptionCache
from app.models.usage import DeviceUsage, UsageSummary
from app.models.user import User
from app.services.revenuecat_service import (
    ConsumableTransaction,
    RevenueCatService,
    RevenueCatUnavailable,
)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _auth(client: TestClient, suffix: str) -> tuple[dict[str, str], int, str]:
    app_user_id = f"credits-{suffix}"
    resp = client.post(
        "/v1/auth/anonymous",
        json={"appUserId": app_user_id, "deviceId": f"device-{suffix}", "platform": "android"},
    )
    body = resp.json()
    return {"Authorization": f"Bearer {body['accessToken']}"}, body["me"]["userId"], app_user_id


def _reply(client: TestClient, auth: dict, key: str):
    return client.post(
        "/v1/reply",
        json={"incoming": "Hello", "guidance": "Reply warmly"},
        headers={**auth, "X-Idempotency-Key": key},
    )


class _FakeRevenueCat(RevenueCatService):
    def __init__(self, transactions: list[ConsumableTransaction]) -> None:
        self.transactions = transactions
        self.seen_app_user_id: str | None = None

    async def fetch_consumable_transactions(self, app_user_id: str) -> list[ConsumableTransaction]:
        self.seen_app_user_id = app_user_id
        return self.transactions


class _UnavailableRevenueCat(RevenueCatService):
    async def fetch_consumable_transactions(self, app_user_id: str) -> list[ConsumableTransaction]:
        raise RevenueCatUnavailable("offline")


def _sync(client: TestClient, auth: dict, fake: RevenueCatService) -> dict:
    app.dependency_overrides[get_revenuecat_service] = lambda: fake
    try:
        return client.post("/v1/credits/sync", headers=auth)
    finally:
        app.dependency_overrides.pop(get_revenuecat_service, None)


# ── Tests ─────────────────────────────────────────────────────────────────────

def test_credits_sync_grants_correct_amounts(client: TestClient) -> None:
    auth, _, app_user_id = _auth(client, "grant")
    fake = _FakeRevenueCat([
        ConsumableTransaction("txn-001", "credits_10"),
        ConsumableTransaction("txn-002", "credits_50"),
    ])
    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    body = resp.json()
    assert body["grantedThisSync"] == 60
    assert body["paidCredits"] == 60
    assert fake.seen_app_user_id == app_user_id


def test_duplicate_transaction_grants_once(client: TestClient) -> None:
    auth, _, _ = _auth(client, "dedup")
    txn = ConsumableTransaction("txn-dup", "credits_100")
    fake = _FakeRevenueCat([txn])

    resp1 = _sync(client, auth, fake)
    assert resp1.status_code == 200
    assert resp1.json()["grantedThisSync"] == 100
    assert resp1.json()["paidCredits"] == 100

    resp2 = _sync(client, auth, fake)
    assert resp2.status_code == 200
    assert resp2.json()["grantedThisSync"] == 0
    assert resp2.json()["paidCredits"] == 100


def test_unknown_product_id_is_ignored(client: TestClient) -> None:
    auth, _, _ = _auth(client, "unknown-product")
    fake = _FakeRevenueCat([
        ConsumableTransaction("txn-unknown", "credits_999"),
        ConsumableTransaction("txn-known", "credits_10"),
    ])
    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 10
    assert resp.json()["paidCredits"] == 10


def test_credits_sync_grants_even_while_premium(client: TestClient) -> None:
    auth, user_id, _ = _auth(client, "premium-grant")

    async def seed() -> None:
        async with AsyncSessionLocal() as db:
            db.add(SubscriptionCache(
                user_id=user_id,
                entitlement_id="premium",
                is_premium=True,
                product_identifier="premium_yearly:yearly",
                expires_at=datetime.now(timezone.utc) + timedelta(days=3),
            ))
            await db.commit()

    asyncio.run(seed())
    fake = _FakeRevenueCat([ConsumableTransaction("txn-premium", "credits_50")])
    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 50
    assert resp.json()["paidCredits"] == 50
    assert resp.json()["isPremium"] is True
    assert resp.json()["freeUsesLeft"] is None


def test_credits_consumed_after_free_exhausted(client: TestClient) -> None:
    auth, user_id, _ = _auth(client, "consume-credits")

    async def seed() -> None:
        # Free usage is device-scoped; exhaust the device allowance.
        async with AsyncSessionLocal() as db:
            user = await db.get(User, user_id)
            device = await db.get(DeviceUsage, user.device_hash)
            device.free_uses_used = device.free_uses_limit
            await db.commit()

    asyncio.run(seed())

    fake = _FakeRevenueCat([ConsumableTransaction("txn-consume", "credits_10")])
    _sync(client, auth, fake)

    resp = _reply(client, auth, "credit-use-key")
    assert resp.status_code == 200
    assert resp.json()["usage"]["source"] == "credit"
    assert resp.json()["usage"]["paidCredits"] == 9


def test_duplicate_sync_race_grants_transaction_exactly_once(
    client: TestClient,
) -> None:
    """Deterministic SQLite-safe equivalent of two syncs racing on one txn.

    Both API calls observe the same RevenueCat transaction. The primary-key
    constraint must leave one purchase row and one grant regardless of retry.
    """
    auth, _, _ = _auth(client, "concurrent")
    txn = ConsumableTransaction("txn-conc", "credits_10")
    fake = _FakeRevenueCat([txn])
    first = _sync(client, auth, fake)
    second = _sync(client, auth, fake)

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["grantedThisSync"] + second.json()["grantedThisSync"] == 10
    assert second.json()["paidCredits"] == 10

    async def purchase_count() -> int:
        async with AsyncSessionLocal() as db:
            return await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.transaction_id == "txn-conc"
                )
            ) or 0

    assert asyncio.run(purchase_count()) == 1


@pytest.mark.parametrize(
    "store_id,expected",
    [("credits_10", 10), ("credits_50", 50), ("credits_100", 100)],
)
def test_default_store_ids_grant_expected_credits(
    client: TestClient, monkeypatch, store_id: str, expected: int
) -> None:
    """With an empty env map, the in-code store defaults still apply."""
    monkeypatch.setattr(settings, "revenuecat_credit_product_map", "")
    auth, _, _ = _auth(client, f"default-{store_id}")
    fake = _FakeRevenueCat([ConsumableTransaction(f"txn-{store_id}", store_id)])
    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == expected
    assert resp.json()["paidCredits"] == expected

    resp2 = _sync(client, auth, fake)
    assert resp2.status_code == 200
    assert resp2.json()["grantedThisSync"] == 0
    assert resp2.json()["paidCredits"] == expected

    async def purchase_count() -> int:
        async with AsyncSessionLocal() as db:
            return await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.transaction_id == f"txn-{store_id}"
                )
            ) or 0

    assert asyncio.run(purchase_count()) == 1


def test_sync_skips_transaction_recorded_under_revenuecat_purchase_id_alias(
    client: TestClient,
) -> None:
    auth, user_id, _ = _auth(client, "legacy-alias")
    store_transaction_id = "GPA.legacy-alias"
    revenuecat_purchase_id = "purchase-legacy-alias"

    async def seed_legacy_purchase() -> None:
        async with AsyncSessionLocal() as db:
            db.add(
                CreditPurchase(
                    transaction_id=revenuecat_purchase_id,
                    user_id=user_id,
                    product_id="credits_10",
                    credits_granted=10,
                )
            )
            summary = await db.get(UsageSummary, user_id)
            if summary is None:
                summary = UsageSummary(user_id=user_id)
                db.add(summary)
            summary.paid_credits = 10
            await db.commit()

    asyncio.run(seed_legacy_purchase())

    fake = _FakeRevenueCat([
        ConsumableTransaction(
            store_transaction_id,
            "credits_10",
            (revenuecat_purchase_id,),
        )
    ])
    resp = _sync(client, auth, fake)

    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 0
    assert resp.json()["paidCredits"] == 10

    async def rows() -> tuple[int, int]:
        async with AsyncSessionLocal() as db:
            store_count = await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.transaction_id == store_transaction_id
                )
            )
            legacy_count = await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.transaction_id == revenuecat_purchase_id
                )
            )
            return int(store_count or 0), int(legacy_count or 0)

    assert asyncio.run(rows()) == (0, 1)


def test_env_mapped_internal_product_ids_grant_credits(
    client: TestClient, monkeypatch
) -> None:
    """RevenueCat internal product ids (prod...) granted per the env map for
    the 10, 50 and 100 credit tiers."""
    monkeypatch.setattr(
        settings,
        "revenuecat_credit_product_map",
        "prod733d52bcdd:10,prodInternal50:50,prodInternal100:100",
    )
    auth, _, _ = _auth(client, "internal-mapped")
    fake = _FakeRevenueCat([
        ConsumableTransaction("txn-i10", "prod733d52bcdd"),
        ConsumableTransaction("txn-i50", "prodInternal50"),
        ConsumableTransaction("txn-i100", "prodInternal100"),
    ])
    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 160
    assert resp.json()["paidCredits"] == 160


def test_env_map_overrides_default_for_same_product_id(
    client: TestClient, monkeypatch
) -> None:
    """Env entries win over in-code defaults for the same product id."""
    monkeypatch.setattr(settings, "revenuecat_credit_product_map", "credits_10:25")
    auth, _, _ = _auth(client, "override")
    fake = _FakeRevenueCat([ConsumableTransaction("txn-override", "credits_10")])
    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 25


def test_internal_product_id_grants_credits_and_persists_row(
    client: TestClient, monkeypatch
) -> None:
    """Production case: a RevenueCat API v2 internal product id (prod733d52bcdd),
    configured via the env map, grants 10 credits and is persisted idempotently
    in credit_purchases."""
    monkeypatch.setattr(
        settings, "revenuecat_credit_product_map", "prod733d52bcdd:10"
    )
    auth, user_id, _ = _auth(client, "internal-product")
    txn_id = "otpGps4ee034de5613a329844dc1bd066ffa9f"
    fake = _FakeRevenueCat([ConsumableTransaction(txn_id, "prod733d52bcdd")])

    resp = _sync(client, auth, fake)
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 10
    assert resp.json()["paidCredits"] == 10

    async def fetch_row() -> CreditPurchase | None:
        async with AsyncSessionLocal() as db:
            return await db.get(CreditPurchase, txn_id)

    row = asyncio.run(fetch_row())
    assert row is not None
    assert row.user_id == user_id
    assert row.product_id == "prod733d52bcdd"
    assert row.credits_granted == 10

    # Idempotent: re-syncing the same transaction grants nothing more.
    resp2 = _sync(client, auth, fake)
    assert resp2.status_code == 200
    assert resp2.json()["grantedThisSync"] == 0
    assert resp2.json()["paidCredits"] == 10

    async def count_rows() -> int:
        async with AsyncSessionLocal() as db:
            return await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.transaction_id == txn_id
                )
            ) or 0

    assert asyncio.run(count_rows()) == 1


def test_empty_purchases_grant_nothing(client: TestClient) -> None:
    auth, _, _ = _auth(client, "empty-purchases")
    resp = _sync(client, auth, _FakeRevenueCat([]))
    assert resp.status_code == 200
    assert resp.json()["grantedThisSync"] == 0
    assert resp.json()["paidCredits"] == 0


def test_credits_sync_unavailability_returns_503(client: TestClient) -> None:
    auth, _, _ = _auth(client, "unavailable")
    resp = _sync(client, auth, _UnavailableRevenueCat())
    assert resp.status_code == 503
    assert resp.json()["error"]["code"] == "CREDIT_SYNC_FAILED"


def test_credits_sync_requires_authentication(client: TestClient) -> None:
    assert client.post("/v1/credits/sync").status_code == 401
