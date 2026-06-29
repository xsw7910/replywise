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
    transaction_id: str
    product_id: str


class RevenueCatService:
    """Thin client for RevenueCat REST API v2.

    Public interface is identical to the former v1 client so callers
    (entitlement_service, credit_service, API routes) need no changes.
    """

    _NON_SUBSCRIPTION_TYPE = "non_subscription"

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
        Active entitlements are returned in customer.entitlements.items[].
        """
        key, project_id = self._require_config()
        payload = await self._get_json(
            self._customer_url(project_id, app_user_id),
            self._headers(key),
        )

        entitlement_id = settings.revenuecat_entitlement_id
        entitlements_block = payload.get("entitlements") or {}
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
        except ValueError as error:
            raise RevenueCatUnavailable("RevenueCat returned an invalid expiry") from error

        product_identifier = entitlement.get("product_id")
        is_active = (
            product_identifier == settings.revenuecat_subscription_product_id
            and expires_at is not None
            and expires_at > datetime.now(timezone.utc)
        )
        return VerifiedEntitlement(
            is_premium=is_active,
            entitlement_id=entitlement_id,
            product_identifier=product_identifier,
            expires_at=expires_at,
        )

    async def fetch_consumable_transactions(
        self, app_user_id: str
    ) -> list[ConsumableTransaction]:
        """Return all verified non-subscription (consumable) transactions for the user.

        Calls GET /v2/projects/{project_id}/customers/{app_user_id}/purchases
        and follows next_page pagination until exhausted.
        Only items with type='non_subscription' are included.
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
                if item.get("type") != self._NON_SUBSCRIPTION_TYPE:
                    continue
                txn_id = item.get("id")
                product_id = item.get("product_id")
                if (
                    txn_id
                    and isinstance(txn_id, str)
                    and product_id
                    and isinstance(product_id, str)
                ):
                    result.append(
                        ConsumableTransaction(
                            transaction_id=txn_id,
                            product_id=product_id,
                        )
                    )
            url = payload.get("next_page") or None

        return result


def _parse_datetime(value: object) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
