import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import ThemeToggle from "./ThemeToggle";

export default function NavBar() {
  const { user, logout, hasRole } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate("/");
  }

  return (
    <nav className="navbar">
      <div className="links">
        <Link to="/" className="brand">Auction Platform</Link>
        {hasRole("SELLER") && <Link to="/seller">Seller</Link>}
        {hasRole("BIDDER") && <Link to="/bidder">My Bidding</Link>}
        {hasRole("MODERATOR") && <Link to="/moderator">Moderation</Link>}
        {hasRole("ADMIN") && <Link to="/admin">Admin</Link>}
        {user && <Link to="/notifications">Notifications</Link>}
      </div>
      <div className="links">
        {user ? (
          <>
            <span>{user.first_name} ({user.roles.join(", ")})</span>
            <button className="secondary" onClick={handleLogout}>Log out</button>
          </>
        ) : (
          <>
            <Link to="/login">Log in</Link>
            <Link to="/register" role="button">Sign up</Link>
          </>
        )}
        <ThemeToggle />
      </div>
    </nav>
  );
}
