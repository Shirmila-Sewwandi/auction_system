import { useState } from "react";

export default function Tabs({ tabs }) {
  const [active, setActive] = useState(tabs[0].label);
  const activeTab = tabs.find((t) => t.label === active);
  return (
    <div>
      <nav>
        <ul style={{ display: "flex", gap: "0.5rem", listStyle: "none", padding: 0 }}>
          {tabs.map((tab) => (
            <li key={tab.label}>
              <button
                className={tab.label === active ? "" : "secondary"}
                onClick={() => setActive(tab.label)}
              >
                {tab.label}
              </button>
            </li>
          ))}
        </ul>
      </nav>
      <div>{activeTab?.content}</div>
    </div>
  );
}
