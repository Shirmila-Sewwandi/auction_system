import { useEffect, useState } from "react";
import { api } from "../api/client";
import { ErrorBanner, SuccessBanner } from "../components/Banner";
import Tabs from "../components/Tabs";

function DashboardTab() {
  const [stats, setStats] = useState(null);
  useEffect(() => {
    api.get("/api/admin/dashboard").then(setStats).catch(() => {});
  }, []);
  if (!stats) return <p>Loading…</p>;
  return (
    <div className="listing-grid">
      {Object.entries(stats).map(([key, value]) => (
        <article key={key}>
          <h4>{value}</h4>
          <p>{key.replace(/_/g, " ")}</p>
        </article>
      ))}
    </div>
  );
}

const ALL_ROLES = ["SELLER", "BIDDER", "MODERATOR", "ADMIN"];

function UsersTab() {
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function load() {
    const d = await api.get("/api/admin/users", { search });
    setUsers(d.users);
  }

  useEffect(() => {
    load().catch((err) => setError(err.message));
  }, [search]);

  async function setStatus(userId, status) {
    setError("");
    try {
      await api.patch(`/api/admin/users/${userId}`, { status });
      setSuccess(`User #${userId} set to ${status}.`);
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  async function toggleRole(userId, currentRoles, role) {
    const roles = currentRoles.includes(role) ? currentRoles.filter((r) => r !== role) : [...currentRoles, role];
    try {
      await api.patch(`/api/admin/users/${userId}/roles`, { roles });
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <input placeholder="Search by name or email…" value={search} onChange={(e) => setSearch(e.target.value)} />
      <table className="data-table">
        <thead><tr><th>Name</th><th>Email</th><th>Roles</th><th>Status</th><th></th></tr></thead>
        <tbody>
          {users.map((u) => (
            <tr key={u.user_id}>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td>
                {ALL_ROLES.map((role) => (
                  <label key={role} style={{ marginRight: 8 }}>
                    <input type="checkbox" checked={u.roles.includes(role)} onChange={() => toggleRole(u.user_id, u.roles, role)} />
                    {role}
                  </label>
                ))}
              </td>
              <td>{u.status}</td>
              <td>
                {u.status !== "Suspended" ? (
                  <button className="contrast" onClick={() => setStatus(u.user_id, "Suspended")}>Suspend</button>
                ) : (
                  <button onClick={() => setStatus(u.user_id, "Active")}>Reactivate</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function CategoriesTab() {
  const [categories, setCategories] = useState([]);
  const [name, setName] = useState("");
  const [error, setError] = useState("");

  async function load() {
    const d = await api.get("/api/admin/categories");
    setCategories(d);
  }

  useEffect(() => {
    load().catch((err) => setError(err.message));
  }, []);

  async function create(e) {
    e.preventDefault();
    setError("");
    try {
      await api.post("/api/admin/categories", { name });
      setName("");
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  async function toggleActive(category) {
    try {
      await api.patch(`/api/admin/categories/${category.category_id}`, { is_active: !category.is_active });
      await load();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div>
      <ErrorBanner message={error} />
      <form onSubmit={create} style={{ display: "flex", gap: "0.5rem" }}>
        <input placeholder="New category name" value={name} onChange={(e) => setName(e.target.value)} required />
        <button type="submit">Add</button>
      </form>
      <table className="data-table">
        <thead><tr><th>Name</th><th>Active</th><th></th></tr></thead>
        <tbody>
          {categories.map((c) => (
            <tr key={c.category_id}>
              <td>{c.name}</td>
              <td>{c.is_active ? "Yes" : "No"}</td>
              <td><button className="secondary" onClick={() => toggleActive(c)}>{c.is_active ? "Deactivate" : "Activate"}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ConfigTab() {
  const [config, setConfig] = useState(null);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    api.get("/api/admin/config").then(setConfig).catch((err) => setError(err.message));
  }, []);

  async function save(e) {
    e.preventDefault();
    setError("");
    try {
      await api.patch("/api/admin/config", {
        min_bid_increment: config.min_bid_increment,
        anti_sniping_window_minutes: Number(config.anti_sniping_window_minutes),
        anti_sniping_extension_minutes: Number(config.anti_sniping_extension_minutes),
        platform_fee_percent: config.platform_fee_percent,
      });
      setSuccess("Configuration saved. Applies to auctions created from now on.");
    } catch (err) {
      setError(err.message);
    }
  }

  if (!config) return <p>Loading…</p>;
  return (
    <form onSubmit={save}>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <label>
        Minimum bid increment ($)
        <input type="number" step="0.01" min="0" value={config.min_bid_increment} onChange={(e) => setConfig({ ...config, min_bid_increment: e.target.value })} />
      </label>
      <label>
        Anti-sniping window (minutes before close)
        <input type="number" min="0" value={config.anti_sniping_window_minutes} onChange={(e) => setConfig({ ...config, anti_sniping_window_minutes: e.target.value })} />
      </label>
      <label>
        Anti-sniping extension (minutes)
        <input type="number" min="0" value={config.anti_sniping_extension_minutes} onChange={(e) => setConfig({ ...config, anti_sniping_extension_minutes: e.target.value })} />
      </label>
      <label>
        Platform fee (%)
        <input type="number" step="0.01" min="0" value={config.platform_fee_percent} onChange={(e) => setConfig({ ...config, platform_fee_percent: e.target.value })} />
      </label>
      <button type="submit">Save configuration</button>
    </form>
  );
}

function AuditLogsTab() {
  const [logs, setLogs] = useState([]);
  const [error, setError] = useState("");

  useEffect(() => {
    api.get("/api/admin/audit-logs").then((d) => setLogs(d.logs)).catch((err) => setError(err.message));
  }, []);

  return (
    <div>
      <ErrorBanner message={error} />
      <table className="data-table">
        <thead><tr><th>Action</th><th>Entity</th><th>User</th><th>When</th></tr></thead>
        <tbody>
          {logs.map((log) => (
            <tr key={log.log_id}>
              <td>{log.action}</td>
              <td>{log.entity_type} #{log.entity_id}</td>
              <td>{log.user_id ?? "system"}</td>
              <td>{new Date(log.created_at).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function AdminHub() {
  return (
    <div>
      <h2>Admin Console</h2>
      <Tabs
        tabs={[
          { label: "Dashboard", content: <DashboardTab /> },
          { label: "Users", content: <UsersTab /> },
          { label: "Categories", content: <CategoriesTab /> },
          { label: "Config", content: <ConfigTab /> },
          { label: "Audit Logs", content: <AuditLogsTab /> },
        ]}
      />
    </div>
  );
}
