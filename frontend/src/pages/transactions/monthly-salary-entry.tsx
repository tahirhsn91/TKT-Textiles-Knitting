import { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useLocation, useSearch } from "wouter";
import type jsPDF from "jspdf";
import type autoTable from "jspdf-autotable";
import { Trash2, Download, PlusCircle, Pencil, Lock, Unlock } from "lucide-react";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { DateInput } from "@/components/ui/date-input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useSort } from "@/hooks/use-sort";
import { SortableHead } from "@/components/sortable-head";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

const CURRENT_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 5 }, (_, i) => CURRENT_YEAR - 2 + i);

function toNum(v: string | number | null | undefined): number {
  const n = parseFloat(String(v ?? ""));
  return isNaN(n) ? 0 : n;
}

function fmtMoney(n: number) {
  return n.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDate(dateStr: string) {
  const d = new Date(dateStr + "T00:00:00");
  const day = String(d.getDate()).padStart(2, "0");
  const mon = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][d.getMonth()];
  return `${day}/${mon}/${d.getFullYear()}`;
}

function getDayName(dateStr: string) {
  const d = new Date(dateStr + "T00:00:00");
  return ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][d.getDay()];
}

function todayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function fmtTimestamp(ts: string | null | undefined): string {
  if (!ts) return "—";
  const d = new Date(ts);
  return d.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
}

function downloadBlob(content: string, filename: string, mime: string) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function toCSV(headers: string[], rows: (string | number | null)[][]): string {
  const escape = (v: string | number | null) => {
    const s = v === null || v === undefined ? "" : String(v);
    return s.includes(",") || s.includes('"') || s.includes("\n")
      ? `"${s.replace(/"/g, '""')}"`
      : s;
  };
  return [headers, ...rows].map((r) => r.map(escape).join(",")).join("\n");
}

// ─── Types ───────────────────────────────────────────────────────────────────

interface Department {
  id: number;
  name: string;
  code: string;
}

interface EmployeeLookup {
  id: number;
  name: string;
  code: string;
  active: boolean;
}

interface SalaryRecord {
  id: number;
  employeeId: number;
  date: string;
  baseWage: string | null;
  commission: string | null;
  finalSalary: string | null;
}

interface Advance {
  id: number;
  employeeId: number;
  employeeName: string;
  date: string;
  amount: string;
  notes: string | null;
}

interface PayrollSummaryItem {
  employeeId: number;
  employeeName: string;
  employeeCode: string;
  totalDaysWorked: number;
  totalSalary: number;
  totalAdvances: number;
  netPayable: number;
  records: SalaryRecord[];
  advances: Advance[];
}

interface SalaryHeader {
  id: number;
  month: number;
  year: number;
  departmentIds: number[];
  departmentNames: string[];
  posted: boolean;
  createdAt: string | null;
  updatedAt: string | null;
}

interface SalaryDetailRow {
  id: number;
  headerId: number;
  employeeId: number;
  employeeName: string;
  basicSalary: string;
  otRateHr: string;
  attAllowance: string;
  othAllowance: string;
  presentDays: string;
  absentDays: string;
  holidays: string;
  totalAttendance: string;
  totalSalary: string;
  otHours: string;
  otAmount: string;
  advanceDeduction: string;
  loanDeduction: string;
  otherDeduction: string;
  payableSalary: string;
}

// ─── API fetch helper ─────────────────────────────────────────────────────────

async function apiFetch<T = unknown>(path: string, opts?: RequestInit): Promise<T> {
  try {
    return await customFetch<T>(path, opts ?? { method: "GET" });
  } catch (err) {
    throw err instanceof Error ? err : new Error(`HTTP request failed`);
  }
}

// ─── Salary Entry Tab ─────────────────────────────────────────────────────────

