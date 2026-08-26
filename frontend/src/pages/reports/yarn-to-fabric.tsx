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
  LineChart, Line, ResponsiveContainer,
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
import {
  ReportRow, Filters, GroupByKey, SummarySortKey, PartyBalanceSortKey, SortDir,
  DetailColKey, Y2FGroupedRow,
  EMPTY_FILTERS, GROUP_BY_OPTIONS, CHART_COLORS, MONTHS, FABRIC_TX_TYPES,
  DETAIL_COLUMNS, ALL_DETAIL_KEYS, RIGHT_ALIGNED,
  toISODate, defaultFilters, loadSavedFilters, toNum, getMultiplier,
  signedQty, signedNetWt, fabricBalanceDelta, signedNetWtIfType,
  fmt, getMonthLabel, getGroupLabel, abbrev, buildQueryString, groupRows,
} from "@/lib/reports/yarn-to-fabric-utils";

// ─── Detail render item ───────────────────────────────────────────────────────

type DetailRenderItem =
  | { kind: "data"; r: ReportRow; idx: number; fabricBal: number };

// ─── Shared sub-components ────────────────────────────────────────────────────

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
      <MultiSelect options={opts} selected={values} onChange={onChange} placeholder="All" />
    </div>
  );
}

// SortHead was duplicated here from reports/index.tsx. Both now share
// SortableHead, aliased so the nine call sites below are unchanged.

// ─── Main Page ───────────────────────────────────────────────────────────────

