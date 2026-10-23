import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, wsUrl } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { ErrorBanner, SuccessBanner } from "../components/Banner";

export default function ListingDetail() {
  const { listingId } = useParams();
  const { user, hasRole } = useAuth();

  const [listing, setListing] = useState(null);
  const [bids, setBids] = useState([]);
  const [amount, setAmount] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const wsRef = useRef(null);

  const loadListing = useCallback(() => {
    api.get(`/api/listings/${listingId}`).then(setListing).catch((err) => setError(err.message));
    api.get(`/api/listings/${listingId}/bids`).then((data) => setBids(data.bids)).catch(() => {});
  }, [listingId]);

  useEffect(() => {
    loadListing();
  }, [loadListing]);

  useEffect(() => {
    const ws = new WebSocket(wsUrl(`/api/ws/listings/${listingId}`));
    wsRef.current = ws;
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setListing((prev) =>
        prev ? { ...prev, current_price: data.current_price, end_time: data.end_time ?? prev.end_time } : prev
      );
      if (data.event === "bid_placed") {
        api.get(`/api/listings/${listingId}/bids`).then((d) => setBids(d.bids)).catch(() => {});
      }
    };
    return () => ws.close();
  }, [listingId]);

  async function placeBid(e) {
    e.preventDefault();
    setError("");
    setSuccess("");
    try {
      const resp = await api.post(`/api/listings/${listingId}/bids`, { amount });
      setSuccess(`Bid of $${resp.amount} accepted!`);
      setAmount("");
      loadListing();
    } catch (err) {
      setError(err.message);
    }
  }

  if (!listing) {
    return error ? <ErrorBanner message={error} /> : <p>Loading…</p>;
  }

  const isOwner = user && user.user_id === listing.seller_id;
  const canBid = hasRole("BIDDER") && !isOwner && listing.status === "Active";

  return (
    <div>
      <h2>{listing.title}</h2>
      <p className="badge muted">{listing.status}</p>
      {listing.moderation_status !== "Approved" && (
        <p className="badge">Moderation: {listing.moderation_status}</p>
      )}
      <p>{listing.description}</p>
      {listing.condition && <p><strong>Condition:</strong> {listing.condition}</p>}
      {listing.provenance && <p><strong>Provenance:</strong> {listing.provenance}</p>}

      {listing.images?.length > 0 && (
        <div className="listing-grid">
          {listing.images.map((img) => (
            <img
              key={img.image_id}
              src={`${import.meta.env.VITE_API_URL}/${img.image_path}`}
              alt={listing.title}
              style={{ width: "100%", borderRadius: "var(--pico-border-radius)" }}
            />
          ))}
        </div>
      )}

      <article>
        <p>Current price: <strong>${listing.current_price}</strong></p>
        <p>Closing time: <strong>{new Date(listing.end_time).toLocaleString()}</strong></p>

        <ErrorBanner message={error} />
        <SuccessBanner message={success} />

        {canBid && (
          <form onSubmit={placeBid}>
            <label>
              Your bid (min next bid is at least the current price plus the increment)
              <input
                type="number"
                step="0.01"
                required
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
              />
            </label>
            <button type="submit">Place bid</button>
          </form>
        )}
        {!user && <p><Link to="/login">Log in</Link> to place a bid.</p>}
        {isOwner && <p>You are the seller of this listing.</p>}
      </article>

      <h3>Bid history</h3>
      {bids.length === 0 ? (
        <p>No bids yet.</p>
      ) : (
        <table className="data-table">
          <thead>
            <tr><th>Amount</th><th>Placed at</th></tr>
          </thead>
          <tbody>
            {bids.map((b) => (
              <tr key={b.bid_id}>
                <td>${b.amount}</td>
                <td>{new Date(b.placed_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
