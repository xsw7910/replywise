from dataclasses import dataclass
from datetime import datetime, timezone
from urllib.parse import quote

import httpx

from app.config import settings


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
    async def _fetch_subscriber_payload(self, app_user_id: str) -> dict:
        if not settings.revenuecat_secret_api_key:
            raise RevenueCatUnavailable("RevenueCat backend key is not configured")

        url = (
            f"{settings.revenuecat_api_base_url.rstrip('/')}/subscribers/"
            f"{quote(app_user_id, safe='')}"
        )
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(
                    url,
                    headers={
                        "Authorization": f"Bearer {settings.revenuecat_secret_api_key}",
                        "Accept": "application/json",
                    },
                )
            response.raise_for_status()
            payload = response.json()
        except (httpx.HTTPError, ValueError, TypeError, KeyError) as error:
            raise RevenueCatUnavailable("RevenueCat verification failed") from error

        if not isinstance(payload, dict):
            raise RevenueCatUnavailable("RevenueCat returned an invalid response")
        return payload

    async def verify(self, app_user_id: str) -> VerifiedEntitlement:
        payload = await self._fetch_subscriber_payload(app_user_id)
        entitlement_id = settings.revenuecat_entitlement_id
        subscriber = payload.get("subscriber")
        entitlements = subscriber.get("entitlements") if isinstance(subscriber, dict) else None
        entitlement = entitlements.get(entitlement_id) if isinstance(entitlements, dict) else None
        if not isinstance(entitlement, dict):
            return VerifiedEntitlement(False, entitlement_id)

        try:
            expires_at = _parse_datetime(entitlement.get("expires_date"))
        except ValueError as error:
            raise RevenueCatUnavailable("RevenueCat returned an invalid expiry") from error
        product_identifier = entitlement.get("product_identifier")
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
        """Return all verified non-subscription (consumable) transactions for the user."""
        payload = await self._fetch_subscriber_payload(app_user_id)
        subscriber = payload.get("subscriber")
        non_subs = subscriber.get("non_subscriptions") if isinstance(subscriber, dict) else None
        if not isinstance(non_subs, dict):
            return []
        result: list[ConsumableTransaction] = []
        for product_id, purchases in non_subs.items():
            if not isinstance(purchases, list):
                continue
            for purchase in purchases:
                if not isinstance(purchase, dict):
                    continue
                txn_id = purchase.get("id")
                if txn_id and isinstance(txn_id, str):
                    result.append(ConsumableTransaction(transaction_id=txn_id, product_id=product_id))
        return result


def _parse_datetime(value: object) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
