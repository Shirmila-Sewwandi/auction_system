import json
from functools import lru_cache

import redis

from app.core.config import settings

LISTING_DETAIL_TTL_SECONDS = 5


@lru_cache
def _client() -> redis.Redis:
    return redis.from_url(settings.redis_url, decode_responses=True, socket_connect_timeout=0.2)


def _listing_key(listing_id: int) -> str:
    return f"listing:{listing_id}"


def get_cached_listing(listing_id: int) -> dict | None:
    """Fails soft on any Redis error — PostgreSQL is always the source of truth (spec §4.1.1:
    Redis is an optimisation, never authoritative), so a cache outage must never surface to
    callers as an error."""
    try:
        raw = _client().get(_listing_key(listing_id))
        return json.loads(raw) if raw else None
    except redis.RedisError:
        return None


def set_cached_listing(listing_id: int, data: dict) -> None:
    try:
        _client().set(_listing_key(listing_id), json.dumps(data, default=str), ex=LISTING_DETAIL_TTL_SECONDS)
    except redis.RedisError:
        pass


def invalidate_listing(listing_id: int) -> None:
    try:
        _client().delete(_listing_key(listing_id))
    except redis.RedisError:
        pass
