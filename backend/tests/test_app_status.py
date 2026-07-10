import asyncio
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete

from app.database import AsyncSessionLocal
from app.models.app_status_config import AppStatusConfig
from app.services.app_status_service import (
    DEFAULT_MAINTENANCE_MESSAGE,
    DEFAULT_SUPPORT_EMAIL,
    DEFAULT_SUPPORTED_BUILD_NUMBER,
    DEFAULT_SUPPORTED_VERSION,
    DEFAULT_UPDATE_MESSAGE,
)


async def _clear_configs() -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(delete(AppStatusConfig))
        await db.commit()


async def _seed_config(
    *,
    app_name: str = "replywise",
    platform: str = "android",
    maintenance_enabled: bool = False,
    maintenance_message: str = DEFAULT_MAINTENANCE_MESSAGE,
    min_supported_version: str = DEFAULT_SUPPORTED_VERSION,
    min_supported_build_number: int = DEFAULT_SUPPORTED_BUILD_NUMBER,
    latest_version: str = DEFAULT_SUPPORTED_VERSION,
    latest_build_number: int = DEFAULT_SUPPORTED_BUILD_NUMBER,
    force_update: bool = False,
    update_message: str = DEFAULT_UPDATE_MESSAGE,
    disabled_features: list[str] | None = None,
    support_email: str = DEFAULT_SUPPORT_EMAIL,
) -> None:
    now = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        db.add(
            AppStatusConfig(
                app_name=app_name,
                platform=platform,
                maintenance_enabled=maintenance_enabled,
                maintenance_message=maintenance_message,
                min_supported_version=min_supported_version,
                min_supported_build_number=min_supported_build_number,
                latest_version=latest_version,
                latest_build_number=latest_build_number,
                force_update=force_update,
                update_message=update_message,
                disabled_features=disabled_features or [],
                support_email=support_email,
                created_at=now,
                updated_at=now,
            )
        )
        await db.commit()


@pytest.fixture(autouse=True)
def clean_app_status_configs(client: TestClient):
    asyncio.run(_clear_configs())
    yield
    asyncio.run(_clear_configs())


def test_app_status_does_not_require_authentication(client: TestClient):
    """The endpoint is public — no Authorization header, still 200."""
    response = client.get("/v1/app-status")
    assert response.status_code == 200
    assert "Authorization" not in response.request.headers


def test_app_status_normal_from_database(client: TestClient):
    asyncio.run(
        _seed_config(
            min_supported_version="1.0.0",
            latest_version="1.0.0",
        )
    )

    response = client.get("/v1/app-status?appName=replywise&platform=android")
    assert response.status_code == 200
    body = response.json()

    assert body["appName"] == "replywise"
    assert body["platform"] == "android"
    assert body["maintenance"] is False
    assert body["maintenanceMessage"] == DEFAULT_MAINTENANCE_MESSAGE
    assert body["forceUpdate"] is False
    assert body["minSupportedVersion"] == "1.0.0"
    assert body["minSupportedBuildNumber"] == DEFAULT_SUPPORTED_BUILD_NUMBER
    assert body["latestVersion"] == "1.0.0"
    assert body["latestBuildNumber"] == DEFAULT_SUPPORTED_BUILD_NUMBER
    assert body["disabledFeatures"] == []
    assert body["supportEmail"] == DEFAULT_SUPPORT_EMAIL
    assert body["updatedAt"]


def test_app_status_defaults_query_params(client: TestClient):
    """Missing query params fall back to replywise/android."""
    response = client.get("/v1/app-status")
    assert response.status_code == 200
    body = response.json()
    assert body["appName"] == "replywise"
    assert body["platform"] == "android"


def test_app_status_unknown_app_platform_returns_safe_defaults(client: TestClient):
    asyncio.run(
        _seed_config(
            app_name="replywise",
            platform="android",
            maintenance_enabled=True,
            latest_version="9.9.9",
        )
    )

    body = client.get("/v1/app-status?appName=other&platform=ios").json()
    assert body["appName"] == "other"
    assert body["platform"] == "ios"
    assert body["maintenance"] is False
    assert body["forceUpdate"] is False
    assert body["minSupportedVersion"] == DEFAULT_SUPPORTED_VERSION
    assert body["minSupportedBuildNumber"] == DEFAULT_SUPPORTED_BUILD_NUMBER
    assert body["latestVersion"] == DEFAULT_SUPPORTED_VERSION
    assert body["latestBuildNumber"] == DEFAULT_SUPPORTED_BUILD_NUMBER
    assert body["maintenanceMessage"] == DEFAULT_MAINTENANCE_MESSAGE
    assert body["updateMessage"] == DEFAULT_UPDATE_MESSAGE
    assert body["disabledFeatures"] == []
    assert body["supportEmail"] == DEFAULT_SUPPORT_EMAIL
    assert body["updatedAt"]


