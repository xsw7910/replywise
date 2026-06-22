from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.services.usage_service import ensure_summary, summary_dict
from app.services.entitlement_service import is_user_premium

router = APIRouter(prefix="/v1", tags=["me"])


class MeResponse(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    user_id: int
    app_user_id: str
    is_premium: bool
    free_uses_limit: int
    free_uses_used: int
    free_uses_left: int | None
    paid_credits: int
    upgrade_required: bool


@router.get("/me", response_model=MeResponse)
async def me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MeResponse:
    summary = await ensure_summary(db, current_user.id)
    d = summary_dict(
        summary,
        is_premium=await is_user_premium(db, current_user.id),
    )
    return MeResponse(
        user_id=current_user.id,
        app_user_id=current_user.app_user_id,
        is_premium=d["isPremium"],
        free_uses_limit=d["freeUsesLimit"],
        free_uses_used=d["freeUsesUsed"],
        free_uses_left=d["freeUsesLeft"],
        paid_credits=d["paidCredits"],
        upgrade_required=d["upgradeRequired"],
    )
