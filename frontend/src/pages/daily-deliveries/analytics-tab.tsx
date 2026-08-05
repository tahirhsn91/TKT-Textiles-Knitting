/**
 * Analytics tab for the Daily Deliveries screen.
 *
 * Charts computed client-side from one `/api/daily-deliveries?date=` summary
 * plus a month series endpoint — same family pattern as yarn receipts.
 */
import { NUM_DECIMALS } from "@/lib/format";
import { useMemo } from "react";
import { Bar, BarChart, CartesianGrid, Line, LineChart, Pie, PieChart, Cell, XAxis, YAxis } from "recharts";
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
import type { DailyDeliveryRow } from "@/hooks/use-daily-deliveries";

const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const PRIMARY = "#2A4C7A";
const SECONDARY = "#627C50";

const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";

const CHART_HEIGHT = 260;

const kg = (r: DailyDeliveryRow) => parseFloat(r.netWeight) || 0;
const fmtKg = (n: number) => `${n.toFixed(NUM_DECIMALS)} kg`;

type Slice = { name: string; value: number };

function sumBy(
  rows: DailyDeliveryRow[],
  keyOf: (r: DailyDeliveryRow) => string | null,
  valueOf: (r: DailyDeliveryRow) => number = kg,
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

/** Average kg per roll, grouped by a key — delivery consistency signal. */
function avgKgPerRollBy(
  rows: DailyDeliveryRow[],
  keyOf: (r: DailyDeliveryRow) => string | null,
): Slice[] {
  const rolls = new Map<string, number>();
  const weights = new Map<string, number>();
  for (const r of rows) {
    const k = keyOf(r) ?? "Unknown";
    rolls.set(k, (rolls.get(k) ?? 0) + r.quantity);
    weights.set(k, (weights.get(k) ?? 0) + kg(r));
  }
  return [...rolls.entries()]
    .map(([name, n]) => ({ name, value: n > 0 ? weights.get(name)! / n : 0 }))
    .sort((a, b) => b.value - a.value);
}

const partyConfig = {
  value: { label: "Net weight (kg)", color: "#4E729E" },
} satisfies ChartConfig;

const rollsConfig = {
  rolls: { label: "Rolls", color: SECONDARY },
} satisfies ChartConfig;

const trendConfig = {
  kg: { label: "Net weight (kg)", color: PRIMARY },
  rolls: { label: "Rolls", color: SECONDARY },
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

export function DailyDeliveryAnalytics({
  rows,
  monthSeries,
  isLoading,
  dateLabel,
}: {
  rows: DailyDeliveryRow[];
  monthSeries: { date: string; totalQty: number; totalNetWeight: string }[];
  isLoading: boolean;
  dateLabel: string;
}) {
  const byParty = useMemo(() => sumBy(rows, (r) => r.partyName), [rows]);
  const byGsm = useMemo(
    () => sumBy(rows, (r) => (r.gsm != null ? `${r.gsm} GSM` : null)),
    [rows],
  );
  const byYarnType = useMemo(() => sumBy(rows, (r) => r.yarnTypeName), [rows]);
  const rollsByParty = useMemo(
    () => sumBy(rows, (r) => r.partyName, (r) => r.quantity),
    [rows],
  );
  const avgPerRoll = useMemo(() => avgKgPerRollBy(rows, (r) => r.yarnTypeName), [rows]);

  const monthStart = monthSeries.length > 0 ? `${monthSeries[0].date.slice(0, 7)}-01` : "";
  const monthEnd = monthSeries.length > 0 ? monthSeries[monthSeries.length - 1].date : "";
  const trend = useMemo(() => {
    if (!monthStart || !monthEnd) return [];
    const byDate = new Map(monthSeries.map((p) => [p.date, p]));
    const out: { day: string; kg: number; rolls: number }[] = [];
    const cur = new Date(monthStart + "T00:00:00");
    const end = new Date(monthEnd + "T00:00:00");
    while (cur <= end) {
      const iso = cur.toISOString().slice(0, 10);
      const p = byDate.get(iso);
      out.push({
        day: iso.slice(8),
        kg: p ? parseFloat(p.totalNetWeight) || 0 : 0,
        rolls: p?.totalQty ?? 0,
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
          Nothing delivered on {dateLabel} yet. Add a delivery to see charts.
        </CardContent>
      </Card>
    );
  }

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
      {/* Party — who received the day's deliveries */}
      <ChartCard title="Deliveries by party" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={partyConfig} style={{ height: CHART_HEIGHT }}>
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

      {/* Rolls by party — the other side of the delivery picture */}
      <ChartCard title="Rolls delivered by party" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={rollsConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={rollsByParty} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} allowDecimals={false} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v)} rolls`} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={SECONDARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* GSM — fabric spec mix on the day */}
      <ChartCard title="Deliveries by GSM" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={partyConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byGsm} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={PRIMARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Yarn type — which yarn the deliveries carry */}
      <ChartCard title="Deliveries by yarn type" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={partyConfig} style={{ height: CHART_HEIGHT }}>
            <PieChart margin={{ top: 10, right: 10, bottom: 10, left: 10 }}>
              <Pie
                data={byYarnType}
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
                {byYarnType.map((_, i) => (
                  <Cell key={i} fill={DYE[i % DYE.length]} />
                ))}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} />
            </PieChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Avg kg per roll — packing consistency by yarn type */}
      <ChartCard title="Avg kg per roll" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={partyConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={avgPerRoll} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v).toFixed(NUM_DECIMALS)} kg/roll`} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill="#AB3F4C" radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Month trend — is outflow steady or spiky */}
      <ChartCard title="Delivery trend (month)" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={trendConfig} style={{ height: CHART_HEIGHT }}>
            <LineChart data={trend} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="day" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v, name) => name === "rolls" ? `${v} rolls` : fmtKg(Number(v))} />} />
              <Line type="monotone" dataKey="kg" stroke={PRIMARY} strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="rolls" stroke={SECONDARY} strokeWidth={2} dot={false} />
              <ChartLegend content={<ChartLegendContent />} />
            </LineChart>
          </ChartContainer>
        )}
      </ChartCard>
    </div>
  );
}
