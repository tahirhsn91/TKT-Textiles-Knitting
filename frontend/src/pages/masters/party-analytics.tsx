/**
 * Party Analytics sub-view for the Parties tab (issue #115).
 *
 * Fabric Production vs Fabric Delivery for a selected party + month + year.
 * - All parties: grouped bar chart (party x prod/delivery kg) + by-party
 *   table + fabric-breakdown table.
 * - Single party: daily trend line (prod/delivery) + totals + fabric
 *   breakdown table.
 *
 * Month/year filters: past months show the full month; the current month
 * shows data through today; future months/years are disabled.
 */
import { useMemo, useState } from "react";
import {
  Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, XAxis, YAxis,
} from "recharts";
import { TrendingUp, Package, Factory, Truck } from "lucide-react";
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
import { Button } from "@/components/ui/button";
import {
  usePartyAnalytics,
  usePartyOptions,
  availableYears,
} from "@/hooks/use-party-analytics";

const PROD = "hsl(var(--chart-1))"; // vat indigo
const DELIV = "hsl(var(--chart-3))"; // ochre
const CHART_HEIGHT = 280;
const MONTH_NAMES = [
  "January","February","March","April","May","June",
  "July","August","September","October","November","December",
];

const fmtKg = (n: number) => `${n.toLocaleString(undefined, { maximumFractionDigits: 0 })} kg`;

const pairConfig = {
  production: { label: "Production (kg)", color: PROD },
  delivery: { label: "Delivery (kg)", color: DELIV },
} satisfies ChartConfig;