function SalaryEntryTab() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [, navigate] = useLocation();
  const search = useSearch();

  // Filter state, sourced from the URL so a filter is deep-linkable and
  // survives a refresh. Read the query params once via a lazy initialiser.
  const initialParams = useMemo(() => new URLSearchParams(search), [search]);
  const [filterMonth, setFilterMonth] = useState(() => initialParams.get("month") ?? "__all__");
  const [filterYear, setFilterYear] = useState(() => initialParams.get("year") ?? "__all__");
  const [filterDept, setFilterDept] = useState(() => initialParams.get("departmentId") ?? "__all__");

  // Keep filter state in sync with the URL (deep-linking + shareable filters).
  useEffect(() => {
    const params = new URLSearchParams();
    if (filterMonth !== "__all__") params.set("month", filterMonth);
    if (filterYear !== "__all__") params.set("year", filterYear);
    if (filterDept !== "__all__") params.set("departmentId", filterDept);
    const qs = params.toString();
    const target = qs ? `/transactions/monthly-salary-entry?${qs}` : "/transactions/monthly-salary-entry";
    if (search !== (qs ? `?${qs}` : "")) {
      navigate(target, { replace: true });
    }
  }, [filterMonth, filterYear, filterDept, navigate, search]);

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ["department-lookup"],
    queryFn: () => apiFetch("/api/lookups/department-master"),
  });

  // Build query string based on filters
  const queryParams = new URLSearchParams();
  if (filterMonth !== "__all__") queryParams.set("month", filterMonth);
  if (filterYear !== "__all__") queryParams.set("year", filterYear);
  if (filterDept !== "__all__") queryParams.set("departmentId", filterDept);

  const hasFilter = filterMonth !== "__all__" || filterYear !== "__all__" || filterDept !== "__all__";

  const { data: headers = [], isLoading } = useQuery<SalaryHeader[]>({
    queryKey: ["salary-headers", filterMonth, filterYear, filterDept],
    queryFn: () => apiFetch(`/api/salary-entries?${queryParams.toString()}`),
  });

  const { sorted: sortedHeaders, sort, toggleSort } = useSort(headers, {
    // Sort the period chronologically, not by the rendered "March 2026" text,
    // which would order alphabetically and interleave years.
    period: (h: SalaryHeader) => h.year * 100 + h.month,
    departments: (h: SalaryHeader) => (h.departmentNames ?? []).join(", "),
    createdAt: (h: SalaryHeader) => h.createdAt,
    posted: (h: SalaryHeader) => h.posted,
  });

  // Which header row currently has a post/unpost/delete in flight, so we can
  // disable that row's actions and avoid double-clicks on it.
  const [pendingId, setPendingId] = useState<number | null>(null);

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiFetch(`/api/salary-entries/${id}`, { method: "DELETE" }),
    onMutate: (id) => setPendingId(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["salary-headers"] });
      toast({ title: "Record deleted." });
    },
    onSettled: () => setPendingId(null),
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  const postMutation = useMutation({
    mutationFn: ({ id, action }: { id: number; action: "post" | "unpost" }) =>
      apiFetch(`/api/salary-entries/${id}/${action}`, { method: "POST" }),
    onMutate: ({ id }) => setPendingId(id),
    onSuccess: (_, vars) => {
      qc.invalidateQueries({ queryKey: ["salary-headers"] });
      toast({ title: vars.action === "post" ? "Record posted." : "Record un-posted." });
    },
    onSettled: () => setPendingId(null),
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  async function handleExportCSV() {
    if (headers.length === 0) {
      toast({ variant: "destructive", title: "No data", description: "No salary entries match the current filter." });
      return;
    }
    // Fetch details only for the currently-filtered headers
    const allDetails: Array<{ header: SalaryHeader; details: SalaryDetailRow[] }> = [];
    for (const h of headers) {
      try {
        const full = await apiFetch<{ details: SalaryDetailRow[] }>(`/api/salary-entries/${h.id}`);
        allDetails.push({ header: h, details: full.details ?? [] });
      } catch {
        // skip on error
      }
    }

    const csvHeaders = [
      "Month", "Year", "Departments", "Status",
      "Employee", "Basic Salary", "OT Rate/Hr", "Att. Allowance", "Oth. Allowance",
      "Present Days", "Absent Days", "Holidays", "Total Attendance",
      "Total Salary", "OT Hours", "OT Amount",
      "Advance Deduction", "Loan Deduction", "Other Deduction", "Payable Salary",
    ];

    const rows: (string | number | null)[][] = [];
    for (const { header, details } of allDetails) {
      const monthName = MONTHS[header.month - 1];
      const deptNames = (header.departmentNames ?? []).join("; ");
      const status = header.posted ? "Posted" : "Draft";
      for (const d of details) {
        rows.push([
          monthName, header.year, deptNames, status,
          d.employeeName, d.basicSalary, d.otRateHr, d.attAllowance, d.othAllowance,
          d.presentDays, d.absentDays, d.holidays, d.totalAttendance,
          d.totalSalary, d.otHours, d.otAmount,
          d.advanceDeduction, d.loanDeduction, d.otherDeduction, d.payableSalary,
        ]);
      }
    }

    const yearPart = filterYear !== "__all__" ? filterYear : "all";
    const monPart = filterMonth !== "__all__" ? MONTHS[parseInt(filterMonth) - 1].toLowerCase() : "all";
    const deptName = filterDept !== "__all__"
      ? (departments.find((d) => String(d.id) === filterDept)?.name ?? "dept").toLowerCase().replace(/\s+/g, "-")
      : "all-depts";
    downloadBlob(toCSV(csvHeaders, rows), `salary-entries-${yearPart}-${monPart}-${deptName}.csv`, "text/csv;charset=utf-8;");
  }

  return (
    <div className="space-y-4">
      {/* Filters + actions */}
      <div className="flex flex-wrap items-end gap-3 justify-between">
        <div className="flex flex-wrap gap-3 items-end">
          <div className="flex flex-col gap-1">
            <Label className="text-xs">Month</Label>
            <Select value={filterMonth} onValueChange={setFilterMonth}>
              <SelectTrigger className="w-36 h-8 text-sm">
                <SelectValue placeholder="All months" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Months</SelectItem>
                {MONTHS.map((m, i) => (
                  <SelectItem key={i + 1} value={String(i + 1)}>{m}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label className="text-xs">Year</Label>
            <Select value={filterYear} onValueChange={setFilterYear}>
              <SelectTrigger className="w-28 h-8 text-sm">
                <SelectValue placeholder="All years" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Years</SelectItem>
                {YEARS.map((y) => (
                  <SelectItem key={y} value={String(y)}>{y}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label className="text-xs">Department</Label>
            <Select value={filterDept} onValueChange={setFilterDept}>
              <SelectTrigger className="w-44 h-8 text-sm">
                <SelectValue placeholder="All departments" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Departments</SelectItem>
                {departments.map((d) => (
                  <SelectItem key={d.id} value={String(d.id)}>{d.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          {hasFilter && (
            <Button
              variant="ghost" size="sm" className="h-8 text-xs text-muted-foreground hover:text-foreground"
              onClick={() => { setFilterMonth("__all__"); setFilterYear("__all__"); setFilterDept("__all__"); }}
            >
              Clear filters
            </Button>
          )}
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" className="gap-1.5" onClick={handleExportCSV} aria-label="Export salary entries to CSV">
            <Download className="h-4 w-4" />
            Export CSV
          </Button>
          <Button size="sm" className="gap-1.5" onClick={() => navigate("/transactions/monthly-salary-entry/new")} aria-label="Add new salary entry">
            <PlusCircle className="h-4 w-4" />
            Add New Salary
          </Button>
        </div>
      </div>

      {/* Result summary line when filters are active */}
      <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
        <span aria-live="polite">
          {isLoading ? "Loading…" : `${headers.length} salary entr${headers.length === 1 ? "y" : "ies"}${hasFilter ? " (filtered)" : ""}`}
        </span>
        {hasFilter && !isLoading && headers.length > 0 && (
          <Button variant="outline" size="sm" className="h-6 px-2 text-[11px]" onClick={() => { setFilterMonth("__all__"); setFilterYear("__all__"); setFilterDept("__all__"); }}>
            Clear filters
          </Button>
        )}
      </div>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <SortableHead label="Month / Year" sortKey="period" sort={sort} onSort={toggleSort} />
                <SortableHead label="Department(s)" sortKey="departments" sort={sort} onSort={toggleSort} />
                <SortableHead label="Created" sortKey="createdAt" sort={sort} onSort={toggleSort} />
                <SortableHead label="Status" sortKey="posted" sort={sort} onSort={toggleSort} />
                <TableHead className="w-52 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading && Array.from({ length: 3 }).map((_, i) => (
                <TableRow key={i}>
                  {[1,2,3,4,5].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                </TableRow>
              ))}
              {!isLoading && headers.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-10">
                    {hasFilter
                      ? "No salary entries match the selected filters."
                      : "No salary entries yet. Click \"Add New Salary\" to get started."}
                  </TableCell>
                </TableRow>
              )}
              {!isLoading && sortedHeaders.map((h) => {
                const busy = pendingId === h.id;
                return (
                <TableRow key={h.id} aria-busy={busy || undefined}>
                  <TableCell className="font-medium">
                    {MONTHS[h.month - 1]} {h.year}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {(h.departmentNames ?? []).join(", ") || "—"}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {fmtTimestamp(h.createdAt)}
                  </TableCell>
                  <TableCell>
                    {h.posted
                      ? <Badge className="bg-green-100 text-green-800 border-green-200">Posted</Badge>
                      : <Badge variant="outline">Draft</Badge>}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end gap-1">
                      {!h.posted && (
                        <>
                          <Button
                            size="icon" variant="ghost" className="h-8 w-8"
                            title="Edit" aria-label="Edit salary entry"
                            disabled={busy}
                            onClick={() => navigate(`/transactions/monthly-salary-entry/${h.id}/edit`)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          {/* Post — requires confirmation */}
                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button
                                size="icon" variant="ghost" className="h-8 w-8 text-green-700"
                                title="Post" aria-label="Post salary entry" disabled={busy || postMutation.isPending}
                              >
                                <Lock className="h-4 w-4" />
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Post Salary Entry</AlertDialogTitle>
                                <AlertDialogDescription>
                                  Post the {MONTHS[h.month - 1]} {h.year} entry? Once posted it will be locked for editing.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancel</AlertDialogCancel>
                                <AlertDialogAction onClick={() => postMutation.mutate({ id: h.id, action: "post" })}>
                                  Post
                                </AlertDialogAction>
                              </AlertDialogFooter>
                            </AlertDialogContent>
                          </AlertDialog>
                        </>
                      )}
                      {h.posted && (
                        /* Un-Post — requires confirmation */
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button
                              size="icon" variant="ghost" className="h-8 w-8 text-amber-600"
                              title="Un-Post" aria-label="Un-post salary entry" disabled={busy || postMutation.isPending}
                            >
                              <Unlock className="h-4 w-4" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Un-Post Salary Entry</AlertDialogTitle>
                              <AlertDialogDescription>
                                Un-post the {MONTHS[h.month - 1]} {h.year} entry? This will revert it to Draft so it can be edited again.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction onClick={() => postMutation.mutate({ id: h.id, action: "unpost" })}>
                                Un-Post
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      )}
                      {!h.posted && (
                        /* Delete — requires confirmation */
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button size="icon" variant="ghost" className="h-8 w-8 text-destructive" title="Delete" aria-label="Delete salary entry" disabled={busy}>
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Delete Salary Entry</AlertDialogTitle>
                              <AlertDialogDescription>
                                Delete the {MONTHS[h.month - 1]} {h.year} entry? This removes all employee detail rows and cannot be undone.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction
                                onClick={() => deleteMutation.mutate(h.id)}
                                className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                              >
                                Delete
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}

// ─── Payroll Summary Tab ──────────────────────────────────────────────────────

function PayrollSummaryTab() {
  const { toast } = useToast();
  const [month, setMonth] = useState(String(new Date().getMonth() + 1));
  const [year, setYear] = useState(String(CURRENT_YEAR));
  const [employeeId, setEmployeeId] = useState("__all__");

  const { data: employees = [] } = useQuery<EmployeeLookup[]>({
    queryKey: ["employee-lookup"],
    queryFn: () => apiFetch("/api/lookups/employee-master"),
  });

  const params = new URLSearchParams({ month, year });
  if (employeeId !== "__all__") params.set("employeeId", employeeId);

  const { data: summary = [], isLoading } = useQuery<PayrollSummaryItem[]>({
    queryKey: ["payroll-summary", month, year, employeeId],
    queryFn: () => apiFetch(`/api/employees/payroll-summary?${params.toString()}`),
  });

  const { sorted: sortedSummary, sort: sumSort, toggleSort: toggleSumSort } = useSort(summary, {
    employeeName: (s: PayrollSummaryItem) => s.employeeName,
    totalDaysWorked: (s: PayrollSummaryItem) => s.totalDaysWorked,
    totalSalary: (s: PayrollSummaryItem) => s.totalSalary,
    totalAdvances: (s: PayrollSummaryItem) => s.totalAdvances,
    netPayable: (s: PayrollSummaryItem) => s.netPayable,
  });

  async function exportPDF() {
    if (summary.length === 0) {
      toast({ variant: "destructive", title: "No data", description: "Run the summary first." });
      return;
    }
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
    const doc = new JsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
    const monthName = MONTHS[parseInt(month) - 1];
    const title = `Payroll Summary — ${monthName} ${year}`;
    doc.setFontSize(16);
    doc.text(title, 14, 18);

    autoTable(doc, {
      startY: 26,
      head: [["Employee", "Days Worked", "Total Salary", "Total Advances", "Net Payable"]],
      body: summary.map((s) => [
        s.employeeName,
        s.totalDaysWorked,
        fmtMoney(s.totalSalary),
        fmtMoney(s.totalAdvances),
        fmtMoney(s.netPayable),
      ]),
      styles: { fontSize: 9 },
      headStyles: { fillColor: [37, 99, 235] },
    });

    let yOffset = (doc as jsPDF & { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 10;

    for (const s of summary) {
      if (yOffset > 250) { doc.addPage(); yOffset = 14; }
      doc.setFontSize(12);
      doc.text(`${s.employeeName} (${s.employeeCode}) — Daily Breakdown`, 14, yOffset);
      yOffset += 4;

      autoTable(doc, {
        startY: yOffset,
        head: [["Date", "Day", "Base Wage", "Commission", "Final Amount"]],
        body: s.records.map((r) => [
          formatDate(r.date),
          getDayName(r.date),
          fmtMoney(toNum(r.baseWage)),
          fmtMoney(toNum(r.commission)),
          fmtMoney(toNum(r.finalSalary)),
        ]),
        styles: { fontSize: 8 },
        headStyles: { fillColor: [100, 116, 139] },
      });

      yOffset = (doc as jsPDF & { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 4;

      if (s.advances.length > 0) {
        doc.setFontSize(10);
        doc.text("Advances", 14, yOffset);
        yOffset += 3;
        autoTable(doc, {
          startY: yOffset,
          head: [["Date", "Amount", "Notes"]],
          body: s.advances.map((a) => [
            formatDate(a.date),
            fmtMoney(toNum(a.amount)),
            a.notes || "",
          ]),
          styles: { fontSize: 8 },
          headStyles: { fillColor: [220, 38, 38] },
        });
        yOffset = (doc as jsPDF & { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 4;
      }

      doc.setFontSize(9);
      doc.text(`Net Payable: ${fmtMoney(s.netPayable)}`, 14, yOffset);
      yOffset += 10;
    }

    doc.save(`payroll-${year}-${String(month).padStart(2, "0")}.pdf`);
  }

  const grandTotal = summary.reduce((acc, s) => ({
    days: acc.days + s.totalDaysWorked,
    salary: acc.salary + s.totalSalary,
    advances: acc.advances + s.totalAdvances,
    net: acc.net + s.netPayable,
  }), { days: 0, salary: 0, advances: 0, net: 0 });

  return (
    <Card>
      <CardHeader>
        <CardTitle>Payroll Summary</CardTitle>
        <p className="text-sm text-muted-foreground">View monthly payroll for all or individual employees.</p>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex flex-wrap gap-4 items-end">
          <div className="flex flex-col gap-1">
            <Label>Month</Label>
            <Select value={month} onValueChange={setMonth}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {MONTHS.map((m, i) => (
                  <SelectItem key={i + 1} value={String(i + 1)}>{m}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label>Year</Label>
            <Select value={year} onValueChange={setYear}>
              <SelectTrigger className="w-28">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {YEARS.map((y) => (
                  <SelectItem key={y} value={String(y)}>{y}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label>Employee (optional)</Label>
            <Select value={employeeId} onValueChange={setEmployeeId}>
              <SelectTrigger className="h-11 w-full sm:h-9 sm:w-48">
                <SelectValue placeholder="All Employees" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Employees</SelectItem>
                {employees.map((op) => (
                  <SelectItem key={op.id} value={String(op.id)}>{op.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <Button onClick={exportPDF} className="gap-2">
            <Download className="h-4 w-4" />
            Download PDF
          </Button>
        </div>

        {isLoading && (
          <div className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
          </div>
        )}

        {!isLoading && (
          <Table>
            <TableHeader>
              <TableRow>
                <SortableHead label="Employee" sortKey="employeeName" sort={sumSort} onSort={toggleSumSort} />
                <SortableHead label="Days Worked" sortKey="totalDaysWorked" sort={sumSort} onSort={toggleSumSort} right />
                <SortableHead label="Total Salary" sortKey="totalSalary" sort={sumSort} onSort={toggleSumSort} right />
                <SortableHead label="Total Advances" sortKey="totalAdvances" sort={sumSort} onSort={toggleSumSort} right />
                <SortableHead label="Net Payable" sortKey="netPayable" sort={sumSort} onSort={toggleSumSort} right />
              </TableRow>
            </TableHeader>
            <TableBody>
              {sortedSummary.map((s) => (
                <TableRow key={s.employeeId}>
                  <TableCell className="font-medium">{s.employeeName} <span className="text-muted-foreground text-xs">({s.employeeCode})</span></TableCell>
                  <TableCell className="text-right">{s.totalDaysWorked}</TableCell>
                  <TableCell className="text-right">{fmtMoney(s.totalSalary)}</TableCell>
                  <TableCell className="text-right text-red-600">{fmtMoney(s.totalAdvances)}</TableCell>
                  <TableCell className={`text-right font-semibold ${s.netPayable < 0 ? "text-red-600" : "text-green-700"}`}>
                    {fmtMoney(s.netPayable)}
                  </TableCell>
                </TableRow>
              ))}
              {summary.length > 1 && (
                <TableRow className="border-t-2 font-bold bg-muted/30">
                  <TableCell>Total</TableCell>
                  <TableCell className="text-right">{grandTotal.days}</TableCell>
                  <TableCell className="text-right">{fmtMoney(grandTotal.salary)}</TableCell>
                  <TableCell className="text-right text-red-600">{fmtMoney(grandTotal.advances)}</TableCell>
                  <TableCell className={`text-right ${grandTotal.net < 0 ? "text-red-600" : "text-green-700"}`}>
                    {fmtMoney(grandTotal.net)}
                  </TableCell>
                </TableRow>
              )}
              {summary.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-8">No data for selected period.</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function PayrollMaintenancePage() {
  return (
    <Layout>
      <div className="flex flex-col gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Payroll Maintenance</h1>
          <p className="text-muted-foreground mt-1">Monthly salary entries, advances, and payroll summary.</p>
        </div>
        <Tabs defaultValue="salary-entry">
          <TabsList>
            <TabsTrigger value="salary-entry">Salary Entry</TabsTrigger>
            <TabsTrigger value="payroll-summary">Payroll Summary</TabsTrigger>
          </TabsList>
          <TabsContent value="salary-entry" className="mt-4">
            <SalaryEntryTab />
          </TabsContent>
          <TabsContent value="payroll-summary" className="mt-4">
            <PayrollSummaryTab />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}
