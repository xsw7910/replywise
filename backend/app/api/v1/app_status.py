from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.app_status import AppStatusResponse
from app.services.app_status_service import get_app_status

router = APIRouter(prefix="/v1", tags=["app-status"])


@router.get("/app-status", response_model=AppStatusResponse)
async def app_status(
    app_name: str = Query("replywise", alias="appName"),
    platform: str = Query("android"),
    db: AsyncSession = Depends(get_db),
) -> AppStatusResponse:
    """Public, unauthenticated remote-config endpoint."""
    return await get_app_status(db, app_name=app_name, platform=platform)
