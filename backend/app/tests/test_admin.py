def test_non_admin_blocked_from_every_admin_route(client, make_user):
    headers, _ = make_user(["BIDDER"], email="notadmin@example.com")
    for method, path in [
        ("get", "/api/admin/users"),
        ("get", "/api/admin/config"),
        ("get", "/api/admin/listings"),
        ("get", "/api/admin/bids"),
        ("get", "/api/admin/auction-results"),
        ("get", "/api/admin/payments"),
        ("get", "/api/admin/disputes"),
        ("get", "/api/admin/audit-logs"),
        ("get", "/api/admin/dashboard"),
    ]:
        resp = getattr(client, method)(path, headers=headers)
        assert resp.status_code == 403, f"{method} {path} should be blocked, got {resp.status_code}"


def test_negative_config_value_rejected(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="configadmin@example.com")
    resp = client.patch("/api/admin/config", json={"min_bid_increment": "-1.00"}, headers=admin_headers)
    assert resp.status_code == 422


def test_valid_config_update_persists(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="configadmin2@example.com")
    resp = client.patch("/api/admin/config", json={"anti_sniping_window_minutes": 7}, headers=admin_headers)
    assert resp.status_code == 200
    got = client.get("/api/admin/config", headers=admin_headers).json()
    assert got["anti_sniping_window_minutes"] == 7


def test_suspending_user_blocks_next_bid(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="suspendadmin@example.com")
    cat = client.post("/api/admin/categories", json={"name": "SuspendTest"}, headers=admin_headers).json()

    from datetime import datetime, timedelta, timezone

    seller_headers, _ = make_user(["SELLER"], email="suspendseller@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="suspendmod@example.com")
    bidder_headers, bidder_id = make_user(["BIDDER"], email="suspendbidder@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": cat["category_id"],
            "title": "Suspend Item",
            "description": "x",
            "starting_price": "10.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)

    suspend = client.patch(f"/api/admin/users/{bidder_id}", json={"status": "Suspended"}, headers=admin_headers)
    assert suspend.status_code == 200

    bid = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "10.00"}, headers=bidder_headers)
    assert bid.status_code == 403


def test_invalid_role_assignment_rejected(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="roleadmin@example.com")
    _, target_id = make_user(["BIDDER"], email="roletarget@example.com")
    resp = client.patch(
        f"/api/admin/users/{target_id}/roles", json={"roles": ["SUPERUSER"]}, headers=admin_headers
    )
    assert resp.status_code == 422
