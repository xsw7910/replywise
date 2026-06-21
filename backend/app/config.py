from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = "dev"
    service_name: str = "reply-backend"

    # Populated by the environment; kept here so future modules can import
    # from a single place rather than reading os.environ directly.
    reply_backend_base_url: str = "http://10.0.2.2:8000"


settings = Settings()
