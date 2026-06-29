"""Unit tests for the RevenueCat API v2 HTTP client layer.

These tests patch httpx.AsyncClient so no network calls are made.
They verify that RevenueCatService correctly parses v2 response shapes
and raises RevenueCatUnavailable on HTTP errors.
"""
import asyncio
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.config import settings
from app.services.revenuecat_service import (
    ConsumableTransaction,
    RevenueCatService,
    RevenueCatUnavailable,
)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _rc_response(status: int, body: dict, rc_request_id: str = "rc-test-123") -> MagicMock:
    """Build a mock httpx Response."""
    resp = MagicMock()
    resp.status_code = status
    resp.is_success = 200 <= status < 300
    resp.headers = MagicMock()
    resp.headers.get.return_value = rc_request_id
    resp.json.return_value = body
    return resp


def _patch_http(*responses):
    """Return a context manager that makes httpx.AsyncClient yield *responses* in order.

    Each element of *responses* is an httpx Response mock as built by _rc_response().
    """
    call_index = 0

    async def fake_get(url, **kwargs):
        nonlocal call_index
        resp = responses[call_index]
        call_index += 1
        return resp

    mock_client = AsyncMock()
    mock_client.get = fake_get
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    return patch("httpx.AsyncClient", return_value=mock_client)


def _future_ms(days: int = 30) -> int:
    return int((datetime.now(timezone.utc) + timedelta(days=days)).timestamp() * 1000)


def _past_ms(days: int = 1) -> int:
    return int((datetime.now(timezone.utc) - timedelta(days=days)).timestamp() * 1000)


def _active_entitlement(entitlement_id: str, expires_at: object) -> dict:
    """Build a v2 customer.active_entitlement item.

    Active entitlement items carry entitlement_id and expires_at
    (Unix ms, or null for non-expiring); they need not carry product_id.
    """
    return {
        "object": "customer.active_entitlement",
        "entitlement_id": entitlement_id,
        "expires_at": expires_at,
    }


def _customer_payload(entitlement_items: list) -> dict:
    return {
        "object": "customer",
        "id": "user-1",
        "active_entitlements": {
            "object": "list",
            "items": entitlement_items,
            "next_page": None,
        },
    }


def _purchases_payload(items: list, next_page: str | None = None) -> dict:
    return {
        "object": "list",
        "items": items,
        "next_page": next_page,
    }


def _non_sub(txn_id: str, product_id: str) -> dict:
    return {
        "object": "purchase",
        "id": txn_id,
        "product_id": product_id,
        "type": "non_subscription",
        "store": "play_store",
    }


def _sub_purchase(txn_id: str, product_id: str) -> dict:
    return {
        "object": "purchase",
        "id": txn_id,
        "product_id": product_id,
        "type": "subscription",
    }


@pytest.fixture(autouse=True)
def _rc_config(monkeypatch):
    monkeypatch.setattr(settings, "revenuecat_secret_api_key", "sk-test")
    monkeypatch.setattr(settings, "revenuecat_project_id", "proj_test")


# ── verify() tests ────────────────────────────────────────────────────────────

def test_verify_active_premium_future_ms_returns_is_premium_true() -> None:
    payload = _customer_payload([_active_entitlement("premium", _future_ms(30))])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().verify("user-1"))

    assert result.is_premium is True
    assert result.entitlement_id == "premium"
    assert result.expires_at is not None
    assert result.expires_at > datetime.now(timezone.utc)


def test_verify_expired_premium_ms_returns_is_premium_false() -> None:
    payload = _customer_payload([_active_entitlement("premium", _past_ms(1))])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().verify("user-1"))

    assert result.is_premium is False
    assert result.expires_at is not None
    assert result.expires_at < datetime.now(timezone.utc)


def test_verify_null_expires_at_returns_is_premium_true() -> None:
    payload = _customer_payload([_active_entitlement("premium", None)])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().verify("user-1"))

    assert result.is_premium is True
    assert result.expires_at is None


def test_verify_non_matching_entitlement_id_returns_is_premium_false() -> None:
    payload = _customer_payload(
        [_active_entitlement("some_other_entitlement", _future_ms(30))]
    )
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().verify("user-1"))

    assert result.is_premium is False
    assert result.product_identifier is None


def test_verify_empty_active_entitlements_returns_is_premium_false() -> None:
    payload = _customer_payload([])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().verify("user-1"))

    assert result.is_premium is False
    assert result.entitlement_id == "premium"
    assert result.product_identifier is None


# ── fetch_consumable_transactions() tests ────────────────────────────────────

def test_fetch_credits_10_returns_one_transaction() -> None:
    payload = _purchases_payload([_non_sub("txn-a", "credits_10")])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))

    assert result == [ConsumableTransaction("txn-a", "credits_10")]


