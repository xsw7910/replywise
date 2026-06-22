import pytest
from pydantic import ValidationError

from app.config import DEV_JWT_SECRET, DEV_SERVER_PEPPER, Settings


def test_development_secret_defaults_are_allowed() -> None:
    config = Settings(_env_file=None, app_env="dev")
    assert config.jwt_secret == DEV_JWT_SECRET
    assert config.server_pepper == DEV_SERVER_PEPPER


@pytest.mark.parametrize(
    ("jwt_secret", "server_pepper"),
    [
        (DEV_JWT_SECRET, "production-pepper"),
        ("production-secret", DEV_SERVER_PEPPER),
        ("", "production-pepper"),
        ("production-secret", ""),
    ],
)
def test_production_rejects_missing_or_development_secrets(
    jwt_secret: str, server_pepper: str
) -> None:
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            app_env="prod",
            jwt_secret=jwt_secret,
            server_pepper=server_pepper,
        )


def test_production_accepts_explicit_non_development_secrets() -> None:
    config = Settings(
        _env_file=None,
        app_env="prod",
        jwt_secret="production-secret",
        server_pepper="production-pepper",
        revenuecat_secret_api_key="production-revenuecat-secret",
    )
    assert config.app_env == "prod"
