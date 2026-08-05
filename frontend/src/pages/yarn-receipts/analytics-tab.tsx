/**
 * Analytics tab for the Yarn Receipts screen.
 *
 * Six charts, all computed client-side from one `/api/yarn-receipts/analytics`
 * call that returns every receipt line for the selected date (count / brand /
 * party / qty / net weight) plus a per-day month series up to that date.
 *
 * Same charting stack as the daily-production analytics tab (Recharts via the
 * shadcn ChartContainer), same colour language: charts stay on brand-neutral
 * tints, totals are the app's muted olive text.
 */
import { useMemo } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
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
import type { YarnReceiptAnalyticsLine, YarnReceiptMonthPoint } from "@/hooks/use-yarn-receipts";

const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const PRIMARY = "#2A4C7A";
const SECONDARY = "#627C50";

const AXIS_TICK = { fontSize: 11, fill: "#656E5E" } as const;
const AXIS_RULE = "#DFE2DA";

const CHART_HEIGHT = 260;

const kg = (r: YarnReceiptAnalyticsLine) => parseFloat(r.netWeight) || 0;
const fmtKg = (n: number) => `${n.toFixed(3)} kg`;

type Slice = { name: string; value: number };

/** Sum a numeric field grouped by a key, descending; null keys fall to "Unknown". */
function sumBy(
  lines: YarnReceiptAnalyticsLine[],
  keyOf: (r: YarnReceiptAnalyticsLine) => string | null,
  valueOf: (r: YarnReceiptAnalyticsLine) => number = kg,
): Slice[] {
  const map = new Map<string, number>();
  for (const r of lines) {
    const k = keyOf(r) ?? "Unknown";
    map.set(k, (map.get(k) ?? 0) + valueOf(r));
  }
  return [...map.entries()]
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);
}

/** Average kg per bag, grouped by a key — delivery consistency signal. */
function avgBagWeightBy(lines: YarnReceiptAnalyticsLine[], keyOf: (r: YarnReceiptAnalyticsLine) => string | null): Slice[] {
  const bags = new Map<string, number>();
  const weights = new Map<string, number>();
  for (const r of lines) {
    const k = keyOf(r) ?? "Unknown";
    bags.set(k, (bags.get(k) ?? 0) + r.quantity);
    weights.set(k, (weights.get(k) ?? 0) + kg(r));
  }
  return [...bags.entries()]
    .map(([name, b]) => ({ name, value: b > 0 ? weights.get(name)! / b : 0 }))
    .sort((a, b) => b.value - a.value);
}

/** Stacked count × brand: one row per count, one series per brand. */
function countByBrand(lines: YarnReceiptAnalyticsLine[]) {
  const counts = new Map<string, Map<string, number>>();
  for (const r of lines) {
    const count = r.yarnCountName ?? "Unknown";
    const brand = r.yarnBrandName ?? "Unknown";
    if (!counts.has(count)) counts.set(count, new Map());
    const brands = counts.get(count)!;
    brands.set(brand, (brands.get(brand) ?? 0) + kg(r));
  }
  const brandSet = new Set<string>();
  for (const brands of counts.values()) for (const b of brands.keys()) brandSet.add(b);
  const brands = [...brandSet];
  const rows = [...counts.entries()].map(([count, brandsMap]) => {
    const row: Record<string, string | number> = { count };
    for (const b of brands) row[b] = brandsMap.get(b) ?? 0;
    return row;
  });
  return { rows, brands };
}

const countConfig = {
  value: { label: "Net weight (kg)", color: PRIMARY },
} satisfies ChartConfig;

const brandConfig = {
  value: { label: "Net weight (kg)", color: SECONDARY },
} satisfies ChartConfig;

const partyConfig = {
  value: { label: "Net weight (kg)", color: "#4E729E" },
} satisfies ChartConfig;

const trendConfig = {
  kg: { label: "Net weight (kg)", color: PRIMARY },
  bags: { label: "Bags", color: SECONDARY },
} satisfies ChartConfig;

