from datetime import datetime, timedelta, timezone


def test_bid_broadcasts_to_websocket_subscriber(client, make_user):
    admin_headers, _ = make_user(["ADMIN"], email="wsadmin@example.com")
    category = client.post("/api/admin/categories", json={"name": "WS Test"}, headers=admin_headers).json()

    seller_headers, _ = make_user(["SELLER"], email="wsseller@example.com")
    mod_headers, _ = make_user(["MODERATOR"], email="wsmod@example.com")
    bidder_headers, _ = make_user(["BIDDER"], email="wsbidder@example.com")

    start = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    end = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    create = client.post(
        "/api/listings",
        json={
            "category_id": category["category_id"],
            "title": "WS Item",
            "description": "x",
            "starting_price": "10.00",
            "start_time": start,
            "end_time": end,
        },
        headers=seller_headers,
    )
    listing_id = create.json()["listing_id"]
    client.patch(f"/api/moderator/listings/{listing_id}", json={"action": "approve"}, headers=mod_headers)

    with client:
        with client.websocket_connect(f"/api/ws/listings/{listing_id}") as ws:
            resp = client.post(f"/api/listings/{listing_id}/bids", json={"amount": "10.00"}, headers=bidder_headers)
            assert resp.status_code == 200
            message = ws.receive_json()
            assert message["event"] == "bid_placed"
            assert message["listing_id"] == listing_id
