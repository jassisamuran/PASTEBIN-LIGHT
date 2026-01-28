import {
  getCurrentTime,
  getExpiresAt,
  getPaste,
  getRemainingViews,
  incrementViewCount,
  isPasteAvailable,
} from "@/lib/paste";
import { NextResponse } from "next/server";

export async function GET(request, { params }) {
  try {
    // AWAIT params - this is the fix!
    const { id } = await params;

    const pasteData = await getPaste(id);

    if (!pasteData) {
      return NextResponse.json({ error: "Paste not found" }, { status: 404 });
    }

    const currentTime = getCurrentTime(request.headers);

    if (!isPasteAvailable(pasteData, currentTime)) {
      return NextResponse.json(
        { error: "Paste not available" },
        { status: 404 },
      );
    }

    const updatedPaste = await incrementViewCount(id);

    if (!updatedPaste) {
      return NextResponse.json({ error: "Paste not found" }, { status: 404 });
    }

    const response = {
      content: updatedPaste.content,
      remaining_views: getRemainingViews(updatedPaste),
      expires_at: getExpiresAt(updatedPaste),
    };

    return NextResponse.json(response, { status: 200 });
  } catch (error) {
    console.error("Error fetching paste:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
