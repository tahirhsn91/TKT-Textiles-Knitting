/**
 * Analytics tab for the Transactions screen.
 *
 * Charts are aggregated client-side from the SAME filtered rows the Entries
 * tab renders — no extra API call, because `GET /api/transactions` already
 * returns the summary rows, and the charts must reflect whatever the user has
 * selected in the filter bar. Aggregation keys off the categorical fields the
 * list carries (transaction type, party, location, fabric type, job), so the
 * charts are count-based; the list endpoint doesn't return monetary/quantity
 * aggregates, so amounts are not charted here (that would need a dedicated
 * aggregate endpoint).
 *
 * Charting stack: shadcn/ui chart components (Recharts under the hood),
 * already shipped in `components/ui/chart.tsx`.
 */
import { useMemo } from "react";
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, XAxis, YAxis } from "recharts";
import { Card, CardContent } from "@/components/ui/card";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import type { TransactionSummary, LookupItem, JobLookupItem } from "@workspace/api-client-react";

// Same palette as the dashboard / daily-production analytics; keep in step.
const PIE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const BAR = "#2A4C7A";
const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";
const CHART_HEIGHT = 260;

type Item = { name: string; value: number };

function sumBy(list: Item[]) {
  return [...list].sort((a, b) => b.value - a.value);
}

function countBy(
  rows: TransactionSummary[],
  keyOf: (r: TransactionSummary) => string | null,
): Item[] {
  const map = new Map<string, number>();
  for (const r of rows) {
    const k = keyOf(r) ?? "Unknown";
    map.set(k, (map.get(k) ?? 0) + 1);
  }
  return [...map.entries()].map(([name, value]) => ({ name, value }));
}

/** Group rows into a daily-series; falls back to monthly when the span is long. */
function byDate(rows: TransactionSummary[]): Item[] {
  if (rows.length === 0) return [];
  const map = new Map<string, number>();
  // Decide granularity from the actual min/max date in the filtered set.
  const dates = rows.map((r) => r.date).filter(Boolean) as string[];
  if (dates.length === 0) return [];
  const min = new Date(Math.min(...dates.map((d) => new Date(d).getTime())));
  const max = new Date(Math.max(...dates.map((d) => new Date(d).getTime())));
  const days = Math.round((max.getTime() - min.getTime()) / 86_400_000);
  const daily = days <= 45;
  for (const r of rows) {
    if (!r.date) continue;
    const key = daily ? r.date : r.date.slice(0, 7); // YYYY-MM or YYYY-MM-DD
    map.set(key, (map.get(key) ?? 0) + 1);
  }
  return [...map.entries()]
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
}

const barConfig = { value: { label: "Transactions", color: BAR } } satisfies ChartConfig;
const pieConfig = { value: { label: "Transactions" } } satisfies ChartConfig;

const nameOf = (list: { id: number; name: string }[] | undefined, id: number | null | undefined) =>
  id != null ? (list?.find((x) => x.id === id)?.name ?? String(id)) : null;

function ChartCard({ title, note, children }: { title: string; note: string; children: React.ReactNode }) {
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">{title}</h2>
        <span className="eyebrow">{note}</span>
      </div>
      <CardContent className="p-3 pt-4">{children}</CardContent>
    </Card>
  );
}

