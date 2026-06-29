from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.errors import ApiException
from app.models.user import User
from app.services.entitlement_service import sync_entitlement
from app.services.revenuecat_service import RevenueCatService, RevenueCatUnavailable
from app.services.usage_service import ensure_device_usage, ensure_summary, summary_view

router = APIRouter(prefix="/v1/entitlement", tags=["entitlement"])


class EntitlementSyncResponse(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    is_premium: bool
    free_uses_limit: int
    free_uses_used: int
    free_uses_left: int | None
    paid_credits: int
    upgrade_required: bool


def get_revenuecat_service() -> RevenueCatService:
    return RevenueCatService()


@router.post("/sync", response_model=EntitlementSyncResponse)
async def entitlement_sync(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    verifier: RevenueCatService = Depends(get_revenuecat_service),
) -> EntitlementSyncResponse:
    try:
        is_premium = await sync_entitlement(
            db, current_user.id, current_user.app_user_id, verifier
        )
    except RevenueCatUnavailable as error:
        raise ApiException(
            "ENTITLEMENT_SYNC_FAILED",
            "Unable to verify subscription status. Please try again.",
            503,
        ) from error

    device = await ensure_device_usage(db, current_user.device_hash)
    summary = await ensure_summary(db, current_user.id)
    return EntitlementSyncResponse.model_validate(
        summary_view(device, summary, is_premium=is_premium)
    )
