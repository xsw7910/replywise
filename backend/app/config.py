import logging

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


DEV_JWT_SECRET = "dev-jwt-secret-please-change-in-production-use-long-random-string"
DEV_SERVER_PEPPER = "dev-pepper-please-change-in-production"


def parse_credit_product_map(raw: str, *, strict: bool) -> dict[str, int]:
    """Parse REVENUECAT_CREDIT_PRODUCT_MAP into a {product_id: credits} dict.

    Format: ``product_id:credits,product_id:credits`` (e.g.
    ``credits_10:10,prod733d52bcdd:10``). Empty entries are ignored and
    whitespace is trimmed. Credits must be positive integers.

    When *strict* is True (production) a malformed entry raises ValueError so
    startup fails loudly; otherwise the entry is skipped with a warning. Product
    ids are not secrets, so the offending entry is safe to log.
    """
    result: dict[str, int] = {}
    for entry in raw.split(","):
        entry = entry.strip()
        if not entry:
            continue

        product_id, separator, credits_text = entry.partition(":")
        product_id = product_id.strip()
        credits_text = credits_text.strip()

        error: str | None = None
        if not separator or not product_id or not credits_text:
            error = "expected 'product_id:credits'"
        else:
            try:
                credits = int(credits_text)
            except ValueError:
                error = "credits is not an integer"
            else:
                if credits <= 0:
                    error = "credits must be a positive integer"

        if error is not None:
            message = (
                f"Invalid REVENUECAT_CREDIT_PRODUCT_MAP entry {entry!r}: {error}"
            )
            if strict:
                raise ValueError(message)
            logger.warning("%s — skipping", message)
            continue

        result[product_id] = credits
    return result


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = "dev"
    reply_env: str | None = None
    service_name: str = "reply-backend"

    database_url: str = "sqlite+aiosqlite:///./replywise.db"

    jwt_secret: str = DEV_JWT_SECRET
    jwt_algorithm: str = "HS256"
    jwt_access_expire_seconds: int = 604800   # 7 days
    jwt_refresh_expire_seconds: int = 2592000  # 30 days

    server_pepper: str = DEV_SERVER_PEPPER

    ai_provider: str = "fake"
    mock_ai_enabled: bool = False
    dev_tools_enabled: bool = False
    explain_daily_limit: int = 10
    free_lifetime_limit: int = 5
    generation_rate_per_minute: int = 8
    idempotency_ttl_seconds: int = 86400
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_timeout_seconds: int = Field(default=30, ge=1, le=120)
    allowed_origins: str = "*"

    revenuecat_secret_api_key: str = ""
    revenuecat_project_id: str = ""
    revenuecat_entitlement_id: str = "premium"
    revenuecat_subscription_product_id: str = "premium_yearly:yearly"
    revenuecat_api_base_url: str = "https://api.revenuecat.com/v2"
    # Optional product_id:credits overrides. RevenueCat API v2 purchases report
    # internal product ids (e.g. "prod733d52bcdd"); map them here per environment
    # instead of hardcoding them. Merged on top of the in-code store defaults.
    revenuecat_credit_product_map: str = ""

    @property
    def runtime_env(self) -> str:
        return (self.reply_env or self.app_env).lower()

    @property
    def credit_product_map(self) -> dict[str, int]:
        """Parsed REVENUECAT_CREDIT_PRODUCT_MAP overrides (env-configured)."""
        return parse_credit_product_map(
            self.revenuecat_credit_product_map,
            strict=(self.runtime_env == "prod"),
        )

    @property
    def is_dev_or_test(self) -> bool:
        return self.runtime_env in {"dev", "test"}

    @property
    def cors_origins(self) -> list[str]:
        value = self.allowed_origins.strip()
        if not value or value == "*":
            return ["*"]
        return [origin.strip() for origin in value.split(",") if origin.strip()]

    @model_validator(mode="after")
    def validate_production_secrets(self) -> "Settings":
        if self.runtime_env == "prod":
            database_url = self.database_url.strip().lower()
            if database_url.startswith("sqlite"):
                raise ValueError(
                    "SQLite is not allowed in production. "
                    "Use PostgreSQL DATABASE_URL."
                )
            if not database_url.startswith("postgresql+asyncpg://"):
                raise ValueError(
                    "Production DATABASE_URL must use PostgreSQL with asyncpg."
                )
            if self.mock_ai_enabled:
                raise ValueError("MOCK_AI_ENABLED must never be true in production")
            if self.dev_tools_enabled:
                raise ValueError("DEV_TOOLS_ENABLED must never be true in production")
            if not self.jwt_secret or self.jwt_secret == DEV_JWT_SECRET:
                raise ValueError("JWT_SECRET must be set to a non-development value in production")
            if not self.server_pepper or self.server_pepper == DEV_SERVER_PEPPER:
                raise ValueError(
                    "SERVER_PEPPER must be set to a non-development value in production"
                )
            if not self.revenuecat_secret_api_key:
                raise ValueError("REVENUECAT_SECRET_API_KEY must be set in production")
            if not self.revenuecat_project_id:
                raise ValueError("REVENUECAT_PROJECT_ID must be set in production")
            if not self.revenuecat_credit_product_map.strip():
                raise ValueError(
                    "REVENUECAT_CREDIT_PRODUCT_MAP must be set in production so "
                    "purchased credit packs map to a credit grant"
                )
            if not self.openai_api_key:
                raise ValueError("OPENAI_API_KEY must be set in production")
        elif not self.is_dev_or_test:
            if self.mock_ai_enabled:
                raise ValueError("MOCK_AI_ENABLED is only allowed in dev/test environments")
            if self.dev_tools_enabled:
                raise ValueError("DEV_TOOLS_ENABLED is only allowed in dev/test environments")

        # Validate the credit product map at startup. In production a malformed
        # entry raises here (failing fast); elsewhere malformed entries are
        # skipped with a warning.
        _ = self.credit_product_map
        return self


settings = Settings()
