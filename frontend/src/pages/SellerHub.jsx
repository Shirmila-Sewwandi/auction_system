import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import { ErrorBanner, SuccessBanner } from "../components/Banner";
import Tabs from "../components/Tabs";

function DashboardTab() {
  const [stats, setStats] = useState(null);
  useEffect(() => {
    api.get("/api/seller/dashboard").then(setStats).catch(() => {});
  }, []);
  if (!stats) return <p>Loading…</p>;
  return (
    <div className="listing-grid">
      <article><h4>{stats.active_listings}</h4><p>Active listings</p></article>
      <article><h4>{stats.completed_sales}</h4><p>Completed sales</p></article>
      <article><h4>{stats.pending_payments}</h4><p>Pending payments</p></article>
    </div>
  );
}

function MyListingsTab() {
  const [listings, setListings] = useState([]);
  useEffect(() => {
    api.get("/api/seller/listings").then((d) => setListings(d.listings)).catch(() => {});
  }, []);
  if (listings.length === 0) return <p>You haven't listed anything yet.</p>;
  return (
    <table className="data-table">
      <thead><tr><th>Title</th><th>Price</th><th>Status</th><th>Ends</th></tr></thead>
      <tbody>
        {listings.map((l) => (
          <tr key={l.listing_id}>
            <td><Link to={`/listings/${l.listing_id}`}>{l.title}</Link></td>
            <td>${l.current_price}</td>
            <td>{l.status}</td>
            <td>{new Date(l.end_time).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function SalesTab() {
  const [sales, setSales] = useState([]);
  useEffect(() => {
    api.get("/api/seller/sales").then((d) => setSales(d.sales)).catch(() => {});
  }, []);
  if (sales.length === 0) return <p>No completed sales yet.</p>;
  return (
    <table className="data-table">
      <thead><tr><th>Title</th><th>Final price</th><th>Payment status</th></tr></thead>
      <tbody>
        {sales.map((s) => (
          <tr key={s.listing_id}>
            <td>{s.title}</td>
            <td>${s.final_price}</td>
            <td>{s.payment_status}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function CreateListingTab() {
  const [categories, setCategories] = useState([]);
  const [form, setForm] = useState({
    category_id: "",
    title: "",
    description: "",
    condition: "",
    provenance: "",
    starting_price: "",
    reserve_price: "",
    start_time: "",
    end_time: "",
  });
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [createdListingId, setCreatedListingId] = useState(null);

  useEffect(() => {
    api.get("/api/categories").then(setCategories).catch(() => {});
  }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    setSuccess("");
    try {
      const payload = {
        ...form,
        category_id: Number(form.category_id),
        reserve_price: form.reserve_price || null,
        start_time: new Date(form.start_time).toISOString(),
        end_time: new Date(form.end_time).toISOString(),
      };
      const resp = await api.post("/api/listings", payload);
      setSuccess(`Listing #${resp.listing_id} submitted for moderator approval. Add photos below, then you're done.`);
      setCreatedListingId(resp.listing_id);
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleImageUpload(e) {
    const file = e.target.files[0];
    if (!file || !createdListingId) return;
    const formData = new FormData();
    formData.append("image", file);
    try {
      await api.upload(`/api/listings/${createdListingId}/images`, formData);
      setSuccess("Image uploaded.");
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <label>
        Category
        <select required value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })}>
          <option value="" disabled>Select a category…</option>
          {categories.map((c) => (
            <option key={c.category_id} value={c.category_id}>{c.name}</option>
          ))}
        </select>
      </label>
      <label>
        Title
        <input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
      </label>
      <label>
        Description
        <textarea required value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
      </label>
      <div className="grid">
        <label>
          Condition
          <input value={form.condition} onChange={(e) => setForm({ ...form, condition: e.target.value })} />
        </label>
        <label>
          Provenance
          <input value={form.provenance} onChange={(e) => setForm({ ...form, provenance: e.target.value })} />
        </label>
      </div>
      <div className="grid">
        <label>
          Starting price
          <input type="number" step="0.01" required value={form.starting_price} onChange={(e) => setForm({ ...form, starting_price: e.target.value })} />
        </label>
        <label>
          Reserve price (optional)
          <input type="number" step="0.01" value={form.reserve_price} onChange={(e) => setForm({ ...form, reserve_price: e.target.value })} />
        </label>
      </div>
      <div className="grid">
        <label>
          Start time
          <input type="datetime-local" required value={form.start_time} onChange={(e) => setForm({ ...form, start_time: e.target.value })} />
        </label>
        <label>
          End time
          <input type="datetime-local" required value={form.end_time} onChange={(e) => setForm({ ...form, end_time: e.target.value })} />
        </label>
      </div>
      <button type="submit">Submit listing</button>

      {createdListingId && (
        <label>
          Add a photo to listing #{createdListingId}
          <input type="file" accept="image/*" onChange={handleImageUpload} />
        </label>
      )}
    </form>
  );
}

export default function SellerHub() {
  return (
    <div>
      <h2>Seller Hub</h2>
      <Tabs
        tabs={[
          { label: "Dashboard", content: <DashboardTab /> },
          { label: "My Listings", content: <MyListingsTab /> },
          { label: "Create Listing", content: <CreateListingTab /> },
          { label: "Sales", content: <SalesTab /> },
        ]}
      />
    </div>
  );
}
