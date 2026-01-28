import { kv } from "@vercel/kv";
import { nanoid } from "nanoid";

export function generatePasteId() {
  return nanoid(8);
}

export function getCurrentTime(headers) {
  const isTestMode = process.env.TEST_MODE === "1";

  if (isTestMode) {
    const testNowHeader = headers.get("x-test-now-ms");
    if (testNowHeader) {
      const testTime = parseInt(testNowHeader, 10);
      if (!isNaN(testTime)) {
        return testTime;
      }
    }
  }

  return Date.now();
}

export function isPasteExpired(pasteData, currentTime) {
  if (!pasteData.ttlSeconds) return false;
  const expiryTime = pasteData.createdAt + pasteData.ttlSeconds * 1000;
  return currentTime >= expiryTime;
}

export function isPasteViewLimitExceeded(pasteData) {
  if (!pasteData.maxViews) return false;
  return pasteData.viewCount >= pasteData.maxViews;
}

export function isPasteAvailable(pasteData, currentTime) {
  if (isPasteExpired(pasteData, currentTime)) return false;
  if (isPasteViewLimitExceeded(pasteData)) return false;
  return true;
}

export function getExpiresAt(pasteData) {
  if (!pasteData.ttlSeconds) return null;
  const expiryTime = pasteData.createdAt + pasteData.ttlSeconds * 1000;
  return new Date(expiryTime).toISOString();
}

export function getRemainingViews(pasteData) {
  if (!pasteData.maxViews) return null;
  const remaining = pasteData.maxViews - pasteData.viewCount;
  return Math.max(0, remaining);
}

export async function savePaste(id, pasteData) {
  // Store as object directly - KV handles serialization
  await kv.set(`paste:${id}`, pasteData);

  if (pasteData.ttlSeconds) {
    await kv.expire(`paste:${id}`, pasteData.ttlSeconds + 60);
  }
}

export async function getPaste(id) {
  const data = await kv.get(`paste:${id}`);

  if (!data) return null;

  // KV returns data directly as an object - no need to parse!
  // If it's already an object, return it
  if (typeof data === "object" && data !== null) {
    return data;
  }

  // If it's a string (shouldn't happen with new code), parse it
  if (typeof data === "string") {
    try {
      return JSON.parse(data);
    } catch (error) {
      console.error("Error parsing paste data:", error);
      return null;
    }
  }

  return null;
}

export async function incrementViewCount(id) {
  const pasteData = await getPaste(id);
  if (!pasteData) return null;

  pasteData.viewCount += 1;

  // Save the updated paste data
  await savePaste(id, pasteData);

  return pasteData;
}
export function validateCreatePasteRequest(body) {
  const errors = [];

  if (!body.content) {
    errors.push("Content is required");
  } else if (typeof body.content !== "string") {
    errors.push("Content must be a string");
  } else if (body.content.trim() === "") {
    errors.push("Content cannot be empty");
  }

  if (body.ttl_seconds !== undefined && body.ttl_seconds !== null) {
    if (!Number.isInteger(body.ttl_seconds)) {
      errors.push("ttl_seconds must be an integer");
    } else if (body.ttl_seconds < 1) {
      errors.push("ttl_seconds must be >= 1");
    }
  }

  if (body.max_views !== undefined && body.max_views !== null) {
    if (!Number.isInteger(body.max_views)) {
      errors.push("max_views must be an integer");
    } else if (body.max_views < 1) {
      errors.push("max_views must be >= 1");
    }
  }

  return { isValid: errors.length === 0, errors };
}
