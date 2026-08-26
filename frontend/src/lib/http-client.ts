import axios, { AxiosError, type AxiosInstance, type AxiosRequestConfig } from "axios";
import { getStoredToken } from "@/context/auth-context";

/**
 * Central Axios HTTP client for the app.
 *
 * A request interceptor acts as middleware: on every outgoing request it reads
 * the bearer token from localStorage (see getStoredToken) and, when a token is
 * present, attaches `Authorization: Bearer <token>`. This replaces the old
 * hand-rolled fetch wrapper with a single Axios-backed client so all API calls
 * in the app authenticate consistently.
 *
 * Relative URLs (starting with "/") are resolved against the Vite base URL so
 * the proxy target is honoured, matching the previous fetch behaviour.
 */
const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

export const BASE_URL = BASE;

export const httpClient: AxiosInstance = axios.create({
  baseURL: BASE,
  timeout: 0, // no client-side timeout — server controls it
});

// ---------------------------------------------------------------------------
// 401 Unauthorized handler (auth middleware)
//
// The Axios response interceptor below is deliberately framework-agnostic
// (a plain module has no access to React context), so unauthenticated (401)
// responses are surfaced to the rest of the app through a single registered
// callback. The auth layer (AuthProvider) registers this callback and, when
// invoked, clears the stored session (logout) and redirects to /login.
//
// Endpoints that are *expected* to return 401 and must NOT trigger logout are
// excluded here:
//   - /api/auth/login       → invalid credentials (user must see the error)
// ---------------------------------------------------------------------------

const LOGIN_URLS = new Set(["/api/auth/login"]);

/** Returns true when a 401 should trigger the app-wide logout + redirect. */
export function shouldHandleUnauthorized(pathname: string | undefined): boolean {
  if (!pathname) return false;
  // Normalise: ignore query/hash, compare against the request path only.
  const path = pathname.split(/[?#]/)[0];
  return !LOGIN_URLS.has(path);
}

type UnauthorizedHandler = () => void;

let unauthorizedHandler: UnauthorizedHandler | null = null;
let unauthorizedFired = false;

/**
 * Register the callback that runs when an API 401 is detected. Only one
 * handler may be active at a time; registering again replaces the previous
 * one. Returns a cleanup function that unregisters and resets the fired flag.
 */
export function setUnauthorizedHandler(handler: UnauthorizedHandler | null): () => void {
  unauthorizedHandler = handler;
  unauthorizedFired = false;
  return () => {
    if (unauthorizedHandler === handler) {
      unauthorizedHandler = null;
    }
    unauthorizedFired = false;
  };
}

/**
 * Invoke the registered 401 handler exactly once per auth-zone event. Guards
 * against several in-flight requests all returning 401 at once (parallel
 * queries) triggering repeated logouts/redirects.
 */
function fireUnauthorizedHandler(): void {
  if (unauthorizedFired) return;
  unauthorizedFired = true;
  unauthorizedHandler?.();
}

/** @internal exported for tests. */
export function _resetUnauthorizedState(): void {
  unauthorizedFired = false;
}

// ── Active-tenant context (issue #219) ──────────────────────────────────────
// The active tenant is carried on each request via the X-Tenant-Id header. It
// is client-held state (the AuthProvider owns it for super-admins; tenant
// users' home tenant is implied by their JWT and the header is optional). We
// register a getter here (module scope, no React) that the AuthProvider keeps
// in sync, mirroring the bearer-token getter pattern.
type TenantIdGetter = () => number | null;
let tenantIdGetter: TenantIdGetter | null = null;

/** Register the callback that returns the active tenant id (from auth context). */
export function setTenantIdGetter(getter: TenantIdGetter | null): () => void {
  tenantIdGetter = getter;
  return () => {
    if (tenantIdGetter === getter) tenantIdGetter = null;
  };
}

// ── Request middleware: attach the bearer token from localStorage ───────────
httpClient.interceptors.request.use((config) => {
  const token = getStoredToken();
  if (token) {
    config.headers.set("Authorization", `Bearer ${token}`);
  }

  // Attach the active tenant context (issue #219). Always send when present;
  // the backend ignores/validates it per the user's role (a tenant user's
  // mismatched header is rejected server-side with 403).
  const tenantId = tenantIdGetter?.() ?? null;
  if (tenantId != null) {
    config.headers.set("X-Tenant-Id", String(tenantId));
  }

  // Axios does not set `Content-Type: application/json` when the body is a
  // pre-serialized JSON string (lots of call sites pass JSON.stringify(...)).
  // For those the request goes out as application/x-www-form-urlencoded, so
  // Express never parses the JSON body and validation middleware returns 400
  // (or the handler sees an empty body). Enforce JSON for body-carrying
  // methods unless the caller already set a content type. (issue #25 E2E)
  const method = (config.method ?? "get").toUpperCase();
  const hasBody = config.data !== undefined && config.data !== null;
  const isFormData =
    typeof FormData !== "undefined" && config.data instanceof FormData;
  if (hasBody && ["POST", "PUT", "PATCH"].includes(method)) {
    // Never force JSON for FormData/multipart uploads — let Axios/the browser
    // set `multipart/form-data; boundary=…` so multer can parse the file.
    if (!isFormData && !config.headers.has("Content-Type")) {
      config.headers.set("Content-Type", "application/json");
    }
  }

  return config;
});

// ── Response middleware: surface server errors consistently ─────────────────
// Keeps the error contract callers rely on (a normal Error whose message
// reflects the server's error body). Additionally, a 401 Unauthorized from any
// endpoint except the login call is treated as an expired/invalid session: the
// registered auth handler (logout + redirect to /login) is invoked.
httpClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // Session-expiry detection: 401 with a locally-stored token means the
    // server rejected our now-invalid bearer token. Log the user out and send
    // them to the login page (unless this is the login request itself).
    if (
      error.response?.status === 401 &&
      getStoredToken() &&
      shouldHandleUnauthorized(error.config?.url)
    ) {
      fireUnauthorizedHandler();
    }

    // If the network/server didn't give us a body, promote the status reason.
    const serverData =
      error.response?.data && typeof error.response.data === "object"
        ? (error.response.data as Record<string, unknown>)
        : undefined;
    const message =
      (typeof serverData?.message === "string" && serverData.message) ||
      (typeof serverData?.error === "string" && serverData.error) ||
      error.message ||
      `HTTP ${error.response?.status ?? 0}`;
    error.message = message;
    return Promise.reject(error);
  },
);

/** Thin wrapper so callers can pass the same options shape as before. */
export function httpRequest<T>(
  url: string,
  config: AxiosRequestConfig = {},
): Promise<T> {
  return httpClient.request<T>({ url, ...config }).then((res) => res.data);
}
