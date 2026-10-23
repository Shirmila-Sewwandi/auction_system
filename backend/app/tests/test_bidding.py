import threading
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest

from app.core.exceptions import BidTooLowError
from app.models.audit_log import AuditLog
from app.models.bid import Bid
from app.models.category import Category
from app.models.listing import Listing
from app.models.notification import Notification
from app.models.user import User
from app.services.bidding import place_bid
from app.tests.conftest import TestSessionLocal, engine


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="bidadmin@example.com")
    resp = client.post("/api/admin/categories", json={"name": "Collectibles"}, headers=admin_headers)
    return resp.json()["category_id"]


@pytest.fixture
def active_listing(client, make_user, category_id):
    """Seller + listing, pre-approved and already Active (start_time in the past)."""
    # Also BIDDER so the self-bid rule itself is what's under test, not role-gating.
    seller_headers, seller_id = make_user(["SELLER", "BIDDER"], email="bidseller@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="bidmod@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Antique Vase",
            "description": "Ming-style vase",
            "starting_price": "100.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    return listing_id, seller_headers, seller_id


def test_below_minimum_bid_rejected(client, make_user, active_listing):
    listing_id, _, _ = active_listing
    bidder_headers, _ = make_user(["BIDDER"], email="bidder1@example.com")
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "50.00"}, headers=bidder_headers)
    assert resp.status_code == 400


def test_seller_cannot_bid_own_listing(client, active_listing):
    listing_id, seller_headers, _ = active_listing
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "150.00"}, headers=seller_headers)
    assert resp.status_code == 400


def test_valid_bid_accepted_and_updates_price(client, make_user, active_listing):
    listing_id, _, _ = active_listing
    bidder_headers, _ = make_user(["BIDDER"], email="bidder2@example.com")
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    assert resp.status_code == 200
    assert resp.json()["current_price"] == "100.00" or float(resp.json()["current_price"]) == 100.00


def test_bid_on_closed_auction_rejected(client, make_user, db_session, active_listing):
    listing_id, _, _ = active_listing
    db_session.query(Listing).filter_by(listing_id=listing_id).update({"status": "Closed"})
    db_session.commit()
    bidder_headers, _ = make_user(["BIDDER"], email="bidder3@example.com")
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "150.00"}, headers=bidder_headers)
    assert resp.status_code == 400


def test_duplicate_retried_bid_does_not_double_insert(client, make_user, db_session, active_listing):
    listing_id, _, _ = active_listing
    bidder_headers, _ = make_user(["BIDDER"], email="bidder4@example.com")
    first = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    second = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=bidder_headers)
    assert first.status_code == 200 and second.status_code == 200
    assert first.json()["bid_id"] == second.json()["bid_id"]
    count = db_session.query(Bid).filter_by(listing_id=listing_id).count()
    assert count == 1


def test_concurrent_bids_resolve_deterministically():
    """N threads submit the SAME amount simultaneously against the same listing, each on its
    own real DB connection (bypassing the single-transaction test fixture on purpose — this is
    the one test that needs real concurrent connections to prove the row lock works).
    Exactly one must win; the rest must see BidTooLowError once the price has moved."""
    setup_db = TestSessionLocal(bind=engine.connect())
    category = Category(name=f"ConcurrencyTest-{threading.get_ident()}")
    setup_db.add(category)
    setup_db.flush()

    seller = User(first_name="S", last_name="S", email="concseller@example.com", password_hash="x")
    setup_db.add(seller)
    setup_db.flush()

    now = datetime.now(timezone.utc)
    listing = Listing(
        seller_id=seller.user_id,
        category_id=category.category_id,
        title="Concurrency Item",
        description="x",
        starting_price=Decimal("100.00"),
        current_price=Decimal("100.00"),
        min_bid_increment=Decimal("5.00"),
        anti_sniping_window_minutes=5,
        anti_sniping_extension_minutes=10,
        start_time=now - timedelta(minutes=1),
        end_time=now + timedelta(hours=1),
        original_end_time=now + timedelta(hours=1),
        status="Active",
        moderation_status="Approved",
    )
    setup_db.add(listing)
    setup_db.flush()

    bidders = []
    for i in range(5):
        u = User(first_name="B", last_name=str(i), email=f"concbidder{i}@example.com", password_hash="x")
        setup_db.add(u)
        bidders.append(u)
    setup_db.flush()
    bidder_ids = [b.user_id for b in bidders]
    listing_id = listing.listing_id
    setup_db.commit()

    results = {"accepted": 0, "rejected": 0}
    lock = threading.Lock()

    def worker(bidder_id):
        session = TestSessionLocal(bind=engine.connect())
        try:
            user = session.get(User, bidder_id)
            place_bid(session, listing_id=listing_id, bidder=user, amount=Decimal("105.00"))
            session.commit()
            with lock:
                results["accepted"] += 1
        except BidTooLowError:
            session.rollback()
            with lock:
                results["rejected"] += 1
        finally:
            session.close()

    threads = [threading.Thread(target=worker, args=(bid,)) for bid in bidder_ids]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    try:
        assert results["accepted"] == 1
        assert results["rejected"] == len(bidder_ids) - 1
        final_listing = setup_db.get(Listing, listing_id)
        setup_db.refresh(final_listing)
        assert final_listing.current_price == Decimal("105.00")
        assert setup_db.query(Bid).filter_by(listing_id=listing_id).count() == 1
    finally:
        all_user_ids = bidder_ids + [seller.user_id]
        setup_db.query(Notification).filter(Notification.user_id.in_(all_user_ids)).delete(
            synchronize_session=False
        )
        setup_db.query(AuditLog).filter(AuditLog.user_id.in_(all_user_ids)).delete(synchronize_session=False)
        setup_db.query(Bid).filter_by(listing_id=listing_id).delete()
        setup_db.query(Listing).filter_by(listing_id=listing_id).delete()
        for bid_id in bidder_ids:
            setup_db.query(User).filter_by(user_id=bid_id).delete()
        setup_db.query(User).filter_by(user_id=seller.user_id).delete()
        setup_db.query(Category).filter_by(category_id=category.category_id).delete()
        setup_db.commit()
        setup_db.close()


@pytest.mark.parametrize("amount", ["99999999999999999999", "250.12345"])
def test_malformed_bid_amount_rejected_with_422(client, make_user, active_listing, amount):
    listing_id, *_ = active_listing
    bidder, _ = make_user(["BIDDER"])
    resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": amount}, headers=bidder)
    assert resp.status_code == 422
