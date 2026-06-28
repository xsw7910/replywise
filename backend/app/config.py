from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


DEV_JWT_SECRET = "dev-jwt-secret-please-change-in-production-use-long-random-string"
DEV_SERVER_PEPPER = "dev-pepper-please-change-in-production"


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
    revenuecat_entitlement_id: str = "premium"
    revenuecat_subscription_product_id: str = "premium_yearly:yearly"
    revenuecat_api_base_url: str = "https://api.revenuecat.com/v1"

    @property
    def runtime_env(self) -> str:
        return (self.reply_env or self.app_env).lower()

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
            if not self.openai_api_key:
                raise ValueError("OPENAI_API_KEY must be set in production")
        elif not self.is_dev_or_test:
            if self.mock_ai_enabled:
                raise ValueError("MOCK_AI_ENABLED is only allowed in dev/test environments")
            if self.dev_tools_enabled:
                raise ValueError("DEV_TOOLS_ENABLED is only allowed in dev/test environments")
        return self


settings = Settings()
