from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/v1", tags=["me"])


class MeResponse(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    user_id: int
    app_user_id: str


@router.get("/me", response_model=MeResponse)
async def me(current_user: User = Depends(get_current_user)) -> MeResponse:
    return MeResponse(user_id=current_user.id, app_user_id=current_user.app_user_id)
