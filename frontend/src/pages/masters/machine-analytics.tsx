/**
 * Production Analytics sub-view for the Machines tab (issue #112).
 *
 * Shows each machine's fabric production since its needle/sinker change date
 * (toggle-switched), computed server-side from Fabric Production transactions.
 *
 * Design (ui-ux-pro-max): data-dense dashboard tuned for both mobile and
 * desktop using the TKT "Mass Balance" tokens — greige page, bleach cards,
 * vat chart workhorse, machine-grey secondary. Mobile-first: headline stat
 * strip stacks, donut drops to a legend-led summary, the table degrades to
 * card rows; desktop uses a 3-col grid with the full ranked table.
 */
import { useState } from "react";
import { useMemo } from "react";
import { Pie, PieChart, Cell, ResponsiveContainer } from "recharts";
import { TrendingUp, Package, Activity, Crown } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import { SortableHead } from "@/components/sortable-head";
import { useSort } from "@/hooks/use-sort";
import { useMachineAnalytics, type MachineAnalyticsBaseline, type MachineAnalyticsRow } from "@/hooks/use-machine-analytics";

// Chart colours from the TKT Mass Balance palette (see index.css tokens).
const CHART_COLORS = [
  "hsl(var(--chart-1))", // vat indigo
  "hsl(var(--chart-2))", // machine green
  "hsl(var(--chart-3))", // ochre
  "hsl(var(--chart-4))", // madder
  "hsl(var(--chart-5))", // signal
  "#8A93A5", // slate fallback for machines beyond the 5 token colours
];
const CHART_HEIGHT = 280;

const shareConfig = {
  value: { label: "Production (kg)", color: "hsl(var(--chart-1))" },
} satisfies ChartConfig;

const fmtKg = (n: number) => `${n.toLocaleString(undefined, { maximumFractionDigits: 0 })} kg`;
const fmtKgFull = (n: number) => `${n.toLocaleString(undefined, { maximumFractionDigits: 2 })} kg`;

/**
 * Recharts Pie label renderer: draws the slice's machine name outside the arc
 * for slices that are large enough to label (>=6%). Returns null otherwise, so
 * small slices stay unlabelled and the legend carries them.
 */
function renderOutsideLabel(props: Record<string, unknown>) {
  const { cx, cy, midAngle, outerRadius, name, percent } = props as {
    cx: number; cy: number; midAngle: number; outerRadius: number; name: string; percent: number;
  };
  if (percent * 100 < 6) return null;
  const RADIAN = Math.PI / 180;
  const radius = (typeof outerRadius === "number" ? outerRadius : 0) + 14;
  const x = cx + radius * Math.cos(-midAngle * RADIAN);
  const y = cy + radius * Math.sin(-midAngle * RADIAN);
  return (
    <text
      x={x}
      y={y}
      textAnchor={x > cx ? "start" : "end"}
      dominantBaseline="central"
      fill="currentColor"
      className="fill-muted-foreground"
      style={{ fontSize: 11, fontWeight: 600 }}
    >
      {name}
    </text>
  );
}


function BaselineToggle({
  value,
  onChange,
}: {
  value: MachineAnalyticsBaseline;
  onChange: (b: MachineAnalyticsBaseline) => void;
}) {
  return (
    <div
      className="inline-flex w-fit rounded-md border border-border bg-muted/40 p-0.5"
      role="group"
      aria-label="Production baseline"
    >
      {(["needle", "sinker"] as MachineAnalyticsBaseline[]).map((b) => {
        const active = value === b;
        return (
          <button
            key={b}
            type="button"
            onClick={() => onChange(b)}
            aria-pressed={active}
            className={
              "min-h-11 rounded px-4 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring sm:min-h-0 sm:px-3 sm:py-1.5 sm:text-xs " +
              (active
                ? "selvedge bg-background text-foreground shadow-sm"
                : "text-muted-foreground hover:text-foreground")
            }
          >
            {b === "needle" ? "Needle" : "Sinker"}
          </button>
        );
      })}
    </div>
  );
}

