import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import { Trash2, Download } from "lucide-react";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { DateInput } from "@/components/ui/date-input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

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

// ─── Types ───────────────────────────────────────────────────────────────────

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

// ─── API fetch helper ─────────────────────────────────────────────────────────

async function apiFetch(path: string, opts?: RequestInit) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...opts,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || body.message || `HTTP ${res.status}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

// ─── Advances Tab ─────────────────────────────────────────────────────────────

function AdvancesTab() {
  const { toast } = useToast();
  const qc = useQueryClient();

  const [form, setForm] = useState({ employeeId: "", date: todayStr(), amount: "", notes: "" });
  const [filterOp, setFilterOp] = useState("__all__");
  const [filterFrom, setFilterFrom] = useState("");
  const [filterTo, setFilterTo] = useState("");

  const { data: employees = [] } = useQuery<EmployeeLookup[]>({
    queryKey: ["employee-lookup"],
    queryFn: () => apiFetch("/api/lookups/employee-master"),
  });

  const advanceParams = new URLSearchParams();
  if (filterOp !== "__all__") advanceParams.set("employeeId", filterOp);
  if (filterFrom) advanceParams.set("dateFrom", filterFrom);
  if (filterTo) advanceParams.set("dateTo", filterTo);

  const { data: advances = [], isLoading } = useQuery<Advance[]>({
    queryKey: ["employee-advances", filterOp, filterFrom, filterTo],
    queryFn: () => apiFetch(`/api/employees/advances?${advanceParams.toString()}`),
  });

  const { sorted: sortedAdvances, sort, toggleSort } = useSort(advances, {
    date: (a: Advance) => a.date,
    employeeName: (a: Advance) => a.employeeName,
    // amount arrives from the API as a string; sorting it as text puts
    // 1000 before 900.
    amount: (a: Advance) => toNum(a.amount),
    notes: (a: Advance) => a.notes,
  });

  const addMutation = useMutation({
    mutationFn: (data: object) => apiFetch("/api/employees/advances", { method: "POST", body: JSON.stringify(data) }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["employee-advances"] });
      setForm({ employeeId: "", date: todayStr(), amount: "", notes: "" });
      toast({ title: "Advance recorded." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiFetch(`/api/employees/advances/${id}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["employee-advances"] });
      toast({ title: "Advance deleted." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  function handleAdd() {
    if (!form.employeeId || !form.date || form.amount === "") {
      toast({ variant: "destructive", title: "Validation", description: "Employee, date, and amount are required." });
      return;
    }
    const amt = parseFloat(form.amount);
    if (isNaN(amt) || amt < 0) {
      toast({ variant: "destructive", title: "Validation", description: "Amount must be ≥ 0." });
      return;
    }
    addMutation.mutate({ employeeId: parseInt(form.employeeId), date: form.date, amount: amt, notes: form.notes || null });
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Add Advance</CardTitle></CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-4 items-end">
            <div className="flex flex-col gap-1">
              <Label>Employee</Label>
              <Select value={form.employeeId} onValueChange={(v) => setForm((p) => ({ ...p, employeeId: v }))}>
                <SelectTrigger className="w-48">
                  <SelectValue placeholder="Select employee" />
                </SelectTrigger>
                <SelectContent>
                  {employees.filter((op) => op.active).map((op) => (
                    <SelectItem key={op.id} value={String(op.id)}>{op.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex flex-col gap-1">
              <Label>Date</Label>
              <DateInput className="w-40" value={form.date} onChange={(e) => setForm((p) => ({ ...p, date: e.target.value }))} />
            </div>
            <div className="flex flex-col gap-1">
              <Label>Amount</Label>
              <Input type="number" min="0" step="0.01" className="w-32" placeholder="0.00"
                value={form.amount} onChange={(e) => setForm((p) => ({ ...p, amount: e.target.value }))} />
            </div>
            <div className="flex flex-col gap-1 flex-1 min-w-40">
              <Label>Notes (optional)</Label>
              <Input placeholder="e.g. Festival advance" value={form.notes}
                onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))} />
            </div>
            <Button onClick={handleAdd} disabled={addMutation.isPending}>
              {addMutation.isPending ? "Adding…" : "Add Advance"}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Advance History</CardTitle>
          <div className="flex flex-wrap gap-4 mt-2">
            <Select value={filterOp} onValueChange={setFilterOp}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="All employees" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Employees</SelectItem>
                {employees.map((op) => (
                  <SelectItem key={op.id} value={String(op.id)}>{op.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <div className="flex items-center gap-2">
              <Label className="text-xs">From</Label>
              <DateInput className="w-36 h-8" value={filterFrom} onChange={(e) => setFilterFrom(e.target.value)} />
            </div>
            <div className="flex items-center gap-2">
              <Label className="text-xs">To</Label>
              <DateInput className="w-36 h-8" value={filterTo} onChange={(e) => setFilterTo(e.target.value)} />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <SortableHead label="Date" sortKey="date" sort={sort} onSort={toggleSort} />
                <SortableHead label="Employee" sortKey="employeeName" sort={sort} onSort={toggleSort} />
                <SortableHead label="Amount" sortKey="amount" sort={sort} onSort={toggleSort} right />
                <SortableHead label="Notes" sortKey="notes" sort={sort} onSort={toggleSort} />
                <TableHead className="w-16"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading && Array.from({ length: 4 }).map((_, i) => (
                <TableRow key={i}>
                  {[1,2,3,4,5].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                </TableRow>
              ))}
              {!isLoading && advances.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-8">No advances found.</TableCell>
                </TableRow>
              )}
              {!isLoading && sortedAdvances.map((a) => (
                <TableRow key={a.id}>
                  <TableCell className="font-mono text-sm">{formatDate(a.date)}</TableCell>
                  <TableCell>{a.employeeName}</TableCell>
                  <TableCell className="text-right font-mono">{fmtMoney(toNum(a.amount))}</TableCell>
                  <TableCell className="text-muted-foreground text-sm">{a.notes || "—"}</TableCell>
                  <TableCell>
                    <AlertDialog>
                      <AlertDialogTrigger asChild>
                        <Button size="icon" variant="ghost" className="h-8 w-8 text-destructive">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </AlertDialogTrigger>
                      <AlertDialogContent>
                        <AlertDialogHeader>
                          <AlertDialogTitle>Delete Advance</AlertDialogTitle>
                          <AlertDialogDescription>
                            Delete {fmtMoney(toNum(a.amount))} advance for {a.employeeName} on {formatDate(a.date)}? This cannot be undone.
                          </AlertDialogDescription>
                        </AlertDialogHeader>
                        <AlertDialogFooter>
                          <AlertDialogCancel>Cancel</AlertDialogCancel>
                          <AlertDialogAction onClick={() => deleteMutation.mutate(a.id)} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                            Delete
                          </AlertDialogAction>
                        </AlertDialogFooter>
                      </AlertDialogContent>
                    </AlertDialog>
                  </TableCell>
                </TableRow>
              ))}
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
  const [hasRun, setHasRun] = useState(false);

  const { data: employees = [] } = useQuery<EmployeeLookup[]>({
    queryKey: ["employee-lookup"],
    queryFn: () => apiFetch("/api/lookups/employee-master"),
  });

  const params = new URLSearchParams({ month, year });
  if (employeeId !== "__all__") params.set("employeeId", employeeId);

  const { data: summary = [], isLoading } = useQuery<PayrollSummaryItem[]>({
    queryKey: ["payroll-summary", month, year, employeeId],
    queryFn: () => apiFetch(`/api/employees/payroll-summary?${params.toString()}`),
    enabled: hasRun,
  });

  const { sorted: sortedSummary, sort, toggleSort } = useSort(summary, {
    employeeName: (s: PayrollSummaryItem) => s.employeeName,
    totalDaysWorked: (s: PayrollSummaryItem) => s.totalDaysWorked,
    totalSalary: (s: PayrollSummaryItem) => s.totalSalary,
    totalAdvances: (s: PayrollSummaryItem) => s.totalAdvances,
    netPayable: (s: PayrollSummaryItem) => s.netPayable,
  });

  function exportPDF() {
    if (summary.length === 0) {
      toast({ variant: "destructive", title: "No data", description: "Run the summary first." });
      return;
    }
    const doc = new jsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
    const monthName = MONTHS[parseInt(month) - 1];
    const title = `Payroll Summary — ${monthName} ${year}`;
    doc.setFontSize(16);
    doc.text(title, 14, 18);

    autoTable(doc, {
      startY: 26,
      head: [["Employee", "Days Worked", "Total Salary", "Total Advances", "Net Payable"]],
      // Export follows the on-screen order. If the user sorted by Net Payable
      // to review the largest payouts, a PDF back in API order would not match
      // what they were looking at when they hit Export.
      body: sortedSummary.map((s) => [
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

    for (const s of sortedSummary) {
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
              <SelectTrigger className="w-48">
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
          <Button onClick={() => { setHasRun(true); }} variant="outline">Run Summary</Button>
          <Button onClick={exportPDF} className="gap-2">
            <Download className="h-4 w-4" />
            Download PDF
          </Button>
        </div>

        {hasRun && isLoading && (
          <div className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
          </div>
        )}

        {hasRun && !isLoading && (
          <Table>
            <TableHeader>
              <TableRow>
                <SortableHead label="Employee" sortKey="employeeName" sort={sort} onSort={toggleSort} />
                <SortableHead label="Days Worked" sortKey="totalDaysWorked" sort={sort} onSort={toggleSort} right />
                <SortableHead label="Total Salary" sortKey="totalSalary" sort={sort} onSort={toggleSort} right />
                <SortableHead label="Total Advances" sortKey="totalAdvances" sort={sort} onSort={toggleSort} right />
                <SortableHead label="Net Payable" sortKey="netPayable" sort={sort} onSort={toggleSort} right />
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

export default function EmployeesPage() {
  return (
    <Layout>
      <div className="flex flex-col gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Employees</h1>
          <p className="text-muted-foreground mt-1">Manage employee advances and payroll summary.</p>
        </div>
        <Tabs defaultValue="advances">
          <TabsList>
            <TabsTrigger value="advances">Advances</TabsTrigger>
            <TabsTrigger value="payroll-summary">Payroll Summary</TabsTrigger>
          </TabsList>
          <TabsContent value="advances" className="mt-4">
            <AdvancesTab />
          </TabsContent>
          <TabsContent value="payroll-summary" className="mt-4">
            <PayrollSummaryTab />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}
