import { useQuery } from "@tanstack/react-query";
import {
  AreaChart, Area,
  BarChart, Bar,
  PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer,
} from "recharts";
import {
  Activity, Weight, Cpu, Wallet,
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

function fmtMoney(n: number) {
  return n.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

interface DashboardData {
  kpis: {
    totalTransactions: number;
    totalNetWeight: number;
    activeMachines: number;
    payrollDue: number;
    periodLabel: string;
  };
  payrollPeriodLabel: string;
  monthlyTrend: { label: string; netWeight: number; quantity: number }[];
  dailyProduction: { date: string; quantity: number; netWeight: number }[];
  fabricBreakdown: { name: string; value: number }[];
  topParties: { name: string; count: number }[];
  machineUtilization: { name: string; lines: number }[];
  operatorOutput: { name: string; netWeight: number }[];
  payrollBreakdown: { operatorName: string; baseWages: number; commissions: number; advances: number; netPayable: number }[];
}

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

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <Card>
      <CardHeader className="pb-2 pt-4 px-5">
        <CardTitle className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent className="px-4 pb-4">
        {children}
      </CardContent>
    </Card>
  );
}

const CustomTooltipStyle = {
  contentStyle: {
    background: "hsl(var(--card))",
    border: "1px solid hsl(var(--border))",
    borderRadius: 8,
    fontSize: 12,
  },
};

