import { useEffect, useState } from "react";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";

/**
 * PageLoadingSkeleton — the loading placeholder shown in the CONTENT AREA
 * while a lazy route chunk downloads.
 *
 * It mirrors the standard page scaffold (eyebrow, 1.75rem title on a hairline
 * rule, then card/table blocks) so the swap from skeleton to real page is a
 * subtle, non-jarring transition. The chrome around it (sidebar + top bar) is
 * NOT part of this — it mounts once in the top-level Layout and never blinks.
 *
 * Like the old SuspenseFallback, it also guards against an infinite skeleton:
 * if the lazy chunk neither resolves nor rejects (stalled/404 chunk after a
 * redeploy), it swaps to a "taking too long" message with a Retry after
 * `timeoutMs`. A plain re-render can't re-attempt the failed promise, so the
 * Retry does a fresh full reload — same guarantee as before, minus the page
 * reload flicker for the common fast case.
 */
export function PageLoadingSkeleton({ timeoutMs = 10000 }: { timeoutMs?: number }) {
  const [timedOut, setTimedOut] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setTimedOut(true), timeoutMs);
    return () => clearTimeout(timer);
  }, [timeoutMs]);

  if (timedOut) {
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

  return (
    <div className="flex flex-col gap-6">
      <header className="border-b pb-5">
        <Skeleton className="h-3 w-24" />
        <Skeleton className="mt-3 h-7 w-52" />
        <Skeleton className="mt-3 h-4 w-80 max-w-full" />
      </header>

      {/* Toolbar / filter row */}
      <div className="flex flex-wrap items-center gap-3">
        <Skeleton className="h-10 w-40" />
        <Skeleton className="h-10 w-40" />
        <Skeleton className="ml-auto h-10 w-28" />
      </div>

      {/* Card block */}
      <div className="rounded-lg border bg-card">
        {/* header row */}
        <div className="flex items-center justify-between border-b px-5 py-4">
          <Skeleton className="h-5 w-40" />
          <Skeleton className="h-8 w-24" />
        </div>
        {/* fake table rows */}
        <div className="space-y-4 p-5">
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-11/12" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-4/5" />
        </div>
      </div>

      {/* secondary cards for dashboard-style pages */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Skeleton className="h-52 w-full rounded-lg" />
        <Skeleton className="h-52 w-full rounded-lg" />
      </div>
    </div>
  );
}
