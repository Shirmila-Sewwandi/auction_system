from datetime import datetime, timedelta, timezone

import pytest

from app.models.listing import Listing
from app.models.notification import Notification
from app.services.closing import close_expired_auction


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="notifyadmin@example.com")
    return client.post("/api/admin/categories", json={"name": "Notify"}, headers=admin_headers).json()[
        "category_id"
    ]


def test_outbid_sends_exactly_one_notification(client, make_user, category_id):
    seller_headers, _ = make_user(["SELLER"], email="notifyseller@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="notifymod@example.com")
    bidder1_headers, bidder1_id = make_user(["BIDDER"], email="notifybidder1@example.com")
    bidder2_headers, _ = make_user(["BIDDER"], email="notifybidder2@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Notify Item",
            "description": "x",
            "starting_price": "10.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)

    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "10.00"}, headers=bidder1_headers)
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "11.00"}, headers=bidder2_headers)

    resp = client.get("/api/notifications", headers=bidder1_headers)
    outbid_notifications = [n for n in resp.json()["notifications"] if n["type"] == "OUTBID"]
    assert len(outbid_notifications) == 1


def test_mark_read_and_read_all(client, make_user, category_id):
    seller_headers, _ = make_user(["SELLER"], email="notifyseller2@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="notifymod2@example.com")
    bidder_headers, _ = make_user(["BIDDER"], email="notifybidder3@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Notify Item 2",
            "description": "x",
            "starting_price": "10.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "10.00"}, headers=bidder_headers)

    notes = client.get("/api/notifications", headers=bidder_headers).json()["notifications"]
    assert len(notes) >= 1
    first_id = notes[0]["notification_id"]

    mark = client.patch(f"/api/notifications/{first_id}/read", headers=bidder_headers)
    assert mark.status_code == 200 and mark.json()["is_read"] is True

    mark_all = client.patch("/api/notifications/read-all", headers=bidder_headers)
    assert mark_all.status_code == 200
    notes_after = client.get("/api/notifications", headers=bidder_headers).json()["notifications"]
    assert all(n["is_read"] for n in notes_after)


def test_rerunning_closer_does_not_duplicate_winner_notification(client, make_user, db_session, category_id):
    seller_headers, _ = make_user(["SELLER"], email="notifyseller3@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="notifymod3@example.com")
    bidder_headers, bidder_id = make_user(["BIDDER"], email="notifybidder4@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=2)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Notify Item 3",
            "description": "x",
            "starting_price": "10.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "10.00"}, headers=bidder_headers)

    db_session.query(Listing).filter_by(listing_id=listing_id).update(
        {"end_time": datetime.now(timezone.utc) - timedelta(seconds=1)}
    )
    db_session.commit()

    first = close_expired_auction(db_session, listing_id)
    db_session.commit()
    assert first is not None

    second = close_expired_auction(db_session, listing_id)  # idempotent no-op — already Closed
    db_session.commit()
    assert second is None

    won_notifications = (
        db_session.query(Notification).filter_by(user_id=bidder_id, type="AUCTION_WON").all()
    )
    assert len(won_notifications) == 1
