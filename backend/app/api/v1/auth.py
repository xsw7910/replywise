from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models.user import User
from app.services.auth_service import resolve_anonymous_user
from app.services.usage_service import ensure_device_usage, ensure_summary
from app.services.token_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_device,
)

router = APIRouter(prefix="/v1/auth", tags=["auth"])


class ApiModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class AnonymousRequest(ApiModel):
    app_user_id: str
    device_id: str
    platform: str = "android"


class MeResponse(ApiModel):
    user_id: int
    app_user_id: str


class TokenResponse(ApiModel):
    access_token: str
    refresh_token: str
    expires_in: int
    me: MeResponse


class RefreshRequest(ApiModel):
    refresh_token: str


class RefreshResponse(ApiModel):
    access_token: str
    expires_in: int


@router.post("/anonymous", response_model=TokenResponse)
async def anonymous(
    body: AnonymousRequest, db: AsyncSession = Depends(get_db)
) -> TokenResponse:
    device_hash = hash_device(body.device_id)
    user = await resolve_anonymous_user(
        db,
        app_user_id=body.app_user_id,
        device_hash=device_hash,
        platform=body.platform,
    )
    await ensure_summary(db, user.id)

    # Free usage is shared per device. Ensuring the row here means a reinstall
    # that mints a new app_user_id immediately inherits the device's remaining
    # free allowance instead of getting a fresh one.
    await ensure_device_usage(db, device_hash)

    access_token = create_access_token(
        user.id, user.app_user_id, user.device_hash, user.token_version
    )
    refresh_token = create_refresh_token(
        user.id, user.app_user_id, user.device_hash, user.token_version
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.jwt_access_expire_seconds,
        me=MeResponse(user_id=user.id, app_user_id=user.app_user_id),
    )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh(
    body: RefreshRequest, db: AsyncSession = Depends(get_db)
) -> RefreshResponse:
    try:
        payload = decode_token(body.refresh_token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    if payload.get("token_type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type"
        )

    user_id: int | None = payload.get("user_id")
    token_version: int = payload.get("token_version", -1)

    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Malformed token"
        )

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None or user.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or blocked"
        )

    if user.token_version != token_version:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalidated"
        )

    if (
        payload.get("app_user_id") != user.app_user_id
        or payload.get("device_hash") != user.device_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token identity does not match current user",
        )

    access_token = create_access_token(
        user.id, user.app_user_id, user.device_hash, user.token_version
    )
    return RefreshResponse(
        access_token=access_token, expires_in=settings.jwt_access_expire_seconds
    )