def test_fetch_credits_50_and_credits_10_returns_both() -> None:
    payload = _purchases_payload([
        _non_sub("txn-a", "credits_50"),
        _non_sub("txn-b", "credits_10"),
    ])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))

    assert len(result) == 2
    txn_ids = {t.transaction_id for t in result}
    product_ids = {t.product_id for t in result}
    assert txn_ids == {"txn-a", "txn-b"}
    assert product_ids == {"credits_50", "credits_10"}


def test_fetch_subscription_type_is_excluded() -> None:
    payload = _purchases_payload([
        _non_sub("txn-a", "credits_10"),
        _sub_purchase("txn-sub", "premium_yearly"),
    ])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))

    assert len(result) == 1
    assert result[0].transaction_id == "txn-a"


def test_fetch_unknown_product_id_is_returned_raw() -> None:
    """Service returns unknown IDs; credit_service is responsible for filtering them."""
    payload = _purchases_payload([_non_sub("txn-x", "credits_999")])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))

    assert result == [ConsumableTransaction("txn-x", "credits_999")]


def test_fetch_follows_next_page_pagination() -> None:
    page1 = _purchases_payload(
        [_non_sub("txn-a", "credits_10")],
        next_page="https://api.revenuecat.com/v2/projects/proj_test/customers/user-1/purchases?after=txn-a",
    )
    page2 = _purchases_payload([_non_sub("txn-b", "credits_50")])
    with _patch_http(_rc_response(200, page1), _rc_response(200, page2)):
        result = asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))

    assert {t.transaction_id for t in result} == {"txn-a", "txn-b"}


def test_fetch_empty_purchases_returns_empty_list() -> None:
    payload = _purchases_payload([])
    with _patch_http(_rc_response(200, payload)):
        result = asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))

    assert result == []


# ── HTTP error mapping tests ─────────────────────────────────────────────────

@pytest.mark.parametrize("status", [401, 403, 500])
def test_verify_http_error_raises_revenuecat_unavailable(status: int) -> None:
    with _patch_http(_rc_response(status, {"message": "error"})):
        with pytest.raises(RevenueCatUnavailable):
            asyncio.run(RevenueCatService().verify("user-1"))


@pytest.mark.parametrize("status", [401, 403, 500])
def test_fetch_http_error_raises_revenuecat_unavailable(status: int) -> None:
    with _patch_http(_rc_response(status, {"message": "error"})):
        with pytest.raises(RevenueCatUnavailable):
            asyncio.run(RevenueCatService().fetch_consumable_transactions("user-1"))


def test_verify_connection_error_raises_revenuecat_unavailable() -> None:
    mock_client = AsyncMock()
    mock_client.get = AsyncMock(side_effect=httpx_connect_error())
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    with patch("httpx.AsyncClient", return_value=mock_client):
        with pytest.raises(RevenueCatUnavailable):
            asyncio.run(RevenueCatService().verify("user-1"))


def httpx_connect_error():
    import httpx
    return httpx.ConnectError("connection refused")


# ── Missing config tests ──────────────────────────────────────────────────────

def test_verify_missing_api_key_raises_revenuecat_unavailable(monkeypatch) -> None:
    monkeypatch.setattr(settings, "revenuecat_secret_api_key", "")
    with pytest.raises(RevenueCatUnavailable, match="key"):
        asyncio.run(RevenueCatService().verify("user-1"))


def test_verify_missing_project_id_raises_revenuecat_unavailable(monkeypatch) -> None:
    monkeypatch.setattr(settings, "revenuecat_project_id", "")
    with pytest.raises(RevenueCatUnavailable, match="project"):
        asyncio.run(RevenueCatService().verify("user-1"))


# ── _parse_datetime tests ─────────────────────────────────────────────────────

def test_parse_datetime_returns_none_for_none() -> None:
    from app.services.revenuecat_service import _parse_datetime

    assert _parse_datetime(None) is None


def test_parse_datetime_handles_millisecond_timestamp() -> None:
    from app.services.revenuecat_service import _parse_datetime

    result = _parse_datetime(1782758313873)
    assert result is not None
    assert result.tzinfo is not None
    assert abs(result.timestamp() - 1782758313.873) < 1


def test_parse_datetime_handles_second_timestamp() -> None:
    from app.services.revenuecat_service import _parse_datetime

    result = _parse_datetime(1782758313)
    assert result is not None
    assert result.tzinfo is not None
    assert abs(result.timestamp() - 1782758313) < 1


def test_parse_datetime_handles_iso_string() -> None:
    from app.services.revenuecat_service import _parse_datetime

    result = _parse_datetime("2026-06-29T12:00:00Z")
    assert result is not None
    assert result.tzinfo is not None
