import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from urllib.parse import quote

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class RevenueCatUnavailable(Exception):
    pass


@dataclass(frozen=True)
class VerifiedEntitlement:
    is_premium: bool
    entitlement_id: str
    product_identifier: str | None = None
    expires_at: datetime | None = None


@dataclass(frozen=True)
class ConsumableTransaction:
    # Canonical, store-level transaction id (Google Play order id on Android).
    transaction_id: str
    product_id: str
    alternate_transaction_ids: tuple[str, ...] = ()
    # RevenueCat V2 purchase resource id (e.g. "otpGps..."); metadata only.
    revenuecat_purchase_id: str | None = None
    store: str | None = None


class RevenueCatService:
    """Thin client for RevenueCat REST API v2.

    Public interface is identical to the former v1 client so callers
    (entitlement_service, credit_service, API routes) need no changes.
    """

    # A v2 purchase item is currently owned (granting access) when these match.
    # The purchases endpoint reports state via status/ownership — not a
    # non_subscription "type" — so acceptance keys on these instead.
    _OWNED_STATUS = "owned"
    _PURCHASED_OWNERSHIP = "purchased"

    @classmethod
    def _is_owned_purchase(cls, item: dict) -> bool:
        if item.get("object") != "purchase":
            return False
        if item.get("status") != cls._OWNED_STATUS:
            return False
        # ownership may be absent on some store payloads; treat missing as the
        # owner's own purchase. Only an explicit non-"purchased" value (e.g.
        # "family_shared") is rejected.
        ownership = item.get("ownership")
        return ownership is None or ownership == cls._PURCHASED_OWNERSHIP

    # ── Config helpers ────────────────────────────────────────────────────────

    def _require_config(self) -> tuple[str, str]:
        """Return (secret_key, project_id) or raise RevenueCatUnavailable."""
        key = settings.revenuecat_secret_api_key
        project_id = settings.revenuecat_project_id
        if not key:
            raise RevenueCatUnavailable("RevenueCat backend key is not configured")
        if not project_id:
            raise RevenueCatUnavailable("RevenueCat project ID is not configured")
        return key, project_id

    def _headers(self, key: str) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {key}",
            "Accept": "application/json",
        }

    def _customer_url(self, project_id: str, app_user_id: str) -> str:
        base = settings.revenuecat_api_base_url.rstrip("/")
        return (
            f"{base}/projects/{quote(project_id, safe='')}/"
            f"customers/{quote(app_user_id, safe='')}"
        )

    def _purchases_url(self, project_id: str, app_user_id: str) -> str:
        return f"{self._customer_url(project_id, app_user_id)}/purchases"

    # ── HTTP ─────────────────────────────────────────────────────────────────

    async def _get_json(self, url: str, headers: dict[str, str]) -> dict:
        """GET *url*, log status and rc-request-id; raise RevenueCatUnavailable on failure."""
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(url, headers=headers)
        except httpx.HTTPError as error:
            raise RevenueCatUnavailable("RevenueCat request failed") from error

        rc_request_id = response.headers.get("X-Request-Id", "-")
        if not response.is_success:
            logger.warning(
                "RevenueCat API %d at %s (rc-request-id: %s)",
                response.status_code,
                url.split("?")[0],
                rc_request_id,
            )
            raise RevenueCatUnavailable(
                f"RevenueCat API error {response.status_code}"
            )

        logger.debug(
            "RevenueCat API 200 at %s (rc-request-id: %s)",
            url.split("?")[0],
            rc_request_id,
        )

        try:
            payload = response.json()
        except (ValueError, TypeError) as error:
            raise RevenueCatUnavailable("RevenueCat returned invalid JSON") from error

        if not isinstance(payload, dict):
            raise RevenueCatUnavailable("RevenueCat returned an invalid response")
        return payload

    # ── Public interface (unchanged from v1 client) ───────────────────────────

    async def verify(self, app_user_id: str) -> VerifiedEntitlement:
        """Check whether *app_user_id* has an active premium entitlement.

        Calls GET /v2/projects/{project_id}/customers/{app_user_id}.
        Active entitlements are returned in customer.active_entitlements.items[].
        Each active entitlement item carries an entitlement_id and an
        expires_at (Unix ms, or null for a non-expiring/lifetime entitlement);
        it may not carry a product_id.
        """
        key, project_id = self._require_config()
        payload = await self._get_json(
            self._customer_url(project_id, app_user_id),
            self._headers(key),
        )

        entitlement_id = settings.revenuecat_entitlement_id
        entitlements_block = payload.get("active_entitlements") or {}
        items: list = (
            entitlements_block.get("items", [])
            if isinstance(entitlements_block, dict)
            else []
        )

        entitlement = next(
            (
                e
                for e in items
                if isinstance(e, dict) and e.get("entitlement_id") == entitlement_id
            ),
            None,
        )
        if entitlement is None:
            return VerifiedEntitlement(False, entitlement_id)

        try:
            expires_at = _parse_datetime(entitlement.get("expires_at"))
        except (ValueError, OverflowError, OSError) as error:
            raise RevenueCatUnavailable("RevenueCat returned an invalid expiry") from error

        # Items under active_entitlements are already filtered to active by
        # RevenueCat. A null expires_at means a non-expiring entitlement.
        is_active = expires_at is None or expires_at > datetime.now(timezone.utc)
        return VerifiedEntitlement(
            is_premium=is_active,
            entitlement_id=entitlement_id,
            product_identifier=entitlement.get("product_id"),
            expires_at=expires_at,
        )

    async def fetch_consumable_transactions(
        self, app_user_id: str
    ) -> list[ConsumableTransaction]:
        """Return all currently-owned purchase transactions for the user.

        Calls GET /v2/projects/{project_id}/customers/{app_user_id}/purchases
        and follows next_page pagination until exhausted.

        Each item is accepted when it is an owned purchase: object='purchase',
        status='owned', and ownership missing or equal to 'purchased'.

        The canonical, idempotent ``transaction_id`` is the STORE transaction id
        (``store_purchase_identifier`` — the Google Play order id on Android),
        which is the SAME identifier the webhook reports. RevenueCat's own
        purchase resource id (``id``, e.g. "otpGps...") is NEVER used as the
        canonical key — the webhook does not carry it, so keying on it would
        double-grant the same purchase (see the credit-doubling incident). It is
        kept only as a metadata/alias (``revenuecat_purchase_id``) so rows
        written before this fix still deduplicate.

        A purchase whose store transaction id is not yet exposed by the API is
        DEFERRED (skipped this round): the webhook grants it now, and a later
        sync grants it once the store id is available. The product_id may be a
        store identifier (e.g. 'credits_10') or a RevenueCat internal product id
        (e.g. 'prod733d52bcdd'); mapping product ids to credit grants is the
        caller's job.
        """
        key, project_id = self._require_config()
        headers = self._headers(key)

        result: list[ConsumableTransaction] = []
        url: str | None = self._purchases_url(project_id, app_user_id)

        while url:
            payload = await self._get_json(url, headers)
            items = payload.get("items")
            if not isinstance(items, list):
                break
            for item in items:
                if not isinstance(item, dict):
                    continue
                if not self._is_owned_purchase(item):
                    continue

                product_id = item.get("product_id")
                if not (product_id and isinstance(product_id, str)):
                    continue

                revenuecat_purchase_id = _first_string(item.get("id"))
                store = _first_string(item.get("store"))
                # Canonical key: the store transaction id, in priority order.
                # These are the identifiers the webhook also reports.
                store_txn_id = _first_string(
                    item.get("store_purchase_identifier"),
                    item.get("store_transaction_id"),
                    item.get("transaction_id"),
                    item.get("original_transaction_id"),
                )
                if store_txn_id is None:
                    # No store-level id yet → defer; the webhook grants it now.
                    logger.info(
                        "CREDIT_GRANT_TRACE stage=sync_deferred_no_store_id "
                        "revenuecat_purchase_id=%s product_id=%s store=%s",
                        revenuecat_purchase_id,
                        product_id,
                        store,
                    )
                    continue

                # The RevenueCat purchase id remains a legacy alias so rows
                # recorded under it before this fix still deduplicate.
                aliases = _unique_strings(
                    revenuecat_purchase_id,
                    item.get("store_transaction_id"),
                    item.get("transaction_id"),
                    item.get("original_transaction_id"),
                    exclude=store_txn_id,
                )
                result.append(
                    ConsumableTransaction(
                        transaction_id=store_txn_id,
                        product_id=product_id,
                        alternate_transaction_ids=aliases,
                        revenuecat_purchase_id=revenuecat_purchase_id,
                        store=store,
                    )
                )
            url = payload.get("next_page") or None

        return result


def _parse_datetime(value: object) -> datetime | None:
    if value is None:
        return None

    if isinstance(value, int | float):
        timestamp = float(value)
        if timestamp > 10_000_000_000:
            timestamp = timestamp / 1000
        return datetime.fromtimestamp(timestamp, tz=timezone.utc)

    if isinstance(value, str) and value:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)

    return None


def _first_string(*values: object) -> str | None:
    """First non-empty stripped string among *values*, else None."""
    for value in values:
        if isinstance(value, str):
            text = value.strip()
            if text:
                return text
    return None


def _unique_strings(*values: object, exclude: str | None = None) -> tuple[str, ...]:
    seen = {exclude} if exclude else set()
    result: list[str] = []
    for value in values:
        if not isinstance(value, str):
            continue
        text = value.strip()
        if not text or text in seen:
            continue
        seen.add(text)
        result.append(text)
    return tuple(result)