/** Key headline number. */
function StatCard({
  label,
  value,
  sub,
  icon: Icon,
}: {
  label: string;
  value: string;
  sub?: string;
  icon: React.ElementType;
}) {
  return (
    <Card className="overflow-hidden">
      <CardContent className="p-4">
        <div className="flex items-center justify-between gap-2">
          <p className="eyebrow">{label}</p>
          <Icon className="h-4 w-4 shrink-0 text-muted-foreground/50" />
        </div>
        <p className="selvedge-top num mt-2 pl-0 text-2xl font-semibold leading-none text-foreground">
          {value}
        </p>
        {sub && <p className="mt-1.5 text-xs text-muted-foreground">{sub}</p>}
      </CardContent>
    </Card>
  );
}

function ChartCard({ title, note, children }: { title: string; note?: string; children: React.ReactNode }) {
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">{title}</h2>
        {note && <span className="eyebrow">{note}</span>}
      </div>
      <CardContent className="p-3 pt-4">{children}</CardContent>
    </Card>
  );
}

/** Donut with per-slice machine labels, a centre total, and a companion legend. */
function ShareChart({ rows }: { rows: { name: string; value: number; zero: boolean }[] }) {
  const total = rows.reduce((s, r) => s + r.value, 0);
  const nonZero = rows.filter((r) => !r.zero);
  const chartData = nonZero.length ? nonZero : rows;

  const reducedMotion =
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  return (
    <div>
      <div className="relative">
        <ChartContainer className="w-full" config={shareConfig} style={{ height: CHART_HEIGHT }}>
          <ResponsiveContainer width="100%" height="100%">
            <PieChart margin={{ top: 20, right: 12, bottom: 20, left: 12 }}>
              
              {/* Centre total */}
              <text
                x="50%"
                y="47%"
                textAnchor="middle"
                dominantBaseline="middle"
                className="fill-foreground"
                style={{ fontSize: 22, fontWeight: 700, fontFamily: "var(--app-font-mono)" }}
              >
                {total.toLocaleString(undefined, { maximumFractionDigits: 0 })}
              </text>
              <text
                x="50%"
                y="56%"
                textAnchor="middle"
                dominantBaseline="middle"
                className="fill-muted-foreground"
                style={{ fontSize: 11, textTransform: "uppercase", letterSpacing: "0.1em" }}
              >
                kg total
              </text>

              <Pie
                data={chartData}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                innerRadius="52%"
                outerRadius="86%"
                paddingAngle={1.5}
                stroke="hsl(var(--background))"
                strokeWidth={2}
                isAnimationActive={!reducedMotion}
                label={(props: Record<string, unknown>) =>
                  renderOutsideLabel(props)
                }
                labelLine
              >
                {chartData.map((d, i) => (
                  <Cell key={d.name} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                ))}
              </Pie>

              <ChartTooltip
                content={<ChartTooltipContent formatter={(v) => fmtKgFull(Number(v))} />}
              />
            </PieChart>
          </ResponsiveContainer>
        </ChartContainer>
      </div>
      {/* Legend — the accessible counterpart (colour is never the only cue). */}
      <ul className="mt-2 space-y-1 px-1">
        {rows.map((r, i) => (
          <li key={r.name} className="flex items-center justify-between gap-2 text-xs">
            <span className="flex min-w-0 items-center gap-2 text-muted-foreground">
              <span
                aria-hidden
                className="h-2.5 w-2.5 shrink-0 rounded-full"
                style={{ backgroundColor: CHART_COLORS[i % CHART_COLORS.length] }}
              />
              <span className="truncate font-medium text-foreground">{r.name}</span>
              {r.zero && <span className="italic text-muted-foreground/70">no production</span>}
            </span>
            <span className="num shrink-0 tabular-nums text-muted-foreground">
              {fmtKg(r.value)}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

/** Mobile card list — the table degrades to readable cards on small screens. */
function MobileRows({ rows }: { rows: MachineAnalyticsRow[] }) {
  return (
    <ul className="divide-y divide-border sm:hidden">
      {rows.map((r, i) => {
        const zero = r.totalKg <= 0;
        return (
          <li key={r.machineId} className={`flex items-start gap-3 px-3 py-3 ${zero ? "opacity-70" : ""}`}>
            <span
              aria-hidden
              className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full"
              style={{ backgroundColor: CHART_COLORS[i % CHART_COLORS.length] }}
            />
            <div className="min-w-0 flex-1">
              <div className="flex items-baseline justify-between gap-2">
                <span className="truncate text-sm font-semibold text-foreground">{r.machineNumber}</span>
                <span className="num text-sm font-semibold text-foreground">{fmtKg(r.totalKg)}</span>
              </div>
              <p className="truncate text-xs text-muted-foreground">
                {r.machineName || "—"} · {r.humanizedDuration ?? "—"} since change
              </p>
              <div className="mt-1 flex flex-wrap gap-x-4 gap-y-0.5 text-xs text-muted-foreground">
                <span><span className="num">{r.totalRolls}</span> rolls</span>
                <span><span className="num">{r.kgPerRoll.toFixed(1)}</span> kg/roll</span>
                <span><span className="num">{r.transactionCount}</span> tx</span>
              </div>
            </div>
          </li>
        );
      })}
    </ul>
  );
}

/** Desktop table — hidden on small screens. */
function DesktopTable({
  rows,
  sort,
  onSort,
}: {
  rows: MachineAnalyticsRow[];
  sort: { key: string | null; dir: "asc" | "desc" };
  onSort: (key: string) => void;
}) {
  return (
    <div className="hidden overflow-x-auto sm:block">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left text-xs text-muted-foreground">
            <SortableHead label="Machine" sortKey="machineNumber" sort={sort} onSort={onSort} />
            <SortableHead label="Name" sortKey="machineName" sort={sort} onSort={onSort} />
            <SortableHead label="Kg" sortKey="totalKg" sort={sort} onSort={onSort} right />
            <SortableHead label="Rolls" sortKey="totalRolls" sort={sort} onSort={onSort} right />
            <SortableHead label="Kg/roll" sortKey="kgPerRoll" sort={sort} onSort={onSort} right />
            <SortableHead label="Transactions" sortKey="transactionCount" sort={sort} onSort={onSort} right />
            <SortableHead label="Change date" sortKey="changeDate" sort={sort} onSort={onSort} />
            <SortableHead label="Since" sortKey="daysSinceChange" sort={sort} onSort={onSort} right />
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => {
            const zero = r.totalKg <= 0;
            return (
              <tr key={r.machineId} className={`border-b last:border-0 ${zero ? "text-muted-foreground" : ""}`}>
                <td className="py-3 pr-4">
                  <span className="inline-flex items-center gap-2 font-semibold text-foreground">
                    <span
                      aria-hidden
                      className="h-2.5 w-2.5 rounded-full"
                      style={{ backgroundColor: CHART_COLORS[i % CHART_COLORS.length] }}
                    />
                    {r.machineNumber}
                  </span>
                </td>
                <td className="py-3 pr-4 text-muted-foreground">{r.machineName || "—"}</td>
                <td className="num py-3 pr-4 text-right font-semibold text-foreground">
                  {fmtKg(r.totalKg)}
                </td>
                <td className="num py-3 pr-4 text-right">{r.totalRolls}</td>
                <td className="num py-3 pr-4 text-right">{r.kgPerRoll.toFixed(1)}</td>
                <td className="num py-3 pr-4 text-right">{r.transactionCount}</td>
                <td className="num py-3 pr-4">{r.changeDate ?? "-"}</td>
                <td className="num py-3 text-right text-xs text-muted-foreground">
                  {r.humanizedDuration ?? "-"}
                  {r.daysSinceChange != null && (
                    <span className="ml-1 text-muted-foreground/70">({r.daysSinceChange}d)</span>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export function MachineAnalyticsView() {
  const [baseline, setBaseline] = useState<MachineAnalyticsBaseline>("needle");
  const { data, isLoading, isError, refetch } = useMachineAnalytics(baseline);

  const rows = data?.rows ?? [];

  // Client-side sortable columns; Machine ascending by default.
  const { sorted: sortedRows, sort, toggleSort } = useSort<
    MachineAnalyticsRow,
    "machineNumber" | "machineName" | "totalKg" | "totalRolls" | "kgPerRoll" | "transactionCount" | "changeDate" | "daysSinceChange"
  >(rows, {
    machineNumber: (r) => r.machineNumber,
    machineName: (r) => r.machineName ?? "",
    totalKg: (r) => r.totalKg,
    totalRolls: (r) => r.totalRolls,
    kgPerRoll: (r) => r.kgPerRoll,
    transactionCount: (r) => r.transactionCount,
    changeDate: (r) => r.changeDate ?? "",
    daysSinceChange: (r) => r.daysSinceChange ?? 0,
  }, { key: "machineNumber", dir: "asc" });

  const totalKg = useMemo(() => rows.reduce((s, r) => s + r.totalKg, 0), [rows]);
  const totalRolls = useMemo(() => rows.reduce((s, r) => s + r.totalRolls, 0), [rows]);
  const activeMachines = useMemo(() => rows.filter((r) => r.totalKg > 0).length, [rows]);
  const top = rows.length ? rows[0] : null; // already ranked most -> least by the API

  // Donut follows the same sort as the table (Machine ascending by default),
  // so chart slices and table rows stay in step.
  const donut = useMemo(
    () =>
      sortedRows.map((r) => ({
        name: r.machineNumber,
        value: r.totalKg,
        zero: r.totalKg <= 0,
      })),
    [sortedRows],
  );

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="eyebrow">Machine production analytics</p>
          <h3 className="mt-1 text-lg font-semibold leading-tight text-foreground">
            Production since {baseline === "needle" ? "needle" : "sinker"} change
          </h3>
          <p className="mt-1 text-xs text-muted-foreground">
            Fabric production per machine from its {baseline === "needle" ? "needle" : "sinker"}{" "}
            change date → {isLoading ? "…" : data ? `computed to ${data.computedTo}` : "-"}
            {data?.excludedCount ? ` · ${data.excludedCount} machine(s) without a date excluded` : ""}
          </p>
        </div>
        <BaselineToggle value={baseline} onChange={setBaseline} />
      </div>

      {isError && !data && (
        <Card>
          <CardContent className="flex flex-col items-start gap-3 px-5 py-6 text-sm">
            <p className="text-destructive">Couldn't load production analytics.</p>
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Retry
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Headline stats */}
      {data && (
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <StatCard label="Total production" value={fmtKgFull(totalKg)} sub="since change date" icon={TrendingUp} />
          <StatCard label="Total rolls" value={totalRolls.toLocaleString()} sub={`${rows.length} machines`} icon={Package} />
          <StatCard label="Machines producing" value={`${activeMachines} / ${rows.length}`} sub="with production in window" icon={Activity} />
          <StatCard
            label="Top machine"
            value={top ? top.machineNumber : "-"}
            sub={top ? `${fmtKg(top.totalKg)} since change` : "no production"}
            icon={Crown}
          />
        </div>
      )}

      {/* Donut + table — stacked vertically (share above, table below) */}
      {isLoading && (
        <div className="grid grid-cols-1 gap-4">
          {skeleton}
          {skeleton}
        </div>
      )}

      {!isLoading && data && (
        <div className="grid grid-cols-1 gap-4">
          {/* Kg-share donut + legend */}
          <ChartCard title="Production share" note={`total ${fmtKg(totalKg)}`}>
            <ShareChart rows={donut} />
          </ChartCard>

          {/* Ranked table (desktop) / card list (mobile) */}
          <ChartCard title="Production since change" note={`${data.machineCount} machine(s)`}>
            {rows.length === 0 ? (
              <p className="px-3 py-8 text-center text-sm text-muted-foreground">
                No machines with a {baseline} change date recorded.
              </p>
            ) : (
              <>
                <MobileRows rows={sortedRows} />
                <DesktopTable rows={sortedRows} sort={sort} onSort={toggleSort} />
              </>
            )}
          </ChartCard>
        </div>
      )}
    </div>
  );
}
