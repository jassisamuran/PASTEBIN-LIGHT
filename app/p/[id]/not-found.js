import Link from "next/link";

export default function NotFound() {
  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#f5f5f5",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "20px",
      }}
    >
      <div
        style={{
          maxWidth: "500px",
          backgroundColor: "white",
          borderRadius: "8px",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          padding: "40px",
          textAlign: "center",
        }}
      >
        <div style={{ fontSize: "64px", marginBottom: "20px" }}>❌</div>
        <h1 style={{ fontSize: "24px", color: "#333", marginBottom: "10px" }}>
          Oops!
        </h1>
        <p style={{ color: "#666", fontSize: "16px", marginBottom: "30px" }}>
          Paste not found or no longer available
        </p>
        <Link
          href="/"
          style={{
            padding: "12px 24px",
            backgroundColor: "#0070f3",
            color: "white",
            textDecoration: "none",
            borderRadius: "4px",
            display: "inline-block",
            fontSize: "14px",
          }}
        >
          Go to Homepage
        </Link>
      </div>
    </div>
  );
}
