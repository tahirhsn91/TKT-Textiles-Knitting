// ─── Abnormal data tab ─────────────────────────────────────────────────────
// A shared "Abnormal" tab for the daily-operation screens (production, deposit
// receipts... actually production / yarn receipts / daily deliveries). It
// renders the plausibility validator's findings — abnormal rows and abnormal
// contextual combination totals — as reviewable error details.
//
// Warn-only and read-only: it never edits data, it just surfaces what the
// validator flagged so a supervisor can investigate before reconciliation.

import { AlertTriangle, ShieldCheck, Pencil } from "lucide-react";
import type { ListValidationResult } from "@/lib/plausibility";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

function fmt(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(3).replace(/\.?0+$/, "");
}

function SourceBadge({ source }: { source: "learned" | "hard_cap" }) {
  return source === "learned" ? (
    <Badge variant="outline" className="border-signal/40 bg-signal/10 text-signal">learned</Badge>
  ) : (
    <Badge variant="outline" className="border-slate-500/40 bg-muted text-muted-foreground">physical limit</Badge>
  );
}

export function AbnormalDataTab({
  plausibility,
  noun,
  onOpen,
}: {
  /** The validator result for this date; null/undefined when unavailable. */
  plausibility: ListValidationResult | null | undefined;
  /** Singular noun for the row type, e.g. "production entry", "receipt", "delivery". */
  noun: string;
  /** Called with the record id when the user wants to open / fix it in the edit popup. */
  onOpen?: (id: number) => void;
}) {
  const rows = plausibility?.rows ?? [];
  const combos = plausibility?.combinationFindings ?? [];
  const totalChecked = plausibility?.totalChecked ?? 0;

  if (!plausibility || (rows.length === 0 && combos.length === 0)) {
    return (
      <Card className="overflow-hidden">
        <CardContent className="flex flex-col items-center gap-2 py-12 text-center">
          <ShieldCheck className="h-8 w-8 text-emerald-600" />
          <p className="text-sm font-medium text-foreground">No abnormal data</p>
          <p className="max-w-sm text-xs text-muted-foreground">
            Every unreconciled {noun} for this date is within its expected range.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Abnormal rows */}
      {rows.length > 0 && (
        <Card className="overflow-hidden">
          <div className="flex items-center justify-between border-b px-5 py-3.5">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-foreground">
              <AlertTriangle className="h-4 w-4 text-signal" />
              Abnormal {noun}s
            </h2>
            <span className="eyebrow">
              {rows.length} of {totalChecked}
            </span>
          </div>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead className="eyebrow h-11 px-5">ID</TableHead>
                  <TableHead className="eyebrow h-11">Field</TableHead>
                  <TableHead className="eyebrow h-11">Entered</TableHead>
                  <TableHead className="eyebrow h-11">Expected range</TableHead>
                  <TableHead className="eyebrow h-11">Source</TableHead>
                  <TableHead className="eyebrow h-11">Reason</TableHead>
                  {onOpen && <TableHead className="eyebrow h-11 text-right">Action</TableHead>}
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((r) =>
                  r.warnings.map((w, wi) => (
                    <TableRow key={`${r.id}-${w.field}`} className="hover:bg-transparent">
                      {wi === 0 && (
                        <TableCell className="px-5 num" rowSpan={r.warnings.length}>{r.id}</TableCell>
                      )}
                      <TableCell className="font-medium text-foreground">{w.label}</TableCell>
                      <TableCell className="num text-signal">{fmt(w.value)}</TableCell>
                      <TableCell className="num text-muted-foreground">
                        {fmt(w.expectedLow)}–{fmt(w.expectedHigh)}
                      </TableCell>
                      <TableCell><SourceBadge source={w.source} /></TableCell>
                      <TableCell className="text-xs text-muted-foreground">{w.reason}</TableCell>
                      {wi === 0 && onOpen && (
                        <TableCell className="text-right" rowSpan={r.warnings.length}>
                          <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => onOpen(r.id)}
                            aria-label={`Open ${noun} ${r.id} to fix`}
                          >
                            <Pencil className="mr-1.5 h-3.5 w-3.5" />
                            Fix
                          </Button>
                        </TableCell>
                      )}
                    </TableRow>
                  )),
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      {/* Abnormal combination totals */}
      {combos.length > 0 && (
        <Card className="overflow-hidden">
          <div className="flex items-center justify-between border-b px-5 py-3.5">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-foreground">
              <AlertTriangle className="h-4 w-4 text-signal" />
              Abnormal weight combinations
            </h2>
            <span className="eyebrow">{combos.length}</span>
          </div>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead className="eyebrow h-11 px-5">Combination</TableHead>
                  <TableHead className="eyebrow h-11">Context</TableHead>
                  <TableHead className="eyebrow h-11">Total</TableHead>
                  <TableHead className="eyebrow h-11">Expected range</TableHead>
                  <TableHead className="eyebrow h-11">Source</TableHead>
                  <TableHead className="eyebrow h-11">Reason</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {combos.map((c, i) => (
                  <TableRow key={`${c.combination}-${c.context}-${i}`} className="hover:bg-transparent">
                    <TableCell className="px-5 font-medium text-foreground">{c.combination}</TableCell>
                    <TableCell className="text-xs text-muted-foreground">{c.context}</TableCell>
                    <TableCell className="num text-signal">{fmt(c.value)}</TableCell>
                    <TableCell className="num text-muted-foreground">
                      {fmt(c.expectedLow)}–{fmt(c.expectedHigh)}
                    </TableCell>
                    <TableCell><SourceBadge source={c.source} /></TableCell>
                    <TableCell className="text-xs text-muted-foreground">{c.reason}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
