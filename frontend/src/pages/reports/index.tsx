import { NUM_DECIMALS } from "@/lib/format";
import { useState, useMemo, useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import { ExportCsvButton } from "@/components/export-csv-button";
// Type-only: jsPDF / autotable / html2canvas are loaded lazily inside each
// export handler so the ~600 kB they add only downloads when the user clicks
// Export.
import type jsPDF from "jspdf";
import type autoTable from "jspdf-autotable";
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
  useListEmployeeMaster,
} from "@workspace/api-client-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  PieChart, Pie, Cell, ResponsiveContainer,
} from "recharts";
import { Printer, Download, FileText, FileSpreadsheet, Upload, Image, Loader2, ClipboardCopy } from "lucide-react";
import { SortableHead as SortHead } from "@/components/sortable-head";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { DateInput } from "@/components/ui/date-input";
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
import { ImportDialog } from "@/components/import-dialog";
import { useToast } from "@/hooks/use-toast";

// ─── Types ───────────────────────────────────────────────────────────────────

interface ReportRow {
  headerId: number;
  date: string;
  docNumber: string;
  reference: string | null;
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
  employeeName: string | null;
  partyWastePercent: string | null;
}

interface Filters {
  dateFrom: string;
  dateTo: string;
  year: string;
  month: string;
  docNumber: string;
  reference: string;
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
  employeeId: string[];
}

type GroupByKey =
  | "date"
  | "month"
  | "docNumber"
  | "reference"
  | "transactionTypeName"
  | "partyName"
  | "jobName"
  | "locationName"
  | "fabricTypeName"
  | "machineName"
  | "employeeName"
  | "yarnTypeName"
  | "yarnCountName"
  | "yarnBrandName"
  | "uomName";

type SummarySortKey = "label" | "count" | "qty" | "netWt";
type SortDir        = "asc" | "desc";

