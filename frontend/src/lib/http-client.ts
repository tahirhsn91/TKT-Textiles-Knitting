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

// ── Request middleware: attach the bearer token from localStorage ───────────
httpClient.interceptors.request.use((config) => {
  const token = getStoredToken();
  if (token) {
    config.headers.set("Authorization", `Bearer ${token}`);
  }
  return config;
});

// ── Response middleware: surface server errors consistently ─────────────────
// Keeps the error contract callers rely on (a normal Error whose message
// reflects the server's error body).
httpClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
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