export function TransactionAnalytics({
  rows,
  isLoading,
  countLabel,
  transactionTypeMaster,
  partyMaster,
  locationMaster,
  fabricTypeMaster,
  jobMaster,
}: {
  rows: TransactionSummary[];
  isLoading: boolean;
  countLabel: string;
  transactionTypeMaster?: LookupItem[];
  partyMaster?: LookupItem[];
  locationMaster?: LookupItem[];
  fabricTypeMaster?: LookupItem[];
  jobMaster?: JobLookupItem[];
}) {
  const byType = useMemo(
    () => sumBy(countBy(rows, (r) => nameOf(transactionTypeMaster, r.transactionTypeId))),
    [rows, transactionTypeMaster],
  );
  const byParty = useMemo(
    () => sumBy(countBy(rows, (r) => nameOf(partyMaster, r.partyId))),
    [rows, partyMaster],
  );
  const byLocation = useMemo(
    () => sumBy(countBy(rows, (r) => nameOf(locationMaster, r.locationId))),
    [rows, locationMaster],
  );
  const byFabric = useMemo(
    () => sumBy(countBy(rows, (r) => nameOf(fabricTypeMaster, r.fabricTypeId))),
    [rows, fabricTypeMaster],
  );
  const byJob = useMemo(
    () => sumBy(countBy(rows, (r) => nameOf(jobMaster, r.jobId))),
    [rows, jobMaster],
  );
  const overTime = useMemo(() => byDate(rows), [rows]);

  const isEmpty = !isLoading && rows.length === 0;
  const fmt = (v: number) => `${Number(v)} tx`;

  if (isEmpty) {
    return (
      <Card>
        <CardContent className="px-5 py-10 text-center text-sm text-muted-foreground">
          No transactions to chart yet. Match the filters (or create a transaction) to see charts.
        </CardContent>
      </Card>
    );
  }

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
      {/* Transactions by party — who we transact with most */}
      <ChartCard title="Transactions by party" note={countLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={pieConfig} style={{ height: CHART_HEIGHT }}>
            <PieChart margin={{ top: 10, right: 10, bottom: 10, left: 10 }}>
              <Pie
                data={byParty}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                innerRadius={58}
                outerRadius={80}
                paddingAngle={1}
                stroke="#FFFFFF"
                strokeWidth={2}
                label={({ name, percent }) => (percent * 100 >= 5 ? `${name} ${(percent * 100).toFixed(0)}%` : "")}
                labelLine={false}
              >
                {byParty.map((_, i) => (
                  <Cell key={i} fill={PIE[i % PIE.length]} />
                ))}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmt(Number(v))} />} />
            </PieChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Transactions by type — which kind dominates */}
      <ChartCard title="Transactions by type" note={countLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={barConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byType} layout="vertical" margin={{ top: 4, right: 36, left: 8, bottom: 4 }}>
              <CartesianGrid stroke={AXIS_RULE} horizontal={false} />
              <XAxis type="number" tick={AXIS_TICK} tickLine={false} axisLine={false} allowDecimals={false} />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fontSize: 11, fill: "#1F221C" }}
                tickLine={false}
                axisLine={{ stroke: AXIS_RULE }}
                width={120}
              />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmt(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={BAR} radius={[0, 2, 2, 0]} barSize={16} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Transactions over time — daily (or monthly for long spans) trend */}
      <ChartCard title="Transactions over time" note={countLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={barConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={overTime} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} tickFormatter={(v) => v.slice(-5)} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={44} allowDecimals={false} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmt(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={BAR} radius={[2, 2, 0, 0]} barSize={18} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Transactions by location */}
      <ChartCard title="Transactions by location" note={countLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={barConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byLocation} layout="vertical" margin={{ top: 4, right: 36, left: 8, bottom: 4 }}>
              <CartesianGrid stroke={AXIS_RULE} horizontal={false} />
              <XAxis type="number" tick={AXIS_TICK} tickLine={false} axisLine={false} allowDecimals={false} />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fontSize: 11, fill: "#1F221C" }}
                tickLine={false}
                axisLine={{ stroke: AXIS_RULE }}
                width={120}
              />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmt(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={BAR} radius={[0, 2, 2, 0]} barSize={16} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Transactions by fabric type */}
      <ChartCard title="Transactions by fabric type" note={countLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={barConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byFabric} layout="vertical" margin={{ top: 4, right: 36, left: 8, bottom: 4 }}>
              <CartesianGrid stroke={AXIS_RULE} horizontal={false} />
              <XAxis type="number" tick={AXIS_TICK} tickLine={false} axisLine={false} allowDecimals={false} />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fontSize: 11, fill: "#1F221C" }}
                tickLine={false}
                axisLine={{ stroke: AXIS_RULE }}
                width={120}
              />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmt(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={BAR} radius={[0, 2, 2, 0]} barSize={16} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Transactions by job */}
      <ChartCard title="Transactions by job" note={countLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={barConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byJob} layout="vertical" margin={{ top: 4, right: 36, left: 8, bottom: 4 }}>
              <CartesianGrid stroke={AXIS_RULE} horizontal={false} />
              <XAxis type="number" tick={AXIS_TICK} tickLine={false} axisLine={false} allowDecimals={false} />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fontSize: 11, fill: "#1F221C" }}
                tickLine={false}
                axisLine={{ stroke: AXIS_RULE }}
                width={120}
              />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmt(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={BAR} radius={[0, 2, 2, 0]} barSize={16} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>
    </div>
  );
}