def test_app_status_maintenance_enabled(client: TestClient):
    asyncio.run(
        _seed_config(
            maintenance_enabled=True,
            maintenance_message="Down for scheduled maintenance.",
        )
    )

    body = client.get("/v1/app-status").json()
    assert body["maintenance"] is True
    assert body["maintenanceMessage"] == "Down for scheduled maintenance."


def test_app_status_force_update_enabled(client: TestClient):
    asyncio.run(
        _seed_config(
            force_update=True,
            min_supported_version="2.0.0",
            update_message="This version is no longer supported.",
        )
    )

    body = client.get("/v1/app-status").json()
    assert body["forceUpdate"] is True
    assert body["minSupportedVersion"] == "2.0.0"
    assert body["updateMessage"] == "This version is no longer supported."


def test_app_status_optional_update_returned(client: TestClient):
    """A newer latestVersion with forceUpdate false signals an optional update."""
    asyncio.run(
        _seed_config(
            force_update=False,
            min_supported_version="1.0.0",
            latest_version="1.2.0",
        )
    )

    body = client.get("/v1/app-status").json()
    assert body["forceUpdate"] is False
    assert body["latestVersion"] == "1.2.0"
    assert body["minSupportedVersion"] == "1.0.0"


def test_app_status_build_numbers_returned(client: TestClient):
    """Same version name, different build number — the client needs both."""
    asyncio.run(
        _seed_config(
            force_update=True,
            min_supported_version="1.0.0",
            min_supported_build_number=33,
            latest_version="1.0.0",
            latest_build_number=34,
        )
    )

    body = client.get("/v1/app-status").json()
    assert body["forceUpdate"] is True
    assert body["minSupportedVersion"] == "1.0.0"
    assert body["minSupportedBuildNumber"] == 33
    assert body["latestVersion"] == "1.0.0"
    assert body["latestBuildNumber"] == 34


def test_app_status_negative_build_numbers_use_safe_defaults(client: TestClient):
    asyncio.run(
        _seed_config(
            min_supported_build_number=-1,
            latest_build_number=-5,
        )
    )

    body = client.get("/v1/app-status").json()
    assert body["minSupportedBuildNumber"] == DEFAULT_SUPPORTED_BUILD_NUMBER
    assert body["latestBuildNumber"] == DEFAULT_SUPPORTED_BUILD_NUMBER


def test_app_status_disabled_features_returned(client: TestClient):
    asyncio.run(_seed_config(disabled_features=["Reply", " POLISH "]))

    body = client.get("/v1/app-status").json()
    assert body["disabledFeatures"] == ["reply", "polish"]


def test_app_status_blank_database_values_use_safe_defaults(client: TestClient):
    """Blank DB strings fall back to safe defaults rather than empty strings."""
    asyncio.run(
        _seed_config(
            maintenance_message="   ",
            min_supported_version="",
            latest_version="",
            update_message="",
            disabled_features=[],
            support_email="",
        )
    )

    body = client.get("/v1/app-status").json()
    assert body["maintenanceMessage"] == DEFAULT_MAINTENANCE_MESSAGE
    assert body["minSupportedVersion"] == DEFAULT_SUPPORTED_VERSION
    assert body["latestVersion"] == DEFAULT_SUPPORTED_VERSION
    assert body["updateMessage"] == DEFAULT_UPDATE_MESSAGE
    assert body["disabledFeatures"] == []
    assert body["supportEmail"] == DEFAULT_SUPPORT_EMAIL


def test_app_status_endpoint_does_not_call_external_services(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
):
    """The endpoint only reads its DB row and performs no external I/O."""

    def fail_if_called(*args, **kwargs):  # pragma: no cover - assertion hook
        raise AssertionError("external HTTP client should not be used")

    monkeypatch.setattr("httpx.AsyncClient", fail_if_called)
    response = client.get("/v1/app-status")
    assert response.status_code == 200
