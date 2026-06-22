from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


DEV_JWT_SECRET = "dev-jwt-secret-please-change-in-production-use-long-random-string"
DEV_SERVER_PEPPER = "dev-pepper-please-change-in-production"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = "dev"
    service_name: str = "reply-backend"

    database_url: str = "sqlite+aiosqlite:///./replywise.db"

    jwt_secret: str = DEV_JWT_SECRET
    jwt_algorithm: str = "HS256"
    jwt_access_expire_seconds: int = 604800   # 7 days
    jwt_refresh_expire_seconds: int = 2592000  # 30 days

    server_pepper: str = DEV_SERVER_PEPPER

    @model_validator(mode="after")
    def validate_production_secrets(self) -> "Settings":
        if self.app_env.lower() == "prod":
            if not self.jwt_secret or self.jwt_secret == DEV_JWT_SECRET:
                raise ValueError("JWT_SECRET must be set to a non-development value in production")
            if not self.server_pepper or self.server_pepper == DEV_SERVER_PEPPER:
                raise ValueError(
                    "SERVER_PEPPER must be set to a non-development value in production"
                )
        return self


settings = Settings()
