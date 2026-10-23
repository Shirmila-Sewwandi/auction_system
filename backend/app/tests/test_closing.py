from datetime import datetime, timedelta, timezone

import pytest

from app.models.listing import Listing
from app.services.closing import close_expired_auction


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="closeadmin@example.com")
    return client.post("/api/admin/categories", json={"name": "Closing"}, headers=admin_headers).json()[
        "category_id"
    ]


def _create_active_listing(client, make_user, category_id, *, reserve=None, email_suffix=""):
    seller_headers, seller_id = make_user(["SELLER"], email=f"closeseller{email_suffix}@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email=f"closemod{email_suffix}@example.com")
    start = (datetime.now(timezone.utc) - timedelta(minutes=2)).isoformat()
    payload = {
        "category_id": category_id,
        "title": "Closing Item",
        "description": "x",
        "starting_price": "100.00",
        "start_time": start,
        "end_time": (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(),
    }
    if reserve:
        payload["reserve_price"] = reserve
    create = client.post("/api/listings", json=payload, headers=seller_headers)
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    return listing_id, seller_headers, seller_id


def _force_past_end_time(db_session, listing_id):
    db_session.query(Listing).filter_by(listing_id=listing_id).update(
        {"end_time": datetime.now(timezone.utc) - timedelta(seconds=1)}
    )
    db_session.commit()


def test_no_bids_results_in_no_bids_status(client, make_user, db_session, category_id):
    listing_id, _, _ = _create_active_listing(client, make_user, category_id, email_suffix="1")
    _force_past_end_time(db_session, listing_id)

    result = close_expired_auction(db_session, listing_id)
    db_session.commit()

    assert result.result_status == "No Bids"
    assert result.winner_id is None


def test_reserve_not_met_results_in_unsold(client, make_user, db_session, category_id):
    listing_id, _, _ = _create_active_listing(client, make_user, category_id, reserve="500.00", email_suffix="2")
    bidder_headers, _ = make_user(["BIDDER"], email="closebidder2@example.com")
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    _force_past_end_time(db_session, listing_id)

    result = close_expired_auction(db_session, listing_id)
    db_session.commit()

    assert result.result_status == "Reserve Not Met"
    assert result.winner_id is None


def test_reserve_met_results_in_sold(client, make_user, db_session, category_id):
    listing_id, _, _ = _create_active_listing(client, make_user, category_id, reserve="100.00", email_suffix="3")
    bidder_headers, bidder_id = make_user(["BIDDER"], email="closebidder3@example.com")
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    _force_past_end_time(db_session, listing_id)

    result = close_expired_auction(db_session, listing_id)
    db_session.commit()

    assert result.result_status == "Sold"
    assert result.winner_id == bidder_id
    assert str(result.final_price) == "100.00"


def test_closing_twice_is_idempotent(client, make_user, db_session, category_id):
    listing_id, _, _ = _create_active_listing(client, make_user, category_id, email_suffix="4")
    _force_past_end_time(db_session, listing_id)

    first = close_expired_auction(db_session, listing_id)
    db_session.commit()
    assert first is not None

    second = close_expired_auction(db_session, listing_id)
    db_session.commit()
    assert second is None  # already Closed — no-op, no duplicate AuctionResult

    from app.models.auction_result import AuctionResult

    count = db_session.query(AuctionResult).filter_by(listing_id=listing_id).count()
    assert count == 1


def test_anti_sniping_extension_prevents_premature_close(client, make_user, db_session, category_id):
    """A listing whose end_time has been pushed forward (e.g. by a last-second bid that
    committed after the scheduler queued this job) must NOT be closed yet."""
    listing_id, _, _ = _create_active_listing(client, make_user, category_id, email_suffix="5")
    db_session.query(Listing).filter_by(listing_id=listing_id).update(
        {"end_time": datetime.now(timezone.utc) + timedelta(minutes=10)}
    )
    db_session.commit()

    result = close_expired_auction(db_session, listing_id)
    assert result is None
    listing = db_session.get(Listing, listing_id)
    assert listing.status == "Active"