function toISODate(d: Date): string {
  const y  = d.getFullYear();
  const m  = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

function defaultFilters(): Filters {
  return {
    dateFrom: "", dateTo: "", year: "", month: "", docNumber: "", reference: "",
    transactionTypeId: [], jobId: [], partyId: [], locationId: [], fabricTypeId: [],
    yarnTypeId: [], yarnCountId: [], yarnBrandId: [], uomId: [],
    machineId: [], employeeId: [],
  };
}

function loadSavedFilters(storageKey: string): Filters {
  try {
    const saved = localStorage.getItem(storageKey);
    if (saved) {
      const parsed = JSON.parse(saved);
      if (parsed && typeof parsed === "object") {
        const defaults = defaultFilters();
        const result: Filters = { ...defaults };
        for (const k of Object.keys(defaults) as (keyof Filters)[]) {
          if (k in parsed) (result as unknown as Record<string, unknown>)[k] = parsed[k];
        }
        return result;
      }
    }
  } catch {}
  return defaultFilters();
}

const EMPTY_FILTERS: Filters = {
  dateFrom: "", dateTo: "", year: "", month: "", docNumber: "", reference: "",
  transactionTypeId: [], jobId: [], partyId: [], locationId: [], fabricTypeId: [],
  yarnTypeId: [], yarnCountId: [], yarnBrandId: [], uomId: [],
  machineId: [], employeeId: [],
};

const GROUP_BY_OPTIONS: { value: GroupByKey; label: string }[] = [
  { value: "date",                label: "Date" },
  { value: "month",               label: "Month" },
  { value: "docNumber",           label: "Doc Number" },
  { value: "reference",           label: "Reference" },
  { value: "transactionTypeName", label: "Transaction Type" },
  { value: "partyName",           label: "Party" },
  { value: "jobName",             label: "Job" },
  { value: "locationName",        label: "Location" },
  { value: "fabricTypeName",      label: "Fabric Type" },
  { value: "machineName",         label: "Machine" },
  { value: "employeeName", label: "Employee" },
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

/** For balance/running-total calculations: skip rows whose action is null/empty. */
function balanceNetWt(row: ReportRow): number {
  const action = row.transactionTypeAction;
  if (!action || action.trim() === "") return 0;
  return toNum(row.netWt) * (action.trim().toLowerCase() === "minus" ? -1 : 1);
}

/** Wastage weight — only for "Fabric Delivery" and "Fabric Delivery Return" rows.
 *  Carries the same sign as signedNetWt (action multiplier already applied). */
function wastageWt(row: ReportRow): number {
  const name = row.transactionTypeName;
  if (name !== "Fabric Delivery" && name !== "Fabric Delivery Return") return 0;
  return signedNetWt(row) * (toNum(row.partyWastePercent) / 100);
}

function fmt(n: number): string {
  return n.toLocaleString("en-US", { minimumFractionDigits: 3, maximumFractionDigits: 3 });
}

function getMonthLabel(dateStr: string): string {
  const d = new Date(dateStr);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

/** Extracts the group-by label for a single row. */
function getGroupLabel(row: ReportRow, key: GroupByKey): string {
  if (key === "month") return getMonthLabel(row.date);
  return String((row as unknown as Record<string, unknown>)[key] ?? "—");
}

type DetailRenderItem =
  | { kind: "data"; r: ReportRow; idx: number; bal: number };

type GroupedRow = {
  label: string;
  count: number;
  qty: number;
  netWt: number;
  wastageWt: number;
  balNetWt: number;
  balNetWtMinusWastage: number;
  docNums: string[];
  refs: string[];
};

function groupRows(rows: ReportRow[], key: GroupByKey): GroupedRow[] {
  const map = new Map<string, {
    qty: number; netWt: number; wastageWt: number; balNetWt: number; balNetWtMinusWastage: number;
    count: number; docNumSet: Set<string>; refSet: Set<string>;
  }>();
  for (const row of rows) {
    const rawKey = key === "month" ? getMonthLabel(row.date) : (row[key] ?? "—");
    const k = String(rawKey);
    const existing = map.get(k) ?? {
      qty: 0, netWt: 0, wastageWt: 0, balNetWt: 0, balNetWtMinusWastage: 0, count: 0,
      docNumSet: new Set<string>(), refSet: new Set<string>(),
    };
    existing.qty                  += signedQty(row);
    existing.netWt                += signedNetWt(row);
    existing.wastageWt            += wastageWt(row);
    existing.balNetWt             += balanceNetWt(row);
    existing.balNetWtMinusWastage += balanceNetWt(row) + wastageWt(row);
    existing.count                += 1;
    if (row.docNumber) existing.docNumSet.add(row.docNumber);
    if (row.reference) existing.refSet.add(row.reference);
    map.set(k, existing);
  }
  return Array.from(map.entries())
    .map(([label, v]) => ({
      label, count: v.count, qty: v.qty, netWt: v.netWt, wastageWt: v.wastageWt,
      balNetWt: v.balNetWt, balNetWtMinusWastage: v.balNetWtMinusWastage,
      docNums: [...v.docNumSet], refs: [...v.refSet],
    }))
    .sort((a, b) => a.label.localeCompare(b.label));
}

function abbrev(arr: string[], max = 3): string {
  if (arr.length === 0) return "—";
  const shown = arr.slice(0, max).join(", ");
  return arr.length > max ? `${shown} …` : shown;
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
// Was a local component duplicated almost verbatim in yarn-to-fabric.tsx. Both
// now use the shared SortableHead, aliased to the old name so the call sites in
// this file are unchanged. The sorting *logic* here is untouched — the summary
// and detail grids still carry each row's running balance by its original
// index, which is what keeps the balance column correct under any sort.

// ─── Detail column definitions ───────────────────────────────────────────────

type DetailColKey =
  | "date" | "docNumber" | "reference" | "sl" | "gsm" | "transactionTypeName"
  | "jobName" | "partyName" | "locationName" | "fabricTypeName"
  | "yarnTypeName" | "yarnCountName" | "yarnBrandName" | "uomName"
  | "machineName" | "employeeName" | "quantity" | "netWt"
  | "wastagePercent" | "wastageWt" | "runningBalance";

const DETAIL_COLUMNS: { key: DetailColKey; label: string }[] = [
  { key: "date",                  label: "Date" },
  { key: "docNumber",             label: "Doc Number" },
  { key: "reference",             label: "Reference" },
  { key: "sl",                    label: "SL" },
  { key: "gsm",                   label: "GSM" },
  { key: "transactionTypeName",   label: "Trans Type" },
  { key: "jobName",               label: "Job" },
  { key: "partyName",             label: "Party" },
  { key: "locationName",          label: "Location" },
  { key: "fabricTypeName",        label: "Fabric Type" },
  { key: "yarnTypeName",          label: "Yarn Type" },
  { key: "yarnCountName",         label: "Yarn Count" },
  { key: "yarnBrandName",         label: "Yarn Brand" },
  { key: "uomName",               label: "UOM" },
  { key: "machineName",           label: "Machine" },
  { key: "employeeName",   label: "Employee" },
  { key: "quantity",              label: "Qty" },
  { key: "netWt",                 label: "Net Wt" },
  { key: "wastagePercent",        label: "Wastage%" },
  { key: "wastageWt",             label: "Wastage Wt" },
  { key: "runningBalance",        label: "Running Balance" },
];

const ALL_DETAIL_KEYS = DETAIL_COLUMNS.map((c) => c.key);

// ─── Main Page ───────────────────────────────────────────────────────────────

export default function ReportsPage() {
  const queryClient = useQueryClient();
  const [importOpen, setImportOpen]   = useState(false);
  const [filters, setFilters]         = useState<Filters>(() => loadSavedFilters("report-filters"));
  const [applied, setApplied]         = useState<Filters>(EMPTY_FILTERS);
  const [groupBy, setGroupBy]         = useState<GroupByKey>(() => {
    try {
      const saved = localStorage.getItem("report-group-by");
      if (saved) return saved as GroupByKey;
    } catch {}
    return "date";
  });
  const [hasRun, setHasRun]           = useState(false);
  const [visibleCols, setVisibleCols] = useState<Set<DetailColKey>>(() => {
    try {
      const saved = localStorage.getItem("report-visible-cols");
      if (saved) {
        const arr = JSON.parse(saved) as string[];
        if (Array.isArray(arr)) return new Set(arr.filter(k => ALL_DETAIL_KEYS.includes(k as DetailColKey)) as DetailColKey[]);
      }
    } catch {}
    return new Set(ALL_DETAIL_KEYS);
  });
  const [activeTab, setActiveTab]     = useState<string>(() => {
    try {
      const saved = localStorage.getItem("yarn-balance-active-tab");
      if (saved === "summary" || saved === "detail" || saved === "charts") return saved;
    } catch {}
    return "summary";
  });
  const [sortSummary, setSortSummary] = useState<{ key: SummarySortKey; dir: SortDir }>({ key: "label", dir: "asc" });
  const [sortDetail,  setSortDetail]  = useState<{ key: DetailColKey | null; dir: SortDir }>({ key: null, dir: "asc" });
  const [colOrder,    setColOrder]    = useState<DetailColKey[]>(() => {
    try {
      const saved = localStorage.getItem("report-col-order");
      if (saved) {
        const arr = JSON.parse(saved) as string[];
        if (Array.isArray(arr)) {
          const valid = arr.filter(k => ALL_DETAIL_KEYS.includes(k as DetailColKey)) as DetailColKey[];
          const missing = ALL_DETAIL_KEYS.filter(k => !valid.includes(k));
          return [...valid, ...missing];
        }
      }
    } catch {}
    return ALL_DETAIL_KEYS;
  });
  const [dragCol,     setDragCol]     = useState<DetailColKey | null>(null);
  const [pngLoading,  setPngLoading]  = useState(false);
  const [copyLoading, setCopyLoading] = useState(false);
  const { toast } = useToast();

  function toggleCol(key: DetailColKey) {
    setVisibleCols((prev) => {
      const next = new Set(prev);
      if (next.has(key)) { next.delete(key); } else { next.add(key); }
      return next;
    });
  }

  function showAllCols()  { setVisibleCols(new Set(ALL_DETAIL_KEYS)); }
  function hideAllCols()  { setVisibleCols(new Set()); }

  function handleColDragStart(_e: React.DragEvent, key: DetailColKey) {
    setDragCol(key);
  }
  function handleColDragOver(e: React.DragEvent, key: DetailColKey) {
    e.preventDefault();
    if (!dragCol || dragCol === key) return;
    setColOrder((prev) => {
      const next = [...prev];
      const from = next.indexOf(dragCol);
      const to   = next.indexOf(key);
      if (from === -1 || to === -1) return prev;
      next.splice(from, 1);
      next.splice(to, 0, dragCol);
      return next;
    });
  }
  function handleColDragEnd() { setDragCol(null); }

  useEffect(() => {
    localStorage.setItem("report-visible-cols", JSON.stringify([...visibleCols]));
  }, [visibleCols]);

  useEffect(() => {
    localStorage.setItem("report-col-order", JSON.stringify(colOrder));
  }, [colOrder]);

  useEffect(() => {
    localStorage.setItem("report-group-by", groupBy);
  }, [groupBy]);

  const visibleColsList = colOrder
    .map((k) => DETAIL_COLUMNS.find((c) => c.key === k)!)
    .filter((c) => c && visibleCols.has(c.key));
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

  function reportDateRange(): string {
    const f = filters.dateFrom;
    const t = filters.dateTo;
    if (f && t) return `From ${f}  Till ${t}`;
    if (f)      return `From ${f}`;
    if (t)      return `Till ${t}`;
    return "All Dates";
  }

  function csvHeading(): string {
    return `TKT Textiles (Knitting)\r\n${reportDateRange()}\r\n`;
  }

  function exportSummaryCSV() {
    const groupLabel = GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy;
    const headers    = [groupLabel, "Doc Number(s)", "Reference(s)", "Rows", "Total Qty", "Total Net Wt", "Total Wastage Wt", "Running Total"];
    let bal = openingBalance;
    const data: (string | number)[][] = [
      ["Opening Balance", "", "", "", "", "", "", fmt(openingBalance)],
      ...sortedGrouped.map((r) => {
        bal += r.balNetWtMinusWastage;
        return [r.label, r.docNums.join(", "), r.refs.join(", "), r.count, fmt(r.qty), fmt(r.netWt), r.wastageWt !== 0 ? fmt(r.wastageWt) : "", fmt(bal)];
      }),
      ["Total", "", "", rows.length, fmt(totalQty), fmt(totalNetWt), fmt(totalWastageWt), fmt(openingBalance + totalNetWt)],
    ];
    downloadBlob(csvHeading() + toCSV(headers, data), "report-summary.csv", "text/csv;charset=utf-8;");
  }

  function exportDetailCSV() {
    const headers = visibleColsList.map((c) => c.label);
    const obRow   = visibleColsList.map((c, i) =>
      i === 0 ? "Opening Balance" : c.key === "runningBalance" ? fmt(openingBalance) : ""
    );
    const bodyRows: (string | number)[][] = [];
    for (const item of detailRenderRows) {
      const { r, bal } = item;
      const wWt = wastageWt(r);
      bodyRows.push(visibleColsList.map((c) => {
        switch (c.key) {
          case "date":                  return r.date;
          case "docNumber":             return r.docNumber;
          case "reference":             return r.reference ?? "";
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
          case "employeeName":   return r.employeeName ?? "";
          case "quantity":              return r.quantity != null ? fmt(signedQty(r)) : "";
          case "netWt":                 return r.netWt    != null ? fmt(signedNetWt(r)) : "";
          case "wastagePercent":        return wWt !== 0 ? (r.partyWastePercent ?? "") : "";
          case "wastageWt":             return wWt !== 0 ? fmt(wWt) : "";
          case "runningBalance":        return fmt(bal);
          default:                      return "";
        }
      }));
    }
    const grandRow = visibleColsList.map((c, ci) =>
      ci === 0               ? "Grand Total"
      : c.key === "netWt"    ? fmt(totalDisplayNetWt)
      : c.key === "wastageWt"? fmt(totalWastageWt)
      : ""
    );
    downloadBlob(csvHeading() + toCSV(headers, [obRow, ...bodyRows, grandRow]), "report-detail.csv", "text/csv;charset=utf-8;");
  }

  async function exportSummaryPDF() {
    let JsPDF: typeof import("jspdf").default;
    let autoTable: typeof import("jspdf-autotable").default;
    try {
      [{ default: JsPDF }, { default: autoTable }] = await Promise.all([
        import("jspdf"),
        import("jspdf-autotable"),
      ]);
    } catch {
      toast({ variant: "destructive", title: "Could not export PDF", description: "The PDF module failed to load. Try again." });
      return;
    }
    const doc        = new JsPDF({ orientation: "landscape" });
    const groupLabel = GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy;
    doc.setFontSize(16);
    doc.setFont("helvetica", "bold");
    doc.text("TKT Textiles (Knitting)", 14, 14);
    doc.setFontSize(11);
    doc.setFont("helvetica", "normal");
    doc.text(reportDateRange(), 14, 22);
    doc.setFontSize(10);
    doc.text(`Summary — grouped by ${groupLabel}`, 14, 30);
    let bal = openingBalance;
    autoTable(doc, {
      startY: 36,
      head: [[groupLabel, "Doc Number(s)", "Reference(s)", "Rows", "Total Qty", "Total Net Wt", "Total Wastage Wt", "Running Total"]],
      body: [
        ["Opening Balance", "", "", "", "", "", "", fmt(openingBalance)],
        ...sortedGrouped.map((r) => {
          bal += r.balNetWtMinusWastage;
          return [r.label, r.docNums.join(", "), r.refs.join(", "), r.count, fmt(r.qty), fmt(r.netWt), r.wastageWt !== 0 ? fmt(r.wastageWt) : "", fmt(bal)];
        }),
        ["Total", "", "", rows.length, fmt(totalQty), fmt(totalNetWt), fmt(totalWastageWt), fmt(openingBalance + totalNetWt)],
      ],
      styles: { fontSize: 9 },
      headStyles: { fillColor: [37, 99, 235] },
      foot: [],
    });
    doc.save("report-summary.pdf");
  }

  async function exportDetailPDF() {
    let JsPDF: typeof import("jspdf").default;
    let autoTable: typeof import("jspdf-autotable").default;
    try {
      [{ default: JsPDF }, { default: autoTable }] = await Promise.all([
        import("jspdf"),
        import("jspdf-autotable"),
      ]);
    } catch {
      toast({ variant: "destructive", title: "Could not export PDF", description: "The PDF module failed to load. Try again." });
      return;
    }
    const doc     = new JsPDF({ orientation: "landscape" });
    const headers = visibleColsList.map((c) => c.label);
    doc.setFontSize(16);
    doc.setFont("helvetica", "bold");
    doc.text("TKT Textiles (Knitting)", 14, 14);
    doc.setFontSize(11);
    doc.setFont("helvetica", "normal");
    doc.text(reportDateRange(), 14, 22);
    doc.setFontSize(10);
    doc.text("Detailed Report", 14, 30);
    const obRow = visibleColsList.map((c, i) =>
      i === 0 ? "Opening Balance" : c.key === "runningBalance" ? fmt(openingBalance) : "—"
    );
    const bodyRows: string[][] = [];
    for (const item of detailRenderRows) {
      const { r, bal } = item;
      const wWt = wastageWt(r);
      bodyRows.push(visibleColsList.map((c) => {
        switch (c.key) {
          case "date":                  return r.date;
          case "docNumber":             return r.docNumber;
          case "reference":             return r.reference ?? "—";
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
          case "employeeName":   return r.employeeName ?? "—";
          case "quantity":              return r.quantity != null ? fmt(signedQty(r)) : "—";
          case "netWt":                 return r.netWt    != null ? fmt(signedNetWt(r)) : "—";
          case "wastagePercent":        return wWt !== 0 ? (r.partyWastePercent ?? "—") : "—";
          case "wastageWt":             return wWt !== 0 ? fmt(wWt) : "—";
          case "runningBalance":        return fmt(bal);
          default:                      return "";
        }
      }));
    }
    const grandRow = visibleColsList.map((c, ci) =>
      ci === 0                ? "Grand Total"
      : c.key === "netWt"    ? fmt(totalDisplayNetWt)
      : c.key === "wastageWt"? fmt(totalWastageWt)
      : "—"
    );
    autoTable(doc, {
      startY: 36,
      head: [headers],
      body: [obRow, ...bodyRows, grandRow],
      styles: { fontSize: 7 },
      headStyles: { fillColor: [37, 99, 235] },
      didParseCell: (data) => {
        const label =
          Array.isArray(data.row.raw) ? data.row.raw[0]?.toString() ?? "" : "";
        if (data.section === "body" && label === "Grand Total") {
          data.cell.styles.fontStyle = "bold";
          data.cell.styles.fillColor = [220, 230, 255];
        }
      },
    });
    doc.save("report-detail.pdf");
  }

  function handlePrint() { window.print(); }

  function printCharts() {
    document.body.classList.add("charts-print");
    const cleanup = () => {
      document.body.classList.remove("charts-print");
      window.removeEventListener("afterprint", cleanup);
    };
    window.addEventListener("afterprint", cleanup);
    window.print();
  }

  async function exportChartsAsPNG() {
    const el = document.getElementById("charts-print-area");
    if (!el) return;
    setPngLoading(true);
    try {
      const canvas = await (await import("html2canvas")).default(el, { backgroundColor: "#ffffff", scale: 2, useCORS: true });
      const url = canvas.toDataURL("image/png");
      const a = Object.assign(document.createElement("a"), { href: url, download: "yarn-balance-charts.png" });
      document.body.appendChild(a);
      a.click();
      a.remove();
    } catch {
      toast({ variant: "destructive", title: "Could not export charts", description: "The chart image module failed to load. Try again." });
    } finally {
      setPngLoading(false);
    }
  }

  async function copyChartsToClipboard() {
    const el = document.getElementById("charts-print-area");
    if (!el) return;
    setCopyLoading(true);
    try {
      const canvas = await (await import("html2canvas")).default(el, { backgroundColor: "#ffffff", scale: 2, useCORS: true });
      const blob = await new Promise<Blob>((resolve, reject) =>
        canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("Failed to create blob"))), "image/png")
      );
      await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
      toast({ title: "Copied!", description: "Charts copied to clipboard." });
    } catch {
      toast({ title: "Copy failed", description: "Your browser may not support clipboard image writing.", variant: "destructive" });
    } finally {
      setCopyLoading(false);
    }
  }

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
  const { data: employees }    = useListEmployeeMaster();

  const qs = useMemo(() => buildQueryString(applied), [applied]);

  const { data: rawRows = [], isFetching, isError } = useQuery<ReportRow[]>({
    queryKey: ["reports/data", qs],
    queryFn: () => customFetch<ReportRow[]>(`/api/reports/data${qs ? `?${qs}` : ""}`, { method: "GET" }),
    enabled: hasRun,
  });

  // When "All" transaction types are selected, exclude Fabric Production rows
  // (they belong to the Yarn to Fabric report, not the Yarn Balance report).
  const rows = useMemo(
    () =>
      applied.transactionTypeId.length === 0
        ? rawRows.filter((r) => r.transactionTypeName !== "Fabric Production")
        : rawRows,
    [rawRows, applied.transactionTypeId]
  );

  // ── Opening Balance query ─────────────────────────────────────────────────
  // Same filters as applied, but date range = everything BEFORE the dateFrom.
  const openingQs = useMemo(() => {
    if (!applied.dateFrom) return null; // no start date → opening balance is always 0
    const d = new Date(applied.dateFrom + "T00:00:00");
    d.setDate(d.getDate() - 1);
    const dateTo = toISODate(d);
    return buildQueryString({ ...applied, dateFrom: "", dateTo });
  }, [applied]);

  const { data: rawOpeningRows = [] } = useQuery<ReportRow[]>({
    queryKey: ["reports/opening-balance", openingQs],
    queryFn: () => customFetch<ReportRow[]>(`/api/reports/data${openingQs ? `?${openingQs}` : ""}`, { method: "GET" }),
    enabled: hasRun && openingQs !== null,
  });

  // Same exclusion for opening-balance rows
  const openingRows = useMemo(
    () =>
      applied.transactionTypeId.length === 0
        ? rawOpeningRows.filter((r) => r.transactionTypeName !== "Fabric Production")
        : rawOpeningRows,
    [rawOpeningRows, applied.transactionTypeId]
  );

  const openingBalance = useMemo(
    () => openingRows.reduce((s, r) => s + balanceNetWt(r) + wastageWt(r), 0),
    [openingRows]
  );

  function set(key: keyof Filters, val: string | string[]) {
    setFilters((prev) => ({ ...prev, [key]: val }));
  }

  function runReport() {
    try { localStorage.setItem("report-filters", JSON.stringify(filters)); } catch {}
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
  /** Used for Summary running-total calculations — excludes null-action rows and subtracts wastage. */
  const totalNetWt = useMemo(() => rows.reduce((s, r) => s + balanceNetWt(r) + wastageWt(r), 0), [rows]);
  /** Grand-total Net Wt for the Detail table (signed display values). */
  const totalDisplayNetWt = useMemo(() => rows.reduce((s, r) => s + signedNetWt(r), 0), [rows]);
  /** Grand-total Wastage Wt for the Detail table. */
  const totalWastageWt = useMemo(() => rows.reduce((s, r) => s + wastageWt(r), 0), [rows]);

  const runningBalances = useMemo(() => {
    let bal = openingBalance;
    return rows.map((r) => {
      bal += balanceNetWt(r) + wastageWt(r);
      return bal;
    });
  }, [rows, openingBalance]);

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

  /** Running total per group row in current display order, starting from openingBalance.
   *  Uses balNetWtMinusWastage so null-action rows and wastage are both excluded. */
  const summaryRunningTotals = useMemo(() => {
    let bal = openingBalance;
    return sortedGrouped.map((r) => {
      bal += r.balNetWtMinusWastage;
      return bal;
    });
  }, [sortedGrouped, openingBalance]);

  const sortedDetailRows = useMemo(() => {
    const indexed = rows.map((r, idx) => ({ r, idx, bal: runningBalances[idx] }));
    if (!sortDetail.key) return indexed;
    const key = sortDetail.key;
    return [...indexed].sort((a, b) => {
      let av: string | number, bv: string | number;
      switch (key) {
        case "runningBalance":  av = a.bal;                        bv = b.bal;                        break;
        case "quantity":        av = signedQty(a.r);               bv = signedQty(b.r);               break;
        case "netWt":           av = signedNetWt(a.r);             bv = signedNetWt(b.r);             break;
        case "wastageWt":       av = wastageWt(a.r);               bv = wastageWt(b.r);               break;
        case "wastagePercent":  av = toNum(a.r.partyWastePercent); bv = toNum(b.r.partyWastePercent); break;
        case "gsm":             av = a.r.gsm ?? 0;                 bv = b.r.gsm ?? 0;                 break;
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

  /** Sorted detail rows with running balance recomputed in display order. */
  const detailRenderRows = useMemo((): DetailRenderItem[] => {
    let runBal = openingBalance;
    return sortedDetailRows.map((item) => {
      runBal += balanceNetWt(item.r) + wastageWt(item.r);
      return { kind: "data", r: item.r, idx: item.idx, bal: runBal };
    });
  }, [sortedDetailRows, openingBalance]);

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
            <h1 className="text-2xl font-bold tracking-tight">Yarn Balance Report</h1>
            <p className="text-sm text-muted-foreground">Apply filters and run the report to see detailed and summary data with charts.</p>
          </div>
        </div>

        {/* ── Report Heading ───────────────────────────────── */}
        <div className="text-center py-2 print:py-4">
          <h2 className="text-2xl font-bold tracking-tight">TKT Textiles (Knitting)</h2>
          <p className="text-sm text-muted-foreground mt-1 print:text-black">{reportDateRange()}</p>
        </div>

        {/* ── Filter Panel ─────────────────────────────────── */}
        <Card className="print:hidden">
          <CardHeader className="pb-3 pt-4 px-4">
            <CardTitle className="text-base">Filters</CardTitle>
          </CardHeader>
          <CardContent className="px-4 pb-4 space-y-4">
            {/* Date / Period row */}
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
              <div className="flex flex-col gap-1">
                <Label htmlFor="report-date-from" className="text-xs text-muted-foreground">Date From</Label>
                <DateInput id="report-date-from" aria-label="Date from" className="h-8 text-sm" value={filters.dateFrom} onChange={(e) => set("dateFrom", e.target.value)} />
              </div>
              <div className="flex flex-col gap-1">
                <Label htmlFor="report-date-to" className="text-xs text-muted-foreground">Date To</Label>
                <DateInput id="report-date-to" aria-label="Date to" className="h-8 text-sm" value={filters.dateTo} onChange={(e) => set("dateTo", e.target.value)} />
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
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Document Number</Label>
                <Input className="h-8 text-sm" placeholder="Search doc number…" value={filters.docNumber} onChange={(e) => set("docNumber", e.target.value)} />
              </div>
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Reference</Label>
                <Input className="h-8 text-sm" placeholder="Search reference…" value={filters.reference} onChange={(e) => set("reference", e.target.value)} />
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
              <FilterMulti label="Employee"  values={filters.employeeId}  onChange={(v) => set("employeeId", v)}  options={employees} />
            </div>

            <div className="flex items-center gap-2 pt-1">
              <Button onClick={runReport} disabled={isFetching} size="sm">
                {isFetching ? "Loading..." : "Run Report"}
              </Button>
              <ExportCsvButton qs={qs} filename="yarn-balance-report.csv" disabled={!hasRun} />
              <Button variant="outline" size="sm" onClick={resetFilters}>Reset</Button>
              <Button variant="outline" size="sm" onClick={() => setImportOpen(true)} className="gap-1.5 ml-auto">
                <Upload className="h-3.5 w-3.5" />
                Import CSV
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* ── Results ──────────────────────────────────────── */}
        {hasRun && (
          <>
            {/* Totals summary bar */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
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
                  <p className="text-xs text-muted-foreground">Running Total</p>
                  <p className="text-2xl font-semibold">{fmt(openingBalance + totalNetWt)}</p>
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
              <Tabs value={activeTab} onValueChange={(v) => { setActiveTab(v); try { localStorage.setItem("yarn-balance-active-tab", v); } catch {} }}>
                <div className="flex items-center justify-between gap-2 flex-wrap print:hidden">
                  <TabsList>
                    <TabsTrigger value="summary">Summary</TabsTrigger>
                    <TabsTrigger value="detail">Detailed</TabsTrigger>
                    <TabsTrigger value="charts">Charts</TabsTrigger>
                  </TabsList>

                  {/* Print / Export / Import toolbar */}
                  {activeTab === "charts" ? (
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={copyChartsToClipboard}
                        disabled={copyLoading}
                        className="gap-1.5"
                      >
                        {copyLoading
                          ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          : <ClipboardCopy className="h-3.5 w-3.5" />
                        }
                        {copyLoading ? "Copying…" : "Copy Image"}
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={exportChartsAsPNG}
                        disabled={pngLoading}
                        className="gap-1.5"
                      >
                        {pngLoading
                          ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          : <Image className="h-3.5 w-3.5" />
                        }
                        {pngLoading ? "Exporting…" : "Export PNG"}
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={printCharts}
                        className="gap-1.5"
                      >
                        <Printer className="h-3.5 w-3.5" />
                        Print Charts
                      </Button>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setImportOpen(true)}
                        className="gap-1.5"
                      >
                        <Upload className="h-3.5 w-3.5" />
                        Import
                      </Button>

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
                  <div className="flex items-center gap-2 print:hidden">
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

                  <div className="rounded-md border overflow-auto max-h-[500px] print:max-h-none print:overflow-visible">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <SortHead
                            label={GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy}
                            sortKey="label"
                            sort={sortSummary}
                            onSort={handleSortSummary}
                          />
                          <TableHead className="whitespace-nowrap">Doc Number(s)</TableHead>
                          <TableHead className="whitespace-nowrap">Reference(s)</TableHead>
                          <SortHead label="Rows"          sortKey="count" sort={sortSummary} onSort={handleSortSummary} right />
                          <SortHead label="Total Qty"     sortKey="qty"   sort={sortSummary} onSort={handleSortSummary} right />
                          <SortHead label="Total Net Wt"  sortKey="netWt" sort={sortSummary} onSort={handleSortSummary} right />
                          <TableHead className="text-right whitespace-nowrap">Total Wastage Wt</TableHead>
                          <TableHead className="text-right whitespace-nowrap">Running Total</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {/* Opening Balance row */}
                        <TableRow className="bg-muted/40 italic text-muted-foreground">
                          <TableCell className="whitespace-nowrap">Opening Balance</TableCell>
                          <TableCell />
                          <TableCell />
                          <TableCell />
                          <TableCell />
                          <TableCell />
                          <TableCell />
                          <TableCell className={`text-right whitespace-nowrap font-semibold not-italic ${openingBalance < 0 ? "text-red-600" : "text-blue-700"}`}>
                            {fmt(openingBalance)}
                          </TableCell>
                        </TableRow>
                        {sortedGrouped.map((r, i) => (
                          <TableRow key={r.label}>
                            <TableCell className="font-medium whitespace-nowrap">{r.label}</TableCell>
                            <TableCell className="text-xs text-muted-foreground whitespace-nowrap max-w-[180px] truncate" title={r.docNums.join(", ")}>
                              {abbrev(r.docNums)}
                            </TableCell>
                            <TableCell className="text-xs text-muted-foreground whitespace-nowrap max-w-[180px] truncate" title={r.refs.join(", ")}>
                              {abbrev(r.refs)}
                            </TableCell>
                            <TableCell className="text-right">{r.count}</TableCell>
                            <TableCell className="text-right">{fmt(r.qty)}</TableCell>
                            <TableCell className="text-right">{fmt(r.netWt)}</TableCell>
                            <TableCell className="text-right text-muted-foreground">
                              {r.wastageWt !== 0 ? fmt(r.wastageWt) : "—"}
                            </TableCell>
                            <TableCell className={`text-right whitespace-nowrap font-semibold ${summaryRunningTotals[i] < 0 ? "text-red-600" : "text-blue-700"}`}>
                              {fmt(summaryRunningTotals[i])}
                            </TableCell>
                          </TableRow>
                        ))}
                        <TableRow className="bg-muted/50 font-semibold">
                          <TableCell>Total</TableCell>
                          <TableCell />
                          <TableCell />
                          <TableCell className="text-right">{rows.length}</TableCell>
                          <TableCell className="text-right">{fmt(totalQty)}</TableCell>
                          <TableCell className="text-right">{fmt(totalNetWt)}</TableCell>
                          <TableCell className="text-right">{fmt(totalWastageWt)}</TableCell>
                          <TableCell className={`text-right whitespace-nowrap ${(openingBalance + totalNetWt) < 0 ? "text-red-600" : "text-blue-700"}`}>
                            {fmt(openingBalance + totalNetWt)}
                          </TableCell>
                        </TableRow>
                      </TableBody>
                    </Table>
                  </div>
                </TabsContent>

                {/* ── Detail Tab ──────────────────────────── */}
                <TabsContent value="detail" className="mt-3 space-y-3">

                  {/* Column visibility picker */}
                  <Card className="border-dashed print:hidden">
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
                  <div className="rounded-md border overflow-auto max-h-[600px] print:max-h-none print:overflow-visible">
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
                              right={c.key === "quantity" || c.key === "netWt" || c.key === "wastageWt" || c.key === "runningBalance"}
                              draggable
                              isDragging={dragCol === c.key}
                              onDragStart={(e) => handleColDragStart(e, c.key)}
                              onDragOver={(e) => handleColDragOver(e, c.key)}
                              onDrop={(e) => e.preventDefault()}
                              onDragEnd={handleColDragEnd}
                            />
                          ))}
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {/* Opening Balance row */}
                        <TableRow className="bg-muted/40 italic text-muted-foreground">
                          {visibleColsList.map((c, i) => {
                            if (c.key === "runningBalance") {
                              return (
                                <TableCell key={c.key} className={`text-right whitespace-nowrap font-semibold not-italic ${openingBalance < 0 ? "text-red-600" : "text-blue-700"}`}>
                                  {fmt(openingBalance)}
                                </TableCell>
                              );
                            }
                            return (
                              <TableCell key={c.key} className="whitespace-nowrap">
                                {i === 0 ? "Opening Balance" : ""}
                              </TableCell>
                            );
                          })}
                        </TableRow>

                        {detailRenderRows.map((item) => {
                          const { r, bal } = item;
                          const neg = getMultiplier(r.transactionTypeAction) < 0;
                          const wWt = wastageWt(r);
                          return (
                            <TableRow key={r.detailId}>
                              {visibleColsList.map((c) => {
                                switch (c.key) {
                                  case "date":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.date}</TableCell>;
                                  case "docNumber":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.docNumber}</TableCell>;
                                  case "reference":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.reference ?? "—"}</TableCell>;
                                  case "sl":
                                    return <TableCell key={c.key}>{r.sl ?? "—"}</TableCell>;
                                  case "gsm":
                                    return <TableCell key={c.key}>{r.gsm ?? "—"}</TableCell>;
                                  case "transactionTypeName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.transactionTypeName ?? "—"}</TableCell>;
                                  case "jobName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.jobName ?? "—"}</TableCell>;
                                  case "partyName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.partyName ?? "—"}</TableCell>;
                                  case "locationName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.locationName ?? "—"}</TableCell>;
                                  case "fabricTypeName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.fabricTypeName ?? "—"}</TableCell>;
                                  case "yarnTypeName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.yarnTypeName ?? "—"}</TableCell>;
                                  case "yarnCountName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.yarnCountName ?? "—"}</TableCell>;
                                  case "yarnBrandName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.yarnBrandName ?? "—"}</TableCell>;
                                  case "uomName":
                                    return <TableCell key={c.key}>{r.uomName ?? "—"}</TableCell>;
                                  case "machineName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.machineName ?? "—"}</TableCell>;
                                  case "employeeName":
                                    return <TableCell key={c.key} className="whitespace-nowrap">{r.employeeName ?? "—"}</TableCell>;
                                  case "quantity":
                                    return (
                                      <TableCell key={c.key} className={`text-right whitespace-nowrap${neg ? " text-red-600" : ""}`}>
                                        {r.quantity != null ? fmt(signedQty(r)) : "—"}
                                      </TableCell>
                                    );
                                  case "netWt":
                                    return (
                                      <TableCell key={c.key} className={`text-right whitespace-nowrap${neg ? " text-red-600" : ""}`}>
                                        {r.netWt != null ? fmt(signedNetWt(r)) : "—"}
                                      </TableCell>
                                    );
                                  case "wastagePercent":
                                    return (
                                      <TableCell key={c.key} className="text-right whitespace-nowrap text-amber-700">
                                        {wWt !== 0 ? `${r.partyWastePercent ?? "—"}%` : "—"}
                                      </TableCell>
                                    );
                                  case "wastageWt":
                                    return (
                                      <TableCell key={c.key} className={`text-right whitespace-nowrap${wWt < 0 ? " text-red-500" : wWt > 0 ? " text-amber-700" : ""}`}>
                                        {wWt !== 0 ? fmt(wWt) : "—"}
                                      </TableCell>
                                    );
                                  case "runningBalance":
                                    return (
                                      <TableCell key={c.key} className={`text-right whitespace-nowrap font-medium${bal < 0 ? " text-red-600" : " text-blue-700"}`}>
                                        {fmt(bal)}
                                      </TableCell>
                                    );
                                  default:
                                    return <TableCell key={c.key} />;
                                }
                              })}
                            </TableRow>
                          );
                        })}

                        {/* Grand Total row */}
                        <TableRow className="bg-blue-50 font-bold border-t-2 text-blue-900">
                          {visibleColsList.map((c, ci) => {
                            if (ci === 0) return <TableCell key={c.key} className="whitespace-nowrap">Grand Total</TableCell>;
                            if (c.key === "netWt")    return <TableCell key={c.key} className="text-right whitespace-nowrap">{fmt(totalDisplayNetWt)}</TableCell>;
                            if (c.key === "wastageWt") return <TableCell key={c.key} className="text-right whitespace-nowrap">{fmt(totalWastageWt)}</TableCell>;
                            return <TableCell key={c.key} />;
                          })}
                        </TableRow>
                      </TableBody>
                    </Table>
                  </div>
                </TabsContent>

                {/* ── Charts Tab ──────────────────────────── */}
                <TabsContent value="charts" className="mt-3 space-y-6">
                  <ChartSection rows={rows} dateRange={
                    applied.dateFrom && applied.dateTo ? `From ${applied.dateFrom}  Till ${applied.dateTo}`
                    : applied.dateFrom ? `From ${applied.dateFrom}`
                    : applied.dateTo   ? `Till ${applied.dateTo}`
                    : "All Dates"
                  } />
                </TabsContent>
              </Tabs>
            )}
          </>
        )}
      </div>

      <ImportDialog
        open={importOpen}
        onOpenChange={setImportOpen}
        onSuccess={() => queryClient.invalidateQueries({ queryKey: ["reports/data"] })}
      />
    </Layout>
  );
}

