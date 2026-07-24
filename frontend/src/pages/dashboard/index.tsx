import { useQuery, type UseQueryResult } from "@tanstack/react-query";
import {
  AreaChart, Area,
  BarChart, Bar,
  PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer,
} from "recharts";
import {
  Activity, Weight, Cpu,
} from "lucide-react";
import { Layout } from "@/components/layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

const COLORS = [
  "#6366f1", "#f59e0b", "#10b981", "#3b82f6",
  "#ef4444", "#8b5cf6", "#ec4899", "#14b8a6",
  "#f97316", "#84cc16",
];

function fmt(n: number, decimals = 1) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(decimals)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(decimals)}K`;
  return n.toFixed(decimals);
}

// ── Per-widget data types ────────────────────────────────────────────────────
interface Kpis {
  totalTransactions: number;
  totalNetWeight: number;
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
function useWidget<T>(key: string): UseQueryResult<T> {
  return useQuery<T>({
    queryKey: ["dashboard", key],
    queryFn: async () => {
      const res = await fetch(`${BASE}/api/dashboard/${key}`);
      if (!res.ok) throw new Error(`Failed to load ${key}`);
      return res.json();
    },
  });
}

const CustomTooltipStyle = {
  contentStyle: {
    background: "hsl(var(--card))",
    border: "1px solid hsl(var(--border))",
    borderRadius: 8,
    fontSize: 12,
  },
};

// ── Presentational helpers ───────────────────────────────────────────────────
function KpiCard({
  title, value, sub, icon: Icon, color,
}: {
  title: string;
  value: string;
  sub: string;
  icon: React.ElementType;
  color: string;
}) {
  return (
    <Card>
      <CardContent className="p-5">
        <div className="flex items-start justify-between">
          <div className="space-y-1">
            <p className="text-sm text-muted-foreground font-medium">{title}</p>
            <p className="text-2xl font-bold tracking-tight">{value}</p>
            <p className="text-xs text-muted-foreground">{sub}</p>
          </div>
          <div className={`p-2 rounded-lg ${color}`}>
            <Icon className="h-5 w-5 text-white" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ChartCard({
  title,
  isLoading,
  isError,
  isEmpty,
  height = 220,
  children,
}: {
  title: string;
  isLoading: boolean;
  isError: boolean;
  isEmpty?: boolean;
  height?: number;
  children: React.ReactNode;
}) {
  return (
    <Card>
      <CardHeader className="pb-2 pt-4 px-5">
        <CardTitle className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent className="px-4 pb-4">
        {isLoading ? (
          <Skeleton className="w-full" style={{ height }} />
        ) : isError ? (
          <div className="flex items-center justify-center text-destructive text-sm" style={{ height }}>
            Failed to load.
          </div>
        ) : isEmpty ? (
          <div className="flex items-center justify-center text-muted-foreground text-sm" style={{ height }}>
            No data for this period
          </div>
        ) : (
          children
        )}
      </CardContent>
    </Card>
  );
}

// ── KPI row widget ───────────────────────────────────────────────────────────
function KpiRow() {
  const { data, isLoading, isError } = useWidget<Kpis>("kpis");

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {[...Array(3)].map((_, i) => (
          <Card key={i}><CardContent className="p-5"><Skeleton className="h-20 w-full" /></CardContent></Card>
        ))}
      </div>
    );
  }
  if (isError || !data) {
    return <p className="text-destructive text-sm">Failed to load KPIs.</p>;
  }
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <KpiCard title="Total Transactions" value={data.totalTransactions.toLocaleString()} sub="transaction headers this month" icon={Activity} color="bg-indigo-500" />
      <KpiCard title="Total Net Weight" value={`${fmt(data.totalNetWeight)} kg`} sub="net weight produced this month" icon={Weight} color="bg-amber-500" />
      <KpiCard title="Active Machines" value={String(data.activeMachines)} sub="machines with activity this month" icon={Cpu} color="bg-emerald-500" />
    </div>
  );
}

// ── Monthly trend widget ─────────────────────────────────────────────────────
function MonthlyTrendWidget() {
  const { data, isLoading, isError } = useWidget<TrendPoint[]>("monthly-trend");
  return (
    <ChartCard title="Monthly Production Trend — Last 12 Months" isLoading={isLoading} isError={isError} isEmpty={data?.length === 0}>
      <ResponsiveContainer width="100%" height={220}>
        <AreaChart data={data} {...CustomTooltipStyle}>
          <defs>
            <linearGradient id="gradNW" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
          <XAxis dataKey="label" tick={{ fontSize: 11 }} />
          <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => fmt(v)} />
          <Tooltip contentStyle={CustomTooltipStyle.contentStyle} formatter={(v: number) => [`${v.toFixed(2)} kg`, "Net Weight"]} />
          <Area type="monotone" dataKey="netWeight" stroke="#6366f1" strokeWidth={2} fill="url(#gradNW)" name="Net Weight (kg)" />
        </AreaChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

// ── Daily production widget ──────────────────────────────────────────────────
function DailyProductionWidget() {
  const { data, isLoading, isError } = useWidget<DailyPoint[]>("daily-production");
  return (
    <ChartCard title="Daily Production Volume — Last 30 Days" isLoading={isLoading} isError={isError} isEmpty={data?.length === 0}>
      <ResponsiveContainer width="100%" height={220}>
        <BarChart data={data} barSize={6}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
          <XAxis dataKey="date" tick={{ fontSize: 10 }} tickFormatter={(v: string) => v.slice(5)} interval="preserveStartEnd" />
          <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => fmt(v)} />
          <Tooltip
            contentStyle={CustomTooltipStyle.contentStyle}
            formatter={(v: number, name: string) => [
              name === "netWeight" ? `${v.toFixed(2)} kg` : v.toFixed(2),
              name === "netWeight" ? "Net Weight" : "Quantity",
            ]}
          />
          <Legend wrapperStyle={{ fontSize: 11 }} />
          <Bar dataKey="quantity" fill="#f59e0b" name="Quantity" radius={[2, 2, 0, 0]} />
          <Bar dataKey="netWeight" fill="#6366f1" name="Net Weight (kg)" radius={[2, 2, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

// ── Fabric breakdown widget ──────────────────────────────────────────────────
function FabricBreakdownWidget() {
  const { data, isLoading, isError } = useWidget<NameValue[]>("fabric-breakdown");
  return (
    <ChartCard title="Production by Fabric Type — This Month" isLoading={isLoading} isError={isError} isEmpty={data?.length === 0}>
      <ResponsiveContainer width="100%" height={220}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={55}
            outerRadius={85}
            paddingAngle={2}
            dataKey="value"
            nameKey="name"
            label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
            labelLine={false}
          >
            {(data ?? []).map((_, i) => (
              <Cell key={i} fill={COLORS[i % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip contentStyle={CustomTooltipStyle.contentStyle} formatter={(v: number) => [`${v.toFixed(2)} kg`, "Net Weight"]} />
        </PieChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

// ── Top parties widget ───────────────────────────────────────────────────────
function TopPartiesWidget() {
  const { data, isLoading, isError } = useWidget<NameCount[]>("top-parties");
  return (
    <ChartCard
      title="Top Parties by Transaction Count — This Month"
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      height={Math.max(180, (data?.length ?? 6) * 28 + 30)}
    >
      <ResponsiveContainer width="100%" height={Math.max(180, (data?.length ?? 0) * 28 + 30)}>
        <BarChart data={data} layout="vertical" margin={{ left: 8, right: 24, top: 4, bottom: 4 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
          <XAxis type="number" tick={{ fontSize: 11 }} allowDecimals={false} />
          <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
          <Tooltip contentStyle={CustomTooltipStyle.contentStyle} formatter={(v: number) => [v, "Transactions"]} />
          <Bar dataKey="count" fill="#10b981" name="Transactions" radius={[0, 3, 3, 0]} barSize={16} />
        </BarChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

// ── Machine utilization widget ───────────────────────────────────────────────
function MachineUtilizationWidget() {
  const { data, isLoading, isError } = useWidget<NameLines[]>("machine-utilization");
  return (
    <ChartCard
      title="Machine Utilization — This Month"
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      height={Math.max(180, (data?.length ?? 6) * 28 + 30)}
    >
      <ResponsiveContainer width="100%" height={Math.max(180, (data?.length ?? 0) * 28 + 30)}>
        <BarChart data={data} layout="vertical" margin={{ left: 8, right: 24, top: 4, bottom: 4 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
          <XAxis type="number" tick={{ fontSize: 11 }} allowDecimals={false} />
          <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
          <Tooltip contentStyle={CustomTooltipStyle.contentStyle} formatter={(v: number) => [v, "Transaction Lines"]} />
          <Bar dataKey="lines" fill="#3b82f6" name="Lines" radius={[0, 3, 3, 0]} barSize={16} />
        </BarChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

// ── Operator output widget ───────────────────────────────────────────────────
function OperatorOutputWidget() {
  const { data, isLoading, isError } = useWidget<NameNetWeight[]>("operator-output");
  return (
    <ChartCard
      title="Top Operators by Net Weight — This Month"
      isLoading={isLoading}
      isError={isError}
      isEmpty={data?.length === 0}
      height={Math.max(180, (data?.length ?? 6) * 28 + 30)}
    >
      <ResponsiveContainer width="100%" height={Math.max(180, (data?.length ?? 0) * 28 + 30)}>
        <BarChart data={data} layout="vertical" margin={{ left: 8, right: 24, top: 4, bottom: 4 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
          <XAxis type="number" tick={{ fontSize: 11 }} tickFormatter={(v) => fmt(v)} />
          <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
          <Tooltip contentStyle={CustomTooltipStyle.contentStyle} formatter={(v: number) => [`${v.toFixed(2)} kg`, "Net Weight"]} />
          <Bar dataKey="netWeight" fill="#8b5cf6" name="Net Weight (kg)" radius={[0, 3, 3, 0]} barSize={16} />
        </BarChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

// ── Page ─────────────────────────────────────────────────────────────────────
export default function DashboardPage() {
  const { data: kpis } = useWidget<Kpis>("kpis");

  return (
    <Layout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
          {kpis && (
            <p className="text-sm text-muted-foreground mt-0.5">
              Overview for {kpis.periodLabel}
            </p>
          )}
        </div>

        {/* Each widget fetches and loads independently */}
        <KpiRow />

        <MonthlyTrendWidget />

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <DailyProductionWidget />
          <FabricBreakdownWidget />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <TopPartiesWidget />
          <MachineUtilizationWidget />
        </div>

        <OperatorOutputWidget />
      </div>
    </Layout>
  );
}
