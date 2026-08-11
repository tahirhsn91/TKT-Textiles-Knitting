/**
 * Production Analytics sub-view for the Machines tab (issue #112).
 *
 * Shows each machine's fabric production since its needle/sinker change date
 * (toggle-switched), computed server-side from Fabric Production transactions.
 * Includes a kg-share donut, a ranked summary table, and per-machine drill-down.
 */
import { useState } from "react";
import { useMemo } from "react";
import { Pie, PieChart, Cell } from "recharts";
import { Card, CardContent } from "@/components/ui/card";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import { useMachineAnalytics, type MachineAnalyticsBaseline } from "@/hooks/use-machine-analytics";

const DYE = [
  "#2A4C7A", "#627C50", "#C8891E", "#AB3F4C", "#FF3C00",
  "#4E729E", "#87A173", "#E0AC55", "#C97682", "#FF7A4D",
];
const CHART_HEIGHT = 280;

const shareConfig = {
  value: { label: "Production (kg)", color: "#2A4C7A" },
} satisfies ChartConfig;

const fmtKg = (n: number) => `${n.toLocaleString(undefined, { maximumFractionDigits: 2 })} kg`;

function BaselineToggle({
  value,
  onChange,
}: {
  value: MachineAnalyticsBaseline;
  onChange: (b: MachineAnalyticsBaseline) => void;
}) {
  return (
    <div className="inline-flex w-fit rounded-md border border-border bg-muted/40 p-0.5">
      {(["needle", "sinker"] as MachineAnalyticsBaseline[]).map((b) => (
        <button
          key={b}
          type="button"
          onClick={() => onChange(b)}
          className={
            "rounded px-3 py-1.5 text-xs font-medium transition-colors " +
            (value === b
              ? "selvedge bg-background text-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground")
          }
        >
          {b === "needle" ? "Needle" : "Sinker"}
        </button>
      ))}
    </div>
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

export function MachineAnalyticsView() {
  const [baseline, setBaseline] = useState<MachineAnalyticsBaseline>("needle");
  const { data, isLoading } = useMachineAnalytics(baseline);

  // kg-share slices for the donut (all machines, incl. zero — their slice is 0).
  const donut = useMemo(
    () =>
      (data?.rows ?? []).map((r) => ({
        name: r.machineNumber,
        value: r.totalKg,
        machine: r,
      })),
    [data],
  );
  const totalKg = useMemo(() => donut.reduce((s, d) => s + d.value, 0), [donut]);

  const skeleton = <Skeleton className="w-full" style={{ height: CHART_HEIGHT }} />;

  return (
    <div className="space-y-4">
      {/* Header: baseline toggle + context */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <BaselineToggle value={baseline} onChange={setBaseline} />
        <p className="text-xs text-muted-foreground">
          Production since {baseline === "needle" ? "needle" : "sinker"} change date →{" "}
          {data ? `computed to ${data.computedTo}` : "…"}
          {data?.excludedCount ? ` · ${data.excludedCount} machine(s) without a date excluded` : ""}
        </p>
      </div>

      {(isLoading || !data) && (
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
          <div className="lg:col-span-1">{skeleton}</div>
          <div className="lg:col-span-2">{skeleton}</div>
        </div>
      )}

      {!isLoading && data && (
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
          {/* Kg-share donut */}
          <ChartCard title="Production share" note={`total ${fmtKg(totalKg)}`}>
            <ChartContainer className="w-full" config={shareConfig} style={{ height: CHART_HEIGHT }}>
              <PieChart margin={{ top: 10, right: 10, bottom: 10, left: 10 }}>
                <Pie
                  data={donut}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius={58}
                  outerRadius={88}
                  paddingAngle={1}
                  stroke="#FFFFFF"
                  strokeWidth={2}
                  label={({ name, percent }) =>
                    percent * 100 >= 5 ? `${name} ${(percent * 100).toFixed(0)}%` : ""
                  }
                  labelLine={false}
                  isAnimationActive
                >
                  {donut.map((d, i) => (
                    <Cell key={d.name} fill={DYE[i % DYE.length]} />
                  ))}
                </Pie>
                <ChartTooltip
                  content={<ChartTooltipContent formatter={(v) => fmtKg(Number(v))} />}
                />
              </PieChart>
            </ChartContainer>
          </ChartCard>

          {/* Ranked summary table */}
          <ChartCard title="Production since change" note={`${data.machineCount} machine(s)`}>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-xs text-muted-foreground">
                    <th className="py-2 pr-3 font-medium">Machine</th>
                    <th className="py-2 pr-3 text-right font-medium">Kg</th>
                    <th className="py-2 pr-3 text-right font-medium">Rolls</th>
                    <th className="py-2 pr-3 text-right font-medium">Kg/roll</th>
                    <th className="py-2 pr-3 text-right font-medium">Change date</th>
                    <th className="py-2 text-right font-medium">Since</th>
                  </tr>
                </thead>
                <tbody>
                  {data.rows.map((r, i) => (
                    <tr key={r.machineId} className="border-b last:border-0">
                      <td className="py-2 pr-3 font-medium">
                        <span className="inline-flex items-center gap-2">
                          <span
                            className="inline-block h-2.5 w-2.5 rounded-full"
                            style={{ backgroundColor: DYE[i % DYE.length] }}
                          />
                          {r.machineNumber}
                        </span>
                      </td>
                      <td className="num py-2 pr-3 text-right">{r.totalKg.toFixed(2)}</td>
                      <td className="num py-2 pr-3 text-right">{r.totalRolls}</td>
                      <td className="num py-2 pr-3 text-right">{r.kgPerRoll.toFixed(2)}</td>
                      <td className="num py-2 pr-3 text-right">{r.changeDate ?? "-"}</td>
                      <td className="num py-2 text-right text-xs text-muted-foreground">
                        <span className="inline-block">{r.humanizedDuration ?? "-"}</span>
                        {r.daysSinceChange != null && (
                          <span className="ml-1 text-muted-foreground/70">({r.daysSinceChange}d)</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </ChartCard>
        </div>
      )}
    </div>
  );
}
