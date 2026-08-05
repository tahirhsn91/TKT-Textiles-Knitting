/**
 * Analytics tab for the Advances screen.
 *
 * Charts computed client-side from the already-filtered advance list
 * (employee, month, and year filters from the History tab apply here too).
 */
import { NUM_DECIMALS } from "@/lib/format";
import { useMemo } from "react";
import {
  Bar, BarChart, CartesianGrid, Line, LineChart, XAxis, YAxis,
} from "recharts";
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

const PRIMARY = "#2A4C7A";
const SECONDARY = "#627C50";

const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";

const CHART_HEIGHT = 260;

export interface AdvanceAnalyticsRow {
  id: number;
  employeeId: number;
  employeeName: string;
  date: string; // YYYY-MM-DD
  amount: string;
  notes: string | null;
}

const amount = (a: AdvanceAnalyticsRow) => parseFloat(a.amount) || 0;

const dailyConfig = {
  amount: { label: "Advance (Rs)", color: PRIMARY },
} satisfies ChartConfig;

const byEmployeeConfig = {
  amount: { label: "Advance (Rs)", color: SECONDARY },
} satisfies ChartConfig;

const fmtRs = (n: number) => n.toLocaleString("en-IN", { maximumFractionDigits: 2 });

function ChartCard({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">{title}</h2>
        {subtitle && <span className="eyebrow">{subtitle}</span>}
      </div>
      <CardContent className="p-3 pt-4">{children}</CardContent>
    </Card>
  );
}

export function AdvancesAnalytics({
  advances,
  month,
  year,
  isLoading,
}: {
  advances: AdvanceAnalyticsRow[];
  month: string; // 1-12
  year: string;
  isLoading: boolean;
}) {
  const monthLabel = new Date(Number(year), Number(month) - 1, 1).toLocaleString("en-US", {
    month: "long",
    year: "numeric",
  });

  // KPI strip
  const kpis = useMemo(() => {
    const total = advances.reduce((s, a) => s + amount(a), 0);
    const count = advances.length;
    const avg = count > 0 ? total / count : 0;
    const max = advances.reduce((m, a) => Math.max(m, amount(a)), 0);
    return { total, count, avg, max };
  }, [advances]);

  // Daily series, gap-filled across the whole month (days with no advance = 0)
  const daily = useMemo(() => {
    const daysInMonth = new Date(Number(year), Number(month), 0).getDate();
    const byDay = new Map<number, number>();
    for (const a of advances) {
      const day = parseInt(a.date.slice(8, 10), 10);
      byDay.set(day, (byDay.get(day) ?? 0) + amount(a));
    }
    return Array.from({ length: daysInMonth }, (_, i) => ({
      day: i + 1,
      amount: byDay.get(i + 1) ?? 0,
    }));
  }, [advances, month, year]);

  // By employee (meaningful when the filter is "All Employees")
  const byEmployee = useMemo(() => {
    const map = new Map<string, number>();
    for (const a of advances) {
      map.set(a.employeeName, (map.get(a.employeeName) ?? 0) + amount(a));
    }
    return [...map.entries()]
      .map(([name, value]) => ({ name, amount: value }))
      .sort((a, b) => b.amount - a.amount);
  }, [advances]);

  if (isLoading) {
    return (
      <div className="grid gap-4 lg:grid-cols-2">
        {[1, 2, 3, 4].map((i) => (
          <Card key={i} className="overflow-hidden">
            <CardContent className="p-6">
              <Skeleton className="h-40 w-full" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      {/* KPI strip */}
      <Card className="overflow-hidden lg:col-span-2">
        <div className="grid grid-cols-2 divide-x divide-border sm:grid-cols-4">
          <div className="px-5 py-4">
            <p className="eyebrow">Total advances</p>
            <p className="num mt-1 text-2xl font-semibold leading-none">{fmtRs(kpis.total)}</p>
            <p className="mt-1.5 text-xs text-muted-foreground">{monthLabel}</p>
          </div>
          <div className="px-5 py-4">
            <p className="eyebrow">Advance count</p>
            <p className="num mt-1 text-2xl font-semibold leading-none">{kpis.count}</p>
            <p className="mt-1.5 text-xs text-muted-foreground">records in month</p>
          </div>
          <div className="px-5 py-4">
            <p className="eyebrow">Average advance</p>
            <p className="num mt-1 text-2xl font-semibold leading-none">{fmtRs(kpis.avg)}</p>
            <p className="mt-1.5 text-xs text-muted-foreground">per record</p>
          </div>
          <div className="px-5 py-4">
            <p className="eyebrow">Largest advance</p>
            <p className="num mt-1 text-2xl font-semibold leading-none">{fmtRs(kpis.max)}</p>
            <p className="mt-1.5 text-xs text-muted-foreground">single record</p>
          </div>
        </div>
      </Card>

      {/* Daily trend */}
      <ChartCard title="Advances by day" subtitle={monthLabel}>
        <ChartContainer config={dailyConfig} className="w-full aspect-auto" style={{ height: CHART_HEIGHT }}>
          <LineChart data={daily} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
            <CartesianGrid vertical={false} stroke={AXIS_RULE} />
            <XAxis dataKey="day" tick={AXIS_TICK} tickLine={false} axisLine={false} />
            <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={48} />
            <ChartTooltip content={<ChartTooltipContent />} />
            <ChartLegend content={<ChartLegendContent />} />
            <Line
              type="monotone"
              dataKey="amount"
              stroke={PRIMARY}
              strokeWidth={2}
              dot={{ r: 2 }}
              activeDot={{ r: 4 }}
            />
          </LineChart>
        </ChartContainer>
      </ChartCard>

      {/* By employee (or top advances when a single employee is selected) */}
      <ChartCard
        title={byEmployee.length > 1 ? "Advances by employee" : "Advances by day (bars)"}
        subtitle={monthLabel}
      >
        <ChartContainer config={byEmployeeConfig} className="w-full aspect-auto" style={{ height: CHART_HEIGHT }}>
          {byEmployee.length > 1 ? (
            <BarChart data={byEmployee} layout="vertical" margin={{ top: 4, right: 24, left: 8, bottom: 0 }}>
              <CartesianGrid horizontal={false} stroke={AXIS_RULE} />
              <XAxis type="number" tick={AXIS_TICK} tickLine={false} axisLine={false} />
              <YAxis
                type="category"
                dataKey="name"
                tick={AXIS_TICK}
                tickLine={false}
                axisLine={false}
                width={96}
              />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ChartLegend content={<ChartLegendContent />} />
              <Bar dataKey="amount" fill={SECONDARY} radius={[0, 3, 3, 0]} barSize={14} />
            </BarChart>
          ) : (
            <BarChart data={daily} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid vertical={false} stroke={AXIS_RULE} />
              <XAxis dataKey="day" tick={AXIS_TICK} tickLine={false} axisLine={false} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={48} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ChartLegend content={<ChartLegendContent />} />
              <Bar dataKey="amount" fill={SECONDARY} radius={[3, 3, 0, 0]} barSize={8} />
            </BarChart>
          )}
        </ChartContainer>
      </ChartCard>
    </div>
  );
}
