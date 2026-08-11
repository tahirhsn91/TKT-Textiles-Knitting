// ─── Plausibility warning UI ───────────────────────────────────────────────
// Two small presentational pieces shared across the daily-operation screens:
//   • PlausibilityWarnings   — the inline list shown in an add-dialog when a
//                              value looks abnormal (soft-warn + save anyway).
//   • PlausibilityListBanner — the top-of-page strip on a listing that counts
//                              abnormal unreconciled rows.
// Warn-only: neither blocks anything. Styling uses the app's Signal/madder
// tokens so a warning reads as attention, not error.

import { useState } from "react";
import { AlertTriangle, ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import type { PlausibilityWarning, CombinationFinding } from "@/lib/plausibility";

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
  combinationFindings,
  className,
}: {
  abnormalCount: number;
  totalChecked: number;
  /** e.g. "production entries", "receipts", "deliveries" */
  noun: string;
  /** Contextual combination totals flagged (production, receipt, delivery). */
  combinationFindings?: CombinationFinding[];
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const combos = combinationFindings ?? [];
  const comboCount = combos.length;

  // Nothing to say if neither rows nor combinations are abnormal.
  if (abnormalCount <= 0 && comboCount <= 0) return null;

  // The same bad day shows up under many combinations; group by the specific
  // key instance (context) and keep the single most-severe/highest finding so
  // the list stays readable instead of dumping dozens of overlapping views.
  const byContext = new Map<string, CombinationFinding>();
  for (const c of combos) {
    const prev = byContext.get(c.context);
    if (!prev || c.value > prev.value) byContext.set(c.context, c);
  }
  const grouped = [...byContext.values()].sort((a, b) => b.value - a.value);

  return (
    <div
      className={cn(
        "selvedge rounded-md border border-signal/40 bg-signal/5 px-4 py-2.5 print:hidden",
        className,
      )}
      role="alert"
    >
      <div className="flex items-start gap-2.5">
        <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-signal" />
        <div className="flex-1 space-y-1">
          {abnormalCount > 0 && (
            <p className="text-sm text-foreground">
              <span className="font-semibold num">{abnormalCount}</span>
              {" "}of{" "}
              <span className="num">{totalChecked}</span>
              {" "}unreconciled {noun} look abnormal — review before reconciliation.
            </p>
          )}

          {grouped.length > 0 && (
            <div>
              <button
                type="button"
                onClick={() => setOpen((o) => !o)}
                className="flex items-center gap-1 text-sm text-foreground hover:text-signal"
                aria-expanded={open}
              >
                <span className="font-semibold num">{grouped.length}</span>
                {" "}weight combination{grouped.length === 1 ? "" : "s"} look abnormal
                <ChevronDown
                  className={cn("h-3.5 w-3.5 transition-transform", open && "rotate-180")}
                />
              </button>

              {open && (
                <ul className="mt-1.5 space-y-1 border-l border-signal/30 pl-3">
                  {grouped.map((c, i) => (
                    <li key={`${c.context}-${i}`} className="text-xs text-muted-foreground">
                      <span className="font-medium text-foreground">{c.combination}</span>
                      {" — "}
                      <span>{c.context}</span>
                      {": total "}
                      <span className="num font-medium text-foreground">{c.value.toFixed(2)}</span>
                      {" kg (typical "}
                      <span className="num">{c.expectedLow.toFixed(0)}</span>–
                      <span className="num">{c.expectedHigh.toFixed(0)}</span>
                      {")"}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
