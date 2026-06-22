from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.errors import ApiException
from app.models.user import User
from app.services.credit_service import sync_credits
from app.services.revenuecat_service import RevenueCatService, RevenueCatUnavailable
from app.services.usage_service import ensure_summary, summary_dict

router = APIRouter(prefix="/v1/credits", tags=["credits"])


class CreditSyncResponse(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    is_premium: bool
    free_uses_limit: int
    free_uses_used: int
    free_uses_left: int | None
    paid_credits: int
    upgrade_required: bool
    granted_this_sync: int


def get_revenuecat_service() -> RevenueCatService:
    return RevenueCatService()


@router.post("/sync", response_model=CreditSyncResponse)
async def credits_sync(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    verifier: RevenueCatService = Depends(get_revenuecat_service),
) -> CreditSyncResponse:
    try:
        granted = await sync_credits(
            db, current_user.id, current_user.app_user_id, verifier
        )
    except RevenueCatUnavailable as error:
        raise ApiException(
            "CREDIT_SYNC_FAILED",
            "Unable to verify credit purchases. Please try again.",
            503,
        ) from error

    summary = await ensure_summary(db, current_user.id)
    from app.services.entitlement_service import is_user_premium
    is_premium = await is_user_premium(db, current_user.id)
    d = summary_dict(summary, is_premium=is_premium)
    return CreditSyncResponse(
        is_premium=d["isPremium"],
        free_uses_limit=d["freeUsesLimit"],
        free_uses_used=d["freeUsesUsed"],
        free_uses_left=d["freeUsesLeft"],
        paid_credits=d["paidCredits"],
        upgrade_required=d["upgradeRequired"],
        granted_this_sync=granted,
    )
