"use client";

import { useState } from "react";

export default function Home() {
  const [content, setContent] = useState("");
  const [ttlSeconds, setTtlSeconds] = useState("");
  const [maxViews, setMaxViews] = useState("");
  const [pasteUrl, setPasteUrl] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setPasteUrl("");
    setLoading(true);

    try {
      const body = { content };

      if (ttlSeconds) {
        const ttl = parseInt(ttlSeconds, 10);
        if (isNaN(ttl) || ttl < 1) {
          setError("TTL must be a positive integer");
          setLoading(false);
          return;
        }
        body.ttl_seconds = ttl;
      }

      if (maxViews) {
        const views = parseInt(maxViews, 10);
        if (isNaN(views) || views < 1) {
          setError("Max views must be a positive integer");
          setLoading(false);
          return;
        }
        body.max_views = views;
      }

      const response = await fetch("/api/pastes", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      const data = await response.json();

      if (!response.ok) {
        setError(data.error || "Failed to create paste");
        setLoading(false);
        return;
      }

      setPasteUrl(data.url);
      setContent("");
      setTtlSeconds("");
      setMaxViews("");
    } catch (err) {
      setError("An error occurred while creating the paste");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#f5f5f5",
        padding: "20px",
      }}
    >
      <div style={{ maxWidth: "900px", margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: "40px" }}>
          <h1 style={{ fontSize: "48px", color: "#0070f3", margin: "10px 0" }}>
            📋 Pastebin Lite
          </h1>
          <p style={{ fontSize: "18px", color: "#666" }}>
            Share text snippets with optional expiry and view limits
          </p>
        </div>

        {error && (
          <div
            style={{
              padding: "15px",
              backgroundColor: "#fee",
              border: "1px solid #fcc",
              borderRadius: "4px",
              marginBottom: "20px",
              color: "#c00",
            }}
          >
            {error}
          </div>
        )}

        {pasteUrl ? (
          <div
            style={{
              backgroundColor: "white",
              borderRadius: "8px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
              padding: "30px",
              marginBottom: "30px",
            }}
          >
            <h2
              style={{
                color: "#0070f3",
                marginBottom: "20px",
                fontSize: "24px",
              }}
            >
              ✅ Paste Created Successfully!
            </h2>
            <div
              style={{
                backgroundColor: "#f8f9fa",
                border: "1px solid #ddd",
                borderRadius: "4px",
                padding: "15px",
                marginBottom: "15px",
                wordBreak: "break-all",
                fontFamily: "monospace",
                fontSize: "14px",
              }}
            >
              {pasteUrl}
            </div>
            <div style={{ display: "flex", gap: "10px" }}>
              <a
                href={pasteUrl}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  flex: 1,
                  padding: "12px 24px",
                  backgroundColor: "#0070f3",
                  color: "white",
                  textDecoration: "none",
                  borderRadius: "4px",
                  fontSize: "14px",
                  textAlign: "center",
                  fontWeight: 600,
                }}
              >
                Visit Paste
              </a>
              <button
                onClick={async () => {
                  if (!navigator?.clipboard) {
                    // fallback
                    const textArea = document.createElement("textarea");
                    textArea.value = pasteUrl;
                    document.body.appendChild(textArea);
                    textArea.select();
                    document.execCommand("copy");
                    document.body.removeChild(textArea);
                    alert("Copied!");
                    return;
                  }

                  await navigator.clipboard.writeText(pasteUrl);
                  alert("Copied!");
                }}
                style={{
                  flex: 1,
                  padding: "12px 24px",
                  backgroundColor: "#6c757d",
                  color: "white",
                  border: "none",
                  borderRadius: "4px",
                  fontSize: "14px",
                  cursor: "pointer",
                  fontWeight: 600,
                }}
              >
                Copy URL
              </button>
              <button
                onClick={() => {
                  setPasteUrl("");
                  setError("");
                }}
                style={{
                  flex: 1,
                  padding: "12px 24px",
                  backgroundColor: "#6c757d",
                  color: "white",
                  border: "none",
                  borderRadius: "4px",
                  fontSize: "14px",
                  cursor: "pointer",
                  fontWeight: 600,
                }}
              >
                Create Another
              </button>
            </div>
          </div>
        ) : (
          <div
            style={{
              backgroundColor: "white",
              borderRadius: "8px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
              padding: "30px",
              marginBottom: "30px",
            }}
          >
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: "20px" }}>
                <label
                  htmlFor="content"
                  style={{
                    display: "block",
                    marginBottom: "8px",
                    fontWeight: 600,
                    color: "#333",
                    fontSize: "14px",
                  }}
                >
                  Paste Content <span style={{ color: "#e00" }}>*</span>
                </label>
                <textarea
                  id="content"
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Enter your text here..."
                  required
                  style={{
                    width: "100%",
                    minHeight: "250px",
                    padding: "12px",
                    border: "1px solid #ddd",
                    borderRadius: "4px",
                    fontSize: "14px",
                    fontFamily: "monospace",
                    resize: "vertical",
                  }}
                />
              </div>

              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "1fr 1fr",
                  gap: "20px",
                  marginBottom: "20px",
                }}
              >
                <div>
                  <label
                    htmlFor="ttl"
                    style={{
                      display: "block",
                      marginBottom: "8px",
                      fontWeight: 600,
                      color: "#333",
                      fontSize: "14px",
                    }}
                  >
                    Time to Live (seconds)
                  </label>
                  <input
                    id="ttl"
                    type="number"
                    value={ttlSeconds}
                    onChange={(e) => setTtlSeconds(e.target.value)}
                    placeholder="Optional"
                    min="1"
                    style={{
                      width: "100%",
                      padding: "12px",
                      border: "1px solid #ddd",
                      borderRadius: "4px",
                      fontSize: "14px",
                    }}
                  />
                  <div
                    style={{
                      fontSize: "12px",
                      color: "#666",
                      marginTop: "5px",
                    }}
                  >
                    Paste will expire after this many seconds
                  </div>
                </div>

                <div>
                  <label
                    htmlFor="maxViews"
                    style={{
                      display: "block",
                      marginBottom: "8px",
                      fontWeight: 600,
                      color: "#333",
                      fontSize: "14px",
                    }}
                  >
                    Maximum Views
                  </label>
                  <input
                    id="maxViews"
                    type="number"
                    value={maxViews}
                    onChange={(e) => setMaxViews(e.target.value)}
                    placeholder="Optional"
                    min="1"
                    style={{
                      width: "100%",
                      padding: "12px",
                      border: "1px solid #ddd",
                      borderRadius: "4px",
                      fontSize: "14px",
                    }}
                  />
                  <div
                    style={{
                      fontSize: "12px",
                      color: "#666",
                      marginTop: "5px",
                    }}
                  >
                    Paste will expire after this many views
                  </div>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                style={{
                  width: "100%",
                  padding: "14px 28px",
                  fontSize: "16px",
                  fontWeight: 600,
                  color: "white",
                  backgroundColor: loading ? "#ccc" : "#0070f3",
                  border: "none",
                  borderRadius: "4px",
                  cursor: loading ? "not-allowed" : "pointer",
                }}
              >
                {loading ? "Creating..." : "Create Paste"}
              </button>
            </form>
          </div>
        )}

        <div
          style={{
            backgroundColor: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            padding: "30px",
          }}
        >
          <h3 style={{ color: "#333", marginBottom: "15px" }}>Features</h3>
          <ul style={{ listStyle: "none", paddingLeft: 0 }}>
            {[
              "Create text pastes instantly",
              "Set optional time-based expiry (TTL)",
              "Set optional view count limits",
              "Share via simple URLs",
              "Safe content rendering (XSS protection)",
            ].map((f, i) => (
              <li key={i} style={{ padding: "8px 0", color: "#666" }}>
                <span
                  style={{
                    color: "#0070f3",
                    fontWeight: "bold",
                    marginRight: "8px",
                  }}
                >
                  ✓
                </span>
                {f}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
