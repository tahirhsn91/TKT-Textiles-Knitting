import { NUM_DECIMALS } from "@/lib/format";
import { useQuery, type UseQueryResult } from "@tanstack/react-query";
import {
  AreaChart, Area,
  BarChart, Bar,
  PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer,
} from "recharts";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

/**
 * Recharts writes colours as SVG presentation attributes, where var() does not
 * resolve — so these literals mirror the light-mode tokens in index.css.
 * Keep them in step if the tokens move.
 */
const TOKEN = {
  ink: "#1F221C",
  machine: "#656E5E",
  rule: "#DFE2DA",
  card: "#FFFFFF",
  signal: "#FF3C00",
};

/**
 * Dye lots, not a hue rotation. Vat indigo carries the workhorse series so the
 * charts never have to borrow the brand colour; Signal sits last and only turns
 * up when a series count genuinely demands it.
 */
const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];

function fmt(n: number, decimals = 2) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(decimals)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(decimals)}K`;
  return n.toFixed(decimals);
}

// ── Per-widget data types ────────────────────────────────────────────────────
interface Kpis {
  totalNetWeight: number;
  netWeightDelivered: number;
  netWeightYarnReceipt: number;
  activeMachines: number;
  periodLabel: string;
}
type TrendPoint = { label: string; netWeight: number; quantity: number };
type DailyPoint = { date: string; quantity: number; netWeight: number };
type NameValue = { name: string; value: number };
type NameCount = { name: string; count: number };
type NameLines = { name: string; lines: number };
type NameNetWeight = { name: string; netWeight: number };

// ── Generic per-widget fetch hook ────────────────────────────────────────────
// Uses customFetch so the bearer auth token is attached — a bare fetch() here
// omitted Authorization and every /api/dashboard call 401'd (dashboard blank).
function useWidget<T>(key: string): UseQueryResult<T> {
  return useQuery<T>({
    queryKey: ["dashboard", key],
    queryFn: () => customFetch<T>(`/api/dashboard/${key}`, { method: "GET" }),
  });
}

const tooltipStyle = {
  background: TOKEN.card,
  border: `1px solid ${TOKEN.rule}`,
  borderRadius: 3,
  fontSize: 12,
  fontFamily: "var(--app-font-mono)",
  padding: "6px 10px",
} as const;

const axisTick = { fontSize: 11, fill: TOKEN.machine, fontFamily: "var(--app-font-mono)" };

// ── Presentational helpers ───────────────────────────────────────────────────

/**
 * One reading on the panel. No icon chip: in a mass-balance system the number
 * is the subject, and a coloured square next to it only competes with it.
 */
function Reading({
  label, value, unit, sub, lead = false,
}: {
  label: string;
  value: string;
  unit?: string;
  sub: string;
  lead?: boolean;
}) {
  return (
    <div className={`px-6 py-5 ${lead ? "selvedge-top" : ""}`}>
      <p className="eyebrow">{label}</p>
      <p className="mt-3 flex items-baseline gap-1.5">
        <span className="num text-[2.125rem] font-medium leading-none text-foreground">
          {value}
        </span>
        {unit && (
          <span className="text-sm font-medium text-muted-foreground">{unit}</span>
        )}
      </p>
      <p className="mt-2 text-xs text-muted-foreground">{sub}</p>
    </div>
  );
}

function ChartCard({
  title,
  scope,
  isLoading,
  isError,
  isEmpty,
  height = 220,
  onRetry,
  children,
}: {
  title: string;
  scope: string;
  isLoading: boolean;
  isError: boolean;
  isEmpty?: boolean;
  height?: number;
  onRetry?: () => void;
  children: React.ReactNode;
}) {
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">{title}</h2>
        <span className="eyebrow">{scope}</span>
      </div>
      <CardContent className="px-3 pt-4 pb-3">
        {isLoading ? (
          <Skeleton className="w-full" style={{ height }} />
        ) : isError ? (
          <div className="flex flex-col items-center justify-center gap-2 px-2 text-sm text-destructive" style={{ height }}>
            <span>Couldn't load this chart.</span>
            {onRetry && (
              <Button variant="outline" size="sm" onClick={onRetry}>
                Retry
              </Button>
            )}
          </div>
        ) : isEmpty ? (
          <div className="flex items-center justify-center px-2 text-sm text-muted-foreground" style={{ height }}>
            Nothing recorded for this period yet.
          </div>
        ) : (
          children
        )}
      </CardContent>
    </Card>
  );
}

// ── KPI row widget ───────────────────────────────────────────────────────────
function ReadingPanel() {
  const { data, isLoading, isError, refetch } = useWidget<Kpis>("kpis");

  if (isLoading) {
    return (
      <Card>
        <div className="grid grid-cols-1 divide-y sm:grid-cols-2 lg:grid-cols-4 sm:divide-x sm:divide-y-0">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="px-6 py-5"><Skeleton className="h-[5.5rem] w-full" /></div>
          ))}
        </div>
      </Card>
    );
  }
  if (isError || !data) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center gap-2 px-6 py-5 text-sm text-destructive">
          <span>Couldn't load the headline figures.</span>
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Retry
          </Button>
        </CardContent>
      </Card>
    );
  }
  return (
    <Card className="overflow-hidden">
      <div className="grid grid-cols-1 divide-y sm:grid-cols-2 lg:grid-cols-4 sm:divide-x sm:divide-y-0">
        <Reading
          lead
          label="Net weight produced"
          value={data.totalNetWeight.toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}
          unit="kg"
          sub="Fabric off the machines this month"
        />
        <Reading
          label="Net weight delivered"
          value={data.netWeightDelivered.toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}
          unit="kg"
          sub="Fabric dispatched to parties this month"
        />
        <Reading
          label="Yarn received"
          value={data.netWeightYarnReceipt.toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}
          unit="kg"
          sub="Yarn receipts booked this month"
        />
        <Reading
          label="Machines running"
          value={String(data.activeMachines)}
          sub="With recorded activity this month"
        />
      </div>
    </Card>
  );
}

// ── Monthly trend widget ─────────────────────────────────────────────────────
function MonthlyTrendWidget() {
  const { data, isLoading, isError, refetch } = useWidget<TrendPoint[]>("monthly-trend");
  return (
    <ChartCard
      title="Production trend"
      scope="Last 12 months"
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      onRetry={() => refetch()}
      height={240}
    >
      <div role="img" aria-label="Area chart of net weight produced per month, last twelve months">
      <ResponsiveContainer width="100%" height={240}>
        <AreaChart data={data} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
          <defs>
            <linearGradient id="gradNW" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={DYE[0]} stopOpacity={0.22} />
              <stop offset="100%" stopColor={DYE[0]} stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid stroke={TOKEN.rule} vertical={false} />
          <XAxis dataKey="label" tick={axisTick} tickLine={false} axisLine={{ stroke: TOKEN.rule }} />
          <YAxis tick={axisTick} tickLine={false} axisLine={false} tickFormatter={(v) => fmt(v)} width={48} />
          <Tooltip
            contentStyle={tooltipStyle}
            cursor={{ stroke: TOKEN.signal, strokeWidth: 1 }}
            formatter={(v: number) => [`${v.toFixed(NUM_DECIMALS)} kg`, "Net weight"]}
          />
          <Area type="monotone" dataKey="netWeight" stroke={DYE[0]} strokeWidth={2} fill="url(#gradNW)" name="Net weight (kg)" />
        </AreaChart>
      </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

// ── Daily production widget ──────────────────────────────────────────────────
function DailyProductionWidget() {
  const { data, isLoading, isError, refetch } = useWidget<DailyPoint[]>("daily-production");
  return (
    <ChartCard
      title="Daily volume"
      scope="Last 30 days"
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      onRetry={() => refetch()}
    >
      <div role="img" aria-label="Bar chart of quantity and net weight per day, last thirty days">
      <ResponsiveContainer width="100%" height={220}>
        <BarChart data={data} barSize={6} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
          <CartesianGrid stroke={TOKEN.rule} vertical={false} />
          <XAxis
            dataKey="date"
            tick={axisTick}
            tickLine={false}
            axisLine={{ stroke: TOKEN.rule }}
            tickFormatter={(v: string) => v.slice(5)}
            interval="preserveStartEnd"
          />
          <YAxis tick={axisTick} tickLine={false} axisLine={false} tickFormatter={(v) => fmt(v)} width={48} />
          <Tooltip
            contentStyle={tooltipStyle}
            cursor={{ fill: "rgba(31,34,28,0.05)" }}
            formatter={(v: number, name: string) => [
              name === "netWeight" ? `${v.toFixed(NUM_DECIMALS)} kg` : v.toFixed(NUM_DECIMALS),
              name === "netWeight" ? "Net weight" : "Quantity",
            ]}
          />
          <Legend wrapperStyle={{ fontSize: 11, color: TOKEN.machine }} />
          <Bar dataKey="quantity" fill={DYE[2]} name="Quantity" radius={[1, 1, 0, 0]} />
          <Bar dataKey="netWeight" fill={DYE[0]} name="Net weight (kg)" radius={[1, 1, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

// ── Fabric breakdown widget ──────────────────────────────────────────────────
function FabricBreakdownWidget() {
  const { data, isLoading, isError, refetch } = useWidget<NameValue[]>("fabric-breakdown");
  return (
    <ChartCard
      title="Production by fabric type"
      scope="This month"
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      onRetry={() => refetch()}
    >
      <div role="img" aria-label="Pie chart of production share by fabric type, this month">
      <ResponsiveContainer width="100%" height={220}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={58}
            outerRadius={84}
            paddingAngle={1}
            dataKey="value"
            nameKey="name"
            stroke={TOKEN.card}
            strokeWidth={2}
            label={({ name, percent }) => `${name} ${(percent * 100).toFixed(NUM_DECIMALS)}%`}
            labelLine={false}
          >
            {(data ?? []).map((_, i) => (
              <Cell key={i} fill={DYE[i % DYE.length]} />
            ))}
          </Pie>
          <Tooltip contentStyle={tooltipStyle} formatter={(v: number) => [`${v.toFixed(NUM_DECIMALS)} kg`, "Net weight"]} />
        </PieChart>
      </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

// ── Ranked horizontal bar, shared by the three "top N" widgets ───────────────
function RankedBars<T extends Record<string, unknown>>({
  title, scope, data, isLoading, isError, dataKey, seriesName, color, formatter, numeric, onRetry,
}: {
  title: string;
  scope: string;
  data: T[] | undefined;
  isLoading: boolean;
  isError: boolean;
  dataKey: string;
  seriesName: string;
  color: string;
  formatter: (v: number) => [string, string];
  numeric?: boolean;
  onRetry: () => void;
}) {
  const height = Math.max(180, (data?.length ?? 6) * 28 + 30);
  return (
    <ChartCard
      title={title}
      scope={scope}
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      onRetry={onRetry}
      height={height}
    >
      <div role="img" aria-label={`Horizontal bar chart of ${title.toLowerCase()}`}>
      <ResponsiveContainer width="100%" height={Math.max(180, (data?.length ?? 0) * 28 + 30)}>
        <BarChart data={data} layout="vertical" margin={{ left: 8, right: 28, top: 4, bottom: 4 }}>
          <CartesianGrid stroke={TOKEN.rule} horizontal={false} />
          <XAxis
            type="number"
            tick={axisTick}
            tickLine={false}
            axisLine={false}
            allowDecimals={!numeric}
            tickFormatter={numeric ? (v) => fmt(v) : undefined}
          />
          <YAxis
            dataKey="name"
            type="category"
            tick={{ fontSize: 11, fill: TOKEN.ink }}
            tickLine={false}
            axisLine={{ stroke: TOKEN.rule }}
            width={118}
          />
          <Tooltip contentStyle={tooltipStyle} cursor={{ fill: "rgba(31,34,28,0.05)" }} formatter={formatter} />
          <Bar dataKey={dataKey} fill={color} name={seriesName} radius={[0, 1, 1, 0]} barSize={14} />
        </BarChart>
      </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

function TopPartiesWidget() {
  const { data, isLoading, isError, refetch } = useWidget<NameCount[]>("top-parties");
  return (
    <RankedBars
      title="Top parties"
      scope="By transaction count, this month"
      data={data}
      isLoading={isLoading}
      isError={isError}
      dataKey="count"
      seriesName="Transactions"
      color={DYE[1]}
      formatter={(v: number) => [String(v), "Transactions"]}
      onRetry={() => refetch()}
    />
  );
}

function MachineUtilizationWidget() {
  const { data, isLoading, isError, refetch } = useWidget<NameLines[]>("machine-utilization");
  return (
    <RankedBars
      title="Machine utilisation"
      scope="By transaction lines, this month"
      data={data}
      isLoading={isLoading}
      isError={isError}
      dataKey="lines"
      seriesName="Lines"
      color={DYE[0]}
      formatter={(v: number) => [String(v), "Transaction lines"]}
      onRetry={() => refetch()}
    />
  );
}

function EmployeeOutputWidget() {
  const { data, isLoading, isError, refetch } = useWidget<NameNetWeight[]>("employee-output");
  return (
    <RankedBars
      title="Top employees"
      scope="By net weight, this month"
      data={data}
      isLoading={isLoading}
      isError={isError}
      dataKey="netWeight"
      seriesName="Net weight (kg)"
      color={DYE[3]}
      formatter={(v: number) => [`${v.toFixed(NUM_DECIMALS)} kg`, "Net weight"]}
      numeric
      onRetry={() => refetch()}
    />
  );
}

// ── Page ─────────────────────────────────────────────────────────────────────
export default function DashboardPage() {
  const { data: kpis } = useWidget<Kpis>("kpis");

  return (
    <>
      <div className="space-y-6">
        <header className="border-b pb-5">
          <p className="eyebrow">Knitting operations</p>
          <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">
            Dashboard
          </h1>
          <p className="mt-2 text-sm text-muted-foreground">
            {kpis ? <>Figures for <span className="num">{kpis.periodLabel}</span>.</> : "Loading figures…"}
          </p>
        </header>

        {/* Each widget fetches and loads independently */}
        <ReadingPanel />

        <MonthlyTrendWidget />

        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <DailyProductionWidget />
          <FabricBreakdownWidget />
        </div>

        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <TopPartiesWidget />
          <MachineUtilizationWidget />
        </div>

        <EmployeeOutputWidget />
      </div>
    </>
  );
}
