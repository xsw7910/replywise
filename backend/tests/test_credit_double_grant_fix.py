"""Regression tests for the doubled consumable-credit bug.

Production evidence: one Google Play ``credits_10`` purchase produced two ledger
rows and +20 credits —

    * webhook  → transaction_id = GPA.3338-9630-9299-80803  (store order id)
    * sync     → transaction_id = otpGps12e020a848e5a00...    (RevenueCat V2 id)

because ``/v1/credits/sync`` keyed the ledger on RevenueCat's V2 purchase
resource id (``otpGps…``) whenever the store id was absent, while the webhook
keyed on the Google Play order id (``GPA…``). The two never matched, so
``PRIMARY KEY(transaction_id)`` could not deduplicate them.

These tests drive the REAL ``fetch_consumable_transactions`` V2 parsing so the
sync path resolves identifiers exactly as production does, plus the real webhook
endpoint. Every purchase must grant its configured amount exactly once.
"""

import asyncio
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import func, select

from app.api.v1.credits import get_revenuecat_service
from app.config import settings
from app.database import AsyncSessionLocal
from app.main import app
from app.models.credit import CreditPurchase
from app.models.usage import UsageSummary
from app.services.revenuecat_service import RevenueCatService

WEBHOOK_SECRET = "double-grant-fix-secret"


@pytest.fixture(autouse=True)
def _settings(monkeypatch):
    monkeypatch.setattr(settings, "revenuecat_webhook_secret", WEBHOOK_SECRET)
    # Webhook reports the store product id (credits_10); the V2 API reports the
    # RevenueCat internal product id (prod...). Both must map to 10 credits.
    monkeypatch.setattr(
        settings,
        "revenuecat_credit_product_map",
        "prod733d52bcdd:10,prodInternal50:50,prodInternal100:100",
    )


class _V2PurchasesRevenueCat(RevenueCatService):
    """Real service whose HTTP layer returns a canned V2 purchases payload.

    Using the real ``fetch_consumable_transactions`` guarantees identifier
    extraction matches production exactly.
    """

    def __init__(self, items: list[dict]) -> None:
        self._items = items

    def _require_config(self) -> tuple[str, str]:
        return "secret", "project"

    async def _get_json(self, url: str, headers: dict) -> dict:
        return {"items": self._items, "next_page": None}


def _v2_item(
    *,
    rc_id: str,
    product_id: str = "prod733d52bcdd",
    store_purchase_identifier: str | None = None,
) -> dict:
    item = {
        "object": "purchase",
        "id": rc_id,
        "product_id": product_id,
        "store": "play_store",
        "status": "owned",
        "ownership": "purchased",
    }
    if store_purchase_identifier is not None:
        item["store_purchase_identifier"] = store_purchase_identifier
    return item


def _auth(client: TestClient, suffix: str) -> tuple[dict, int, str]:
    app_user_id = f"dg-{suffix}"
    resp = client.post(
        "/v1/auth/anonymous",
        json={
            "appUserId": app_user_id,
            "deviceId": f"device-{suffix}",
            "platform": "android",
        },
    )
    body = resp.json()
    return (
        {"Authorization": f"Bearer {body['accessToken']}"},
        body["me"]["userId"],
        app_user_id,
    )


def _webhook(
    client: TestClient,
    app_user_id: str,
    *,
    order_id: str,
    product_id: str = "credits_10",
    event_id: str | None = None,
):
    event = {
        "id": event_id or f"evt_{uuid4().hex}",
        "type": "NON_RENEWING_PURCHASE",
        "app_user_id": app_user_id,
        "product_id": product_id,
        "store": "play_store",
        "transaction_id": order_id,
        "original_transaction_id": order_id,
    }
    return client.post(
        "/v1/webhooks/revenuecat",
        headers={"Authorization": f"Bearer {WEBHOOK_SECRET}"},
        json={"api_version": "1.0", "event": event},
    )


