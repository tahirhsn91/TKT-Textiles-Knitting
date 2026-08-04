/**
 * lazyRetry — a self-healing React.lazy (issue #2).
 *
 * Plain `lazy(() => import(...))` caches the import promise: once it rejects
 * (stale chunk after a redeploy, transient network drop), every subsequent
 * render re-throws the same cached rejection — the route stays on the Suspense
 * skeleton forever with no API requests, because the page component never
 * mounts.
 *
 * This wrapper re-attempts the import a limited number of times before giving
 * up. If all attempts fail, the error propagates to the RouteErrorBoundary,
 * which offers a page reload (the only true fix for a stale chunk: a fresh
 * index.html references the current hashed chunk names).
 */
import { lazy, type ComponentType, type LazyExoticComponent } from "react";

type ImportFactory<T extends ComponentType<unknown>> = () => Promise<{
  default: T;
}>;

export function lazyRetry<T extends ComponentType<unknown>>(
  factory: ImportFactory<T>,
  retries = 1,
): LazyExoticComponent<T> {
  return lazy(async () => {
    let lastError: unknown;
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        return await factory();
      } catch (err) {
        lastError = err;
        console.warn(`[lazyRetry] chunk load failed (attempt ${attempt + 1}/${retries + 1})`, err);
      }
    }
    throw lastError;
  });
}
