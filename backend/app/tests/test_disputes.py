from datetime import datetime, timedelta, timezone

import pytest

from app.models.listing import Listing
from app.services.closing import close_expired_auction


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="dispadmin@example.com")
    return client.post("/api/admin/categories", json={"name": "Disputes"}, headers=admin_headers).json()[
        "category_id"
    ]


@pytest.fixture
def paid_result(client, make_user, db_session, category_id):
    seller_headers, seller_id = make_user(["SELLER"], email="dispseller@example.com")
    mod_headers, mod_id = make_user(["MODERATOR"], email="dispmod@example.com")
    winner_headers, winner_id = make_user(["BIDDER"], email="dispwinner@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=2)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category_id,
            "title": "Dispute Item",
            "description": "x",
            "starting_price": "100.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)
    client.post(f"/api/listings/{listing_id}/bids", json={"amount": "100.00"}, headers=winner_headers)

    db_session.query(Listing).filter_by(listing_id=listing_id).update(
        {"end_time": datetime.now(timezone.utc) - timedelta(seconds=1)}
    )
    db_session.commit()
    result = close_expired_auction(db_session, listing_id)
    db_session.commit()

    pay = client.post(
        "/api/payments", json={"auction_result_id": result.result_id}, headers=winner_headers
    )
    return {
        "auction_result_id": result.result_id,
        "payment_id": pay.json()["payment_id"],
        "winner_headers": winner_headers,
        "seller_headers": seller_headers,
        "mod_headers": mod_headers,
    }


def test_non_party_cannot_raise_dispute(client, make_user, paid_result):
    stranger_headers, _ = make_user(["BIDDER"], email="dispstranger@example.com")
    resp = client.post(
        "/api/disputes",
        json={"auction_result_id": paid_result["auction_result_id"], "dispute_type": "fraud", "reason": "x"},
        headers=stranger_headers,
    )
    assert resp.status_code == 403


def test_resolve_with_refund_updates_escrow(client, paid_result):
    dispute = client.post(
        "/api/disputes",
        json={
            "auction_result_id": paid_result["auction_result_id"],
            "dispute_type": "item_not_as_described",
            "reason": "Not as described",
        },
        headers=paid_result["winner_headers"],
    )
    dispute_id = dispute.json()["dispute_id"]

    resolve = client.patch(
        f"/api/moderator/disputes/{dispute_id}",
        json={"status": "Resolved", "resolution": "Refunded buyer", "refund_funds": True},
        headers=paid_result["mod_headers"],
    )
    assert resolve.status_code == 200
    assert resolve.json()["status"] == "Resolved"

    payment = client.get(f"/api/payments/{paid_result['payment_id']}", headers=paid_result["winner_headers"]).json()
    assert payment["escrow_status"] == "Refunded"


def test_cannot_resolve_twice(client, paid_result):
    dispute = client.post(
        "/api/disputes",
        json={
            "auction_result_id": paid_result["auction_result_id"],
            "dispute_type": "item_not_as_described",
            "reason": "Not as described",
        },
        headers=paid_result["winner_headers"],
    )
    dispute_id = dispute.json()["dispute_id"]

    first = client.patch(
        f"/api/moderator/disputes/{dispute_id}",
        json={"status": "Resolved", "resolution": "Released to seller", "release_funds": True},
        headers=paid_result["mod_headers"],
    )
    assert first.status_code == 200

    second = client.patch(
        f"/api/moderator/disputes/{dispute_id}",
        json={"status": "Resolved", "resolution": "Try again"},
        headers=paid_result["mod_headers"],
    )
    assert second.status_code == 409


def test_cannot_amend_after_under_review(client, paid_result):
    dispute = client.post(
        "/api/disputes",
        json={
            "auction_result_id": paid_result["auction_result_id"],
            "dispute_type": "item_not_as_described",
            "reason": "Not as described",
        },
        headers=paid_result["winner_headers"],
    )
    dispute_id = dispute.json()["dispute_id"]

    client.patch(
        f"/api/moderator/disputes/{dispute_id}",
        json={"status": "Under Review", "resolution": "Investigating"},
        headers=paid_result["mod_headers"],
    )

    amend = client.patch(
        f"/api/disputes/{dispute_id}", json={"reason": "New reason"}, headers=paid_result["winner_headers"]
    )
    assert amend.status_code == 409
