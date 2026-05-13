import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
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
import { Printer, Download, FileText, FileSpreadsheet, ChevronUp, ChevronDown, ChevronsUpDown } from "lucide-react";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { Checkbox } from "@/components/ui/checkbox";

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

type SummarySortKey = "label" | "count" | "qty" | "netWt";
type SortDir        = "asc" | "desc";

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

// ─── Sortable column header ───────────────────────────────────────────────────

function SortHead({
  label, sortKey, sort, onSort, right,
}: {
  label: string;
  sortKey: string;
  sort: { key: string | null; dir: SortDir };
  onSort: (key: string) => void;
  right?: boolean;
}) {
  const active = sort.key === sortKey;
  return (
    <TableHead
      className={`cursor-pointer select-none whitespace-nowrap${right ? " text-right" : ""}`}
      onClick={() => onSort(sortKey)}
    >
      <span className={`inline-flex items-center gap-1${right ? " justify-end w-full" : ""}`}>
        {label}
        {active
          ? sort.dir === "asc"
            ? <ChevronUp className="h-3 w-3 shrink-0" />
            : <ChevronDown className="h-3 w-3 shrink-0" />
          : <ChevronsUpDown className="h-3 w-3 shrink-0 opacity-35" />
        }
      </span>
    </TableHead>
  );
}

// ─── Detail column definitions ───────────────────────────────────────────────

type DetailColKey =
  | "date" | "docNumber" | "sl" | "gsm" | "transactionTypeName"
  | "jobName" | "partyName" | "locationName" | "fabricTypeName"
  | "yarnTypeName" | "yarnCountName" | "yarnBrandName" | "uomName"
  | "machineName" | "machineOperatorName" | "quantity" | "netWt" | "runningBalance";

const DETAIL_COLUMNS: { key: DetailColKey; label: string }[] = [
  { key: "date",                  label: "Date" },
  { key: "docNumber",             label: "Doc Number" },
  { key: "sl",                    label: "SL" },
  { key: "gsm",                   label: "GSM" },
  { key: "transactionTypeName",   label: "Txn Type" },
  { key: "jobName",               label: "Job" },
  { key: "partyName",             label: "Party" },
  { key: "locationName",          label: "Location" },
  { key: "fabricTypeName",        label: "Fabric Type" },
  { key: "yarnTypeName",          label: "Yarn Type" },
  { key: "yarnCountName",         label: "Yarn Count" },
  { key: "yarnBrandName",         label: "Yarn Brand" },
  { key: "uomName",               label: "UOM" },
  { key: "machineName",           label: "Machine" },
  { key: "machineOperatorName",   label: "Operator" },
  { key: "quantity",              label: "Qty" },
  { key: "netWt",                 label: "Net Wt" },
  { key: "runningBalance",        label: "Running Balance" },
];

const ALL_DETAIL_KEYS = DETAIL_COLUMNS.map((c) => c.key);

// ─── Main Page ───────────────────────────────────────────────────────────────