export default function YarnToFabricPage() {
  const queryClient = useQueryClient();
  const [importOpen, setImportOpen]   = useState(false);
  const [filters, setFilters]         = useState<Filters>(() => loadSavedFilters("ytf-filters"));
  const [applied, setApplied]         = useState<Filters>(EMPTY_FILTERS);
  const [groupBy, setGroupBy]         = useState<GroupByKey>(() => {
    try {
      const saved = localStorage.getItem("ytf-group-by");
      if (saved) return saved as GroupByKey;
    } catch {}
    return "date";
  });
  const [hasRun, setHasRun]           = useState(false);
  const [visibleCols, setVisibleCols] = useState<Set<DetailColKey>>(() => {
    try {
      const saved = localStorage.getItem("ytf-visible-cols");
      if (saved) {
        const arr = JSON.parse(saved) as string[];
        if (Array.isArray(arr)) return new Set(arr.filter(k => ALL_DETAIL_KEYS.includes(k as DetailColKey)) as DetailColKey[]);
      }
    } catch {}
    return new Set(ALL_DETAIL_KEYS);
  });
  const [activeTab, setActiveTab]     = useState<string>(() => {
    try {
      const saved = localStorage.getItem("yarn-to-fabric-active-tab");
      if (saved === "summary" || saved === "detail" || saved === "charts" || saved === "party-balance") return saved;
    } catch {}
    return "summary";
  });
  const [sortSummary,      setSortSummary]      = useState<{ key: SummarySortKey; dir: SortDir }>({ key: "label", dir: "asc" });
  const [sortDetail,       setSortDetail]       = useState<{ key: DetailColKey | null; dir: SortDir }>({ key: null, dir: "asc" });
  const [sortPartyBalance, setSortPartyBalance] = useState<{ key: PartyBalanceSortKey; dir: SortDir }>({ key: "party", dir: "asc" });
  const [colOrder,    setColOrder]    = useState<DetailColKey[]>(() => {
    try {
      const saved = localStorage.getItem("ytf-col-order");
      if (saved) {
        const arr = JSON.parse(saved) as string[];
        if (Array.isArray(arr)) {
          const valid   = arr.filter(k => ALL_DETAIL_KEYS.includes(k as DetailColKey)) as DetailColKey[];
          const missing = ALL_DETAIL_KEYS.filter(k => !valid.includes(k));
          return [...valid, ...missing];
        }
      }
    } catch {}
    return ALL_DETAIL_KEYS;
  });
  const [dragCol,    setDragCol]    = useState<DetailColKey | null>(null);
  const [pngLoading, setPngLoading] = useState(false);
  const [copyLoading, setCopyLoading] = useState(false);
  const { toast } = useToast();

  function toggleCol(key: DetailColKey) {
    setVisibleCols((prev) => {
      const next = new Set(prev);
      if (next.has(key)) { next.delete(key); } else { next.add(key); }
      return next;
    });
  }
  function showAllCols() { setVisibleCols(new Set(ALL_DETAIL_KEYS)); }
  function hideAllCols() { setVisibleCols(new Set()); }

  function handleColDragStart(_e: React.DragEvent, key: DetailColKey) { setDragCol(key); }
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

  useEffect(() => { localStorage.setItem("ytf-visible-cols", JSON.stringify([...visibleCols])); }, [visibleCols]);
  useEffect(() => { localStorage.setItem("ytf-col-order",    JSON.stringify(colOrder)); },        [colOrder]);
  useEffect(() => { localStorage.setItem("ytf-group-by",     groupBy); },                         [groupBy]);

  const visibleColsList = colOrder
    .map((k) => DETAIL_COLUMNS.find((c) => c.key === k)!)
    .filter((c) => c && visibleCols.has(c.key));

  // ── Queries ───────────────────────────────────────────────────────────────

  const { data: transactionTypes }  = useListTransactionTypeMaster();
  const { data: jobs }              = useListJobMaster();
  const { data: parties }           = useListPartyMaster();
  const { data: locations }         = useListLocationMaster();
  const { data: fabricTypes }       = useListFabricTypeMaster();
  const { data: yarnTypes }         = useListYarnTypeMaster();
  const { data: yarnCounts }        = useListYarnCountMaster();
  const { data: yarnBrands }        = useListYarnBrandMaster();
  const { data: uoms }              = useListUomMaster();
  const { data: machines }          = useListMachineMaster();
  const { data: employees }  = useListEmployeeMaster();

  const qs = useMemo(() => buildQueryString(applied), [applied]);

  const { data: rawRows = [], isFetching, isError } = useQuery<ReportRow[]>({
    queryKey: ["ytf-reports/data", qs],
    queryFn: () => customFetch<ReportRow[]>(`/api/reports/data${qs ? `?${qs}` : ""}`, { method: "GET" }),
    enabled: hasRun,
  });

  // Restrict to fabric-related transaction types only
  const rows = useMemo(
    () => rawRows.filter((r) => FABRIC_TX_TYPES.has(r.transactionTypeName ?? "")),
    [rawRows]
  );

  // Opening balance: all data before dateFrom
  const openingQs = useMemo(() => {
    if (!applied.dateFrom) return null;
    const d = new Date(applied.dateFrom + "T00:00:00");
    d.setDate(d.getDate() - 1);
    return buildQueryString({ ...applied, dateFrom: "", dateTo: toISODate(d) });
  }, [applied]);

  const { data: rawOpeningRows = [] } = useQuery<ReportRow[]>({
    queryKey: ["ytf-reports/opening", openingQs],
    queryFn: () => customFetch<ReportRow[]>(`/api/reports/data${openingQs ? `?${openingQs}` : ""}`, { method: "GET" }),
    enabled: hasRun && openingQs !== null,
  });

  // Restrict opening rows to fabric-related transaction types only
  const openingRows = useMemo(
    () => rawOpeningRows.filter((r) => FABRIC_TX_TYPES.has(r.transactionTypeName ?? "")),
    [rawOpeningRows]
  );

  // Opening fabric balance = Σ(Fabric Production signed) + Σ(Fabric Delivery signed) + Σ(Fab Del Return signed)
  const openingFabricBalance = useMemo(
    () => openingRows.reduce((s, r) => s + fabricBalanceDelta(r), 0),
    [openingRows]
  );

  // ── Computed values ───────────────────────────────────────────────────────

  const totalQty            = useMemo(() => rows.reduce((s, r) => s + signedQty(r), 0), [rows]);
  const totalFabricProd     = useMemo(() => rows.reduce((s, r) => s + (r.transactionTypeName === "Fabric Production"      ? signedNetWt(r) : 0), 0), [rows]);
  const totalFabricDelivery = useMemo(() => rows.reduce((s, r) => s + (r.transactionTypeName === "Fabric Delivery"        ? signedNetWt(r) : 0), 0), [rows]);
  const totalFabricDelRtn   = useMemo(() => rows.reduce((s, r) => s + (r.transactionTypeName === "Fabric Delivery Return" ? signedNetWt(r) : 0), 0), [rows]);

  const runningFabricBalances = useMemo(() => {
    let bal = openingFabricBalance;
    return rows.map((r) => { bal += fabricBalanceDelta(r); return bal; });
  }, [rows, openingFabricBalance]);

  const currentFabricBalance = useMemo(
    () => runningFabricBalances.length > 0
      ? runningFabricBalances[runningFabricBalances.length - 1]
      : openingFabricBalance,
    [runningFabricBalances, openingFabricBalance]
  );

  // ── Party Balance (cumulative: opening + filtered rows) ───────────────────

  const partyBalanceRows = useMemo(() => {
    const map = new Map<string, {
      fabricDelivery: number;
      fabricReturn: number;
    }>();

    const allRows = [...openingRows, ...rows];

    for (const r of allRows) {
      const name = r.transactionTypeName;
      if (name !== "Fabric Delivery" && name !== "Fabric Delivery Return") continue;
      const party = r.partyName ?? "—";
      const e = map.get(party) ?? { fabricDelivery: 0, fabricReturn: 0 };
      const sNetWt = signedNetWt(r);
      if (name === "Fabric Delivery") {
        e.fabricDelivery += sNetWt;
      } else {
        e.fabricReturn += sNetWt;
      }
      map.set(party, e);
    }

    return Array.from(map.entries()).map(([party, v]) => ({
      party,
      fabricDelivery: v.fabricDelivery,
      fabricReturn:   v.fabricReturn,
      netOutstanding: v.fabricDelivery + v.fabricReturn,
    }));
  }, [openingRows, rows]);

  const sortedPartyBalance = useMemo(() => {
    const arr = [...partyBalanceRows];
    arr.sort((a, b) => {
      const av = a[sortPartyBalance.key];
      const bv = b[sortPartyBalance.key];
      if (typeof av === "number")
        return sortPartyBalance.dir === "asc" ? av - (bv as number) : (bv as number) - av;
      return sortPartyBalance.dir === "asc"
        ? (av as string).localeCompare(bv as string)
        : (bv as string).localeCompare(av as string);
    });
    return arr;
  }, [partyBalanceRows, sortPartyBalance]);

  const partyBalanceTotals = useMemo(() => ({
    fabricDelivery: partyBalanceRows.reduce((s, r) => s + r.fabricDelivery, 0),
    fabricReturn:   partyBalanceRows.reduce((s, r) => s + r.fabricReturn,   0),
    netOutstanding: partyBalanceRows.reduce((s, r) => s + r.netOutstanding, 0),
  }), [partyBalanceRows]);

  function handleSortPartyBalance(key: string) {
    const k = key as PartyBalanceSortKey;
    setSortPartyBalance((prev) =>
      prev.key === k ? { key: k, dir: prev.dir === "asc" ? "desc" : "asc" } : { key: k, dir: "asc" }
    );
  }

  // Grouped summary rows
  const grouped = useMemo(() => groupRows(rows, groupBy), [rows, groupBy]);

  const sortedGrouped = useMemo(() => {
    const arr = [...grouped];
    arr.sort((a, b) => {
      let av: string | number, bv: string | number;
      switch (sortSummary.key) {
        case "count": av = a.count; bv = b.count; break;
        case "qty":   av = a.qty;   bv = b.qty;   break;
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

  const summaryFabricRunning = useMemo(() => {
    let bal = openingFabricBalance;
    return sortedGrouped.map((r) => { bal += r.fabricDelta; return bal; });
  }, [sortedGrouped, openingFabricBalance]);

  // Sorted detail rows
  const sortedDetailRows = useMemo(() => {
    const indexed = rows.map((r, idx) => ({
      r, idx, fabricBal: runningFabricBalances[idx],
    }));
    if (!sortDetail.key) return indexed;
    const key = sortDetail.key;
    return [...indexed].sort((a, b) => {
      let av: string | number = 0, bv: string | number = 0;
      switch (key) {
        case "runningFabricBalance": av = a.fabricBal;                          bv = b.fabricBal;                          break;
        case "quantity":             av = signedQty(a.r);                       bv = signedQty(b.r);                       break;
        case "fabricProduction":     av = signedNetWtIfType(a.r, "Fabric Production")      ?? 0; bv = signedNetWtIfType(b.r, "Fabric Production")      ?? 0; break;
        case "fabricDelivery":       av = signedNetWtIfType(a.r, "Fabric Delivery")        ?? 0; bv = signedNetWtIfType(b.r, "Fabric Delivery")        ?? 0; break;
        case "fabricDeliveryReturn": av = signedNetWtIfType(a.r, "Fabric Delivery Return") ?? 0; bv = signedNetWtIfType(b.r, "Fabric Delivery Return") ?? 0; break;
        case "gsm":                  av = a.r.gsm ?? 0;                         bv = b.r.gsm ?? 0;                         break;
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
  }, [rows, runningFabricBalances, sortDetail]);

  // Detail rows with running fabric balance recomputed in display order
  const detailRenderRows = useMemo((): DetailRenderItem[] => {
    let runBal = openingFabricBalance;
    return sortedDetailRows.map((item) => {
      runBal += fabricBalanceDelta(item.r);
      return { kind: "data", r: item.r, idx: item.idx, fabricBal: runBal };
    });
  }, [sortedDetailRows, openingFabricBalance]);

  // ── Helpers ───────────────────────────────────────────────────────────────

  function set(key: keyof Filters, val: string | string[]) {
    setFilters((prev) => ({ ...prev, [key]: val }));
  }
  function runReport() {
    try { localStorage.setItem("ytf-filters", JSON.stringify(filters)); } catch {}
    setApplied(filters);
    setHasRun(true);
  }
  function resetFilters() { setFilters(EMPTY_FILTERS); setApplied(EMPTY_FILTERS); setHasRun(false); }
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
      const a = Object.assign(document.createElement("a"), { href: url, download: "yarn-to-fabric-charts.png" });
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

  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 6 }, (_, i) => currentYear - i);
  const uomOptions = uoms?.map((u) => ({ id: u.id, name: u.name }));

  const filteredJobOptions = useMemo(
    () => (jobs ?? []).filter((j) =>
      filters.partyId.length === 0 ? true : filters.partyId.includes(String(j.partyId ?? ""))
    ),
    [jobs, filters.partyId]
  );

  function reportDateRange(): string {
    const f = applied.dateFrom;
    const t = applied.dateTo;
    if (f && t) return `From ${f}  Till ${t}`;
    if (f)      return `From ${f}`;
    if (t)      return `Till ${t}`;
    return "All Dates";
  }

  function csvHeading(): string {
    return `TKT Textiles (Knitting) — Yarn to Fabric Movement\r\n${reportDateRange()}\r\n`;
  }

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
    const headers = [groupLabel, "Doc Number(s)", "Rows", "Qty", "Fabric Production", "Fabric Delivery", "Fab Del Return", "Run Fabric Bal."];
    let fabricBal = openingFabricBalance;
    const data: (string | number)[][] = [
      ["Opening Balance", "", "", "", "", "", "", fmt(openingFabricBalance)],
      ...sortedGrouped.map((r) => {
        fabricBal += r.fabricDelta;
        return [r.label, r.docNums.join(", "), r.count, fmt(r.qty), fmt(r.fabricProduction), fmt(r.fabricDelivery), fmt(r.fabricDeliveryReturn), fmt(fabricBal)];
      }),
      ["Total", "", rows.length, fmt(totalQty), fmt(totalFabricProd), fmt(totalFabricDelivery), fmt(totalFabricDelRtn), ""],
    ];
    downloadBlob(csvHeading() + toCSV(headers, data), "ytf-summary.csv", "text/csv;charset=utf-8;");
  }

  function exportDetailCSV() {
    const headers = visibleColsList.map((c) => c.label);
    const obRow   = visibleColsList.map((c, i) =>
      i === 0 ? "Opening Balance"
      : c.key === "runningFabricBalance" ? fmt(openingFabricBalance)
      : ""
    );
    const bodyRows: (string | number)[][] = [];
    for (const item of detailRenderRows) {
      const { r, fabricBal } = item;
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
          case "fabricProduction":      { const v = signedNetWtIfType(r, "Fabric Production");      return v != null ? fmt(v) : ""; }
          case "fabricDelivery":        { const v = signedNetWtIfType(r, "Fabric Delivery");        return v != null ? fmt(v) : ""; }
          case "fabricDeliveryReturn":  { const v = signedNetWtIfType(r, "Fabric Delivery Return"); return v != null ? fmt(v) : ""; }
          case "runningFabricBalance":  return fmt(fabricBal);
          default:                      return "";
        }
      }));
    }
    const grandRow = visibleColsList.map((c, ci) =>
      ci === 0                           ? "Grand Total"
      : c.key === "fabricProduction"     ? fmt(totalFabricProd)
      : c.key === "fabricDelivery"       ? fmt(totalFabricDelivery)
      : c.key === "fabricDeliveryReturn" ? fmt(totalFabricDelRtn)
      : ""
    );
    downloadBlob(csvHeading() + toCSV(headers, [obRow, ...bodyRows, grandRow]), "ytf-detail.csv", "text/csv;charset=utf-8;");
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
    doc.setFontSize(16); doc.setFont("helvetica", "bold");
    doc.text("TKT Textiles (Knitting) — Yarn to Fabric Movement", 14, 14);
    doc.setFontSize(11); doc.setFont("helvetica", "normal");
    doc.text(reportDateRange(), 14, 22);
    doc.setFontSize(10);
    doc.text(`Summary — grouped by ${groupLabel}`, 14, 30);
    let fabricBal = openingFabricBalance;
    autoTable(doc, {
      startY: 36,
      head: [[groupLabel, "Rows", "Qty", "Fabric Production", "Fabric Delivery", "Fab Del Return", "Run Fabric Bal."]],
      body: [
        ["Opening Balance", "", "", "", "", "", fmt(openingFabricBalance)],
        ...sortedGrouped.map((r) => {
          fabricBal += r.fabricDelta;
          return [r.label, r.count, fmt(r.qty), fmt(r.fabricProduction), fmt(r.fabricDelivery), fmt(r.fabricDeliveryReturn), fmt(fabricBal)];
        }),
        ["Total", rows.length, fmt(totalQty), fmt(totalFabricProd), fmt(totalFabricDelivery), fmt(totalFabricDelRtn), ""],
      ],
      styles: { fontSize: 8 },
      headStyles: { fillColor: [37, 99, 235] },
    });
    doc.save("ytf-summary.pdf");
  }

  function exportPartyBalanceCSV() {
    const headers = ["Party", "Fabric Delivered", "Fab Del Return", "Net Outstanding"];
    const data: (string | number)[][] = [
      ...sortedPartyBalance.map((r) => [r.party, fmt(r.fabricDelivery), fmt(r.fabricReturn), fmt(r.netOutstanding)]),
      ["Total", fmt(partyBalanceTotals.fabricDelivery), fmt(partyBalanceTotals.fabricReturn), fmt(partyBalanceTotals.netOutstanding)],
    ];
    downloadBlob(csvHeading() + toCSV(headers, data), "ytf-party-balance.csv", "text/csv;charset=utf-8;");
  }

  async function exportPartyBalancePDF() {
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
    const doc = new JsPDF({ orientation: "landscape" });
    doc.setFontSize(16); doc.setFont("helvetica", "bold");
    doc.text("TKT Textiles (Knitting) — Yarn to Fabric Movement", 14, 14);
    doc.setFontSize(11); doc.setFont("helvetica", "normal");
    doc.text(reportDateRange(), 14, 22);
    doc.setFontSize(10); doc.text("Party Balance Report", 14, 30);
    autoTable(doc, {
      startY: 36,
      head: [["Party", "Fabric Delivered", "Fab Del Return", "Net Outstanding"]],
      body: [
        ...sortedPartyBalance.map((r) => [r.party, fmt(r.fabricDelivery), fmt(r.fabricReturn), fmt(r.netOutstanding)]),
        ["Total", fmt(partyBalanceTotals.fabricDelivery), fmt(partyBalanceTotals.fabricReturn), fmt(partyBalanceTotals.netOutstanding)],
      ],
      styles: { fontSize: 9 },
      headStyles: { fillColor: [37, 99, 235] },
      columnStyles: { 1: { halign: "right" }, 2: { halign: "right" }, 3: { halign: "right" } },
      didParseCell: (data) => {
        if (data.section === "body" && Array.isArray(data.row.raw) && data.row.raw[0] === "Total") {
          data.cell.styles.fontStyle = "bold";
          data.cell.styles.fillColor = [220, 230, 255];
        }
      },
    });
    doc.save("ytf-party-balance.pdf");
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
    doc.setFontSize(16); doc.setFont("helvetica", "bold");
    doc.text("TKT Textiles (Knitting) — Yarn to Fabric Movement", 14, 14);
    doc.setFontSize(11); doc.setFont("helvetica", "normal");
    doc.text(reportDateRange(), 14, 22);
    doc.setFontSize(10); doc.text("Detailed Report", 14, 30);
    const obRow = visibleColsList.map((c, i) =>
      i === 0 ? "Opening Balance"
      : c.key === "runningFabricBalance" ? fmt(openingFabricBalance)
      : "—"
    );
    const bodyRows: string[][] = [];
    for (const item of detailRenderRows) {
      const { r, fabricBal } = item;
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
          case "fabricProduction":      { const v = signedNetWtIfType(r, "Fabric Production");      return v != null ? fmt(v) : "—"; }
          case "fabricDelivery":        { const v = signedNetWtIfType(r, "Fabric Delivery");        return v != null ? fmt(v) : "—"; }
          case "fabricDeliveryReturn":  { const v = signedNetWtIfType(r, "Fabric Delivery Return"); return v != null ? fmt(v) : "—"; }
          case "runningFabricBalance":  return fmt(fabricBal);
          default:                      return "";
        }
      }));
    }
    const grandRow = visibleColsList.map((c, ci) =>
      ci === 0                           ? "Grand Total"
      : c.key === "fabricProduction"     ? fmt(totalFabricProd)
      : c.key === "fabricDelivery"       ? fmt(totalFabricDelivery)
      : c.key === "fabricDeliveryReturn" ? fmt(totalFabricDelRtn)
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
    doc.save("ytf-detail.pdf");
  }

  // ── JSX ───────────────────────────────────────────────────────────────────

  return (
    <Layout>
      <div className="space-y-4 p-4 md:p-6 max-w-[1600px] mx-auto">
        <div>
          <h1 className="text-2xl font-bold">Yarn to Fabric Movement Report</h1>
          <p className="text-sm text-muted-foreground">Track fabric production, deliveries, and running balances.</p>
        </div>

        <div className="text-center py-2 print:py-4">
          <p className="text-lg font-bold">TKT Textiles (Knitting)</p>
          <p className="text-sm text-muted-foreground print:text-black">{reportDateRange()}</p>
          <p className="text-sm font-medium print:block hidden">Yarn to Fabric Movement Report</p>
        </div>

        {/* ── Filters ───────────────────────────────────────── */}
        <Card className="print:hidden">
          <CardContent className="pt-4 space-y-3">
            <p className="text-sm font-semibold">Filters</p>
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
              <div className="flex flex-col gap-1">
                <Label htmlFor="ytf-date-from" className="text-xs text-muted-foreground">Date From</Label>
                <DateInput id="ytf-date-from" aria-label="Date from" className="h-8 text-sm" value={filters.dateFrom} onChange={(e) => set("dateFrom", e.target.value)} />
              </div>
              <div className="flex flex-col gap-1">
                <Label htmlFor="ytf-date-to" className="text-xs text-muted-foreground">Date To</Label>
                <DateInput id="ytf-date-to" aria-label="Date to" className="h-8 text-sm" value={filters.dateTo} onChange={(e) => set("dateTo", e.target.value)} />
              </div>
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Year</Label>
                <Select value={filters.year} onValueChange={(v) => set("year", v === "all" ? "" : v)}>
                  <SelectTrigger className="h-8 text-sm"><SelectValue placeholder="All Years" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Years</SelectItem>
                    {years.map((y) => <SelectItem key={y} value={String(y)}>{y}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex flex-col gap-1">
                <Label className="text-xs text-muted-foreground">Month</Label>
                <Select value={filters.month} onValueChange={(v) => set("month", v === "all" ? "" : v)}>
                  <SelectTrigger className="h-8 text-sm"><SelectValue placeholder="All Months" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Months</SelectItem>
                    {MONTHS.map((m, i) => <SelectItem key={m} value={String(i + 1)}>{m}</SelectItem>)}
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

            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
              <FilterMulti label="Transaction Type" values={filters.transactionTypeId} onChange={(v) => set("transactionTypeId", v)} options={transactionTypes} />
              <FilterMulti label="Party"            values={filters.partyId}           onChange={(v) => { set("partyId", v); set("jobId", []); }} options={parties} />
              <FilterMulti label="Job Type"         values={filters.jobId}             onChange={(v) => set("jobId", v)}             options={filteredJobOptions} />
              <FilterMulti label="Location"         values={filters.locationId}        onChange={(v) => set("locationId", v)}        options={locations} />
              <FilterMulti label="Fabric Type"      values={filters.fabricTypeId}      onChange={(v) => set("fabricTypeId", v)}      options={fabricTypes} />
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
              <FilterMulti label="Yarn Type"        values={filters.yarnTypeId}        onChange={(v) => set("yarnTypeId", v)}        options={yarnTypes} />
              <FilterMulti label="Yarn Count"       values={filters.yarnCountId}       onChange={(v) => set("yarnCountId", v)}       options={yarnCounts} />
              <FilterMulti label="Yarn Brand"       values={filters.yarnBrandId}       onChange={(v) => set("yarnBrandId", v)}       options={yarnBrands} />
              <FilterMulti label="UOM"              values={filters.uomId}             onChange={(v) => set("uomId", v)}             options={uomOptions} />
              <FilterMulti label="Machine"          values={filters.machineId}         onChange={(v) => set("machineId", v)}         options={machines} />
              <FilterMulti label="Employee" values={filters.employeeId} onChange={(v) => set("employeeId", v)} options={employees} />
            </div>

            <div className="flex items-center gap-2 pt-1">
              <Button onClick={runReport} disabled={isFetching} size="sm">
                {isFetching ? "Loading..." : "Run Report"}
              </Button>
              <ExportCsvButton qs={qs} filename="yarn-to-fabric-report.csv" disabled={!hasRun} />
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
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Total Rows</p>
                  <p className="text-2xl font-semibold">{rows.length.toLocaleString()}</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Fabric Production</p>
                  <p className="text-2xl font-semibold">{fmt(totalFabricProd)}</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Fabric Delivered</p>
                  <p className={`text-2xl font-semibold${totalFabricDelivery < 0 ? " text-red-600" : ""}`}>{fmt(totalFabricDelivery)}</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-4 pb-3">
                  <p className="text-xs text-muted-foreground">Run Fabric Bal.</p>
                  <p className={`text-2xl font-semibold${currentFabricBalance < 0 ? " text-red-600" : " text-emerald-700"}`}>{fmt(currentFabricBalance)}</p>
                </CardContent>
              </Card>
            </div>

            {isError && <p className="text-sm text-destructive">Failed to load report data. Please try again.</p>}
            {!isError && rows.length === 0 && !isFetching && <p className="text-sm text-muted-foreground">No data found for the selected filters.</p>}

            {rows.length > 0 && (
              <Tabs value={activeTab} onValueChange={(v) => { setActiveTab(v); try { localStorage.setItem("yarn-to-fabric-active-tab", v); } catch {} }}>
                <div className="flex items-center justify-between gap-2 flex-wrap print:hidden">
                  <TabsList>
                    <TabsTrigger value="summary">Summary</TabsTrigger>
                    <TabsTrigger value="detail">Detailed</TabsTrigger>
                    <TabsTrigger value="party-balance">Party Balance</TabsTrigger>
                    <TabsTrigger value="charts">Charts</TabsTrigger>
                  </TabsList>

                  {activeTab === "charts" ? (
                    <div className="flex items-center gap-2">
                      <Button variant="outline" size="sm" onClick={copyChartsToClipboard} disabled={copyLoading} className="gap-1.5">
                        {copyLoading
                          ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          : <ClipboardCopy className="h-3.5 w-3.5" />
                        }
                        {copyLoading ? "Copying…" : "Copy Image"}
                      </Button>
                      <Button variant="outline" size="sm" onClick={exportChartsAsPNG} disabled={pngLoading} className="gap-1.5">
                        {pngLoading
                          ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          : <Image className="h-3.5 w-3.5" />
                        }
                        {pngLoading ? "Exporting…" : "Export PNG"}
                      </Button>
                      <Button variant="outline" size="sm" onClick={printCharts} className="gap-1.5">
                        <Printer className="h-3.5 w-3.5" />
                        Print Charts
                      </Button>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <Button variant="outline" size="sm" onClick={() => setImportOpen(true)} className="gap-1.5">
                        <Upload className="h-3.5 w-3.5" />
                        Import
                      </Button>
                      <Button variant="outline" size="sm" onClick={handlePrint} className="gap-1.5">
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
                          <DropdownMenuItem onClick={activeTab === "summary" ? exportSummaryCSV : activeTab === "party-balance" ? exportPartyBalanceCSV : exportDetailCSV} className="gap-2">
                            <FileSpreadsheet className="h-4 w-4 text-green-600" />
                            Export as CSV
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={activeTab === "summary" ? exportSummaryPDF : activeTab === "party-balance" ? exportPartyBalancePDF : exportDetailPDF} className="gap-2">
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
                      <SelectTrigger className="h-8 w-52 text-sm"><SelectValue /></SelectTrigger>
                      <SelectContent>
                        {GROUP_BY_OPTIONS.map((o) => (
                          <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="rounded-md border overflow-auto max-h-[520px] print:max-h-none print:overflow-visible">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <SortHead label={GROUP_BY_OPTIONS.find((o) => o.value === groupBy)?.label ?? groupBy} sortKey="label" sort={sortSummary} onSort={handleSortSummary} />
                          <TableHead className="whitespace-nowrap">Doc Number(s)</TableHead>
                          <SortHead label="Rows" sortKey="count" sort={sortSummary} onSort={handleSortSummary} right />
                          <SortHead label="Qty"  sortKey="qty"   sort={sortSummary} onSort={handleSortSummary} right />
                          <TableHead className="text-right whitespace-nowrap">Fabric Production</TableHead>
                          <TableHead className="text-right whitespace-nowrap">Fabric Delivery</TableHead>
                          <TableHead className="text-right whitespace-nowrap">Fab Del Return</TableHead>
                          <TableHead className="text-right whitespace-nowrap">Run Fabric Bal.</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {/* Opening Balance row */}
                        <TableRow className="bg-muted/40 italic text-muted-foreground">
                          <TableCell className="whitespace-nowrap">Opening Balance</TableCell>
                          <TableCell /><TableCell /><TableCell /><TableCell /><TableCell /><TableCell />
                          <TableCell className={`text-right whitespace-nowrap font-semibold not-italic ${openingFabricBalance < 0 ? "text-red-600" : "text-emerald-700"}`}>{fmt(openingFabricBalance)}</TableCell>
                        </TableRow>

                        {sortedGrouped.map((r, i) => (
                          <TableRow key={r.label}>
                            <TableCell className="font-medium whitespace-nowrap">{r.label}</TableCell>
                            <TableCell className="text-xs text-muted-foreground whitespace-nowrap max-w-[180px] truncate" title={r.docNums.join(", ")}>{abbrev(r.docNums)}</TableCell>
                            <TableCell className="text-right">{r.count}</TableCell>
                            <TableCell className="text-right">{fmt(r.qty)}</TableCell>
                            <TableCell className="text-right">{r.fabricProduction !== 0 ? fmt(r.fabricProduction) : "—"}</TableCell>
                            <TableCell className={`text-right${r.fabricDelivery < 0 ? " text-red-600" : ""}`}>{r.fabricDelivery !== 0 ? fmt(r.fabricDelivery) : "—"}</TableCell>
                            <TableCell className={`text-right${r.fabricDeliveryReturn > 0 ? " text-green-700" : ""}`}>{r.fabricDeliveryReturn !== 0 ? fmt(r.fabricDeliveryReturn) : "—"}</TableCell>
                            <TableCell className={`text-right whitespace-nowrap font-semibold ${summaryFabricRunning[i] < 0 ? "text-red-600" : "text-emerald-700"}`}>{fmt(summaryFabricRunning[i])}</TableCell>
                          </TableRow>
                        ))}

                        <TableRow className="bg-muted/50 font-semibold">
                          <TableCell>Total</TableCell>
                          <TableCell /><TableCell className="text-right">{rows.length}</TableCell>
                          <TableCell className="text-right">{fmt(totalQty)}</TableCell>
                          <TableCell className="text-right">{fmt(totalFabricProd)}</TableCell>
                          <TableCell className={`text-right${totalFabricDelivery < 0 ? " text-red-600" : ""}`}>{fmt(totalFabricDelivery)}</TableCell>
                          <TableCell className="text-right">{fmt(totalFabricDelRtn)}</TableCell>
                          <TableCell />
                        </TableRow>
                      </TableBody>
                    </Table>
                  </div>
                </TabsContent>

                {/* ── Detail Tab ──────────────────────────── */}
                <TabsContent value="detail" className="mt-3 space-y-3">
                  <Card className="border-dashed print:hidden">
                    <CardContent className="px-4 py-3">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Show / Hide Columns</span>
                        <div className="flex gap-2">
                          <button className="text-xs text-primary hover:underline" onClick={showAllCols}>Show All</button>
                          <span className="text-xs text-muted-foreground">·</span>
                          <button className="text-xs text-primary hover:underline" onClick={hideAllCols}>Hide All</button>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-x-5 gap-y-2">
                        {DETAIL_COLUMNS.map((c) => (
                          <label key={c.key} className="flex items-center gap-1.5 cursor-pointer select-none">
                            <Checkbox checked={visibleCols.has(c.key)} onCheckedChange={() => toggleCol(c.key)} />
                            <span className="text-xs">{c.label}</span>
                          </label>
                        ))}
                      </div>
                    </CardContent>
                  </Card>

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
                              right={RIGHT_ALIGNED.has(c.key)}
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
                            if (c.key === "runningFabricBalance") {
                              return <TableCell key={c.key} className={`text-right whitespace-nowrap font-semibold not-italic ${openingFabricBalance < 0 ? "text-red-600" : "text-emerald-700"}`}>{fmt(openingFabricBalance)}</TableCell>;
                            }
                            return <TableCell key={c.key} className="whitespace-nowrap">{i === 0 ? "Opening Balance" : ""}</TableCell>;
                          })}
                        </TableRow>

                        {detailRenderRows.map((item) => {
                          const { r, fabricBal } = item;

                          return (
                            <TableRow key={r.detailId}>
                              {visibleColsList.map((c) => {
                                switch (c.key) {
                                  case "date":                 return <TableCell key={c.key} className="whitespace-nowrap">{r.date}</TableCell>;
                                  case "docNumber":            return <TableCell key={c.key} className="whitespace-nowrap">{r.docNumber}</TableCell>;
                                  case "reference":            return <TableCell key={c.key} className="whitespace-nowrap">{r.reference ?? "—"}</TableCell>;
                                  case "sl":                   return <TableCell key={c.key}>{r.sl ?? "—"}</TableCell>;
                                  case "gsm":                  return <TableCell key={c.key}>{r.gsm ?? "—"}</TableCell>;
                                  case "transactionTypeName":  return <TableCell key={c.key} className="whitespace-nowrap">{r.transactionTypeName ?? "—"}</TableCell>;
                                  case "jobName":              return <TableCell key={c.key} className="whitespace-nowrap">{r.jobName ?? "—"}</TableCell>;
                                  case "partyName":            return <TableCell key={c.key} className="whitespace-nowrap">{r.partyName ?? "—"}</TableCell>;
                                  case "locationName":         return <TableCell key={c.key} className="whitespace-nowrap">{r.locationName ?? "—"}</TableCell>;
                                  case "fabricTypeName":       return <TableCell key={c.key} className="whitespace-nowrap">{r.fabricTypeName ?? "—"}</TableCell>;
                                  case "yarnTypeName":         return <TableCell key={c.key} className="whitespace-nowrap">{r.yarnTypeName ?? "—"}</TableCell>;
                                  case "yarnCountName":        return <TableCell key={c.key} className="whitespace-nowrap">{r.yarnCountName ?? "—"}</TableCell>;
                                  case "yarnBrandName":        return <TableCell key={c.key} className="whitespace-nowrap">{r.yarnBrandName ?? "—"}</TableCell>;
                                  case "uomName":              return <TableCell key={c.key}>{r.uomName ?? "—"}</TableCell>;
                                  case "machineName":          return <TableCell key={c.key} className="whitespace-nowrap">{r.machineName ?? "—"}</TableCell>;
                                  case "employeeName":  return <TableCell key={c.key} className="whitespace-nowrap">{r.employeeName ?? "—"}</TableCell>;
                                  case "quantity":             return <TableCell key={c.key} className="text-right whitespace-nowrap">{r.quantity != null ? fmt(signedQty(r)) : "—"}</TableCell>;
                                  case "fabricProduction": {
                                    const v = signedNetWtIfType(r, "Fabric Production");
                                    return <TableCell key={c.key} className="text-right whitespace-nowrap text-emerald-700">{v != null ? fmt(v) : "—"}</TableCell>;
                                  }
                                  case "fabricDelivery": {
                                    const v = signedNetWtIfType(r, "Fabric Delivery");
                                    return <TableCell key={c.key} className={`text-right whitespace-nowrap${v != null && v < 0 ? " text-red-600" : " text-orange-600"}`}>{v != null ? fmt(v) : "—"}</TableCell>;
                                  }
                                  case "fabricDeliveryReturn": {
                                    const v = signedNetWtIfType(r, "Fabric Delivery Return");
                                    return <TableCell key={c.key} className="text-right whitespace-nowrap text-green-600">{v != null ? fmt(v) : "—"}</TableCell>;
                                  }
                                  case "runningFabricBalance":
                                    return <TableCell key={c.key} className={`text-right whitespace-nowrap font-medium${fabricBal < 0 ? " text-red-600" : " text-emerald-700"}`}>{fmt(fabricBal)}</TableCell>;
                                  default:
                                    return <TableCell key={c.key} />;
                                }
                              })}
                            </TableRow>
                          );
                        })}

                        {/* Grand Total */}
                        <TableRow className="bg-blue-50 font-bold border-t-2 text-blue-900">
                          {visibleColsList.map((c, ci) => {
                            if (ci === 0)                           return <TableCell key={c.key} className="whitespace-nowrap">Grand Total</TableCell>;
                            if (c.key === "fabricProduction")       return <TableCell key={c.key} className="text-right whitespace-nowrap">{fmt(totalFabricProd)}</TableCell>;
                            if (c.key === "fabricDelivery")         return <TableCell key={c.key} className="text-right whitespace-nowrap">{fmt(totalFabricDelivery)}</TableCell>;
                            if (c.key === "fabricDeliveryReturn")   return <TableCell key={c.key} className="text-right whitespace-nowrap">{fmt(totalFabricDelRtn)}</TableCell>;
                            return <TableCell key={c.key} />;
                          })}
                        </TableRow>
                      </TableBody>
                    </Table>
                  </div>
                </TabsContent>

                {/* ── Party Balance Tab ───────────────────── */}
                <TabsContent value="party-balance" className="mt-3 space-y-3">
                  <div className="flex items-start gap-2">
                    <p className="text-xs text-muted-foreground">
                      Cumulative fabric balance per party — includes all data up to the selected end date.
                    </p>
                  </div>
                  {partyBalanceRows.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No Fabric Delivery or Fabric Delivery Return transactions found.</p>
                  ) : (
                    <div className="rounded-md border overflow-auto max-h-[560px] print:max-h-none print:overflow-visible">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <SortHead label="Party"            sortKey="party"          sort={sortPartyBalance} onSort={handleSortPartyBalance} />
                            <SortHead label="Fabric Delivered" sortKey="fabricDelivery" sort={sortPartyBalance} onSort={handleSortPartyBalance} right />
                            <SortHead label="Fab Del Return"   sortKey="fabricReturn"   sort={sortPartyBalance} onSort={handleSortPartyBalance} right />
                            <SortHead label="Net Outstanding"  sortKey="netOutstanding" sort={sortPartyBalance} onSort={handleSortPartyBalance} right />
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {sortedPartyBalance.map((r) => (
                            <TableRow key={r.party}>
                              <TableCell className="font-medium whitespace-nowrap">{r.party}</TableCell>
                              <TableCell className={`text-right whitespace-nowrap${r.fabricDelivery < 0 ? " text-red-600" : ""}`}>{fmt(r.fabricDelivery)}</TableCell>
                              <TableCell className={`text-right whitespace-nowrap${r.fabricReturn > 0 ? " text-green-700" : ""}`}>{r.fabricReturn !== 0 ? fmt(r.fabricReturn) : "—"}</TableCell>
                              <TableCell className={`text-right whitespace-nowrap font-semibold${r.netOutstanding < 0 ? " text-red-600" : " text-emerald-700"}`}>{fmt(r.netOutstanding)}</TableCell>
                            </TableRow>
                          ))}
                          <TableRow className="bg-blue-50 font-bold border-t-2 text-blue-900">
                            <TableCell className="whitespace-nowrap">Total</TableCell>
                            <TableCell className="text-right whitespace-nowrap">{fmt(partyBalanceTotals.fabricDelivery)}</TableCell>
                            <TableCell className="text-right whitespace-nowrap">{fmt(partyBalanceTotals.fabricReturn)}</TableCell>
                            <TableCell className={`text-right whitespace-nowrap${partyBalanceTotals.netOutstanding < 0 ? " text-red-600" : " text-emerald-700"}`}>{fmt(partyBalanceTotals.netOutstanding)}</TableCell>
                          </TableRow>
                        </TableBody>
                      </Table>
                    </div>
                  )}
                </TabsContent>

                {/* ── Charts Tab ──────────────────────────── */}
                <TabsContent value="charts" className="mt-3 space-y-6">
                  <YtfChartSection
                    rows={rows}
                    runningFabricBalances={runningFabricBalances}
                    openingFabricBalance={openingFabricBalance}
                    dateRange={reportDateRange()}
                  />
                </TabsContent>
              </Tabs>
            )}
          </>
        )}
      </div>

      <ImportDialog
        open={importOpen}
        onOpenChange={setImportOpen}
        onSuccess={() => queryClient.invalidateQueries({ queryKey: ["ytf-reports/data"] })}
      />
    </Layout>
  );
}

