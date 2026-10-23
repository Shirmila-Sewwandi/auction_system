import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, imageUrl } from "../api/client";
import { ErrorBanner } from "../components/Banner";
import Pagination from "../components/Pagination";

function timeLeft(endTime) {
  const diffMs = new Date(endTime) - new Date();
  if (diffMs <= 0) return "closed";
  const mins = Math.floor(diffMs / 60000);
  if (mins < 60) return `${mins}m left`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ${mins % 60}m left`;
  return `${Math.floor(hours / 24)}d left`;
}

export default function Home() {
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;
    api
      .get("/api/listings", { search, page })
      .then((data) => {
        if (cancelled) return;
        setItems(data.items);
        setTotal(data.total);
        setError("");
      })
      .catch((err) => !cancelled && setError(err.message));
    return () => {
      cancelled = true;
    };
  }, [search, page]);

  return (
    <div>
      <h2>Live Auctions</h2>
      <ErrorBanner message={error} />
      <input
        type="search"
        placeholder="Search antiques and collectibles…"
        value={search}
        onChange={(e) => {
          setPage(1);
          setSearch(e.target.value);
        }}
      />
      {items.length === 0 ? (
        <p>No auctions match your search.</p>
      ) : (
        <div className="listing-grid">
          {items.map((item) => (
            <Link key={item.listing_id} to={`/listings/${item.listing_id}`} className="listing-card">
              {item.thumbnail ? (
                <img className="listing-card-image" src={imageUrl(item.thumbnail)} alt={item.title} loading="lazy" />
              ) : (
                <div className="listing-card-image" aria-hidden="true">{item.title.charAt(0)}</div>
              )}
              <div className="listing-card-body">
                <h4>{item.title}</h4>
                <p className="estimate">Current bid: ${item.current_price}</p>
                <span className="badge muted">{timeLeft(item.end_time)}</span>
              </div>
            </Link>
          ))}
        </div>
      )}
      <Pagination page={page} total={total} onChange={setPage} />
    </div>
  );
}
