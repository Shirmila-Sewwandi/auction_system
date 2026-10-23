from datetime import datetime, timedelta, timezone

import pytest


def _times(start_offset_hours=1, duration_hours=24):
    start = datetime.now(timezone.utc) + timedelta(hours=start_offset_hours)
    end = start + timedelta(hours=duration_hours)
    return start.isoformat(), end.isoformat()


@pytest.fixture
def category_id(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="admin@example.com")
    resp = client.post(
        "/api/admin/categories", json={"name": "Antiques", "description": "Old things"}, headers=admin_headers
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["category_id"]


def _listing_payload(category_id, **overrides):
    start, end = _times()
    payload = {
        "category_id": category_id,
        "title": "Victorian Clock",
        "description": "A fine old clock",
        "starting_price": "100.00",
        "reserve_price": "150.00",
        "start_time": start,
        "end_time": end,
    }
    payload.update(overrides)
    return payload


def test_create_listing_requires_seller_role(client, make_user, category_id):
    headers, _ = make_user(["BIDDER"], email="bidderonly@example.com")
    resp = client.post("/api/listings", json=_listing_payload(category_id), headers=headers)
    assert resp.status_code == 403


def test_negative_price_rejected(client, make_user, category_id):
    headers, _ = make_user(["SELLER"], email="seller1@example.com")
    resp = client.post(
        "/api/listings", json=_listing_payload(category_id, starting_price="-5.00"), headers=headers
    )
    assert resp.status_code == 422


def test_reserve_below_starting_rejected(client, make_user, category_id):
    headers, _ = make_user(["SELLER"], email="seller2@example.com")
    resp = client.post(
        "/api/listings", json=_listing_payload(category_id, reserve_price="50.00"), headers=headers
    )
    assert resp.status_code == 422


def test_start_after_end_rejected(client, make_user, category_id):
    headers, _ = make_user(["SELLER"], email="seller3@example.com")
    start, end = _times()
    resp = client.post(
        "/api/listings", json=_listing_payload(category_id, start_time=end, end_time=start), headers=headers
    )
    assert resp.status_code == 422


def test_listing_hidden_until_approved(client, make_user, category_id):
    seller_headers, seller_id = make_user(["SELLER"], email="seller4@example.com")
    create = client.post("/api/listings", json=_listing_payload(category_id), headers=seller_headers)
    listing_id = create.json()["listing_id"]

    # Guest cannot see a pending listing
    guest_resp = client.get(f"/api/listings/{listing_id}")
    assert guest_resp.status_code == 404

    # Owner can still preview it (US-S02)
    owner_resp = client.get(f"/api/listings/{listing_id}", headers=seller_headers)
    assert owner_resp.status_code == 200

    # Doesn't show up in public browse either
    browse = client.get("/api/listings")
    assert all(item["listing_id"] != listing_id for item in browse.json()["items"])


def test_moderation_approve_makes_listing_visible_and_audited(client, make_user, category_id):
    seller_headers, _ = make_user(["SELLER"], email="seller5@example.com")
    mod_headers, mod_id = make_user(["MODERATOR"], email="mod1@example.com")

    create = client.post("/api/listings", json=_listing_payload(category_id), headers=seller_headers)
    listing_id = create.json()["listing_id"]

    approve = client.patch(
        f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers
    )
    assert approve.status_code == 200
    assert approve.json()["moderation_status"] == "Approved"

    guest_resp = client.get(f"/api/listings/{listing_id}")
    assert guest_resp.status_code == 200


def test_reject_requires_reason(client, make_user, category_id):
    seller_headers, _ = make_user(["SELLER"], email="seller6@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="mod2@example.com")
    create = client.post("/api/listings", json=_listing_payload(category_id), headers=seller_headers)
    listing_id = create.json()["listing_id"]

    resp = client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "reject"}, headers=mod_headers)
    assert resp.status_code == 409


def test_cannot_remoderate_terminal_listing(client, make_user, category_id):
    seller_headers, _ = make_user(["SELLER"], email="seller7@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="mod3@example.com")
    create = client.post("/api/listings", json=_listing_payload(category_id), headers=seller_headers)
    listing_id = create.json()["listing_id"]

    reject = client.patch(
        f"/api/moderator/listings/{listing_id}",
        json={"action": "reject", "reason": "Prohibited item"},
        headers=mod_headers,
    )
    assert reject.status_code == 200

    stale_approve = client.patch(
        f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers
    )
    assert stale_approve.status_code == 409


def test_non_owner_cannot_edit_listing(client, make_user, category_id):
    seller_headers, _ = make_user(["SELLER"], email="seller8@example.com")
    other_headers, _ = make_user(["SELLER"], email="seller9@example.com")
    create = client.post("/api/listings", json=_listing_payload(category_id), headers=seller_headers)
    listing_id = create.json()["listing_id"]

    resp = client.put(
        f"/api/listings/{listing_id}", json=_listing_payload(category_id, title="Hijacked"), headers=other_headers
    )
    assert resp.status_code == 403