// ─── Charts Section ──────────────────────────────────────────────────────────

function ChartSection({ rows, dateRange }: { rows: ReportRow[]; dateRange: string }) {
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
      .map(([month, v]) => ({ month, qty: parseFloat(v.qty.toFixed(NUM_DECIMALS)), netWt: parseFloat(v.netWt.toFixed(NUM_DECIMALS)) }));
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
      .map(([name, val]) => ({ name, netWt: parseFloat(val.toFixed(NUM_DECIMALS)) }));
  }, [rows]);

  const byYarnCount = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.yarnCountName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedNetWt(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value: parseFloat(value.toFixed(NUM_DECIMALS)) }));
  }, [rows]);

  const byTransactionType = useMemo(() => {
    const map = new Map<string, number>();
    for (const r of rows) {
      const k = r.transactionTypeName ?? "Unknown";
      map.set(k, (map.get(k) ?? 0) + signedNetWt(r));
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value: parseFloat(value.toFixed(NUM_DECIMALS)) }));
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
      .map(([name, v]) => ({ name, qty: parseFloat(v.qty.toFixed(NUM_DECIMALS)), netWt: parseFloat(v.netWt.toFixed(NUM_DECIMALS)) }));
  }, [rows]);

  return (
    <div id="charts-print-area" className="space-y-6">
      {/* Print-only header */}
      <div className="hidden print:block mb-4">
        <h1 className="text-xl font-bold">TKT Textiles (Knitting) — Yarn Balance Report</h1>
        <p className="text-sm text-gray-600 mt-0.5">{dateRange}</p>
      </div>

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
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(NUM_DECIMALS)}%)`}
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
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(NUM_DECIMALS)}%)`}
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