def _sync(client: TestClient, auth: dict, items: list[dict]):
    app.dependency_overrides[get_revenuecat_service] = lambda: _V2PurchasesRevenueCat(
        items
    )
    try:
        return client.post("/v1/credits/sync", headers=auth)
    finally:
        app.dependency_overrides.pop(get_revenuecat_service, None)


async def _paid(user_id: int) -> int:
    async with AsyncSessionLocal() as db:
        summary = await db.get(UsageSummary, user_id)
        return summary.paid_credits if summary else 0


async def _row_count(user_id: int) -> int:
    async with AsyncSessionLocal() as db:
        return int(
            await db.scalar(
                select(func.count(CreditPurchase.transaction_id)).where(
                    CreditPurchase.user_id == user_id
                )
            )
            or 0
        )


# ── The exact production incident ────────────────────────────────────────────


def test_production_repro_webhook_then_sync_without_store_id_grants_once(
    client: TestClient,
) -> None:
    """Webhook has the GPA order id; the V2 sync item exposes only otpGps.

    Before the fix this granted +20 (two rows). Now the sync defers the
    store-id-less purchase and only the webhook grants: +10, one row.
    """
    auth, user_id, app_user_id = _auth(client, uuid4().hex[:8])
    order_id = "GPA.3338-9630-9299-80803"
    rc_id = f"otpGps{uuid4().hex}"

    assert _webhook(client, app_user_id, order_id=order_id).json()["credits_granted"] == 10
    assert asyncio.run(_paid(user_id)) == 10

    sync = _sync(client, auth, [_v2_item(rc_id=rc_id)])  # no store_purchase_identifier
    assert sync.status_code == 200
    assert sync.json()["grantedThisSync"] == 0
    assert sync.json()["paidCredits"] == 10
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


# ── Ordering: both paths converge on the store order id ──────────────────────


def test_webhook_first_then_sync_with_store_id_grants_once(client: TestClient) -> None:
    auth, user_id, app_user_id = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    rc_id = f"otpGps{uuid4().hex}"

    assert _webhook(client, app_user_id, order_id=order_id).json()["credits_granted"] == 10
    sync = _sync(
        client,
        auth,
        [_v2_item(rc_id=rc_id, store_purchase_identifier=order_id)],
    )
    assert sync.json()["grantedThisSync"] == 0
    assert sync.json()["paidCredits"] == 10
    assert asyncio.run(_row_count(user_id)) == 1


def test_sync_first_then_webhook_grants_once(client: TestClient) -> None:
    auth, user_id, app_user_id = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    rc_id = f"otpGps{uuid4().hex}"

    sync = _sync(
        client,
        auth,
        [_v2_item(rc_id=rc_id, store_purchase_identifier=order_id)],
    )
    assert sync.json()["grantedThisSync"] == 10
    wh = _webhook(client, app_user_id, order_id=order_id)
    assert wh.json()["credits_granted"] == 0
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


# ── Replays ──────────────────────────────────────────────────────────────────


def test_repeated_sync_grants_once(client: TestClient) -> None:
    auth, user_id, _ = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    items = [_v2_item(rc_id=f"otpGps{uuid4().hex}", store_purchase_identifier=order_id)]

    assert _sync(client, auth, items).json()["grantedThisSync"] == 10
    assert _sync(client, auth, items).json()["grantedThisSync"] == 0
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


def test_repeated_webhook_grants_once(client: TestClient) -> None:
    auth, user_id, app_user_id = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    # Two DIFFERENT webhook events (different event ids) for one store order id.
    assert _webhook(client, app_user_id, order_id=order_id).json()["credits_granted"] == 10
    assert _webhook(client, app_user_id, order_id=order_id).json()["credits_granted"] == 0
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


# ── Concurrency (deterministic SQLite-safe equivalent) ───────────────────────