// ─── Charts Section ──────────────────────────────────────────────────────────

function YtfChartSection({
  rows,
  runningFabricBalances,
  openingFabricBalance,
  dateRange,
}: {
  rows: ReportRow[];
  runningFabricBalances: number[];
  openingFabricBalance: number;
  dateRange: string;
}) {
  // Fabric Production vs Delivery by Month
  const fabricByMonth = useMemo(() => {
    const map = new Map<string, { production: number; delivery: number }>();
    for (const r of rows) {
      const k = getMonthLabel(r.date);
      const e = map.get(k) ?? { production: 0, delivery: 0 };
      if (r.transactionTypeName === "Fabric Production") e.production += toNum(r.netWt);
      if (r.transactionTypeName === "Fabric Delivery")   e.delivery   += toNum(r.netWt);
      map.set(k, e);
    }
    return Array.from(map.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([month, v]) => ({ month, "Fabric Production": +v.production.toFixed(NUM_DECIMALS), "Fabric Delivery": +v.delivery.toFixed(NUM_DECIMALS) }));
  }, [rows]);

  // Running Fabric Balance over time (by date)
  const fabricBalanceOverTime = useMemo(() => {
    const dateMap = new Map<string, number>();
    rows.forEach((r, idx) => {
      dateMap.set(r.date, runningFabricBalances[idx]);
    });
    const entries = Array.from(dateMap.entries()).sort((a, b) => a[0].localeCompare(b[0]));
    return [
      { date: "Opening", balance: +openingFabricBalance.toFixed(NUM_DECIMALS) },
      ...entries.map(([date, bal]) => ({ date, balance: +bal.toFixed(NUM_DECIMALS) })),
    ];
  }, [rows, runningFabricBalances, openingFabricBalance]);

  return (
    <div id="charts-print-area" className="space-y-6">
      {/* Print-only header */}
      <div className="hidden print:block mb-4">
        <h1 className="text-xl font-bold">TKT Textiles (Knitting) — Yarn to Fabric Report</h1>
        <p className="text-sm text-gray-600 mt-0.5">{dateRange}</p>
      </div>

      {fabricByMonth.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Fabric Production vs Delivery by Month</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={fabricByMonth} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => v.toLocaleString("en-US", { minimumFractionDigits: 3 })} />
                <Legend />
                <Bar dataKey="Fabric Production" fill={CHART_COLORS[1]} />
                <Bar dataKey="Fabric Delivery"   fill={CHART_COLORS[3]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {fabricBalanceOverTime.length > 1 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Running Fabric Balance over Time</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <LineChart data={fabricBalanceOverTime} margin={{ top: 4, right: 16, bottom: 4, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" tick={{ fontSize: 10 }} interval="preserveStartEnd" />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => v.toLocaleString("en-US", { minimumFractionDigits: 3 })} />
                <Line type="monotone" dataKey="balance" name="Fabric Balance" stroke={CHART_COLORS[1]} dot={false} strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
