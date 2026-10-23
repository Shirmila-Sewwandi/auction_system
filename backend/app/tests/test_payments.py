from datetime import datetime, timedelta, timezone

import pytest

from app.models.listing import Listing
from app.services.closing import close_expired_auction


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="payadmin@example.com")
    return client.post("/api/admin/categories", json={"name": "Payments"}, headers=admin_headers).json()[
        "category_id"
    ]


@pytest.fixture
def sold_result(client, make_user, db_session, category_id):
    """A closed, Sold auction result + the headers of winner, loser and seller."""
    seller_headers, _ = make_user(["SELLER"], email="payseller@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="paymod@example.com")
    winner_headers, winner_id = make_user(["BIDDER"], email="paywinner@example.com")
    loser_headers, loser_id = make_user(["BIDDER"], email="payloser@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=2)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Payment Item",
            "description": "x",
            "starting_price": "100.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=loser_headers)
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "150.00"}, headers=winner_headers)

    db_session.query(Listing).filter_by(listing_id=listing_id).update(
        {"end_time": datetime.now(timezone.utc) - timedelta(seconds=1)}
    )
    db_session.commit()
    result = close_expired_auction(db_session, listing_id)
    db_session.commit()

    return {
        "auction_result_id": result.result_id,
        "winner_headers": winner_headers,
        "loser_headers": loser_headers,
        "seller_headers": seller_headers,
    }


def test_only_winner_can_pay(client, sold_result):
    resp = client.post(
        "/api/payments",
        json={"auction_result_id": sold_result["auction_result_id"], "payment_method": "simulated"},
        headers=sold_result["loser_headers"],
    )
    assert resp.status_code == 403


def test_winner_can_pay_and_double_payment_rejected(client, sold_result):
    first = client.post(
        "/api/payments",
        json={"auction_result_id": sold_result["auction_result_id"]},
        headers=sold_result["winner_headers"],
    )
    assert first.status_code == 200
    assert first.json()["escrow_status"] == "Held"

    second = client.post(
        "/api/payments",
        json={"auction_result_id": sold_result["auction_result_id"]},
        headers=sold_result["winner_headers"],
    )
    assert second.status_code == 409


def test_confirm_receipt_releases_escrow_and_double_release_rejected(client, sold_result):
    pay = client.post(
        "/api/payments",
        json={"auction_result_id": sold_result["auction_result_id"]},
        headers=sold_result["winner_headers"],
    )
    payment_id = pay.json()["payment_id"]

    release = client.post(
        f"/api/payments/{payment_id}/confirm-receipt", json={"received": True}, headers=sold_result["winner_headers"]
    )
    assert release.status_code == 200
    assert release.json()["escrow_status"] == "Released"

    double_release = client.post(
        f"/api/payments/{payment_id}/confirm-receipt", json={"received": True}, headers=sold_result["winner_headers"]
    )
    assert double_release.status_code == 409


def test_release_blocked_while_dispute_open(client, sold_result):
    pay = client.post(
        "/api/payments",
        json={"auction_result_id": sold_result["auction_result_id"]},
        headers=sold_result["winner_headers"],
    )
    payment_id = pay.json()["payment_id"]

    dispute = client.post(
        "/api/disputes",
        json={
            "auction_result_id": sold_result["auction_result_id"],
            "dispute_type": "item_not_as_described",
            "reason": "Item was damaged",
        },
        headers=sold_result["winner_headers"],
    )
    assert dispute.status_code == 200

    release = client.post(
        f"/api/payments/{payment_id}/confirm-receipt", json={"received": True}, headers=sold_result["winner_headers"]
    )
    assert release.status_code == 409