export default function DashboardPage() {
  const { data, isLoading, isError } = useQuery<DashboardData>({
    queryKey: ["dashboard-summary"],
    queryFn: async () => {
      const res = await fetch(`${BASE}/api/dashboard/summary`);
      if (!res.ok) throw new Error("Failed to load dashboard data");
      return res.json();
    },
  });

  return (
    <Layout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
          {data && (
            <p className="text-sm text-muted-foreground mt-0.5">
              Overview for {data.kpis.periodLabel}
            </p>
          )}
        </div>

        {/* KPI Cards */}
        {isLoading ? (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {[...Array(4)].map((_, i) => (
              <Card key={i}><CardContent className="p-5"><Skeleton className="h-20 w-full" /></CardContent></Card>
            ))}
          </div>
        ) : isError ? (
          <p className="text-destructive text-sm">Failed to load dashboard data.</p>
        ) : data ? (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <KpiCard
              title="Total Transactions"
              value={data.kpis.totalTransactions.toLocaleString()}
              sub="transaction headers this month"
              icon={Activity}
              color="bg-indigo-500"
            />
            <KpiCard
              title="Total Net Weight"
              value={`${fmt(data.kpis.totalNetWeight)} kg`}
              sub="net weight produced this month"
              icon={Weight}
              color="bg-amber-500"
            />
            <KpiCard
              title="Active Machines"
              value={String(data.kpis.activeMachines)}
              sub="machines with activity this month"
              icon={Cpu}
              color="bg-emerald-500"
            />
            <KpiCard
              title="Operator Payroll Due"
              value={`₹${fmt(data.kpis.payrollDue, 0)}`}
              sub={`net payable this period`}
              icon={Wallet}
              color="bg-blue-500"
            />
          </div>
        ) : null}

        {isLoading ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {[...Array(6)].map((_, i) => (
              <Card key={i}><CardContent className="p-5"><Skeleton className="h-56 w-full" /></CardContent></Card>
            ))}
          </div>
        ) : data ? (
          <>
            {/* Row 1: Monthly Trend (full width) */}
            <ChartCard title="Monthly Production Trend — Last 12 Months">
              <ResponsiveContainer width="100%" height={220}>
                <AreaChart data={data.monthlyTrend} {...CustomTooltipStyle}>
                  <defs>
                    <linearGradient id="gradNW" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                  <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => fmt(v)} />
                  <Tooltip
                    contentStyle={CustomTooltipStyle.contentStyle}
                    formatter={(v: number) => [`${v.toFixed(2)} kg`, "Net Weight"]}
                  />
                  <Area
                    type="monotone"
                    dataKey="netWeight"
                    stroke="#6366f1"
                    strokeWidth={2}
                    fill="url(#gradNW)"
                    name="Net Weight (kg)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </ChartCard>

            {/* Row 2: Daily Production + Fabric Breakdown */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <ChartCard title="Daily Production Volume — Last 30 Days">
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={data.dailyProduction} barSize={6}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                    <XAxis
                      dataKey="date"
                      tick={{ fontSize: 10 }}
                      tickFormatter={(v: string) => v.slice(5)}
                      interval="preserveStartEnd"
                    />
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

              <ChartCard title="Production by Fabric Type — This Month">
                {data.fabricBreakdown.length === 0 ? (
                  <div className="h-[220px] flex items-center justify-center text-muted-foreground text-sm">
                    No data for this period
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={220}>
                    <PieChart>
                      <Pie
                        data={data.fabricBreakdown}
                        cx="50%"
                        cy="50%"
                        innerRadius={55}
                        outerRadius={85}
                        paddingAngle={2}
                        dataKey="value"
                        nameKey="name"
                        label={({ name, percent }) =>
                          `${name} ${(percent * 100).toFixed(0)}%`
                        }
                        labelLine={false}
                      >
                        {data.fabricBreakdown.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={CustomTooltipStyle.contentStyle}
                        formatter={(v: number) => [`${v.toFixed(2)} kg`, "Net Weight"]}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                )}
              </ChartCard>
            </div>

            {/* Row 3: Top Parties + Machine Utilization */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <ChartCard title="Top Parties by Transaction Count — This Month">
                {data.topParties.length === 0 ? (
                  <div className="h-[220px] flex items-center justify-center text-muted-foreground text-sm">
                    No data for this period
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={Math.max(180, data.topParties.length * 28 + 30)}>
                    <BarChart
                      data={data.topParties}
                      layout="vertical"
                      margin={{ left: 8, right: 24, top: 4, bottom: 4 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
                      <XAxis type="number" tick={{ fontSize: 11 }} allowDecimals={false} />
                      <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
                      <Tooltip
                        contentStyle={CustomTooltipStyle.contentStyle}
                        formatter={(v: number) => [v, "Transactions"]}
                      />
                      <Bar dataKey="count" fill="#10b981" name="Transactions" radius={[0, 3, 3, 0]} barSize={16} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </ChartCard>

              <ChartCard title="Machine Utilization — This Month">
                {data.machineUtilization.length === 0 ? (
                  <div className="h-[220px] flex items-center justify-center text-muted-foreground text-sm">
                    No data for this period
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={Math.max(180, data.machineUtilization.length * 28 + 30)}>
                    <BarChart
                      data={data.machineUtilization}
                      layout="vertical"
                      margin={{ left: 8, right: 24, top: 4, bottom: 4 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
                      <XAxis type="number" tick={{ fontSize: 11 }} allowDecimals={false} />
                      <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
                      <Tooltip
                        contentStyle={CustomTooltipStyle.contentStyle}
                        formatter={(v: number) => [v, "Transaction Lines"]}
                      />
                      <Bar dataKey="lines" fill="#3b82f6" name="Lines" radius={[0, 3, 3, 0]} barSize={16} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </ChartCard>
            </div>

            {/* Row 4: Operator Output + Payroll Breakdown */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <ChartCard title="Top Operators by Net Weight — This Month">
                {data.operatorOutput.length === 0 ? (
                  <div className="h-[220px] flex items-center justify-center text-muted-foreground text-sm">
                    No data for this period
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={Math.max(180, data.operatorOutput.length * 28 + 30)}>
                    <BarChart
                      data={data.operatorOutput}
                      layout="vertical"
                      margin={{ left: 8, right: 24, top: 4, bottom: 4 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
                      <XAxis type="number" tick={{ fontSize: 11 }} tickFormatter={(v) => fmt(v)} />
                      <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
                      <Tooltip
                        contentStyle={CustomTooltipStyle.contentStyle}
                        formatter={(v: number) => [`${v.toFixed(2)} kg`, "Net Weight"]}
                      />
                      <Bar dataKey="netWeight" fill="#8b5cf6" name="Net Weight (kg)" radius={[0, 3, 3, 0]} barSize={16} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </ChartCard>

              <ChartCard title={`Operator Payroll Breakdown — ${data.payrollPeriodLabel}`}>
                {data.payrollBreakdown.length === 0 ? (
                  <div className="h-[220px] flex items-center justify-center text-muted-foreground text-sm">
                    No salary records for this period
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={Math.max(180, data.payrollBreakdown.length * 32 + 40)}>
                    <BarChart
                      data={data.payrollBreakdown}
                      layout="vertical"
                      margin={{ left: 8, right: 24, top: 4, bottom: 4 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" horizontal={false} />
                      <XAxis type="number" tick={{ fontSize: 11 }} tickFormatter={(v) => `₹${fmt(v, 0)}`} />
                      <YAxis dataKey="operatorName" type="category" tick={{ fontSize: 11 }} width={110} />
                      <Tooltip
                        contentStyle={CustomTooltipStyle.contentStyle}
                        formatter={(v: number, name: string) => [`₹${fmtMoney(v)}`, name]}
                      />
                      <Legend wrapperStyle={{ fontSize: 11 }} />
                      <Bar dataKey="baseWages" stackId="a" fill="#6366f1" name="Base Wages" barSize={16} />
                      <Bar dataKey="commissions" stackId="a" fill="#f59e0b" name="Commissions" barSize={16} />
                      <Bar dataKey="advances" stackId="a" fill="#ef4444" name="Advances" radius={[0, 3, 3, 0]} barSize={16} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </ChartCard>
            </div>
          </>
        ) : null}
      </div>
    </Layout>
  );
}
