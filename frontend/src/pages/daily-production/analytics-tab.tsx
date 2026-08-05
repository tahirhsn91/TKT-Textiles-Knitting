/**
 * Analytics tab for the Daily Production screen.
 *
 * Charts for a SINGLE selected date, aggregated client-side from the same
 * summary rows the Entries tab renders — no extra API call, because
 * `GET /api/daily-production?date=` already returns machine / employee /
 * party / shift / rollCount / totalProduction per header. Issue #33.
 *
 * Charting stack: shadcn/ui chart components (Recharts under the hood),
 * already shipped in `components/ui/chart.tsx`.
 */
import { NUM_DECIMALS } from "@/lib/format";
import { useMemo } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  XAxis,
  YAxis,
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
import type { DailyProductionSummaryRow } from "@/hooks/use-daily-production";

// Same palette as the dashboard widgets; keep in step if those move.
const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const MORNING = "#2A4C7A";
const NIGHT = "#C8891E";
const MACHINE = "#2A4C7A";
const EMPLOYEE = "#AB3F4C";
const ROLLS = "#627C50";

const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";

/** Uniform chart body height — keeps every card in a grid row the same size. */
const CHART_HEIGHT = 260;

const kg = (r: DailyProductionSummaryRow) => parseFloat(r.totalProduction) || 0;
const fmtKg = (n: number) => `${n.toFixed(NUM_DECIMALS)} kg`;

type Slice = { name: string; value: number };
type MachineShift = { machine: string; Morning: number; Night: number };

/**
 * Sum a numeric row field by a row key, descending. Null keys fall under
 * "Unknown". `valueOf` defaults to weight, but any numeric field works — the
 * rolls-by-machine chart uses `rollCount`.
 */
function sumBy(
  rows: DailyProductionSummaryRow[],
  keyOf: (r: DailyProductionSummaryRow) => string | null,
  valueOf: (r: DailyProductionSummaryRow) => number = kg,
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

/** Per-machine Morning/Night totals for the grouped comparison bar chart. */
function machineByShift(rows: DailyProductionSummaryRow[]): MachineShift[] {
  const map = new Map<string, { Morning: number; Night: number }>();
  for (const r of rows) {
    const name = r.machineName ?? "Unknown";
    const cur = map.get(name) ?? { Morning: 0, Night: 0 };
    cur[r.shift] += kg(r);
    map.set(name, cur);
  }
  return [...map.entries()].map(([machine, v]) => ({ machine, ...v }));
}

const productionConfig = {
  production: { label: "Production (kg)", color: MACHINE },
} satisfies ChartConfig;

const employeeConfig = {
  production: { label: "Production (kg)", color: EMPLOYEE },
} satisfies ChartConfig;

const rollsConfig = {
  rolls: { label: "Rolls", color: ROLLS },
} satisfies ChartConfig;

const shiftConfig = {
  Morning: { label: "Morning", color: MORNING },
  Night: { label: "Night", color: NIGHT },
} satisfies ChartConfig;

function ChartCard({
  title,
  dateLabel,
  children,
}: {
  title: string;
  dateLabel: string;
  children: React.ReactNode;
}) {
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

export function ProductionAnalytics({
  rows,
  isLoading,
  dateLabel,
}: {
  rows: DailyProductionSummaryRow[];
  isLoading: boolean;
  dateLabel: string;
}) {
  const byMachine = useMemo(() => sumBy(rows, (r) => r.machineName), [rows]);
  const byShift = useMemo(() => sumBy(rows, (r) => r.shift), [rows]);
  const byParty = useMemo(() => sumBy(rows, (r) => r.partyName), [rows]);
  const byEmployee = useMemo(() => sumBy(rows, (r) => r.employeeName), [rows]);
  const byRolls = useMemo(
    () => sumBy(rows, (r) => r.machineName, (r) => r.rollCount),
    [rows],
  );
  const machineShift = useMemo(() => machineByShift(rows), [rows]);

  const isEmpty = !isLoading && rows.length === 0;

  if (isEmpty) {
    return (
      <Card>
        <CardContent className="px-5 py-10 text-center text-sm text-muted-foreground">
          Nothing recorded for {dateLabel} yet. Add an entry to see charts.
        </CardContent>
      </Card>
    );
  }

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
      {/* Production by machine — which machines carried the load */}
      <ChartCard title="Production by machine" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={productionConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byMachine} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={MACHINE} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Shift split — Morning vs Night balance */}
      <ChartCard title="Production by shift" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={shiftConfig} style={{ height: CHART_HEIGHT }}>
            <PieChart margin={{ top: 10, right: 10, bottom: 10, left: 10 }}>
              <Pie
                data={byShift}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                innerRadius={58}
                outerRadius={80}
                paddingAngle={1}
                stroke="#FFFFFF"
                strokeWidth={2}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(NUM_DECIMALS)}%`}
                labelLine={false}
              >
                {byShift.map((s) => (
                  <Cell key={s.name} fill={s.name === "Morning" ? MORNING : NIGHT} />
                ))}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} />
            </PieChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Party split — who we produced for */}
      <ChartCard title="Production by party" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={productionConfig} style={{ height: CHART_HEIGHT }}>
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
                label={({ name, percent }) =>
                  percent * 100 >= 5 ? `${name} ${(percent * 100).toFixed(NUM_DECIMALS)}%` : ""
                }
                labelLine={false}
              >
                {byParty.map((_, i) => (
                  <Cell key={i} fill={DYE[i % DYE.length]} />
                ))}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} />
            </PieChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Employee ranking — top employees by kg */}
      <ChartCard title="Employee ranking" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={employeeConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byEmployee} layout="vertical" margin={{ top: 4, right: 32, left: 8, bottom: 4 }}>
              <CartesianGrid stroke={AXIS_RULE} horizontal={false} />
              <XAxis type="number" tick={AXIS_TICK} tickLine={false} axisLine={false} />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fontSize: 11, fill: "#1F221C" }}
                tickLine={false}
                axisLine={{ stroke: AXIS_RULE }}
                width={110}
              />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={EMPLOYEE} radius={[0, 2, 2, 0]} barSize={14} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Machine output by shift — grouped comparison */}
      <ChartCard title="Machine output by shift" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={shiftConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={machineShift} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="machine" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <ChartLegend content={<ChartLegendContent />} />
              <Bar dataKey="Morning" fill={MORNING} radius={[2, 2, 0, 0]} barSize={12} />
              <Bar dataKey="Night" fill={NIGHT} radius={[2, 2, 0, 0]} barSize={12} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Rolls by machine — roll count, the other side of the weight picture */}
      <ChartCard title="Rolls by machine" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={rollsConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byRolls} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} allowDecimals={false} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v)} rolls`} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={ROLLS} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>
    </div>
  );
}
