import { kv } from "@vercel/kv";
import { headers } from "next/headers";
import Link from "next/link";
import { notFound } from "next/navigation";

export const dynamic = "force-dynamic";
export const revalidate = 0;

function getCurrentTime(headersList) {
  const isTestMode = process.env.TEST_MODE === "1";
  if (isTestMode) {
    const testNowHeader = headersList.get("x-test-now-ms");
    if (testNowHeader) {
      const testTime = parseInt(testNowHeader, 10);
      if (!isNaN(testTime)) {
        return testTime;
      }
    }
  }
  return Date.now();
}

async function getPasteForView(id) {
  try {
    const data = await kv.get(`paste:${id}`);
    if (!data) return null;

    data.viewCount = (data.viewCount || 0) + 1;
    await kv.set(`paste:${id}`, data);

    if (typeof data === "object" && data !== null) {
      return data;
    }
    if (typeof data === "string") {
      return JSON.parse(data);
    }
    return null;
  } catch (error) {
    console.error("Error getting paste:", error);
    return null;
  }
}

function isPasteAvailableForView(pasteData, currentTime) {
  if (pasteData.ttlSeconds) {
    const expiryTime = pasteData.createdAt + pasteData.ttlSeconds * 1000;
    if (currentTime >= expiryTime) {
      return false;
    }
  }
  if (pasteData.maxViews && pasteData.viewCount >= pasteData.maxViews) {
    return false;
  }
  return true;
}

export default async function ViewPastePage({ params }) {
  const { id } = await params;
  const headersList = await headers();
  const currentTime = getCurrentTime(headersList);

  const pasteData = await getPasteForView(id);

  if (!pasteData || !isPasteAvailableForView(pasteData, currentTime)) {
    notFound();
  }

  console.log("now", pasteData);

  const remainingViews = pasteData.maxViews
    ? Math.max(0, pasteData.maxViews - pasteData.viewCount)
    : null;
  const expiresAt = pasteData.ttlSeconds
    ? new Date(pasteData.createdAt + pasteData.ttlSeconds * 1000)
    : null;

  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#f5f5f5",
        padding: "20px",
      }}
    >
      <div
        style={{
          maxWidth: "900px",
          margin: "0 auto",
          backgroundColor: "white",
          borderRadius: "8px",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            backgroundColor: "#0070f3",
            color: "white",
            padding: "20px 30px",
          }}
        >
          <h1 style={{ fontSize: "24px", margin: "0 0 5px 0" }}>
            📋 Paste View
          </h1>
          <p style={{ fontSize: "14px", margin: 0, opacity: 0.9 }}>ID: {id}</p>
        </div>
        <div style={{ padding: "30px" }}>
          <div
            style={{
              backgroundColor: "#f8f9fa",
              border: "1px solid #e1e4e8",
              borderRadius: "6px",
              padding: "20px",
              fontFamily: "monospace",
              fontSize: "14px",
              lineHeight: "1.6",
              whiteSpace: "pre-wrap",
              wordWrap: "break-word",
              overflowX: "auto",
            }}
          >
            {pasteData.content}
          </div>
          {(remainingViews !== null || expiresAt) && (
            <div
              style={{
                marginTop: "20px",
                padding: "15px",
                backgroundColor: "#f0f7ff",
                borderLeft: "4px solid #0070f3",
                fontSize: "14px",
              }}
            >
              {remainingViews !== null && (
                <p style={{ margin: "5px 0" }}>
                  <strong>Views:</strong> {pasteData.viewCount} /{" "}
                  {pasteData.maxViews} ({remainingViews} remaining)
                </p>
              )}
              {expiresAt && (
                <p style={{ margin: "5px 0" }}>
                  <strong>Expires:</strong> {expiresAt.toLocaleString()}
                </p>
              )}
            </div>
          )}
          <div style={{ marginTop: "20px" }}>
            <Link
              href="/"
              style={{
                padding: "10px 20px",
                backgroundColor: "#0070f3",
                color: "white",
                textDecoration: "none",
                borderRadius: "4px",
                fontSize: "14px",
                display: "inline-block",
              }}
            >
              Create New Paste
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
