from datetime import datetime, timedelta, timezone

import pytest


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="snipeadmin@example.com")
    return client.post("/api/admin/categories", json={"name": "Sniping"}, headers=admin_headers).json()[
        "category_id"
    ]


def _create_and_approve(client, make_user, category_id, *, window_minutes_from_now_end: int, email_suffix: str):
    """Listing whose end_time is `window_minutes_from_now_end` minutes from now, with the
    platform default anti-sniping window (5 min) / extension (10 min)."""
    seller_headers, _ = make_user(["SELLER"], email=f"snipeseller{email_suffix}@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email=f"snipemod{email_suffix}@example.com")
    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(minutes=window_minutes_from_now_end)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Snipe Item",
            "description": "x",
            "starting_price": "100.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    return listing_id


def test_bid_inside_window_extends_end_time(client, make_user, category_id):
    # end_time is 2 minutes away; default anti-sniping window is 5 minutes -> inside window
    listing_id = _create_and_approve(client, make_user, category_id, window_minutes_from_now_end=2, email_suffix="1")
    before = client.get(f"/api/listings/{listing_id}").json()["end_time"]

    bidder_headers, _ = make_user(["BIDDER"], email="snipebidder1@example.com")
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    assert resp.status_code == 200
    after = resp.json()["end_time"]
    assert after > before  # extended forward, never shortened


def test_bid_outside_window_does_not_extend(client, make_user, category_id):
    # end_time is 30 minutes away; default window is 5 minutes -> outside window
    listing_id = _create_and_approve(
        client, make_user, category_id, window_minutes_from_now_end=30, email_suffix="2"
    )
    before = client.get(f"/api/listings/{listing_id}").json()["end_time"]

    bidder_headers, _ = make_user(["BIDDER"], email="snipebidder2@example.com")
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    assert resp.status_code == 200
    assert resp.json()["end_time"] == before


def test_repeated_late_bids_each_extend_further(client, make_user, db_session, category_id):
    """A single extension pushes end_time well outside the window, so a second bid placed
    right after the first should NOT extend again (it's no longer 'late' relative to the new
    end_time) — but if the clock keeps closing in on that new end_time, a second qualifying
    bid must extend it again."""
    listing_id = _create_and_approve(client, make_user, category_id, window_minutes_from_now_end=2, email_suffix="3")
    bidder1, _ = make_user(["BIDDER"], email="snipebidder3a@example.com")
    bidder2, _ = make_user(["BIDDER"], email="snipebidder3b@example.com")

    first = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder1)
    second_immediate = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "110.00"}, headers=bidder2)
    assert second_immediate.json()["end_time"] == first.json()["end_time"]  # not late relative to new end_time

    # Simulate time closing back in on the (already extended) end_time.
    from app.models.listing import Listing

    listing = db_session.query(Listing).filter_by(listing_id=listing_id).one()
    listing.end_time = datetime.now(timezone.utc) + timedelta(minutes=2)
    db_session.commit()

    bidder3, _ = make_user(["BIDDER"], email="snipebidder3c@example.com")
    third = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "120.00"}, headers=bidder3)
    assert third.json()["end_time"] > second_immediate.json()["end_time"]
