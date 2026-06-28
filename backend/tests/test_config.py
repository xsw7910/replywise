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
        openai_api_key="sk-prod-key",
    )
    assert config.app_env == "prod"


@pytest.mark.parametrize("field", ["mock_ai_enabled", "dev_tools_enabled"])
def test_production_rejects_local_testing_flags(field: str) -> None:
    kwargs = {
        "_env_file": None,
        "app_env": "prod",
        "jwt_secret": "production-secret",
        "server_pepper": "production-pepper",
        "revenuecat_secret_api_key": "production-revenuecat-secret",
        "openai_api_key": "sk-prod-key",
        field: True,
    }
    with pytest.raises(ValidationError):
        Settings(**kwargs)


def test_production_rejects_missing_openai_api_key() -> None:
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            app_env="prod",
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="prod-rc-key",
            openai_api_key="",
        )


def test_production_accepts_all_required_secrets() -> None:
    config = Settings(
        _env_file=None,
        app_env="prod",
        jwt_secret="production-secret",
        server_pepper="production-pepper",
        revenuecat_secret_api_key="prod-rc-key",
        openai_api_key="sk-prod-key",
    )
    assert config.app_env == "prod"


def test_reply_env_controls_production_guard() -> None:
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            app_env="dev",
            reply_env="prod",
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="production-revenuecat-secret",
            mock_ai_enabled=True,
        )


@pytest.mark.parametrize("field", ["mock_ai_enabled", "dev_tools_enabled"])
def test_local_testing_flags_are_allowed_in_test(field: str) -> None:
    config = Settings(_env_file=None, app_env="test", **{field: True})
    assert getattr(config, field) is True


def test_openai_timeout_and_cors_origins_are_configurable() -> None:
    config = Settings(
        _env_file=None,
        app_env="dev",
        openai_timeout_seconds=45,
        allowed_origins="https://one.example, https://two.example",
    )
    assert config.openai_timeout_seconds == 45
    assert config.cors_origins == [
        "https://one.example",
        "https://two.example",
    ]


def test_wildcard_cors_origin_is_preserved() -> None:
    config = Settings(_env_file=None, app_env="dev", allowed_origins="*")
    assert config.cors_origins == ["*"]
