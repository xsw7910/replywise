from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device_user_binding import DeviceUserBinding
from app.models.user import User


async def resolve_anonymous_user(
    db: AsyncSession,
    *,
    app_user_id: str,
    device_hash: str,
    platform: str,
) -> User:
    """Resolve anonymous auth without allowing a device to claim another user.

    The binding's primary key is also the concurrency guard: two first-launch
    requests for the same device cannot commit two owners. The losing
    transaction rolls back its tentative user and adopts the committed owner.
    """

    binding = await db.get(DeviceUserBinding, device_hash)
    if binding is not None:
        user = await db.get(User, binding.user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Device identity binding is invalid",
            )
        return await _touch_and_validate(db, user, platform)

    app_user = await db.scalar(select(User).where(User.app_user_id == app_user_id))
    if app_user is not None and app_user.device_hash != device_hash:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="App user identity belongs to a different device",
        )

    user = app_user
    if user is None:
        # Backward compatibility for users created before device bindings
        # existed. The oldest row is the original RevenueCat identity and owns
        # purchases made before an uninstall/reinstall.
        user = await db.scalar(
            select(User)
            .where(User.device_hash == device_hash)
            .order_by(User.id.asc())
            .limit(1)
        )

    if user is not None and user.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is blocked",
        )

    if user is None:
        user = User(
            app_user_id=app_user_id,
            device_hash=device_hash,
            platform=platform,
        )
        db.add(user)
        await db.flush()

    user.platform = platform
    user.last_seen_at = datetime.now(timezone.utc)
    db.add(DeviceUserBinding(device_hash=device_hash, user_id=user.id))

    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        # Another request won either the device binding race or the
        # app_user_id uniqueness race. Only a matching device binding is safe
        # to adopt.
        binding = await db.get(DeviceUserBinding, device_hash)
        if binding is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Anonymous identity conflict",
            )
        user = await db.get(User, binding.user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Device identity binding is invalid",
            )
        return await _touch_and_validate(db, user, platform)

    await db.refresh(user)
    return user


async def _touch_and_validate(
    db: AsyncSession,
    user: User,
    platform: str,
) -> User:
    if user.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is blocked",
        )
    user.platform = platform
    user.last_seen_at = datetime.now(timezone.utc)
    await db.commit()
    return user

