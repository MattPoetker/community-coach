/**
 * Server-side API client.
 *
 * Every call forwards the inbound Cookie header to Rails. That is the whole trick behind
 * the single-origin design: the browser holds one session cookie, Caddy routes /api to
 * Rails and everything else to Next, and server components pass the cookie straight
 * through. No JWT, no refresh, no CORS.
 */
import { cookies, headers } from "next/headers";

const API = process.env.API_INTERNAL_URL || "http://localhost:3001";

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public detail?: unknown,
  ) {
    super(message);
  }
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const cookieStore = await cookies();
  const headerStore = await headers();

  const response = await fetch(`${API}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Cookie: cookieStore.toString(),
      // Development resolves the tenant by header; production resolves it from the host.
      "X-Community-Slug": process.env.COMMUNITY_SLUG || "momentum",
      "X-Forwarded-Host": headerStore.get("host") || "",
      ...init.headers,
    },
    cache: "no-store",
  });

  if (!response.ok) {
    let payload: { error?: { code?: string; message?: string; detail?: unknown } } = {};
    try {
      payload = await response.json();
    } catch {
      /* an error page from a proxy, not our JSON shape */
    }
    throw new ApiError(
      response.status,
      payload.error?.code ?? "unknown",
      payload.error?.message ?? `Request failed (${response.status})`,
      payload.error?.detail,
    );
  }

  if (response.status === 204) return undefined as T;
  return response.json();
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "POST", body: body ? JSON.stringify(body) : undefined }),
};

/** Returns null instead of throwing, for surfaces that render for signed-out visitors. */
export async function maybe<T>(fn: () => Promise<T>): Promise<T | null> {
  try {
    return await fn();
  } catch (error) {
    if (error instanceof ApiError && [401, 403, 404].includes(error.status)) return null;
    throw error;
  }
}
