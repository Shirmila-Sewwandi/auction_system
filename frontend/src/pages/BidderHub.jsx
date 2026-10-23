import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import { ErrorBanner, SuccessBanner } from "../components/Banner";
import Tabs from "../components/Tabs";

function DashboardTab() {
  const [stats, setStats] = useState(null);
  useEffect(() => {
    api.get("/api/bidder/dashboard").then(setStats).catch(() => {});
  }, []);
  if (!stats) return <p>Loading…</p>;
  return (
    <div className="listing-grid">
      <article><h4>{stats.active_bids}</h4><p>Active bids</p></article>
      <article><h4>{stats.auctions_won}</h4><p>Auctions won</p></article>
      <article><h4>{stats.pending_payments}</h4><p>Pending payments</p></article>
    </div>
  );
}

function MyBidsTab() {
  const [bids, setBids] = useState([]);
  useEffect(() => {
    api.get("/api/bids/me").then((d) => setBids(d.bids)).catch(() => {});
  }, []);
  if (bids.length === 0) return <p>You haven't placed any bids yet.</p>;
  return (
    <table className="data-table">
      <thead><tr><th>Listing</th><th>Amount</th><th>Status</th><th>Placed</th></tr></thead>
      <tbody>
        {bids.map((b) => (
          <tr key={b.bid_id}>
            <td><Link to={`/listings/${b.listing_id}`}>{b.title}</Link></td>
            <td>${b.amount}</td>
            <td>{b.status}</td>
            <td>{new Date(b.placed_at).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function WinsTab({ onPaid }) {
  const [wins, setWins] = useState([]);
  const [resultsByListing, setResultsByListing] = useState({});
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function load() {
    const d = await api.get("/api/bidder/wins");
    setWins(d.wins);
    const results = {};
    await Promise.all(
      d.wins.map(async (w) => {
        try {
          results[w.listing_id] = await api.get(`/api/listings/${w.listing_id}/result`);
        } catch {
          /* ignore */
        }
      })
    );
    setResultsByListing(results);
  }

  useEffect(() => {
    load().catch((err) => setError(err.message));
  }, []);

  async function pay(listingId) {
    setError("");
    const result = resultsByListing[listingId];
    if (!result) return;
    try {
      await api.post("/api/payments", { auction_result_id: result.result_id, payment_method: "simulated" });
      setSuccess("Payment made — funds are held in escrow until you confirm receipt.");
      await load();
      onPaid?.();
    } catch (err) {
      setError(err.message);
    }
  }

  if (wins.length === 0) return <p>You haven't won any auctions yet.</p>;
  return (
    <div>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <table className="data-table">
        <thead><tr><th>Listing</th><th>Final price</th><th>Payment</th><th></th></tr></thead>
        <tbody>
          {wins.map((w) => (
            <tr key={w.listing_id}>
              <td>{w.title}</td>
              <td>${w.final_price}</td>
              <td>{w.payment_status}</td>
              <td>
                {w.payment_status === "Pending" && (
                  <button onClick={() => pay(w.listing_id)}>Pay now</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function PaymentsTab() {
  const [payments, setPayments] = useState([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function load() {
    const d = await api.get("/api/payments/me");
    setPayments(d.payments);
  }

  useEffect(() => {
    load().catch((err) => setError(err.message));
  }, []);

  async function confirmReceipt(paymentId, received) {
    setError("");
    try {
      const resp = await api.post(`/api/payments/${paymentId}/confirm-receipt`, { received });
      setSuccess(resp.message);
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  if (payments.length === 0) return <p>No payments yet.</p>;
  return (
    <div>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <table className="data-table">
        <thead><tr><th>Listing</th><th>Amount</th><th>Payment status</th><th>Escrow</th><th></th></tr></thead>
        <tbody>
          {payments.map((p) => (
            <tr key={p.payment_id}>
              <td>{p.listing}</td>
              <td>${p.amount}</td>
              <td>{p.payment_status}</td>
              <td>{p.escrow_status}</td>
              <td>
                {p.escrow_status === "Held" && (
                  <>
                    <button onClick={() => confirmReceipt(p.payment_id, true)}>Confirm receipt</button>{" "}
                    <button className="secondary" onClick={() => confirmReceipt(p.payment_id, false)}>Not received</button>
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function DisputesTab() {
  const [disputes, setDisputes] = useState([]);
  const [form, setForm] = useState({ auction_result_id: "", dispute_type: "item_not_as_described", reason: "", description: "" });
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function load() {
    const d = await api.get("/api/disputes/me");
    setDisputes(d.disputes);
  }

  useEffect(() => {
    load().catch(() => {});
  }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    try {
      await api.post("/api/disputes", { ...form, auction_result_id: Number(form.auction_result_id) });
      setSuccess("Dispute filed.");
      setForm({ ...form, auction_result_id: "", reason: "", description: "" });
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div>
      <h4>Raise a dispute</h4>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <form onSubmit={handleSubmit}>
        <label>
          Auction result ID
          <input required type="number" value={form.auction_result_id} onChange={(e) => setForm({ ...form, auction_result_id: e.target.value })} />
        </label>
        <label>
          Type
          <select value={form.dispute_type} onChange={(e) => setForm({ ...form, dispute_type: e.target.value })}>
            <option value="item_not_as_described">Item not as described</option>
            <option value="item_not_received">Item not received</option>
            <option value="payment_issue">Payment issue</option>
            <option value="other">Other</option>
          </select>
        </label>
        <label>
          Reason
          <input required value={form.reason} onChange={(e) => setForm({ ...form, reason: e.target.value })} />
        </label>
        <label>
          Description
          <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
        </label>
        <button type="submit">File dispute</button>
      </form>

      <h4>My disputes</h4>
      {disputes.length === 0 ? (
        <p>No disputes filed.</p>
      ) : (
        <table className="data-table">
          <thead><tr><th>ID</th><th>Type</th><th>Status</th><th>Filed</th></tr></thead>
          <tbody>
            {disputes.map((d) => (
              <tr key={d.dispute_id}>
                <td>{d.dispute_id}</td>
                <td>{d.dispute_type}</td>
                <td>{d.status}</td>
                <td>{new Date(d.created_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

export default function BidderHub() {
  return (
    <div>
      <h2>My Bidding</h2>
      <Tabs
        tabs={[
          { label: "Dashboard", content: <DashboardTab /> },
          { label: "My Bids", content: <MyBidsTab /> },
          { label: "My Wins", content: <WinsTab /> },
          { label: "Payments", content: <PaymentsTab /> },
          { label: "Disputes", content: <DisputesTab /> },
        ]}
      />
    </div>
  );
}
