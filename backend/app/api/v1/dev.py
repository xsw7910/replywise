from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.errors import ApiException
from app.models.subscription import SubscriptionCache
from app.models.usage import UsageSummary
from app.models.user import User
from app.services.usage_service import ensure_summary

router = APIRouter(prefix="/v1/dev", tags=["dev"])


class ApiModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class ResetUsageRequest(ApiModel):
    free_uses_used: int | None = Field(default=None, ge=0, le=1000)
    paid_credits: int | None = Field(default=None, ge=0, le=1000)


class AddCreditsRequest(ApiModel):
    amount: int = Field(gt=0, le=1000)


class SetPremiumRequest(ApiModel):
    is_premium: bool


class DevActionResponse(ApiModel):
    ok: bool


def _require_dev_tools() -> None:
    if not settings.dev_tools_enabled:
        raise ApiException(
            code="NOT_FOUND",
            message="Developer tools are not enabled.",
            status_code=404,
        )
    if not settings.is_dev_or_test:
        raise ApiException(
            code="FORBIDDEN",
            message="Developer tools are only available in dev/test.",
            status_code=403,
        )


@router.post("/reset-usage", response_model=DevActionResponse)
async def reset_usage(
    body: ResetUsageRequest | None = None,
    _: None = Depends(_require_dev_tools),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DevActionResponse:
    summary = await ensure_summary(db, current_user.id)
    summary.free_uses_used = 0 if body is None or body.free_uses_used is None else body.free_uses_used
    summary.paid_credits = 0 if body is None or body.paid_credits is None else body.paid_credits
    summary.updated_at = datetime.now(timezone.utc)
    await db.commit()
    return DevActionResponse(ok=True)


@router.post("/add-credits", response_model=DevActionResponse)
async def add_credits(
    body: AddCreditsRequest,
    _: None = Depends(_require_dev_tools),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DevActionResponse:
    summary = await ensure_summary(db, current_user.id)
    summary.paid_credits += body.amount
    summary.updated_at = datetime.now(timezone.utc)
    await db.commit()
    return DevActionResponse(ok=True)


@router.post("/set-premium", response_model=DevActionResponse)
async def set_premium(
    body: SetPremiumRequest,
    _: None = Depends(_require_dev_tools),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DevActionResponse:
    cache = await db.get(SubscriptionCache, current_user.id)
    if cache is None:
        cache = SubscriptionCache(
            user_id=current_user.id,
            entitlement_id=settings.revenuecat_entitlement_id,
        )
        db.add(cache)
    cache.entitlement_id = settings.revenuecat_entitlement_id
    cache.is_premium = body.is_premium
    cache.product_identifier = "dev_premium_override"
    cache.expires_at = None
    cache.verified_at = datetime.now(timezone.utc)
    await db.commit()
    return DevActionResponse(ok=True)