const bagConfig = {
  value: { label: "Avg kg per bag", color: "#AB3F4C" },
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

/** Fill missing days in the month series so the trend axis is continuous. */
function fillMonthSeries(series: YarnReceiptMonthPoint[], monthStart: string, monthEnd: string): YarnReceiptMonthPoint[] {
  const byDate = new Map(series.map((p) => [p.date, p]));
  const out: YarnReceiptMonthPoint[] = [];
  const cur = new Date(monthStart + "T00:00:00");
  const end = new Date(monthEnd + "T00:00:00");
  while (cur <= end) {
    const iso = cur.toISOString().slice(0, 10);
    out.push(byDate.get(iso) ?? { date: iso, totalQty: 0, totalNetWeight: "0" });
    cur.setDate(cur.getDate() + 1);
  }
  return out;
}

export function YarnReceiptAnalytics({
  lines,
  monthSeries,
  isLoading,
  dateLabel,
}: {
  lines: YarnReceiptAnalyticsLine[];
  monthSeries: YarnReceiptMonthPoint[];
  isLoading: boolean;
  dateLabel: string;
}) {
  const byCount = useMemo(() => sumBy(lines, (r) => r.yarnCountName), [lines]);
  const byBrand = useMemo(() => sumBy(lines, (r) => r.yarnBrandName), [lines]);
  const byParty = useMemo(() => sumBy(lines, (r) => r.partyName), [lines]);
  const bagByCount = useMemo(() => avgBagWeightBy(lines, (r) => r.yarnCountName), [lines]);
  const { rows: cxbRows, brands: cxbBrands } = useMemo(() => countByBrand(lines), [lines]);

  const monthStart = monthSeries.length > 0 ? `${monthSeries[0].date.slice(0, 7)}-01` : "";
  const monthEnd = monthSeries.length > 0 ? monthSeries[monthSeries.length - 1].date : "";
  const trend = useMemo(() => {
    if (!monthStart || !monthEnd) return [];
    return fillMonthSeries(monthSeries, monthStart, monthEnd).map((p) => ({
      day: p.date.slice(8), // "04" — axis label without month/year noise
      kg: parseFloat(p.totalNetWeight) || 0,
      bags: p.totalQty,
    }));
  }, [monthSeries, monthStart, monthEnd]);

  const cxbConfig = useMemo(() => {
    const cfg: ChartConfig = {};
    cxbBrands.forEach((b, i) => { cfg[b] = { label: b, color: DYE[i % DYE.length] }; });
    return cfg;
  }, [cxbBrands]);

  const isEmpty = !isLoading && lines.length === 0;

  if (isEmpty) {
    return (
      <Card>
        <CardContent className="px-5 py-10 text-center text-sm text-muted-foreground">
          Nothing received on {dateLabel} yet. Add a receipt to see charts.
        </CardContent>
      </Card>
    );
  }

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
      {/* Count — which yarn counts we're stocking up on */}
      <ChartCard title="Yarn received by count" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={countConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byCount} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={PRIMARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Brand — who's supplying */}
      <ChartCard title="Yarn received by brand" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={brandConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={byBrand} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill={SECONDARY} radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Party — which supplier dominates the day */}
      <ChartCard title="Yarn received by party" dateLabel={dateLabel}>
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
                  percent * 100 >= 5 ? `${name} ${(percent * 100).toFixed(0)}%` : ""
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

      {/* Month trend — is inflow steady or spiky */}
      <ChartCard title="Daily receipts trend (month)" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={trendConfig} style={{ height: CHART_HEIGHT }}>
            <LineChart data={trend} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="day" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v, name) => name === "bags" ? `${v} bags` : fmtKg(Number(v))} />} />
              <Line type="monotone" dataKey="kg" stroke={PRIMARY} strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="bags" stroke={SECONDARY} strokeWidth={2} dot={false} />
              <ChartLegend content={<ChartLegendContent />} />
            </LineChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Count × Brand — which combos arrive together */}
      <ChartCard title="Count × Brand (kg)" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={cxbConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={cxbRows} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="count" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <ChartLegend content={<ChartLegendContent />} />
              {cxbBrands.map((b) => (
                <Bar key={b} dataKey={b} stackId="a" fill={DYE[cxbBrands.indexOf(b) % DYE.length]} barSize={28} />
              ))}
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>

      {/* Bag-size distribution — delivery consistency */}
      <ChartCard title="Avg kg per bag" dateLabel={dateLabel}>
        {isLoading ? skeleton : (
          <ChartContainer className="w-full aspect-auto" config={bagConfig} style={{ height: CHART_HEIGHT }}>
            <BarChart data={bagByCount} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid stroke={AXIS_RULE} vertical={false} />
              <XAxis dataKey="name" tick={AXIS_TICK} tickLine={false} axisLine={{ stroke: AXIS_RULE }} />
              <YAxis tick={AXIS_TICK} tickLine={false} axisLine={false} width={52} />
              <ChartTooltip content={<ChartTooltipContent formatter={(v) => `${Number(v).toFixed(3)} kg/bag`} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
              <Bar dataKey="value" fill="#AB3F4C" radius={[2, 2, 0, 0]} barSize={28} />
            </BarChart>
          </ChartContainer>
        )}
      </ChartCard>
    </div>
  );
}
