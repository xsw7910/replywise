import hmac
import logging
from typing import Any

from fastapi import APIRouter, Depends, Header, Request
from pydantic import BaseModel, ConfigDict, Field, ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.errors import ApiException
from app.services.revenuecat_webhook_service import process_revenuecat_event

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/webhooks", tags=["webhooks"])


class RevenueCatEventPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: str = Field(min_length=1)
    type: str = Field(min_length=1)
    app_user_id: str = Field(min_length=1)
    product_id: str | None = None


class RevenueCatWebhookPayload(BaseModel):
    model_config = ConfigDict(extra="ignore")

    event: RevenueCatEventPayload


class RevenueCatWebhookResponse(BaseModel):
    status: str
    credits_granted: int = 0


def _valid_secret(authorization: str | None) -> bool:
    expected = settings.revenuecat_webhook_secret
    if not expected or not authorization:
        return False
    if hmac.compare_digest(authorization, expected):
        return True
    scheme, separator, token = authorization.partition(" ")
    return (
        bool(separator)
        and scheme.lower() == "bearer"
        and hmac.compare_digest(token.strip(), expected)
    )


@router.post("/revenuecat", response_model=RevenueCatWebhookResponse)
async def revenuecat_webhook(
    request: Request,
    authorization: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
) -> RevenueCatWebhookResponse:
    if not _valid_secret(authorization):
        raise ApiException(
            "WEBHOOK_UNAUTHORIZED",
            "Invalid RevenueCat webhook secret",
            401,
        )

    try:
        raw_payload: Any = await request.json()
        payload = RevenueCatWebhookPayload.model_validate(raw_payload)
    except (ValueError, ValidationError):
        raise ApiException(
            "VALIDATION_ERROR",
            "Invalid RevenueCat webhook payload",
            400,
        )

    event = payload.event.model_dump(mode="json")
    result = await process_revenuecat_event(db, event)
    logger.info(
        "RevenueCat webhook event %s handled with status %s",
        payload.event.id,
        result.status,
    )
    return RevenueCatWebhookResponse(
        status=result.status,
        credits_granted=result.credits_granted,
    )