function StatCard({ label, value, sub, icon: Icon }: { label: string; value: string; sub?: string; icon: React.ElementType }) {
  return (
    <Card className="overflow-hidden">
      <CardContent className="p-4">
        <div className="flex items-center justify-between gap-2">
          <p className="eyebrow">{label}</p>
          <Icon className="h-4 w-4 shrink-0 text-muted-foreground/50" />
        </div>
        <p className="selvedge-top num mt-2 text-2xl font-semibold leading-none text-foreground">{value}</p>
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

export function PartyAnalyticsView() {
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());
  const [partyId, setPartyId] = useState<number | "all">("all");

  const parties = usePartyOptions();
  const years = availableYears();

  // Disable future months within the current year, and months of future years.
  const isCurrentYear = year === now.getFullYear();
  const monthDisabled = (m: number) => (isCurrentYear && m > now.getMonth() + 1);

  const filters = useMemo(
    () => ({ month, year, partyId: partyId === "all" ? null : partyId }),
    [month, year, partyId],
  );
  const { data, isLoading, isError, refetch } = usePartyAnalytics(filters);
  const isAll = partyId === "all";

  const allPartiesChart = useMemo(
    () =>
      (data?.byParty ?? []).map((p) => ({
        name: p.partyName,
        production: p.production.kg,
        delivery: p.delivery.kg,
      })),
    [data],
  );
  const trendChart = useMemo(
    () =>
      (data?.dailyTrend ?? []).map((d) => ({
        day: d.date.slice(8),
        production: d.productionKg,
        delivery: d.deliveryKg,
      })),
    [data],
  );

  const windowLabel = data
    ? `${MONTH_NAMES[data.window.month - 1]} ${data.window.year}`
    : `${MONTH_NAMES[month - 1]} ${year}`;
  const partyLabel = isAll ? "All parties" : (parties.find((p) => p.id === partyId)?.name ?? `Party ${partyId}`);

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="space-y-4">
      {/* Filters */}
      <Card className="overflow-hidden">
        <CardContent className="grid grid-cols-1 gap-3 p-4 sm:grid-cols-[minmax(0,1fr)_auto_auto] sm:items-end sm:gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="eyebrow" htmlFor="party-filter">Party</label>
            <select
              id="party-filter"
              value={partyId === "all" ? "all" : String(partyId)}
              onChange={(e) => setPartyId(e.target.value === "all" ? "all" : Number(e.target.value))}
              className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-1 focus:ring-ring sm:h-9"
            >
              <option value="all">All Parties</option>
              {parties.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="eyebrow" htmlFor="month-filter">Month</label>
            <select
              id="month-filter"
              value={month}
              onChange={(e) => setMonth(Number(e.target.value))}
              className="h-11 rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-1 focus:ring-ring sm:h-9"
            >
              {MONTH_NAMES.map((name, i) => (
                <option key={i + 1} value={i + 1} disabled={monthDisabled(i + 1)}>{name}</option>
              ))}
            </select>
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="eyebrow" htmlFor="year-filter">Year</label>
            <select
              id="year-filter"
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              className="h-11 rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-1 focus:ring-ring sm:h-9"
            >
              {years.map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>
        </CardContent>
      </Card>

      {isError && (
        <Card>
          <CardContent className="flex flex-col items-start gap-3 px-5 py-6 text-sm">
            <p className="text-destructive">Couldn't load party analytics.</p>
            <Button variant="outline" size="sm" onClick={() => refetch()}>Retry</Button>
          </CardContent>
        </Card>
      )}

      {/* Headline stats */}
      {!isError && data && (
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <StatCard label="Production" value={fmtKg(data.totals.production.kg)} sub={`${data.totals.production.rolls} rolls`} icon={Factory} />
          <StatCard label="Delivery" value={fmtKg(data.totals.delivery.kg)} sub={`${data.totals.delivery.rolls} rolls`} icon={Truck} />
          <StatCard label="Party" value={isAll ? "All" : data.party?.name ?? "-"} sub={partyLabel} icon={Package} />
          <StatCard label="Window" value={windowLabel} sub={data.window.isCurrentMonth ? `through ${data.window.to}` : "full month"} icon={TrendingUp} />
        </div>
      )}

      {/* Empty state */}
      {!isError && data && data.totals.production.kg === 0 && data.totals.delivery.kg === 0 && (
        <Card>
          <CardContent className="px-5 py-10 text-center text-sm text-muted-foreground">
            No production or delivery data for {partyLabel} in {windowLabel}.
          </CardContent>
        </Card>
      )}

      {/* Loading skeleton */}
      {isLoading && (
        <div className="grid grid-cols-1 gap-4">
          {skeleton}
          {skeleton}
        </div>
      )}

      {/* Data views */}
      {!isError && !isLoading && data && (data.totals.production.kg > 0 || data.totals.delivery.kg > 0) && (
        <div className="grid grid-cols-1 gap-4">
          {/* All parties: grouped bar + by-party table */}
          {isAll && (
            <>
              <ChartCard title="Production vs delivery by party" note={windowLabel}>
                <ChartContainer className="w-full" config={pairConfig} style={{ height: CHART_HEIGHT }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={allPartiesChart} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
                      <CartesianGrid stroke="hsl(var(--border))" vertical={false} />
                      <XAxis
                        dataKey="name"
                        tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                        tickLine={false}
                        axisLine={{ stroke: "hsl(var(--border))" }}
                        interval={0}
                        angle={-15}
                        textAnchor="end"
                        height={60}
                      />
                      <YAxis
                        tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                        tickLine={false}
                        axisLine={false}
                        width={54}
                        tickFormatter={(v: number) => (v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v))}
                      />
                      <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} cursor={{ fill: "rgba(31,34,28,0.05)" }} />
                      <Bar dataKey="production" fill={PROD} radius={[2, 2, 0, 0]} barSize={18} />
                      <Bar dataKey="delivery" fill={DELIV} radius={[2, 2, 0, 0]} barSize={18} />
                      <ChartLegend content={<ChartLegendContent />} />
                    </BarChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </ChartCard>

              <ChartCard title="By party" note={windowLabel}>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b text-left text-xs text-muted-foreground">
                        <th className="py-2.5 pr-4 font-medium">Party</th>
                        <th className="py-2.5 pr-4 text-right font-medium">Production kg</th>
                        <th className="py-2.5 pr-4 text-right font-medium">Production rolls</th>
                        <th className="py-2.5 pr-4 text-right font-medium">Delivery kg</th>
                        <th className="py-2.5 text-right font-medium">Delivery rolls</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.byParty.map((p) => (
                        <tr key={p.partyId} className="border-b last:border-0">
                          <td className="py-3 pr-4 font-semibold text-foreground">{p.partyName}</td>
                          <td className="num py-3 pr-4 text-right">{p.production.kg.toFixed(2)}</td>
                          <td className="num py-3 pr-4 text-right">{p.production.rolls}</td>
                          <td className="num py-3 pr-4 text-right">{p.delivery.kg.toFixed(2)}</td>
                          <td className="num py-3 text-right">{p.delivery.rolls}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </ChartCard>
            </>
          )}

          {/* Single party: daily trend line */}
          {!isAll && (
            <ChartCard title={`Daily production & delivery — ${partyLabel}`} note={windowLabel}>
              <ChartContainer className="w-full" config={pairConfig} style={{ height: CHART_HEIGHT }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={trendChart} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
                    <CartesianGrid stroke="hsl(var(--border))" vertical={false} />
                    <XAxis
                      dataKey="day"
                      tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                      tickLine={false}
                      axisLine={{ stroke: "hsl(var(--border))" }}
                    />
                    <YAxis
                      tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                      tickLine={false}
                      axisLine={false}
                      width={54}
                      tickFormatter={(v: number) => (v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v))}
                    />
                    <ChartTooltip content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />} />
                    <Line type="monotone" dataKey="production" stroke={PROD} strokeWidth={2} dot={false} />
                    <Line type="monotone" dataKey="delivery" stroke={DELIV} strokeWidth={2} dot={false} />
                    <ChartLegend content={<ChartLegendContent />} />
                  </LineChart>
                </ResponsiveContainer>
              </ChartContainer>
            </ChartCard>
          )}

          {/* Fabric breakdown table */}
          <ChartCard title="Breakdown by fabric type" note={windowLabel}>
            {data.fabricBreakdown.length === 0 ? (
              <p className="px-3 py-8 text-center text-sm text-muted-foreground">No fabric type data for this selection.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b text-left text-xs text-muted-foreground">
                      <th className="py-2.5 pr-4 font-medium">Fabric type</th>
                      <th className="py-2.5 pr-4 text-right font-medium">Production kg</th>
                      <th className="py-2.5 pr-4 text-right font-medium">Production rolls</th>
                      <th className="py-2.5 pr-4 text-right font-medium">Delivery kg</th>
                      <th className="py-2.5 text-right font-medium">Delivery rolls</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.fabricBreakdown.map((f) => (
                      <tr key={f.type} className="border-b last:border-0">
                        <td className="py-3 pr-4 font-semibold text-foreground">{f.type}</td>
                        <td className="num py-3 pr-4 text-right">{f.productionKg.toFixed(2)}</td>
                        <td className="num py-3 pr-4 text-right">{f.productionRolls}</td>
                        <td className="num py-3 pr-4 text-right">{f.deliveryKg.toFixed(2)}</td>
                        <td className="num py-3 text-right">{f.deliveryRolls}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </ChartCard>
        </div>
      )}
    </div>
  );
}
