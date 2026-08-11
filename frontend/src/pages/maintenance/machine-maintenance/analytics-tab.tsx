/**
 * Analytics tab for the Machine Maintenance screen.
 *
 * Charts computed client-side from the day's list rows plus the month cost
 * series returned by /api/maintenance/machine.
 */
import { useMemo } from "react";
import { Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, XAxis, YAxis } from "recharts";
import { Card, CardContent } from "@/components/ui/card";
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import type { MachineMaintenanceRow } from "@/hooks/use-machine-maintenance";

const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const PRIMARY = "#2A4C7A";
const SECONDARY = "#627C50";

const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";
const CHART_HEIGHT = 260;

const costOf = (r: MachineMaintenanceRow) => (r.cost != null ? parseFloat(r.cost) || 0 : 0);
const fmtMoney = (n: number) => `${n.toFixed(2)}`;

type Slice = { name: string; value: number };

/** Sum a numeric value grouped by a key. */
function sumBy(
  rows: MachineMaintenanceRow[],
  keyOf: (r: MachineMaintenanceRow) => string | null,
  valueOf: (r: MachineMaintenanceRow) => number = costOf,
): Slice[] {
  const map = new Map<string, number>();
  for (const r of rows) {
    const k = keyOf(r) ?? "Unknown";
    map.set(k, (map.get(k) ?? 0) + valueOf(r));
  }
  return [...map.entries()]
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);
}

/** Count rows grouped by a key. */
function countBy(rows: MachineMaintenanceRow[], keyOf: (r: MachineMaintenanceRow) => string | null): Slice[] {
  return sumBy(rows, keyOf, () => 1);
}

const machineConfig = {
  value: { label: "Cost", color: PRIMARY },
} satisfies ChartConfig;

const jobConfig = {
  value: { label: "Jobs", color: SECONDARY },
} satisfies ChartConfig;

const trendConfig = {
  cost: { label: "Cost", color: PRIMARY },
  jobs: { label: "Jobs", color: SECONDARY },
} satisfies ChartConfig;

function ChartCard({ title, dateLabel, children }: { title: string; dateLabel: string; children: React.ReactNode }) {
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">{title}</h2>
        <span className="eyebrow">{dateLabel}</span>
      </div>
      <CardContent className="p-3 pt-4">{children}</CardContent>
    </Card>
  );
}

export function MachineMaintenanceAnalytics({
  rows,
  monthSeries,
  isLoading,
  dateLabel,
}: {
  rows: MachineMaintenanceRow[];
  monthSeries: { date: string; jobs: number; cost: string }[];
  isLoading: boolean;
  dateLabel: string;
}) {
  const costByMachine = useMemo(() => sumBy(rows, (r) => r.machineNumber ?? `Machine ${r.machineId}`), [rows]);
  const costByVendor = useMemo(() => sumBy(rows, (r) => r.vendor), [rows]);
  const jobsByMachine = useMemo(() => countBy(rows, (r) => r.machineNumber ?? `Machine ${r.machineId}`), [rows]);

  const monthStart = monthSeries.length > 0 ? `${monthSeries[0].date.slice(0, 7)}-01` : "";
  const monthEnd = monthSeries.length > 0 ? monthSeries[monthSeries.length - 1].date : "";
  const trend = useMemo(() => {
    if (!monthStart || !monthEnd) return [];
    const byDate = new Map(monthSeries.map((p) => [p.date, p]));
    const out: { day: string; cost: number; jobs: number }[] = [];
    const cur = new Date(monthStart + "T00:00:00");
    const end = new Date(monthEnd + "T00:00:00");
    while (cur <= end) {
      const iso = cur.toISOString().slice(0, 10);
      const p = byDate.get(iso);
      out.push({
        day: iso.slice(8),
        cost: p ? parseFloat(p.cost) || 0 : 0,
        jobs: p?.jobs ?? 0,
      });
      cur.setDate(cur.getDate() + 1);
    }
    return out;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [monthSeries, monthStart, monthEnd]);

  const isEmpty = !isLoading && rows.length === 0;
  if (isEmpty) {
    return (
      <Card>
        <CardContent className="px-5 py-10 text-center text-sm text-muted-foreground">
          No machine maintenance on {dateLabel} yet. Add one to see charts.
        </CardContent>
      </Card>
    );
  }

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
      {/* Cost by machine — where the maintenance spend goes */}
      <ChartCard title="Cost by machine" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={machineConfig} style={{ height: CHART_HEIGHT }}>
            <PieChart margin={{ top: 10, right: 10, bottom: 10, left: 10 }}>
              <Pie
                data={costByMachine}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                innerRadius={58}
                outerRadius={80}
                paddingAngle={1}
                stroke="#FFFFFF"
                strokeWidth={2}
                label={({ name, percent }) =>
                  percent * 100 >= 5 ? `${name} ${(percent * 100).toFixed(1)}%` : ""
                }
                labelLine={false}
              >
                {costByMachine.map((_, i) => (
                  <Cell key={i} fill={DYE[i % DYE.length]} />
                ))}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtMoney(Number(v))} />} />
            </PieChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Cost by vendor — external spend split */}
      <ChartCard title="Cost by vendor" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={machineConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={costByVendor} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={56} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtMoney(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={PRIMARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Jobs by machine — how often each machine needs work */}
      <ChartCard title="Jobs by machine" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={jobConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={jobsByMachine} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={40} allowDecimals={false} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v)} job${v === 1 ? "" : "s"}`} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={SECONDARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Month cost + jobs trend */}
      <ChartCard title="Maintenance trend (month)" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={trendConfig} style={{ height: CHART_HEIGHT }}>
            <LineChart data={trend} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="day" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={56} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v, name) => name === "jobs" ? `${v} job${v === 1 ? "" : "s"}` : fmtMoney(Number(v))} />} />
              <Line type="monotone" dataKey="cost" stroke={PRIMARY} strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="jobs" stroke={SECONDARY} strokeWidth={2} dot={false} />
              <ChartLegend content={<ChartLegendContent />} />
            </LineChart>
          </ChartContainer>
        )}
      </ChartCard>
    </div>
  );
}
