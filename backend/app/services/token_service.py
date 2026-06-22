import hashlib
import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt

from app.config import settings


def hash_device(device_id: str) -> str:
    raw = f"{device_id}{settings.server_pepper}".encode()
    return hashlib.sha256(raw).hexdigest()


def _now() -> datetime:
    return datetime.now(timezone.utc)


def create_access_token(
    user_id: int, app_user_id: str, device_hash: str, token_version: int
) -> str:
    exp = _now() + timedelta(seconds=settings.jwt_access_expire_seconds)
    payload = {
        "user_id": user_id,
        "app_user_id": app_user_id,
        "device_hash": device_hash,
        "token_version": token_version,
        "token_type": "access",
        "jti": str(uuid.uuid4()),
        "iat": _now(),
        "exp": exp,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(
    user_id: int, app_user_id: str, device_hash: str, token_version: int
) -> str:
    exp = _now() + timedelta(seconds=settings.jwt_refresh_expire_seconds)
    payload = {
        "user_id": user_id,
        "app_user_id": app_user_id,
        "device_hash": device_hash,
        "token_version": token_version,
        "token_type": "refresh",
        "jti": str(uuid.uuid4()),
        "iat": _now(),
        "exp": exp,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    """Raises JWTError on invalid or expired token."""
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
