/**
 * Analytics tab for the Factory Maintenance screen.
 *
 * Charts computed client-side from the day's list rows plus the month job
 * series returned by /api/maintenance/factory.
 */
import { useMemo } from "react";
import { Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, XAxis, YAxis } from "recharts";
import { Card, CardContent } from "@/components/ui/card";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import type { FactoryMaintenanceRow } from "@/hooks/use-factory-maintenance";

const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const PRIMARY = "#2A4C7A";

const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";
const CHART_HEIGHT = 260;

type Slice = { name: string; value: number };

/** Count rows grouped by a key. */
function countBy(rows: FactoryMaintenanceRow[], keyOf: (r: FactoryMaintenanceRow) => string | null): Slice[] {
  const map = new Map<string, number>();
  for (const r of rows) {
    const k = keyOf(r) ?? "Unknown";
    map.set(k, (map.get(k) ?? 0) + 1);
  }
  return [...map.entries()]
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);
}

const jobsConfig = {
  value: { label: "Jobs", color: PRIMARY },
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

export function FactoryMaintenanceAnalytics({
  rows,
  monthSeries,
  isLoading,
  dateLabel,
}: {
  rows: FactoryMaintenanceRow[];
  monthSeries: { date: string; jobs: number }[];
  isLoading: boolean;
  dateLabel: string;
}) {
  const jobsByCategory = useMemo(() => countBy(rows, (r) => r.category), [rows]);

  const monthStart = monthSeries.length > 0 ? `${monthSeries[0].date.slice(0, 7)}-01` : "";
  const monthEnd = monthSeries.length > 0 ? monthSeries[monthSeries.length - 1].date : "";
  const trend = useMemo(() => {
    if (!monthStart || !monthEnd) return [];
    const byDate = new Map(monthSeries.map((p) => [p.date, p]));
    const out: { day: string; jobs: number }[] = [];
    const cur = new Date(monthStart + "T00:00:00");
    const end = new Date(monthEnd + "T00:00:00");
    while (cur <= end) {
      const iso = cur.toISOString().slice(0, 10);
      out.push({ day: iso.slice(8), jobs: byDate.get(iso)?.jobs ?? 0 });
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
          No factory maintenance on {dateLabel} yet. Add one to see charts.
        </CardContent>
      </Card>
    );
  }

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
      {/* Jobs by category — pie */}
      <ChartCard title="Jobs by category" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={jobsConfig} style={{ height: CHART_HEIGHT }}>
            <PieChart margin={{ top: 10, right: 10, bottom: 10, left: 10 }}>
              <Pie
                data={jobsByCategory}
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
                {jobsByCategory.map((_, i) => (
                  <Cell key={i} fill={DYE[i % DYE.length]} />
                ))}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v)} job${v === 1 ? "" : "s"}`} />} />
            </PieChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Jobs by category — bar */}
      <ChartCard title="Jobs by category" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={jobsConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={jobsByCategory} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={40} allowDecimals={false} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v)} job${v === 1 ? "" : "s"}`} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={PRIMARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Month jobs trend */}
      <ChartCard title="Factory maintenance trend (month)" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full" config={jobsConfig} style={{ height: CHART_HEIGHT }}>
            <LineChart data={trend} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="day" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={40} allowDecimals={false} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v)} job${v === 1 ? "" : "s"}`} />} />
              <Line type="monotone" dataKey="jobs" stroke={PRIMARY} strokeWidth={2} dot={false} />
            </LineChart>
          </ChartContainer>
        )}
      </ChartCard>
    </div>
  );
}
