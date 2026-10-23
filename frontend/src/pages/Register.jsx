import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { ErrorBanner, SuccessBanner } from "../components/Banner";

const ALL_ROLES = ["SELLER", "BIDDER"];

export default function Register() {
  const { register, login } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ first_name: "", last_name: "", email: "", password: "", phone: "" });
  const [roles, setRoles] = useState(["BIDDER"]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  function toggleRole(role) {
    setRoles((prev) => (prev.includes(role) ? prev.filter((r) => r !== role) : [...prev, role]));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    try {
      await register({ ...form, roles });
      setSuccess("Account created — logging you in…");
      await login(form.email, form.password);
      navigate("/");
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <article style={{ maxWidth: 480, margin: "0 auto" }}>
      <h2>Create an account</h2>
      <ErrorBanner message={error} />
      <SuccessBanner message={success} />
      <form onSubmit={handleSubmit}>
        <div className="grid">
          <label>
            First name
            <input required value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} />
          </label>
          <label>
            Last name
            <input required value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} />
          </label>
        </div>
        <label>
          Email
          <input type="email" required value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
        </label>
        <label>
          Password (min 8 characters)
          <input
            type="password"
            required
            minLength={8}
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
          />
        </label>
        <label>
          Phone (optional)
          <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
        </label>
        <fieldset>
          <legend>I want to:</legend>
          {ALL_ROLES.map((role) => (
            <label key={role}>
              <input type="checkbox" checked={roles.includes(role)} onChange={() => toggleRole(role)} />
              {role === "SELLER" ? "Sell items" : "Bid on items"}
            </label>
          ))}
        </fieldset>
        <button type="submit" disabled={roles.length === 0}>Sign up</button>
      </form>
    </article>
  );
}