def test_concurrent_webhook_and_sync_grant_once(client: TestClient) -> None:
    """Webhook and sync race on the same order id → exactly one grant.

    The store-transaction primary key (and unique revenuecat_purchase_id) make
    the second writer a no-op regardless of interleaving.
    """
    auth, user_id, app_user_id = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    items = [_v2_item(rc_id=f"otpGps{uuid4().hex}", store_purchase_identifier=order_id)]

    wh = _webhook(client, app_user_id, order_id=order_id)
    sync = _sync(client, auth, items)

    total = wh.json()["credits_granted"] + sync.json()["grantedThisSync"]
    assert total == 10
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


# ── Exact amounts, never doubled ─────────────────────────────────────────────


@pytest.mark.parametrize(
    "webhook_product,v2_product,expected",
    [
        ("credits_10", "prod733d52bcdd", 10),
        ("credits_50", "prodInternal50", 50),
        ("credits_100", "prodInternal100", 100),
    ],
)
def test_exact_amounts_never_doubled(
    client: TestClient, webhook_product: str, v2_product: str, expected: int
) -> None:
    auth, user_id, app_user_id = _auth(client, f"{expected}-{uuid4().hex[:6]}")
    order_id = f"GPA.{uuid4().hex[:16]}"
    rc_id = f"otpGps{uuid4().hex}"

    _webhook(client, app_user_id, order_id=order_id, product_id=webhook_product)
    _sync(
        client,
        auth,
        [_v2_item(rc_id=rc_id, product_id=v2_product, store_purchase_identifier=order_id)],
    )
    assert asyncio.run(_paid(user_id)) == expected
    assert asyncio.run(_row_count(user_id)) == 1


# ── Restore after reinstall ──────────────────────────────────────────────────


def test_restore_after_reinstall_grants_missing_once(client: TestClient) -> None:
    """Reinstall: the store order id is now available. A never-granted purchase
    is restored exactly once; a second restore grants nothing."""
    auth, user_id, _ = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    items = [_v2_item(rc_id=f"otpGps{uuid4().hex}", store_purchase_identifier=order_id)]

    first = _sync(client, auth, items)
    second = _sync(client, auth, items)
    assert first.json()["grantedThisSync"] == 10
    assert second.json()["grantedThisSync"] == 0
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


def test_legacy_row_under_revenuecat_id_is_not_regranted(client: TestClient) -> None:
    """A pre-fix row keyed by the RevenueCat purchase id must still dedupe when
    a post-fix sync keys the same purchase by the store order id."""
    auth, user_id, _ = _auth(client, uuid4().hex[:8])
    order_id = f"GPA.{uuid4().hex[:16]}"
    rc_id = f"otpGps{uuid4().hex}"

    async def seed_legacy() -> None:
        async with AsyncSessionLocal() as db:
            db.add(
                CreditPurchase(
                    transaction_id=rc_id,  # legacy: keyed by RevenueCat id
                    user_id=user_id,
                    product_id="prod733d52bcdd",
                    credits_granted=10,
                )
            )
            summary = await db.get(UsageSummary, user_id) or UsageSummary(
                user_id=user_id
            )
            summary.paid_credits = 10
            db.add(summary)
            await db.commit()

    asyncio.run(seed_legacy())

    sync = _sync(
        client,
        auth,
        [_v2_item(rc_id=rc_id, store_purchase_identifier=order_id)],
    )
    assert sync.json()["grantedThisSync"] == 0
    assert asyncio.run(_paid(user_id)) == 10
    assert asyncio.run(_row_count(user_id)) == 1


# ── Deferral ─────────────────────────────────────────────────────────────────


def test_sync_defers_purchase_without_store_id(client: TestClient) -> None:
    """A V2 item exposing only the RevenueCat id (no store order id) grants
    nothing — it is deferred so it cannot double the webhook's grant."""
    auth, user_id, _ = _auth(client, uuid4().hex[:8])
    sync = _sync(client, auth, [_v2_item(rc_id=f"otpGps{uuid4().hex}")])
    assert sync.status_code == 200
    assert sync.json()["grantedThisSync"] == 0
    assert asyncio.run(_paid(user_id)) == 0
    assert asyncio.run(_row_count(user_id)) == 0
