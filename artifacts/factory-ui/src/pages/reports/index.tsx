import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  useListTransactionTypeMaster,
  useListJobMaster,
  useListPartyMaster,
  useListLocationMaster,
  useListFabricTypeMaster,
  useListYarnTypeMaster,
  useListYarnCountMaster,
  useListYarnBrandMaster,
  useListUomMaster,
  useListMachineMaster,
  useListMachineOperatorMaster,
} from "@workspace/api-client-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  PieChart, Pie, Cell, ResponsiveContainer,
} from "recharts";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { MultiSelect } from "@/components/ui/multi-select";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

// ─── Types ───────────────────────────────────────────────────────────────────

interface ReportRow {
  headerId: number;
  date: string;
  docNumber: string;
  sl: string | null;
  gsm: number | null;
  transactionTypeName: string | null;
  transactionTypeAction: string | null;
  jobName: string | null;
  partyName: string | null;
  locationName: string | null;
  fabricTypeName: string | null;
  detailId: number;
  quantity: string | null;
  netWt: string | null;
  yarnTypeName: string | null;
  yarnCountName: string | null;
  yarnBrandName: string | null;
  uomName: string | null;
  machineName: string | null;
  machineOperatorName: string | null;
}

interface Filters {
  dateFrom: string;
  dateTo: string;
  year: string;
  month: string;
  transactionTypeId: string[];
  jobId: string[];
  partyId: string[];
  locationId: string[];
  fabricTypeId: string[];
  yarnTypeId: string[];
  yarnCountId: string[];
  yarnBrandId: string[];
  uomId: string[];
  machineId: string[];
  machineOperatorId: string[];
}

type GroupByKey =
  | "date"
  | "month"
  | "transactionTypeName"
  | "partyName"
  | "jobName"
  | "locationName"
  | "fabricTypeName"
  | "machineName"
  | "machineOperatorName"
  | "yarnTypeName"
  | "yarnCountName"
  | "yarnBrandName"
  | "uomName";

const EMPTY_FILTERS: Filters = {
  dateFrom: "", dateTo: "", year: "", month: "",
  transactionTypeId: [], jobId: [], partyId: [], locationId: [], fabricTypeId: [],
  yarnTypeId: [], yarnCountId: [], yarnBrandId: [], uomId: [],
  machineId: [], machineOperatorId: [],
};

const GROUP_BY_OPTIONS: { value: GroupByKey; label: string }[] = [
  { value: "date",                label: "Date" },
  { value: "month",               label: "Month" },
  { value: "transactionTypeName", label: "Transaction Type" },
  { value: "partyName",           label: "Party" },
  { value: "jobName",             label: "Job" },
  { value: "locationName",        label: "Location" },
  { value: "fabricTypeName",      label: "Fabric Type" },
  { value: "machineName",         label: "Machine" },
  { value: "machineOperatorName", label: "Machine Operator" },
  { value: "yarnTypeName",        label: "Yarn Type" },
  { value: "yarnCountName",       label: "Yarn Count" },
  { value: "yarnBrandName",       label: "Yarn Brand" },
  { value: "uomName",             label: "UOM" },
];

const CHART_COLORS = [
  "#2563eb", "#16a34a", "#dc2626", "#d97706", "#7c3aed",
  "#0891b2", "#be185d", "#65a30d", "#ea580c", "#6d28d9",
];

