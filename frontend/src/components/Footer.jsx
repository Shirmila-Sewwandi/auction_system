export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="app-shell">
        <span className="brand" style={{ fontSize: "1.1rem" }}>Auction Platform</span>
        <small>&copy; {new Date().getFullYear()} Auction Platform — a local, offline demo build.</small>
      </div>
    </footer>
  );
}
