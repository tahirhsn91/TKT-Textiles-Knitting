import type { AxiosError, AxiosRequestConfig } from "axios";
import { httpClient } from "@/lib/http-client";

// ---------------------------------------------------------------------------
// Types — preserved from the original fetch-based wrapper so all call sites
// and the generated API client keep compiling unchanged.
// ---------------------------------------------------------------------------

export type CustomFetchOptions = RequestInit & {
  responseType?: "json" | "text" | "blob" | "auto";
};

export type ErrorType<T = unknown> = ApiError<T>;

export type BodyType<T> = T;

export type AuthTokenGetter = () => Promise<string | null> | string | null;

// ---------------------------------------------------------------------------
// Backward-compatible no-ops. The bearer token is now attached by the Axios
// request interceptor (src/lib/http-client.ts), which reads localStorage
// directly, so these legacy hooks are kept only so existing callers (e.g.
// AuthProvider's effect) don't break.
// ---------------------------------------------------------------------------

/** @deprecated Axios interceptor handles auth; kept for signature compatibility. */
export function setBaseUrl(_url: string | null): void {}

/**
 * @deprecated Axios interceptor reads the token from localStorage directly;
 * kept for signature compatibility with the AuthProvider effect.
 */
export function setAuthTokenGetter(_getter: AuthTokenGetter | null): void {}

// ---------------------------------------------------------------------------
// Error classes — preserved shape (status / data / message) so callers that
// `instanceof Error`, read `.status` (e.g. 409 handling) or `.data.error`
// keep working. They are now surfaced from Axios errors.
// ---------------------------------------------------------------------------

function errorData(axiosError: AxiosError): unknown {
  return axiosError.response?.data ?? null;
}

function errorStatus(axiosError: AxiosError): number {
  return axiosError.response?.status ?? 0;
}

export class ApiError<T = unknown> extends Error {
  readonly name = "ApiError";
  readonly status: number;
  readonly statusText: string;
  readonly data: T | null;
  readonly method: string;
  readonly url: string;

  constructor(axiosError: AxiosError, data: T | null) {
    const status = errorStatus(axiosError);
    const statusText = axiosError.response?.statusText ?? "";
    const reason =
      (data && typeof data === "object" && (data as Record<string, unknown>).error) as
        | string
        | undefined;
    super(reason || axiosError.message || `HTTP ${status} ${statusText}`);
    Object.setPrototypeOf(this, new.target.prototype);

    this.status = status;
    this.statusText = statusText;
    this.data = data;
    this.method = (axiosError.config?.method ?? "GET").toUpperCase();
    this.url = typeof axiosError.config?.url === "string" ? axiosError.config.url : "";
  }
}

export class ResponseParseError extends Error {
  readonly name = "ResponseParseError";
  readonly status: number;
  readonly statusText: string;
  readonly method: string;
  readonly url: string;
  readonly rawBody: string;
  readonly cause: unknown;

  constructor(
    err: Error,
    config: { method: string; url: string },
    status: number,
    statusText: string,
    rawBody: string,
  ) {
    super(`Failed to parse response from ${config.method} ${config.url} (${status} ${statusText}) as JSON`);
    Object.setPrototypeOf(this, new.target.prototype);

    this.status = status;
    this.statusText = statusText;
    this.method = config.method;
    this.url = config.url;
    this.rawBody = rawBody;
    this.cause = err;
  }
}

// ---------------------------------------------------------------------------
// customFetch — the app-wide request helper, now backed by Axios.
//
// Same signature as before: customFetch<T>(url, { method, headers, body,
// responseType }). It resolves relative URLs against the Vite base URL and
// delegates to the Axios client, whose request interceptor attaches the bearer
// token from localStorage. The axios request body may be a plain object or a
// pre-serialized JSON string (the old call sites pass JSON.stringify(...));
// we accept both and let axios set the content-type.
// ---------------------------------------------------------------------------

function toUrl(input: string | URL | Request): string {
  if (typeof input === "string") return input;
  if (typeof URL !== "undefined" && input instanceof URL) return input.href;
  // Remaining: a Request object — the generated client only ever passes
  // string URLs, but keep this branch safe for generic consumers.
  return (input as Request).url;
}

function stringifyBody(body: unknown): unknown {
  // Already a string (call sites used JSON.stringify) — leave as-is so axios
  // sends it verbatim with the caller's content-type.
  return body;
}

export async function customFetch<T = unknown>(
  input: string | URL | Request,
  options: CustomFetchOptions = {},
): Promise<T> {
  const url = toUrl(input);
  const method = (options.method ?? "GET").toUpperCase();
  const { responseType, headers: headersInit, body } = options;

  const axiosConfig: AxiosRequestConfig = {
    url,
    method,
    data: body !== null && body !== undefined ? stringifyBody(body) : undefined,
    signal: (options.signal ?? undefined) as AxiosRequestConfig["signal"],
  };

  if (headersInit) {
    axiosConfig.headers = headersInit as AxiosRequestConfig["headers"];
  }

  try {
    const axiosResponse = await httpClient.request<T>(axiosConfig);

    // Honour the responseType override (axios default already handles JSON).
    if (responseType === "text") {
      return String(axiosResponse.data) as T;
    }
    return axiosResponse.data as T;
  } catch (err) {
    const axiosError = err as AxiosError;
    // Never throw non-Axios errors as ApiError (e.g. cancelled requests).
    if (!axiosError || !axiosError.isAxiosError) {
      throw err;
    }
    const data = errorData(axiosError) as T | null;

    // 204/205/304 have no body — return null like the old wrapper did.
    const noBodyStatus = [204, 205, 304].includes(axiosError.response?.status ?? 0);
    if (axiosError.response && noBodyStatus && !axiosError.response.data) {
      return null as T;
    }

    throw new ApiError<T>(axiosError, data);
  }
}
