import { NextResponse } from "next/server";
import { cookies } from "next/headers";

/**
 * Plain GET route (not a form action) so it's reachable by typing the URL
 * directly — the escape hatch for when a broken session cookie causes the
 * proxy's login<->protected-route redirect loop, which means the page that
 * would normally offer this action (the login page) can never finish
 * loading in the first place.
 */
export async function GET(request: Request) {
  const cookieStore = await cookies();
  for (const cookie of cookieStore.getAll()) {
    if (cookie.name.startsWith("sb-")) {
      cookieStore.delete(cookie.name);
    }
  }
  return NextResponse.redirect(new URL("/login", request.url));
}
