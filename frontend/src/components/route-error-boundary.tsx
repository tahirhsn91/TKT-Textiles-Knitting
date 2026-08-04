/**
 * Route-level error boundary + Suspense fallback with timeout (issue #2).
 *
 * The transactions routes are lazy-loaded: the page stays on the Suspense
 * skeleton until the dynamic chunk finishes downloading. Before this fix there
 * was no error boundary and no timeout anywhere in the tree, so a chunk that
 * failed or stalled (stale hashed chunk after a redeploy, transient network
 * drop, etc.) left the skeleton on screen forever with zero API requests —
 * the component never mounted.
 *
 * Two layers fix that:
 *  - RouteErrorBoundary catches a REJECTED import (chunk 404 / parse error)
 *    and offers a Retry that reloads the page. A plain re-render can't retry
 *    the import: React caches the rejected promise on the lazy component, so
 *    only a fresh document (fresh module graph, fresh index.html → fresh chunk
 *    names) can genuinely re-attempt it.
 *  - SuspenseFallback switches from the skeleton to a "taking too long"
 *    message after `timeoutMs` — covering the case where the import promise
 *    neither resolves nor rejects (stalled request) instead of spinning on the
 *    skeleton indefinitely.
 */
import { Component, useEffect, useState, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

// ─── Error boundary ──────────────────────────────────────────────────────────

interface BoundaryProps {
  children: ReactNode;
}
interface BoundaryState {
  hasError: boolean;
  message: string | null;
}

export class RouteErrorBoundary extends Component<BoundaryProps, BoundaryState> {
  state: BoundaryState = { hasError: false, message: null };

  static getDerivedStateFromError(error: unknown): BoundaryState {
    return {
      hasError: true,
      message: error instanceof Error ? error.message : "Unknown error",
    };
  }

  componentDidCatch(error: unknown, info: unknown) {
    console.error("[RouteErrorBoundary] failed to load route:", error, info);
  }

  handleRetry = () => {
    // Full reload: the failed lazy-import promise is cached in the current
    // module graph, so re-rendering cannot re-attempt it. A fresh document
    // re-fetches index.html and, with it, the current chunk names.
    window.location.reload();
  };

  render() {
    if (!this.state.hasError) return this.props.children;

    return (
      <div className="flex min-h-[60vh] items-center justify-center p-8">
        <div className="max-w-md space-y-3 text-center">
          <h1 className="text-xl font-semibold text-foreground">
            Couldn't load this page
          </h1>
          <p className="text-sm text-muted-foreground">
            The page's code failed to load — usually because the app was updated
            while this page was open. Reloading will fetch the current version.
          </p>
          {this.state.message && (
            <p className="font-mono text-xs text-muted-foreground/70">
              {this.state.message}
            </p>
          )}
          <Button onClick={this.handleRetry} className="mt-2">
            Retry
          </Button>
        </div>
      </div>
    );
  }
}

// ─── Suspense fallback with timeout ──────────────────────────────────────────

/** The original skeleton, shown while a route chunk loads. */
export function RouteFallback() {
  return (
    <div className="space-y-4 p-8">
      <Skeleton className="h-8 w-64" />
      <Skeleton className="h-32 w-full" />
      <Skeleton className="h-32 w-full" />
    </div>
  );
}

/**
 * Renders the skeleton, but if the suspended chunk still hasn't resolved after
 * `timeoutMs`, swaps in a "taking too long" message with a Retry. Prevents the
 * infinite-skeleton hang when the import neither resolves nor rejects.
 */
export function SuspenseFallback({ timeoutMs = 10000 }: { timeoutMs?: number }) {
  const [timedOut, setTimedOut] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setTimedOut(true), timeoutMs);
    return () => clearTimeout(timer);
  }, [timeoutMs]);

  if (!timedOut) return <RouteFallback />;

  return (
    <div className="flex min-h-[60vh] items-center justify-center p-8">
      <div className="max-w-md space-y-3 text-center">
        <h1 className="text-xl font-semibold text-foreground">
          This page is taking longer than expected to load
        </h1>
        <p className="text-sm text-muted-foreground">
          Your connection to the server may be slow, or the app was updated
          while this page was open. You can reload to try again.
        </p>
        <Button onClick={() => window.location.reload()} className="mt-2">
          Retry
        </Button>
      </div>
    </div>
  );
}
