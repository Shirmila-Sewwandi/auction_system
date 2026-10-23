import { useEffect, useState } from "react";
import { api } from "../api/client";
import { ErrorBanner, SuccessBanner } from "../components/Banner";
import Tabs from "../components/Tabs";

function ListingsTab() {
  const [listings, setListings] = useState([]);
  const [reasons, setReasons] = useState({});
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function load() {
    const d = await api.get("/api/moderator/listings");
    setListings(d.listings);
  }

  useEffect(() => {
    load().catch((err) => setError(err.message));
  }, []);

  async function act(listingId, action) {
    setError("");
    try {
      await api.patch(`/api/moderator/listings/${listingId}`, { action, reason: reasons[listingId] || null });
      setSuccess(`Listing ${action}d.`);
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  if (listings.length === 0) return <p>No listings awaiting review.</p>;
  return (
    <div>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <table className="data-table">
        <thead><tr><th>Title</th><th>Seller</th><th>Reason (for reject/suspend)</th><th></th></tr></thead>
        <tbody>
          {listings.map((l) => (
            <tr key={l.listing_id}>
              <td>{l.title}</td>
              <td>#{l.seller_id}</td>
              <td>
                <input
                  value={reasons[l.listing_id] || ""}
                  onChange={(e) => setReasons({ ...reasons, [l.listing_id]: e.target.value })}
                  placeholder="Required for reject/suspend"
                />
              </td>
              <td>
                <button onClick={() => act(l.listing_id, "approve")}>Approve</button>{" "}
                <button className="secondary" onClick={() => act(l.listing_id, "reject")}>Reject</button>{" "}
                <button className="contrast" onClick={() => act(l.listing_id, "suspend")}>Suspend</button>
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
  const [resolutions, setResolutions] = useState({});
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function load() {
    const d = await api.get("/api/moderator/disputes");
    setDisputes(d.disputes);
  }

  useEffect(() => {
    load().catch((err) => setError(err.message));
  }, []);

  function updateField(id, field, value) {
    setResolutions({ ...resolutions, [id]: { ...resolutions[id], [field]: value } });
  }

  async function resolve(disputeId, status) {
    setError("");
    const r = resolutions[disputeId] || {};
    try {
      await api.patch(`/api/moderator/disputes/${disputeId}`, {
        status,
        resolution: r.resolution || "No notes provided",
        release_funds: !!r.release_funds,
        refund_funds: !!r.refund_funds,
      });
      setSuccess(`Dispute ${status.toLowerCase()}.`);
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  if (disputes.length === 0) return <p>No disputes to review.</p>;
  return (
    <div>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      {disputes.map((d) => {
        const r = resolutions[d.dispute_id] || {};
        return (
          <article key={d.dispute_id}>
            <p><strong>Dispute #{d.dispute_id}</strong> — raised by #{d.raised_by} — status: {d.status}</p>
            <label>
              Resolution notes
              <input value={r.resolution || ""} onChange={(e) => updateField(d.dispute_id, "resolution", e.target.value)} />
            </label>
            <div className="grid">
              <label>
                <input
                  type="checkbox"
                  checked={!!r.release_funds}
                  onChange={(e) => updateField(d.dispute_id, "release_funds", e.target.checked)}
                />
                Release funds to seller
              </label>
              <label>
                <input
                  type="checkbox"
                  checked={!!r.refund_funds}
                  onChange={(e) => updateField(d.dispute_id, "refund_funds", e.target.checked)}
                />
                Refund buyer
              </label>
            </div>
            <button className="secondary" onClick={() => resolve(d.dispute_id, "Under Review")}>Mark under review</button>{" "}
            <button onClick={() => resolve(d.dispute_id, "Resolved")}>Resolve</button>
          </article>
        );
      })}
    </div>
  );
}

export default function ModeratorHub() {
  return (
    <div>
      <h2>Moderation</h2>
      <Tabs
        tabs={[
          { label: "Listings", content: <ListingsTab /> },
          { label: "Disputes", content: <DisputesTab /> },
        ]}
      />
    </div>
  );
}
