import {
  generatePasteId,
  getCurrentTime,
  savePaste,
  validateCreatePasteRequest,
} from "@/lib/paste";
import { NextResponse } from "next/server";

export async function POST(request) {
  try {
    const body = await request.json();
    const validation = validateCreatePasteRequest(body);

    if (!validation.isValid) {
      return NextResponse.json(
        { error: validation.errors.join(", ") },
        { status: 400 },
      );
    }

    const id = generatePasteId();
    const currentTime = getCurrentTime(request.headers);

    const pasteData = {
      content: body.content,
      createdAt: currentTime,
      viewCount: 0,
    };

    if (body.ttl_seconds) pasteData.ttlSeconds = body.ttl_seconds;
    if (body.max_views) pasteData.maxViews = body.max_views;

    await savePaste(id, pasteData);

    // Construct URL - CRITICAL: must be absolute URL with https://
    const baseUrl =
      process.env.NEXT_PUBLIC_BASE_URL ||
      (process.env.VERCEL_URL
        ? `https://${process.env.VERCEL_URL}`
        : "http://localhost:3000/");

    // URL must point to /p/:id
    const url = `${baseUrl}/p/${id}`;

    // Response must include both id and url
    return NextResponse.json(
      {
        id: id,
        url: url,
      },
      {
        status: 201,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    console.error("Error creating paste:", error);
    return NextResponse.json(
      { error: "Invalid request body" },
      { status: 400 },
    );
  }
}
