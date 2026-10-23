import { useEffect, useState } from "react";
import { api } from "../api/client";

export default function Notifications() {
  const [notifications, setNotifications] = useState([]);

  async function load() {
    const d = await api.get("/api/notifications");
    setNotifications(d.notifications);
  }

  useEffect(() => {
    load().catch(() => {});
  }, []);

  async function markRead(id) {
    await api.patch(`/api/notifications/${id}/read`);
    load();
  }

  async function markAllRead() {
    await api.patch("/api/notifications/read-all");
    load();
  }

  return (
    <div>
      <h2>Notifications</h2>
      {notifications.length > 0 && <button className="secondary" onClick={markAllRead}>Mark all as read</button>}
      {notifications.length === 0 ? (
        <p>No notifications yet.</p>
      ) : (
        notifications.map((n) => (
          <article key={n.notification_id} style={{ opacity: n.is_read ? 0.6 : 1 }}>
            <header>
              <strong>{n.title}</strong> — <small>{new Date(n.created_at).toLocaleString()}</small>
            </header>
            <p>{n.message}</p>
            {!n.is_read && <button className="secondary" onClick={() => markRead(n.notification_id)}>Mark as read</button>}
          </article>
        ))
      )}
    </div>
  );
}
