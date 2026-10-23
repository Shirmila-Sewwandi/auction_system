from app.services.cache import get_cached_listing, invalidate_listing, set_cached_listing


def test_cache_roundtrip_and_invalidate():
    set_cached_listing(999999, {"listing_id": 999999, "title": "Cache Test"})
    assert get_cached_listing(999999) == {"listing_id": 999999, "title": "Cache Test"}

    invalidate_listing(999999)
    assert get_cached_listing(999999) is None


def test_cache_miss_on_unknown_key_returns_none():
    assert get_cached_listing(-1) is None