const MONTHS = [
  "January","February","March","April","May","June",
  "July","August","September","October","November","December",
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

function toNum(s: string | null | undefined): number {
  const n = parseFloat(s ?? "");
  return isNaN(n) ? 0 : n;
}

function getMultiplier(action: string | null | undefined): number {
  if (!action) return 1;
  return action.trim().toLowerCase() === "minus" ? -1 : 1;
}

function signedQty(row: ReportRow): number {
  return toNum(row.quantity) * getMultiplier(row.transactionTypeAction);
}

function signedNetWt(row: ReportRow): number {
  return toNum(row.netWt) * getMultiplier(row.transactionTypeAction);
}

function fmt(n: number): string {
  return n.toLocaleString("en-US", { minimumFractionDigits: 3, maximumFractionDigits: 3 });
}

function getMonthLabel(dateStr: string): string {
  const d = new Date(dateStr);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

function groupRows(rows: ReportRow[], key: GroupByKey) {
  const map = new Map<string, { qty: number; netWt: number; count: number }>();
  for (const row of rows) {
    const rawKey = key === "month" ? getMonthLabel(row.date) : (row[key] ?? "—");
    const k = String(rawKey);
    const existing = map.get(k) ?? { qty: 0, netWt: 0, count: 0 };
    existing.qty   += signedQty(row);
    existing.netWt += signedNetWt(row);
    existing.count += 1;
    map.set(k, existing);
  }
  return Array.from(map.entries())
    .map(([label, v]) => ({ label, ...v }))
    .sort((a, b) => a.label.localeCompare(b.label));
}

function buildQueryString(f: Filters): string {
  const params = new URLSearchParams();
  Object.entries(f).forEach(([k, v]) => {
    if (Array.isArray(v)) {
      if (v.length > 0) params.set(k, v.join(","));
    } else if (v) {
      params.set(k, v as string);
    }
  });
  return params.toString();
}

// ─── Filter Row helper component ────────────────────────────────────────────

function FilterMulti({
  label, values, onChange, options,
}: {
  label: string;
  values: string[];
  onChange: (v: string[]) => void;
  options: { id: number; name: string }[] | undefined;
}) {
  const opts = useMemo(
    () => (options ?? []).map((o) => ({ value: o.id.toString(), label: o.name })),
    [options]
  );
  return (
    <div className="flex flex-col gap-1">
      <Label className="text-xs text-muted-foreground">{label}</Label>
      <MultiSelect options={opts} selected={values} onChange={onChange} placeholder={`All`} />
    </div>
  );
}

// ─── Main Page ───────────────────────────────────────────────────────────────

export default function ReportsPage() {
  const [filters, setFilters]         = useState<Filters>(EMPTY_FILTERS);
  const [applied, setApplied]         = useState<Filters>(EMPTY_FILTERS);
  const [groupBy, setGroupBy]         = useState<GroupByKey>("date");
  const [hasRun, setHasRun]           = useState(false);

  // Master data for filter dropdowns
  const { data: transactionTypes }    = useListTransactionTypeMaster();
  const { data: jobs }                = useListJobMaster();
  const { data: parties }             = useListPartyMaster();
  const { data: locations }           = useListLocationMaster();
  const { data: fabricTypes }         = useListFabricTypeMaster();
  const { data: yarnTypes }           = useListYarnTypeMaster();
  const { data: yarnCounts }          = useListYarnCountMaster();
  const { data: yarnBrands }          = useListYarnBrandMaster();
  const { data: uoms }                = useListUomMaster();
  const { data: machines }            = useListMachineMaster();
  const { data: machineOperators }    = useListMachineOperatorMaster();

  const qs = useMemo(() => buildQueryString(applied), [applied]);

  const { data: rows = [], isFetching, isError } = useQuery<ReportRow[]>({
    queryKey: ["reports/data", qs],
    queryFn: async () => {
      const res = await fetch(`/api/reports/data${qs ? `?${qs}` : ""}`);
      if (!res.ok) throw new Error("Failed to fetch report data");
      return res.json();
    },
    enabled: hasRun,
  });

  function set(key: keyof Filters, val: string | string[]) {
    setFilters((prev) => ({ ...prev, [key]: val }));
  }

  function runReport() {
    setApplied(filters);
    setHasRun(true);
  }

  function resetFilters() {
    setFilters(EMPTY_FILTERS);
    setApplied(EMPTY_FILTERS);
    setHasRun(false);
  }

  const grouped  = useMemo(() => groupRows(rows, groupBy), [rows, groupBy]);
  const totalQty  = useMemo(() => rows.reduce((s, r) => s + signedQty(r), 0), [rows]);
  const totalNetWt = useMemo(() => rows.reduce((s, r) => s + signedNetWt(r), 0), [rows]);

  const runningBalances = useMemo(() => {
    let bal = 0;
    return rows.map((r) => {
      bal += signedNetWt(r);
      return bal;
    });
  }, [rows]);

  // Years available in data for the year dropdown
  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 6 }, (_, i) => currentYear - i);

  // UOM options need name
  const uomOptions = uoms?.map((u) => ({ id: u.id, name: u.name }));

  return (
    <Layout>
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Reports</h1>
            <p className="text-sm text-muted-foreground">Apply filters and run the report to see detailed and summary data with charts.</p>
          </div>
        </div>

        {/* ── Filter Panel ─────────────────────────────────── */}
        <Card>
          <CardHeader className="pb-3 pt-4 px-4">
            <CardTitle className="text-base">Filters</CardTitle>
          </CardHeader>
          <CardContent className="px-4 pb-4 space-y-4">
            {/* Date / Period row */}
            <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-6 gap-3">
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Date From</Label>
                <Input type="date" className="h-8 text-sm" value={filters.dateFrom} onChange={(e) => set("dateFrom", e.target.value)} />
              </div>
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Date To</Label>
                <Input type="date" className="h-8 text-sm" value={filters.dateTo} onChange={(e) => set("dateTo", e.target.value)} />
              </div>
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Year</Label>
                <Select value={filters.year || "all"} onValueChange={(v) => set("year", v === "all" ? "" : v)}>
                  <SelectTrigger className="h-8 text-sm"><SelectValue placeholder="All Years" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Years</SelectItem>
                    {years.map((y) => <SelectItem key={y} value={y.toString()}>{y}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Month</Label>
                <Select value={filters.month || "all"} onValueChange={(v) => set("month", v === "all" ? "" : v)}>
                  <SelectTrigger className="h-8 text-sm"><SelectValue placeholder="All Months" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Months</SelectItem>
                    {MONTHS.map((m, i) => <SelectItem key={i + 1} value={(i + 1).toString()}>{m}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Header master filters */}
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
              <FilterMulti label="Transaction Type" values={filters.transactionTypeId} onChange={(v) => set("transactionTypeId", v)} options={transactionTypes} />
              <FilterMulti label="Job"              values={filters.jobId}             onChange={(v) => set("jobId", v)}             options={jobs} />
              <FilterMulti label="Party"            values={filters.partyId}           onChange={(v) => set("partyId", v)}           options={parties} />
              <FilterMulti label="Location"         values={filters.locationId}        onChange={(v) => set("locationId", v)}        options={locations} />
              <FilterMulti label="Fabric Type"      values={filters.fabricTypeId}      onChange={(v) => set("fabricTypeId", v)}      options={fabricTypes} />
            </div>

            {/* Detail master filters */}
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
              <FilterMulti label="Yarn Type"         values={filters.yarnTypeId}         onChange={(v) => set("yarnTypeId", v)}         options={yarnTypes} />
              <FilterMulti label="Yarn Count"        values={filters.yarnCountId}        onChange={(v) => set("yarnCountId", v)}        options={yarnCounts} />
              <FilterMulti label="Yarn Brand"        values={filters.yarnBrandId}        onChange={(v) => set("yarnBrandId", v)}        options={yarnBrands} />
              <FilterMulti label="UOM"               values={filters.uomId}              onChange={(v) => set("uomId", v)}              options={uomOptions} />
              <FilterMulti label="Machine"           values={filters.machineId}          onChange={(v) => set("machineId", v)}          options={machines} />
              <FilterMulti label="Machine Operator"  values={filters.machineOperatorId}  onChange={(v) => set("machineOperatorId", v)}  options={machineOperators} />
            </div>

            <div className="flex items-center gap-2 pt-1">
              <Button onClick={runReport} disabled={isFetching} size="sm">
                {isFetching ? "Loading..." : "Run Report"}
              </Button>
              <Button variant="outline" size="sm" onClick={resetFilters}>Reset</Button>
            </div>
          </CardContent>
        </Card>

        {/* ── Results ──────────────────────────────────────── */}
        {hasRun && (
          <>
            {/* Totals summary bar */}
            <div className="grid grid-cols-3 gap-3">
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Total Rows</p>
                  <p className="text-2xl font-semibold">{rows.length.toLocaleString()}</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Total Qty</p>
                  <p className="text-2xl font-semibold">{fmt(totalQty)}</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Total Net Wt</p>
                  <p className="text-2xl font-semibold">{fmt(totalNetWt)}</p>
                </CardContent>
              </Card>
            </div>

            {isError && (
              <p className="text-sm text-destructive">Failed to load report data. Please try again.</p>
            )}

            {!isError && rows.length === 0 && !isFetching && (
              <p className="text-sm text-muted-foreground">No data found for the selected filters.</p>
            )}

            {rows.length > 0 && (
              <Tabs defaultValue="summary">
                <TabsList>
                  <TabsTrigger value="summary">Summary</TabsTrigger>
                  <TabsTrigger value="detail">Detailed</TabsTrigger>
                  <TabsTrigger value="charts">Charts</TabsTrigger>
                </TabsList>

                {/* ── Summary Tab ─────────────────────────── */}
                <TabsContent value="summary" className="space-y-3 mt-3">
                  <div className="flex items-center gap-2">
                    <Label className="text-sm shrink-0">Group By:</Label>
                    <Select value={groupBy} onValueChange={(v) => setGroupBy(v as GroupByKey)}>
                      <SelectTrigger className="h-8 w-52 text-sm">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {GROUP_BY_OPTIONS.map((o) => (
                          <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="rounded-md border overflow-auto max-h-[500px]">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>{GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy}</TableHead>
                          <TableHead className="text-right">Rows</TableHead>
                          <TableHead className="text-right">Total Qty</TableHead>
                          <TableHead className="text-right">Total Net Wt</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {grouped.map((r) => (
                          <TableRow key={r.label}>
                            <TableCell className="font-medium">{r.label}</TableCell>
                            <TableCell className="text-right">{r.count}</TableCell>
                            <TableCell className="text-right">{fmt(r.qty)}</TableCell>
                            <TableCell className="text-right">{fmt(r.netWt)}</TableCell>
                          </TableRow>
                        ))}
                        <TableRow className="bg-muted/50 font-semibold">
                          <TableCell>Total</TableCell>
                          <TableCell className="text-right">{rows.length}</TableCell>
                          <TableCell className="text-right">{fmt(totalQty)}</TableCell>
                          <TableCell className="text-right">{fmt(totalNetWt)}</TableCell>
                        </TableRow>
                      </TableBody>
                    </Table>
                  </div>
                </TabsContent>

                {/* ── Detail Tab ──────────────────────────── */}
                <TabsContent value="detail" className="mt-3">
                  <div className="rounded-md border overflow-auto max-h-[600px]">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="whitespace-nowrap">Date</TableHead>
                          <TableHead className="whitespace-nowrap">Doc Number</TableHead>
                          <TableHead className="whitespace-nowrap">SL</TableHead>
                          <TableHead className="whitespace-nowrap">GSM</TableHead>
                          <TableHead className="whitespace-nowrap">Txn Type</TableHead>
                          <TableHead className="whitespace-nowrap">Job</TableHead>
                          <TableHead className="whitespace-nowrap">Party</TableHead>
                          <TableHead className="whitespace-nowrap">Location</TableHead>
                          <TableHead className="whitespace-nowrap">Fabric Type</TableHead>
                          <TableHead className="whitespace-nowrap">Yarn Type</TableHead>
                          <TableHead className="whitespace-nowrap">Yarn Count</TableHead>
                          <TableHead className="whitespace-nowrap">Yarn Brand</TableHead>
                          <TableHead className="whitespace-nowrap">UOM</TableHead>
                          <TableHead className="whitespace-nowrap">Machine</TableHead>
                          <TableHead className="whitespace-nowrap">Operator</TableHead>
                          <TableHead className="whitespace-nowrap text-right">Qty</TableHead>
                          <TableHead className="whitespace-nowrap text-right">Net Wt</TableHead>
                          <TableHead className="whitespace-nowrap text-right">Running Balance</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {rows.map((r, idx) => (
                          <TableRow key={r.detailId}>
                            <TableCell className="whitespace-nowrap">{r.date}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.docNumber}</TableCell>
                            <TableCell>{r.sl ?? "—"}</TableCell>
                            <TableCell>{r.gsm ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.transactionTypeName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.jobName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.partyName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.locationName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.fabricTypeName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.yarnTypeName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.yarnCountName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.yarnBrandName ?? "—"}</TableCell>
                            <TableCell>{r.uomName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.machineName ?? "—"}</TableCell>
                            <TableCell className="whitespace-nowrap">{r.machineOperatorName ?? "—"}</TableCell>
                            <TableCell className={`text-right whitespace-nowrap${getMultiplier(r.transactionTypeAction) < 0 ? " text-red-600" : ""}`}>
                              {r.quantity != null ? fmt(signedQty(r)) : "—"}
                            </TableCell>
                            <TableCell className={`text-right whitespace-nowrap${getMultiplier(r.transactionTypeAction) < 0 ? " text-red-600" : ""}`}>
                              {r.netWt != null ? fmt(signedNetWt(r)) : "—"}
                            </TableCell>
                            <TableCell className={`text-right whitespace-nowrap font-medium${runningBalances[idx] < 0 ? " text-red-600" : " text-blue-700"}`}>
                              {fmt(runningBalances[idx])}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                </TabsContent>

                {/* ── Charts Tab ──────────────────────────── */}
                <TabsContent value="charts" className="mt-3 space-y-6">
                  <ChartSection rows={rows} />
                </TabsContent>
              </Tabs>
            )}
          </>
        )}
      </div>
    </Layout>
  );
}

// ─── Charts Section ──────────────────────────────────────────────────────────

function ChartSection({ rows }: { rows: ReportRow[] }) {
  const byMonth = useMemo(() => {
    const map = new Map<string, { qty: number; netWt: number }>();
    for (const r of rows) {
      const k = getMonthLabel(r.date);
      const e = map.get(k) ?? { qty: 0, netWt: 0 };
      e.qty   += signedQty(r);
      e.netWt += signedNetWt(r);
      map.set(k, e);
    }
    return Array.from(map.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([month, v]) => ({ month, qty: parseFloat(v.qty.toFixed(3)), netWt: parseFloat(v.netWt.toFixed(3)) }));
  }, [rows]);

  const byMachine = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.machineName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedQty(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 15)
      .map(([name, qty]) => ({ name, qty: parseFloat(qty.toFixed(3)) }));
  }, [rows]);

  const byYarnType = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.yarnTypeName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedQty(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value: parseFloat(value.toFixed(3)) }));
  }, [rows]);

  const byFabricType = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.fabricTypeName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedQty(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value: parseFloat(value.toFixed(3)) }));
  }, [rows]);

  const byParty = useMemo(() => {
    const map = new Map<string, { qty: number; netWt: number }>();
    for (const r of rows) {
      const k = r.partyName ?? "Unknown";
      const e = map.get(k) ?? { qty: 0, netWt: 0 };
      e.qty   += signedQty(r);
      e.netWt += signedNetWt(r);
      map.set(k, e);
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1].qty - a[1].qty)
      .slice(0, 10)
      .map(([name, v]) => ({ name, qty: parseFloat(v.qty.toFixed(3)), netWt: parseFloat(v.netWt.toFixed(3)) }));
  }, [rows]);

  return (
    <div className="space-y-6">
      {/* Qty and Net Wt by Month */}
      {byMonth.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Qty and Net Wt by Month</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byMonth} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => fmt(v)} />
                <Legend />
                <Bar dataKey="qty"   name="Qty"    fill={CHART_COLORS[0]} />
                <Bar dataKey="netWt" name="Net Wt" fill={CHART_COLORS[1]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Qty by Machine */}
      {byMachine.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Qty by Machine</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byMachine} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => fmt(v)} />
                <Bar dataKey="qty" name="Qty" fill={CHART_COLORS[2]}>
                  {byMachine.map((_, i) => (
                    <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Qty by Party */}
      {byParty.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Qty and Net Wt by Party</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byParty} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => fmt(v)} />
                <Legend />
                <Bar dataKey="qty"   name="Qty"    fill={CHART_COLORS[3]} />
                <Bar dataKey="netWt" name="Net Wt" fill={CHART_COLORS[4]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Pie: Qty by Yarn Type */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {byYarnType.length > 0 && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Qty by Yarn Type</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie
                    data={byYarnType}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={90}
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(1)}%)`}
                    labelLine={false}
                  >
                    {byYarnType.map((_, i) => (
                      <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v: number) => fmt(v)} />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        )}

        {/* Pie: Qty by Fabric Type */}
        {byFabricType.length > 0 && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Qty by Fabric Type</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie
                    data={byFabricType}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={90}
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(1)}%)`}
                    labelLine={false}
                  >
                    {byFabricType.map((_, i) => (
                      <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v: number) => fmt(v)} />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
