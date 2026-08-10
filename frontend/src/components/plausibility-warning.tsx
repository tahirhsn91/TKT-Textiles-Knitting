// ─── Plausibility warning UI ───────────────────────────────────────────────
// Two small presentational pieces shared across the daily-operation screens:
//   • PlausibilityWarnings   — the inline list shown in an add-dialog when a
//                              value looks abnormal (soft-warn + save anyway).
//   • PlausibilityListBanner — the top-of-page strip on a listing that counts
//                              abnormal unreconciled rows.
// Warn-only: neither blocks anything. Styling uses the app's Signal/madder
// tokens so a warning reads as attention, not error.

import { AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";
import type { PlausibilityWarning } from "@/lib/plausibility";

function fmt(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(3).replace(/\.?0+$/, "");
}

export function PlausibilityWarnings({
  warnings,
  className,
}: {
  warnings: PlausibilityWarning[];
  className?: string;
}) {
  if (warnings.length === 0) return null;
  return (
    <div
      className={cn(
        "selvedge rounded-md border border-signal/40 bg-signal/5 px-3 py-2.5",
        className,
      )}
      role="alert"
    >
      <div className="flex items-start gap-2">
        <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-signal" />
        <div className="space-y-1">
          <p className="text-sm font-semibold text-foreground">
            {warnings.length === 1
              ? "This value looks unusual"
              : `${warnings.length} values look unusual`}
          </p>
          <ul className="space-y-0.5">
            {warnings.map((w, i) => (
              <li key={`${w.field}-${i}`} className="text-xs text-muted-foreground">
                <span className="font-medium text-foreground">{w.label}:</span>{" "}
                <span className="num">{fmt(w.value)}</span>
                {w.source === "learned" ? (
                  <>
                    {" "}— typical range{" "}
                    <span className="num">{fmt(w.expectedLow)}</span>–
                    <span className="num">{fmt(w.expectedHigh)}</span>
                  </>
                ) : (
                  <>
                    {" "}— outside plausible range{" "}
                    <span className="num">{fmt(w.expectedLow)}</span>–
                    <span className="num">{fmt(w.expectedHigh)}</span>
                  </>
                )}
              </li>
            ))}
          </ul>
          <p className="text-xs text-muted-foreground">
            Double-check the entry. You can still save if it's correct.
          </p>
        </div>
      </div>
    </div>
  );
}

export function PlausibilityListBanner({
  abnormalCount,
  totalChecked,
  noun,
  className,
}: {
  abnormalCount: number;
  totalChecked: number;
  /** e.g. "production entries", "receipts", "deliveries" */
  noun: string;
  className?: string;
}) {
  if (abnormalCount <= 0) return null;
  return (
    <div
      className={cn(
        "selvedge flex items-center gap-2.5 rounded-md border border-signal/40 bg-signal/5 px-4 py-2.5 print:hidden",
        className,
      )}
      role="alert"
    >
      <AlertTriangle className="h-4 w-4 shrink-0 text-signal" />
      <p className="text-sm text-foreground">
        <span className="font-semibold num">{abnormalCount}</span>
        {" "}of{" "}
        <span className="num">{totalChecked}</span>
        {" "}unreconciled {noun} look abnormal — review before reconciliation.
      </p>
    </div>
  );
}
