import pytest
from pydantic import ValidationError

from app.config import (
    DEV_JWT_SECRET,
    DEV_SERVER_PEPPER,
    Settings,
    parse_credit_product_map,
)

PROD_DATABASE_URL = (
    "postgresql+asyncpg://replywise:test@localhost:5432/replywise"
)


def test_development_secret_defaults_are_allowed() -> None:
    config = Settings(_env_file=None, app_env="dev")
    assert config.jwt_secret == DEV_JWT_SECRET
    assert config.server_pepper == DEV_SERVER_PEPPER


def test_development_allows_sqlite() -> None:
    config = Settings(
        _env_file=None,
        app_env="dev",
        database_url="sqlite+aiosqlite:///./replywise.db",
    )
    assert config.database_url.startswith("sqlite")


def test_production_rejects_sqlite_database() -> None:
    with pytest.raises(
        ValidationError,
        match="SQLite is not allowed in production",
    ):
        Settings(
            _env_file=None,
            reply_env="prod",
            database_url="sqlite+aiosqlite:///./replywise.db",
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="production-revenuecat-secret",
            revenuecat_project_id="proj_test",
            openai_api_key="sk-prod-key",
        )


def test_production_requires_postgresql_asyncpg_url() -> None:
    with pytest.raises(
        ValidationError,
        match="must use PostgreSQL with asyncpg",
    ):
        Settings(
            _env_file=None,
            reply_env="prod",
            database_url="postgresql://replywise:test@localhost/replywise",
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="production-revenuecat-secret",
            revenuecat_project_id="proj_test",
            openai_api_key="sk-prod-key",
        )


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
            database_url=PROD_DATABASE_URL,
            jwt_secret=jwt_secret,
            server_pepper=server_pepper,
        )


def test_production_accepts_explicit_non_development_secrets() -> None:
    config = Settings(
        _env_file=None,
        app_env="prod",
        database_url=PROD_DATABASE_URL,
        jwt_secret="production-secret",
        server_pepper="production-pepper",
        revenuecat_secret_api_key="production-revenuecat-secret",
        revenuecat_project_id="proj_test",
        openai_api_key="sk-prod-key",
    )
    assert config.app_env == "prod"


@pytest.mark.parametrize("field", ["mock_ai_enabled", "dev_tools_enabled"])
def test_production_rejects_local_testing_flags(field: str) -> None:
    kwargs = {
        "_env_file": None,
        "app_env": "prod",
        "database_url": PROD_DATABASE_URL,
        "jwt_secret": "production-secret",
        "server_pepper": "production-pepper",
        "revenuecat_secret_api_key": "production-revenuecat-secret",
        "revenuecat_project_id": "proj_test",
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
            database_url=PROD_DATABASE_URL,
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="prod-rc-key",
            revenuecat_project_id="proj_test",
            openai_api_key="",
        )


def test_production_rejects_missing_revenuecat_project_id() -> None:
    with pytest.raises(ValidationError, match="REVENUECAT_PROJECT_ID"):
        Settings(
            _env_file=None,
            app_env="prod",
            database_url=PROD_DATABASE_URL,
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="prod-rc-key",
            revenuecat_project_id="",
            openai_api_key="sk-prod-key",
        )


def test_production_accepts_all_required_secrets() -> None:
    config = Settings(
        _env_file=None,
        app_env="prod",
        database_url=PROD_DATABASE_URL,
        jwt_secret="production-secret",
        server_pepper="production-pepper",
        revenuecat_secret_api_key="prod-rc-key",
        revenuecat_project_id="proj_test",
        openai_api_key="sk-prod-key",
    )
    assert config.app_env == "prod"


def test_reply_env_controls_production_guard() -> None:
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            app_env="dev",
            reply_env="prod",
            database_url=PROD_DATABASE_URL,
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


# ── REVENUECAT_CREDIT_PRODUCT_MAP parsing ─────────────────────────────────────

def test_credit_product_map_parses_valid_entries() -> None:
    result = parse_credit_product_map(
        "credits_10:10, credits_50:50 , prod733d52bcdd:10", strict=True
    )
    assert result == {"credits_10": 10, "credits_50": 50, "prod733d52bcdd": 10}


def test_credit_product_map_empty_returns_empty() -> None:
    assert parse_credit_product_map("", strict=True) == {}
    assert parse_credit_product_map("  ,  , ", strict=True) == {}


def test_credit_product_map_skips_malformed_when_not_strict() -> None:
    result = parse_credit_product_map(
        "credits_10:10,bogus,credits_50:notanint,credits_100:0,credits_75:75",
        strict=False,
    )
    assert result == {"credits_10": 10, "credits_75": 75}


@pytest.mark.parametrize(
    "bad",
    ["bogus", "credits_10:notanint", "credits_10:0", "credits_10:-5", ":10", "credits_10:"],
)
def test_credit_product_map_raises_when_strict(bad: str) -> None:
    with pytest.raises(ValueError, match="REVENUECAT_CREDIT_PRODUCT_MAP"):
        parse_credit_product_map(bad, strict=True)


def test_production_rejects_malformed_credit_product_map() -> None:
    with pytest.raises(ValidationError, match="REVENUECAT_CREDIT_PRODUCT_MAP"):
        Settings(
            _env_file=None,
            app_env="prod",
            database_url=PROD_DATABASE_URL,
            jwt_secret="production-secret",
            server_pepper="production-pepper",
            revenuecat_secret_api_key="prod-rc-key",
            revenuecat_project_id="proj_test",
            openai_api_key="sk-prod-key",
            revenuecat_credit_product_map="credits_10:not_a_number",
        )


def test_production_accepts_valid_credit_product_map() -> None:
    config = Settings(
        _env_file=None,
        app_env="prod",
        database_url=PROD_DATABASE_URL,
        jwt_secret="production-secret",
        server_pepper="production-pepper",
        revenuecat_secret_api_key="prod-rc-key",
        revenuecat_project_id="proj_test",
        openai_api_key="sk-prod-key",
        revenuecat_credit_product_map="credits_10:10,prod733d52bcdd:10",
    )
    assert config.credit_product_map == {"credits_10": 10, "prod733d52bcdd": 10}


def test_dev_skips_malformed_credit_product_map_without_raising() -> None:
    config = Settings(
        _env_file=None,
        app_env="dev",
        revenuecat_credit_product_map="bogus,credits_10:10",
    )
    assert config.credit_product_map == {"credits_10": 10}
