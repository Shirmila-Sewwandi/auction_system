from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://auction:auction@localhost:5432/auction_db"
    secret_key: str = "dev-secret-change-me"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Fallbacks only — platform_config DB row (Phase 10) is authoritative once it exists.
    default_min_bid_increment: float = 1.00
    default_anti_sniping_window_minutes: int = 5
    default_anti_sniping_extension_minutes: int = 10

    enable_background_worker: bool = True
    redis_url: str = "redis://localhost:6379/0"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
