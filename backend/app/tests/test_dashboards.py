def test_seller_dashboard_empty_state(client, make_user):
    headers, _ = make_user(["SELLER"], email="emptyseller@example.com")
    resp = client.get("/api/seller/dashboard", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == {"active_listings": 0, "completed_sales": 0, "pending_payments": 0}


def test_bidder_dashboard_empty_state(client, make_user):
    headers, _ = make_user(["BIDDER"], email="emptybidder@example.com")
    resp = client.get("/api/bidder/dashboard", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == {"active_bids": 0, "auctions_won": 0, "pending_payments": 0}


def test_admin_dashboard_on_near_empty_db(client, make_user):
    headers, _ = make_user(["ADMIN"], email="emptyadmin@example.com")
    resp = client.get("/api/admin/dashboard", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert set(body) == {"total_users", "active_auctions", "total_bids", "completed_auctions", "open_disputes"}
    assert all(isinstance(v, int) for v in body.values())


def test_browse_with_no_matching_filters_returns_empty_list(client):
    resp = client.get("/api/listings", params={"search": "nonexistent-item-xyz"})
    assert resp.status_code == 200
    assert resp.json()["items"] == []
    assert resp.json()["total"] == 0


def test_bid_history_is_paginated(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="pageadmin@example.com")
    cat = client.post("/api/admin/categories", json={"name": "Pagination"}, headers=admin_headers).json()

    from datetime import datetime, timedelta, timezone

    seller_headers, _ = make_user(["SELLER"], email="pageseller@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="pagemod@example.com")
    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": cat["category_id"],
            "title": "Pagination Item",
            "description": "x",
            "starting_price": "10.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)

    resp = client.get(f"/api/listings/{listing_id}/bids")
    assert resp.status_code == 200
    assert "page" in resp.json() and "total" in resp.json()