export default function ReportsPage() {
  const [filters, setFilters]         = useState<Filters>(EMPTY_FILTERS);
  const [applied, setApplied]         = useState<Filters>(EMPTY_FILTERS);
  const [groupBy, setGroupBy]         = useState<GroupByKey>("date");
  const [hasRun, setHasRun]           = useState(false);
  const [visibleCols, setVisibleCols] = useState<Set<DetailColKey>>(new Set(ALL_DETAIL_KEYS));
  const [activeTab, setActiveTab]     = useState("summary");
  const [sortSummary, setSortSummary] = useState<{ key: SummarySortKey; dir: SortDir }>({ key: "label", dir: "asc" });
  const [sortDetail,  setSortDetail]  = useState<{ key: DetailColKey | null; dir: SortDir }>({ key: null, dir: "asc" });

  function toggleCol(key: DetailColKey) {
    setVisibleCols((prev) => {
      const next = new Set(prev);
      if (next.has(key)) { next.delete(key); } else { next.add(key); }
      return next;
    });
  }

  function showAllCols()  { setVisibleCols(new Set(ALL_DETAIL_KEYS)); }
  function hideAllCols()  { setVisibleCols(new Set()); }

  const visibleColsList = DETAIL_COLUMNS.filter((c) => visibleCols.has(c.key));
  const col = (key: DetailColKey) => visibleCols.has(key);

  // ── Export helpers ────────────────────────────────────────────────────────

  function downloadBlob(content: string, filename: string, mime: string) {
    const blob = new Blob([content], { type: mime });
    const url  = URL.createObjectURL(blob);
    const a    = Object.assign(document.createElement("a"), { href: url, download: filename });
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  function toCSV(headers: string[], dataRows: (string | number | null)[][]): string {
    const escape = (v: string | number | null) => {
      const s = String(v ?? "");
      return s.includes(",") || s.includes('"') || s.includes("\n") ? `"${s.replace(/"/g, '""')}"` : s;
    };
    return [headers, ...dataRows].map((row) => row.map(escape).join(",")).join("\r\n");
  }

  function exportSummaryCSV() {
    const groupLabel = GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy;
    const headers    = [groupLabel, "Rows", "Total Qty", "Total Net Wt"];
    const data       = [
      ...grouped.map((r) => [r.label, r.count, fmt(r.qty), fmt(r.netWt)]),
      ["Total", rows.length, fmt(totalQty), fmt(totalNetWt)],
    ];
    downloadBlob(toCSV(headers, data), "report-summary.csv", "text/csv;charset=utf-8;");
  }

  function exportDetailCSV() {
    const headers = visibleColsList.map((c) => c.label);
    const data    = rows.map((r, idx) => {
      return visibleColsList.map((c) => {
        switch (c.key) {
          case "date":                  return r.date;
          case "docNumber":             return r.docNumber;
          case "sl":                    return r.sl ?? "";
          case "gsm":                   return r.gsm ?? "";
          case "transactionTypeName":   return r.transactionTypeName ?? "";
          case "jobName":               return r.jobName ?? "";
          case "partyName":             return r.partyName ?? "";
          case "locationName":          return r.locationName ?? "";
          case "fabricTypeName":        return r.fabricTypeName ?? "";
          case "yarnTypeName":          return r.yarnTypeName ?? "";
          case "yarnCountName":         return r.yarnCountName ?? "";
          case "yarnBrandName":         return r.yarnBrandName ?? "";
          case "uomName":               return r.uomName ?? "";
          case "machineName":           return r.machineName ?? "";
          case "machineOperatorName":   return r.machineOperatorName ?? "";
          case "quantity":              return r.quantity != null ? fmt(signedQty(r)) : "";
          case "netWt":                 return r.netWt    != null ? fmt(signedNetWt(r)) : "";
          case "runningBalance":        return fmt(runningBalances[idx]);
          default:                      return "";
        }
      });
    });
    downloadBlob(toCSV(headers, data), "report-detail.csv", "text/csv;charset=utf-8;");
  }

  function exportSummaryPDF() {
    const doc        = new jsPDF({ orientation: "landscape" });
    const groupLabel = GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy;
    doc.setFontSize(13);
    doc.text(`Report Summary — grouped by ${groupLabel}`, 14, 14);
    autoTable(doc, {
      startY: 20,
      head: [[groupLabel, "Rows", "Total Qty", "Total Net Wt"]],
      body: [
        ...grouped.map((r) => [r.label, r.count, fmt(r.qty), fmt(r.netWt)]),
        ["Total", rows.length, fmt(totalQty), fmt(totalNetWt)],
      ],
      styles: { fontSize: 9 },
      headStyles: { fillColor: [37, 99, 235] },
      foot: [],
    });
    doc.save("report-summary.pdf");
  }

  function exportDetailPDF() {
    const doc     = new jsPDF({ orientation: "landscape" });
    const headers = visibleColsList.map((c) => c.label);
    doc.setFontSize(13);
    doc.text("Report — Detailed", 14, 14);
    autoTable(doc, {
      startY: 20,
      head: [headers],
      body: rows.map((r, idx) =>
        visibleColsList.map((c) => {
          switch (c.key) {
            case "date":                  return r.date;
            case "docNumber":             return r.docNumber;
            case "sl":                    return r.sl ?? "—";
            case "gsm":                   return String(r.gsm ?? "—");
            case "transactionTypeName":   return r.transactionTypeName ?? "—";
            case "jobName":               return r.jobName ?? "—";
            case "partyName":             return r.partyName ?? "—";
            case "locationName":          return r.locationName ?? "—";
            case "fabricTypeName":        return r.fabricTypeName ?? "—";
            case "yarnTypeName":          return r.yarnTypeName ?? "—";
            case "yarnCountName":         return r.yarnCountName ?? "—";
            case "yarnBrandName":         return r.yarnBrandName ?? "—";
            case "uomName":               return r.uomName ?? "—";
            case "machineName":           return r.machineName ?? "—";
            case "machineOperatorName":   return r.machineOperatorName ?? "—";
            case "quantity":              return r.quantity != null ? fmt(signedQty(r)) : "—";
            case "netWt":                 return r.netWt    != null ? fmt(signedNetWt(r)) : "—";
            case "runningBalance":        return fmt(runningBalances[idx]);
            default:                      return "";
          }
        })
      ),
      styles: { fontSize: 7 },
      headStyles: { fillColor: [37, 99, 235] },
    });
    doc.save("report-detail.pdf");
  }

  function handlePrint() { window.print(); }

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

  function handleSortSummary(key: string) {
    const k = key as SummarySortKey;
    setSortSummary((prev) =>
      prev.key === k ? { key: k, dir: prev.dir === "asc" ? "desc" : "asc" } : { key: k, dir: "asc" }
    );
  }

  function handleSortDetail(key: string) {
    const k = key as DetailColKey;
    setSortDetail((prev) =>
      prev.key === k ? { key: k, dir: prev.dir === "asc" ? "desc" : "asc" } : { key: k, dir: "asc" }
    );
  }

  const sortedGrouped = useMemo(() => {
    const arr = [...grouped];
    arr.sort((a, b) => {
      let av: string | number, bv: string | number;
      switch (sortSummary.key) {
        case "count": av = a.count; bv = b.count; break;
        case "qty":   av = a.qty;   bv = b.qty;   break;
        case "netWt": av = a.netWt; bv = b.netWt; break;
        default:      av = a.label; bv = b.label;
      }
      if (typeof av === "number")
        return sortSummary.dir === "asc" ? av - (bv as number) : (bv as number) - av;
      return sortSummary.dir === "asc"
        ? av.localeCompare(bv as string)
        : (bv as string).localeCompare(av);
    });
    return arr;
  }, [grouped, sortSummary]);

  const sortedDetailRows = useMemo(() => {
    const indexed = rows.map((r, idx) => ({ r, idx, bal: runningBalances[idx] }));
    if (!sortDetail.key) return indexed;
    const key = sortDetail.key;
    return [...indexed].sort((a, b) => {
      let av: string | number, bv: string | number;
      switch (key) {
        case "runningBalance": av = a.bal;             bv = b.bal;             break;
        case "quantity":       av = signedQty(a.r);    bv = signedQty(b.r);    break;
        case "netWt":          av = signedNetWt(a.r);  bv = signedNetWt(b.r);  break;
        case "gsm":            av = a.r.gsm ?? 0;      bv = b.r.gsm ?? 0;      break;
        default: {
          const rawA = a.r[key as keyof ReportRow];
          const rawB = b.r[key as keyof ReportRow];
          av = rawA != null ? String(rawA) : "";
          bv = rawB != null ? String(rawB) : "";
        }
      }
      if (typeof av === "number")
        return sortDetail.dir === "asc" ? av - (bv as number) : (bv as number) - av;
      return sortDetail.dir === "asc"
        ? av.localeCompare(bv as string)
        : (bv as string).localeCompare(av);
    });
  }, [rows, runningBalances, sortDetail]);

  // Years available in data for the year dropdown
  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 6 }, (_, i) => currentYear - i);

  // UOM options need name
  const uomOptions = uoms?.map((u) => ({ id: u.id, name: u.name }));

  // Job options filtered by selected parties (all if no party filter)
  const filteredJobOptions = useMemo(
    () =>
      (jobs ?? []).filter((j) =>
        filters.partyId.length === 0 ? true : filters.partyId.includes(String(j.partyId ?? ""))
      ),
    [jobs, filters.partyId]
  );

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
              <FilterMulti label="Party"            values={filters.partyId}           onChange={(v) => { set("partyId", v); set("jobId", []); }} options={parties} />
              <FilterMulti label="Job Type"         values={filters.jobId}             onChange={(v) => set("jobId", v)}             options={filteredJobOptions} />
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
              <Tabs value={activeTab} onValueChange={setActiveTab}>
                <div className="flex items-center justify-between gap-2 flex-wrap">
                  <TabsList>
                    <TabsTrigger value="summary">Summary</TabsTrigger>
                    <TabsTrigger value="detail">Detailed</TabsTrigger>
                    <TabsTrigger value="charts">Charts</TabsTrigger>
                  </TabsList>

                  {/* Print / Export toolbar */}
                  {activeTab !== "charts" && (
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={handlePrint}
                        className="gap-1.5"
                      >
                        <Printer className="h-3.5 w-3.5" />
                        Print
                      </Button>

                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="outline" size="sm" className="gap-1.5">
                            <Download className="h-3.5 w-3.5" />
                            Export
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem
                            onClick={activeTab === "summary" ? exportSummaryCSV : exportDetailCSV}
                            className="gap-2"
                          >
                            <FileSpreadsheet className="h-4 w-4 text-green-600" />
                            Export as CSV
                          </DropdownMenuItem>
                          <DropdownMenuItem
                            onClick={activeTab === "summary" ? exportSummaryPDF : exportDetailPDF}
                            className="gap-2"
                          >
                            <FileText className="h-4 w-4 text-red-600" />
                            Export as PDF
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  )}
                </div>

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
                          <SortHead
                            label={GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy}
                            sortKey="label"
                            sort={sortSummary}
                            onSort={handleSortSummary}
                          />
                          <SortHead label="Rows"         sortKey="count" sort={sortSummary} onSort={handleSortSummary} right />
                          <SortHead label="Total Qty"    sortKey="qty"   sort={sortSummary} onSort={handleSortSummary} right />
                          <SortHead label="Total Net Wt" sortKey="netWt" sort={sortSummary} onSort={handleSortSummary} right />
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {sortedGrouped.map((r) => (
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
                <TabsContent value="detail" className="mt-3 space-y-3">

                  {/* Column visibility picker */}
                  <Card className="border-dashed">
                    <CardContent className="px-4 py-3">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Show / Hide Columns</span>
                        <div className="flex gap-2">
                          <button
                            className="text-xs text-primary hover:underline"
                            onClick={showAllCols}
                          >Show All</button>
                          <span className="text-xs text-muted-foreground">·</span>
                          <button
                            className="text-xs text-primary hover:underline"
                            onClick={hideAllCols}
                          >Hide All</button>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-x-5 gap-y-2">
                        {DETAIL_COLUMNS.map((c) => (
                          <label
                            key={c.key}
                            className="flex items-center gap-1.5 cursor-pointer select-none"
                          >
                            <Checkbox
                              checked={visibleCols.has(c.key)}
                              onCheckedChange={() => toggleCol(c.key)}
                            />
                            <span className="text-xs">{c.label}</span>
                          </label>
                        ))}
                      </div>
                    </CardContent>
                  </Card>

                  {/* Detail table */}
                  <div className="rounded-md border overflow-auto max-h-[600px]">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          {visibleColsList.map((c) => (
                            <SortHead
                              key={c.key}
                              label={c.label}
                              sortKey={c.key}
                              sort={sortDetail}
                              onSort={handleSortDetail}
                              right={c.key === "quantity" || c.key === "netWt" || c.key === "runningBalance"}
                            />
                          ))}
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {sortedDetailRows.map(({ r, bal }) => {
                          const neg = getMultiplier(r.transactionTypeAction) < 0;
                          return (
                            <TableRow key={r.detailId}>
                              {col("date")                && <TableCell className="whitespace-nowrap">{r.date}</TableCell>}
                              {col("docNumber")           && <TableCell className="whitespace-nowrap">{r.docNumber}</TableCell>}
                              {col("sl")                  && <TableCell>{r.sl ?? "—"}</TableCell>}
                              {col("gsm")                 && <TableCell>{r.gsm ?? "—"}</TableCell>}
                              {col("transactionTypeName") && <TableCell className="whitespace-nowrap">{r.transactionTypeName ?? "—"}</TableCell>}
                              {col("jobName")             && <TableCell className="whitespace-nowrap">{r.jobName ?? "—"}</TableCell>}
                              {col("partyName")           && <TableCell className="whitespace-nowrap">{r.partyName ?? "—"}</TableCell>}
                              {col("locationName")        && <TableCell className="whitespace-nowrap">{r.locationName ?? "—"}</TableCell>}
                              {col("fabricTypeName")      && <TableCell className="whitespace-nowrap">{r.fabricTypeName ?? "—"}</TableCell>}
                              {col("yarnTypeName")        && <TableCell className="whitespace-nowrap">{r.yarnTypeName ?? "—"}</TableCell>}
                              {col("yarnCountName")       && <TableCell className="whitespace-nowrap">{r.yarnCountName ?? "—"}</TableCell>}
                              {col("yarnBrandName")       && <TableCell className="whitespace-nowrap">{r.yarnBrandName ?? "—"}</TableCell>}
                              {col("uomName")             && <TableCell>{r.uomName ?? "—"}</TableCell>}
                              {col("machineName")         && <TableCell className="whitespace-nowrap">{r.machineName ?? "—"}</TableCell>}
                              {col("machineOperatorName") && <TableCell className="whitespace-nowrap">{r.machineOperatorName ?? "—"}</TableCell>}
                              {col("quantity")            && (
                                <TableCell className={`text-right whitespace-nowrap${neg ? " text-red-600" : ""}`}>
                                  {r.quantity != null ? fmt(signedQty(r)) : "—"}
                                </TableCell>
                              )}
                              {col("netWt")               && (
                                <TableCell className={`text-right whitespace-nowrap${neg ? " text-red-600" : ""}`}>
                                  {r.netWt != null ? fmt(signedNetWt(r)) : "—"}
                                </TableCell>
                              )}
                              {col("runningBalance")      && (
                                <TableCell className={`text-right whitespace-nowrap font-medium${bal < 0 ? " text-red-600" : " text-blue-700"}`}>
                                  {fmt(bal)}
                                </TableCell>
                              )}
                            </TableRow>
                          );
                        })}
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
      map.set(k, (map.get(k) ?? 0) + signedNetWt(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 15)
      .map(([name, val]) => ({ name, netWt: parseFloat(val.toFixed(3)) }));
  }, [rows]);

  const byYarnCount = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.yarnCountName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedNetWt(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value: parseFloat(value.toFixed(3)) }));
  }, [rows]);

  const byTransactionType = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.transactionTypeName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedNetWt(r));
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
      {/* Net Wt by Month */}
      {byMonth.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Net Wt by Month</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byMonth} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => fmt(v)} />
                <Legend />
                <Bar dataKey="netWt" name="Net Wt" fill={CHART_COLORS[1]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Net Wt by Machine */}
      {byMachine.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Net Wt by Machine</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byMachine} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => fmt(v)} />
                <Bar dataKey="netWt" name="Net Wt" fill={CHART_COLORS[2]}>
                  {byMachine.map((_, i) => (
                    <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Net Wt by Party */}
      {byParty.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Net Wt by Party</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byParty} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => fmt(v)} />
                <Legend />
                <Bar dataKey="netWt" name="Net Wt" fill={CHART_COLORS[4]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Pie: Net Wt by Yarn Count */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {byYarnCount.length > 0 && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Net Wt by Yarn Count</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie
                    data={byYarnCount}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={90}
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(1)}%)`}
                    labelLine={false}
                  >
                    {byYarnCount.map((_, i) => (
                      <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v: number) => fmt(v)} />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        )}

        {/* Pie: Net Wt by Transaction Type */}
        {byTransactionType.length > 0 && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Net Wt by Transaction Type</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie
                    data={byTransactionType}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={90}
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(1)}%)`}
                    labelLine={false}
                  >
                    {byTransactionType.map((_, i) => (
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
