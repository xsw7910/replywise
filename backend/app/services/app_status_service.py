"""Database-backed app status / remote config."""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_status_config import AppStatusConfig
from app.schemas.app_status import AppStatusResponse

# Safe fallbacks applied when a DB row or individual value is missing.
DEFAULT_SUPPORTED_VERSION = "1.0.0"
# Current Android build number (pubspec `version: 1.0.0+33`).
DEFAULT_SUPPORTED_BUILD_NUMBER = 33
DEFAULT_SUPPORT_EMAIL = "support@novaaistudio.ca"
DEFAULT_MAINTENANCE_MESSAGE = "We are doing maintenance. Please try again later."
DEFAULT_UPDATE_MESSAGE = (
    "A new version is available. Please update for the best experience."
)


def _normalize_key(value: str) -> str:
    return value.strip().lower()


def _clean_text(value: str | None, fallback: str) -> str:
    if value is None:
        return fallback
    cleaned = value.strip()
    return cleaned or fallback


def _clean_build_number(value: object, fallback: int) -> int:
    try:
        number = int(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return fallback
    return number if number >= 0 else fallback


def _clean_disabled_features(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [
        feature.strip().lower()
        for feature in (str(item) for item in value)
        if feature.strip()
    ]


def _default_response(app_name: str, platform: str) -> AppStatusResponse:
    now = datetime.now(timezone.utc)
    return AppStatusResponse(
        app_name=app_name,
        platform=platform,
        maintenance=False,
        maintenance_message=DEFAULT_MAINTENANCE_MESSAGE,
        min_supported_version=DEFAULT_SUPPORTED_VERSION,
        min_supported_build_number=DEFAULT_SUPPORTED_BUILD_NUMBER,
        latest_version=DEFAULT_SUPPORTED_VERSION,
        latest_build_number=DEFAULT_SUPPORTED_BUILD_NUMBER,
        force_update=False,
        update_message=DEFAULT_UPDATE_MESSAGE,
        disabled_features=[],
        support_email=DEFAULT_SUPPORT_EMAIL,
        updated_at=now,
    )


async def get_app_status(
    db: AsyncSession,
    *,
    app_name: str,
    platform: str,
) -> AppStatusResponse:
    """Read one app/platform row and return safe defaults when absent."""
    normalized_app_name = _normalize_key(app_name) or "replywise"
    normalized_platform = _normalize_key(platform) or "android"

    result = await db.execute(
        select(AppStatusConfig)
        .where(
            AppStatusConfig.app_name == normalized_app_name,
            AppStatusConfig.platform == normalized_platform,
        )
        .limit(1)
    )
    row = result.scalar_one_or_none()
    if row is None:
        return _default_response(normalized_app_name, normalized_platform)

    fallback = _default_response(normalized_app_name, normalized_platform)
    return AppStatusResponse(
        app_name=row.app_name,
        platform=row.platform,
        maintenance=row.maintenance_enabled,
        maintenance_message=_clean_text(
            row.maintenance_message,
            fallback.maintenance_message,
        ),
        min_supported_version=_clean_text(
            row.min_supported_version,
            fallback.min_supported_version,
        ),
        min_supported_build_number=_clean_build_number(
            row.min_supported_build_number,
            fallback.min_supported_build_number,
        ),
        latest_version=_clean_text(row.latest_version, fallback.latest_version),
        latest_build_number=_clean_build_number(
            row.latest_build_number,
            fallback.latest_build_number,
        ),
        force_update=row.force_update,
        update_message=_clean_text(row.update_message, fallback.update_message),
        disabled_features=_clean_disabled_features(row.disabled_features),
        support_email=_clean_text(row.support_email, fallback.support_email),
        updated_at=row.updated_at or fallback.updated_at,
    )
