import { useState, useMemo, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import { Trash2, Save, Download, Pencil, Check, X } from "lucide-react";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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

function getDaysInMonth(year: number, month: number): string[] {
  const count = new Date(year, month, 0).getDate();
  return Array.from({ length: count }, (_, i) => {
    const d = i + 1;
    return `${year}-${String(month).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
  });
}

function todayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

// ─── Types ───────────────────────────────────────────────────────────────────

interface Operator {
  operatorId: number;
  operatorName: string;
  operatorCode: string;
  baseDailyWage: string | null;
}

interface SalaryRecord {
  id: number;
  operatorId: number;
  date: string;
  baseWage: string | null;
  commission: string | null;
  finalSalary: string | null;
}

interface Advance {
  id: number;
  operatorId: number;
  operatorName: string;
  date: string;
  amount: string;
  notes: string | null;
}

interface PayrollSummaryItem {
  operatorId: number;
  operatorName: string;
  operatorCode: string;
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

// ─── Salary Settings Tab ─────────────────────────────────────────────────────

function SalarySettingsTab() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editValue, setEditValue] = useState("");

  const { data: operators = [], isLoading } = useQuery<Operator[]>({
    queryKey: ["operators-salary-settings"],
    queryFn: () => apiFetch("/api/operators/salary-settings"),
  });

  const saveMutation = useMutation({
    mutationFn: ({ operatorId, baseDailyWage }: { operatorId: number; baseDailyWage: number }) =>
      apiFetch("/api/operators/salary-settings", {
        method: "POST",
        body: JSON.stringify({ operatorId, baseDailyWage }),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["operators-salary-settings"] });
      setEditingId(null);
      toast({ title: "Saved", description: "Base daily wage updated." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  function startEdit(op: Operator) {
    setEditingId(op.operatorId);
    setEditValue(op.baseDailyWage ? String(parseFloat(op.baseDailyWage)) : "0");
  }

  function cancelEdit() {
    setEditingId(null);
    setEditValue("");
  }

  function handleSave(op: Operator) {
    const val = parseFloat(editValue);
    if (isNaN(val) || val < 0) {
      toast({ variant: "destructive", title: "Invalid", description: "Wage must be ≥ 0." });
      return;
    }
    saveMutation.mutate({ operatorId: op.operatorId, baseDailyWage: val });
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Salary Settings</CardTitle>
        <p className="text-sm text-muted-foreground">Set the base daily wage for each operator.</p>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Code</TableHead>
              <TableHead>Name</TableHead>
              <TableHead className="text-right">Base Daily Wage (₹)</TableHead>
              <TableHead className="w-24 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <TableRow key={i}>
                {[1,2,3,4].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
              </TableRow>
            ))}
            {!isLoading && operators.map((op) => (
              <TableRow key={op.operatorId}>
                <TableCell className="font-mono text-sm">{op.operatorCode}</TableCell>
                <TableCell className="font-medium">{op.operatorName}</TableCell>
                <TableCell className="text-right">
                  {editingId === op.operatorId ? (
                    <Input
                      type="number"
                      min="0"
                      step="0.01"
                      className="w-32 ml-auto text-right h-8"
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      onKeyDown={(e) => { if (e.key === "Enter") handleSave(op); if (e.key === "Escape") cancelEdit(); }}
                      autoFocus
                    />
                  ) : (
                    <span className={op.baseDailyWage ? "font-mono" : "text-muted-foreground"}>
                      {op.baseDailyWage ? `₹ ${fmtMoney(toNum(op.baseDailyWage))}` : "—"}
                    </span>
                  )}
                </TableCell>
                <TableCell className="text-right">
                  {editingId === op.operatorId ? (
                    <div className="flex justify-end gap-1">
                      <Button size="icon" variant="ghost" className="h-8 w-8 text-green-600"
                        onClick={() => handleSave(op)} disabled={saveMutation.isPending}>
                        <Check className="h-4 w-4" />
                      </Button>
                      <Button size="icon" variant="ghost" className="h-8 w-8"
                        onClick={cancelEdit}>
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ) : (
                    <Button size="icon" variant="ghost" className="h-8 w-8 text-muted-foreground"
                      onClick={() => startEdit(op)}>
                      <Pencil className="h-4 w-4" />
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
            {!isLoading && operators.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} className="text-center py-10 text-muted-foreground">
                  No operators found. Add operators in Master Data first.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

// ─── Salary Records Tab ───────────────────────────────────────────────────────

function SalaryRecordsTab() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [selectedOperator, setSelectedOperator] = useState("");
  const [selectedMonth, setSelectedMonth] = useState(String(new Date().getMonth() + 1));
  const [selectedYear, setSelectedYear] = useState(String(CURRENT_YEAR));
  const [commissions, setCommissions] = useState<Record<string, string>>({});

  const { data: operators = [] } = useQuery<Operator[]>({
    queryKey: ["operators-salary-settings"],
    queryFn: () => apiFetch("/api/operators/salary-settings"),
  });

  const selectedOp = operators.find((o) => String(o.operatorId) === selectedOperator);
  const baseWage = toNum(selectedOp?.baseDailyWage);

  const enabled = !!(selectedOperator && selectedMonth && selectedYear);

  const { data: records, isLoading: recordsLoading } = useQuery<SalaryRecord[]>({
    queryKey: ["salary-records", selectedOperator, selectedMonth, selectedYear],
    queryFn: () => apiFetch(`/api/operators/salary-records?operatorId=${selectedOperator}&month=${selectedMonth}&year=${selectedYear}`),
    enabled,
  });

  useEffect(() => {
    const map: Record<string, string> = {};
    for (const r of records ?? []) {
      if (r.commission !== null) map[r.date] = String(parseFloat(r.commission));
    }
    setCommissions(map);
  }, [records]);

  const days = useMemo(() => {
    if (!enabled) return [];
    return getDaysInMonth(parseInt(selectedYear), parseInt(selectedMonth));
  }, [enabled, selectedYear, selectedMonth]);

  const bulkMutation = useMutation({
    mutationFn: (entries: { operatorId: number; date: string; commission: number }[]) =>
      apiFetch("/api/operators/salary-records/bulk", { method: "POST", body: JSON.stringify(entries) }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["salary-records", selectedOperator, selectedMonth, selectedYear] });
      toast({ title: "Saved", description: "Salary records saved successfully." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  function handleSave() {
    const entries = Object.entries(commissions)
      .filter(([, v]) => v !== "" && v !== undefined)
      .map(([date, v]) => ({
        operatorId: parseInt(selectedOperator),
        date,
        commission: parseFloat(v) || 0,
      }))
      .filter((e) => e.commission >= 0);
    if (entries.length === 0) {
      toast({ variant: "destructive", title: "Nothing to save", description: "Enter at least one commission value." });
      return;
    }
    bulkMutation.mutate(entries);
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Salary Records</CardTitle>
        <p className="text-sm text-muted-foreground">Select an operator and month to enter daily commission/production amounts.</p>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex flex-wrap gap-4">
          <div className="flex flex-col gap-1">
            <Label>Operator</Label>
            <Select value={selectedOperator} onValueChange={setSelectedOperator}>
              <SelectTrigger className="w-56">
                <SelectValue placeholder="Select operator" />
              </SelectTrigger>
              <SelectContent>
                {operators.map((op) => (
                  <SelectItem key={op.operatorId} value={String(op.operatorId)}>{op.operatorName}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label>Month</Label>
            <Select value={selectedMonth} onValueChange={setSelectedMonth}>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Month" />
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
            <Select value={selectedYear} onValueChange={setSelectedYear}>
              <SelectTrigger className="w-28">
                <SelectValue placeholder="Year" />
              </SelectTrigger>
              <SelectContent>
                {YEARS.map((y) => (
                  <SelectItem key={y} value={String(y)}>{y}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        {!enabled && (
          <p className="text-muted-foreground text-sm">Select an operator and month to view the grid.</p>
        )}

        {enabled && (
          <>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Day</TableHead>
                    <TableHead className="text-right">Base Wage (₹)</TableHead>
                    <TableHead className="text-right">Commission / Production (₹)</TableHead>
                    <TableHead className="text-right">Final Amount (₹)</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {recordsLoading && Array.from({ length: 7 }).map((_, i) => (
                    <TableRow key={i}>
                      {[1,2,3,4,5].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                    </TableRow>
                  ))}
                  {!recordsLoading && days.map((date) => {
                    const commStr = commissions[date] ?? "";
                    const commVal = commStr !== "" ? parseFloat(commStr) : 0;
                    const finalAmt = Math.max(baseWage, isNaN(commVal) ? 0 : commVal);
                    return (
                      <TableRow key={date}>
                        <TableCell className="font-mono text-sm whitespace-nowrap">{formatDate(date)}</TableCell>
                        <TableCell className="text-sm">{getDayName(date)}</TableCell>
                        <TableCell className="text-right text-sm">{fmtMoney(baseWage)}</TableCell>
                        <TableCell className="text-right">
                          <Input
                            type="number"
                            min="0"
                            step="0.01"
                            className="w-32 ml-auto text-right h-8"
                            value={commissions[date] ?? ""}
                            onChange={(e) => {
                              const v = e.target.value;
                              setCommissions((prev) => {
                                if (v === "") {
                                  const next = { ...prev };
                                  delete next[date];
                                  return next;
                                }
                                return { ...prev, [date]: v };
                              });
                            }}
                          />
                        </TableCell>
                        <TableCell className="text-right font-medium">
                          {commStr !== "" ? fmtMoney(finalAmt) : "—"}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
            <div className="flex justify-end pt-2">
              <Button onClick={handleSave} disabled={bulkMutation.isPending} className="gap-2">
                <Save className="h-4 w-4" />
                {bulkMutation.isPending ? "Saving…" : "Save Records"}
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

// ─── Advances Tab ─────────────────────────────────────────────────────────────

function AdvancesTab() {
  const { toast } = useToast();
  const qc = useQueryClient();

  const [form, setForm] = useState({ operatorId: "", date: todayStr(), amount: "", notes: "" });
  const [filterOp, setFilterOp] = useState("__all__");
  const [filterFrom, setFilterFrom] = useState("");
  const [filterTo, setFilterTo] = useState("");

  const { data: operators = [] } = useQuery<Operator[]>({
    queryKey: ["operators-salary-settings"],
    queryFn: () => apiFetch("/api/operators/salary-settings"),
  });

  const advanceParams = new URLSearchParams();
  if (filterOp !== "__all__") advanceParams.set("operatorId", filterOp);
  if (filterFrom) advanceParams.set("dateFrom", filterFrom);
  if (filterTo) advanceParams.set("dateTo", filterTo);

  const { data: advances = [], isLoading } = useQuery<Advance[]>({
    queryKey: ["operator-advances", filterOp, filterFrom, filterTo],
    queryFn: () => apiFetch(`/api/operators/advances?${advanceParams.toString()}`),
  });

  const addMutation = useMutation({
    mutationFn: (data: object) => apiFetch("/api/operators/advances", { method: "POST", body: JSON.stringify(data) }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["operator-advances"] });
      setForm({ operatorId: "", date: todayStr(), amount: "", notes: "" });
      toast({ title: "Advance recorded." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiFetch(`/api/operators/advances/${id}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["operator-advances"] });
      toast({ title: "Advance deleted." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  function handleAdd() {
    if (!form.operatorId || !form.date || form.amount === "") {
      toast({ variant: "destructive", title: "Validation", description: "Operator, date, and amount are required." });
      return;
    }
    const amt = parseFloat(form.amount);
    if (isNaN(amt) || amt < 0) {
      toast({ variant: "destructive", title: "Validation", description: "Amount must be ≥ 0." });
      return;
    }
    addMutation.mutate({ operatorId: parseInt(form.operatorId), date: form.date, amount: amt, notes: form.notes || null });
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Add Advance</CardTitle></CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-4 items-end">
            <div className="flex flex-col gap-1">
              <Label>Operator</Label>
              <Select value={form.operatorId} onValueChange={(v) => setForm((p) => ({ ...p, operatorId: v }))}>
                <SelectTrigger className="w-48">
                  <SelectValue placeholder="Select operator" />
                </SelectTrigger>
                <SelectContent>
                  {operators.map((op) => (
                    <SelectItem key={op.operatorId} value={String(op.operatorId)}>{op.operatorName}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex flex-col gap-1">
              <Label>Date</Label>
              <Input type="date" className="w-40" value={form.date} onChange={(e) => setForm((p) => ({ ...p, date: e.target.value }))} />
            </div>
            <div className="flex flex-col gap-1">
              <Label>Amount (₹)</Label>
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
                <SelectValue placeholder="All operators" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Operators</SelectItem>
                {operators.map((op) => (
                  <SelectItem key={op.operatorId} value={String(op.operatorId)}>{op.operatorName}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <div className="flex items-center gap-2">
              <Label className="text-xs">From</Label>
              <Input type="date" className="w-36 h-8" value={filterFrom} onChange={(e) => setFilterFrom(e.target.value)} />
            </div>
            <div className="flex items-center gap-2">
              <Label className="text-xs">To</Label>
              <Input type="date" className="w-36 h-8" value={filterTo} onChange={(e) => setFilterTo(e.target.value)} />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>Operator</TableHead>
                <TableHead className="text-right">Amount (₹)</TableHead>
                <TableHead>Notes</TableHead>
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
              {!isLoading && advances.map((a) => (
                <TableRow key={a.id}>
                  <TableCell className="font-mono text-sm">{formatDate(a.date)}</TableCell>
                  <TableCell>{a.operatorName}</TableCell>
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
                            Delete ₹{fmtMoney(toNum(a.amount))} advance for {a.operatorName} on {formatDate(a.date)}? This cannot be undone.
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
  const [operatorId, setOperatorId] = useState("__all__");
  const [hasRun, setHasRun] = useState(false);

  const { data: operators = [] } = useQuery<Operator[]>({
    queryKey: ["operators-salary-settings"],
    queryFn: () => apiFetch("/api/operators/salary-settings"),
  });

  const params = new URLSearchParams({ month, year });
  if (operatorId !== "__all__") params.set("operatorId", operatorId);

  const { data: summary = [], isLoading } = useQuery<PayrollSummaryItem[]>({
    queryKey: ["payroll-summary", month, year, operatorId],
    queryFn: () => apiFetch(`/api/operators/payroll-summary?${params.toString()}`),
    enabled: hasRun,
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
      head: [["Operator", "Days Worked", "Total Salary (₹)", "Total Advances (₹)", "Net Payable (₹)"]],
      body: summary.map((s) => [
        s.operatorName,
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
      doc.text(`${s.operatorName} (${s.operatorCode}) — Daily Breakdown`, 14, yOffset);
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
      doc.text(`Net Payable: ₹${fmtMoney(s.netPayable)}`, 14, yOffset);
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
        <p className="text-sm text-muted-foreground">View monthly payroll for all or individual operators.</p>
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
            <Label>Operator (optional)</Label>
            <Select value={operatorId} onValueChange={setOperatorId}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="All Operators" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Operators</SelectItem>
                {operators.map((op) => (
                  <SelectItem key={op.operatorId} value={String(op.operatorId)}>{op.operatorName}</SelectItem>
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
                <TableHead>Operator</TableHead>
                <TableHead className="text-right">Days Worked</TableHead>
                <TableHead className="text-right">Total Salary (₹)</TableHead>
                <TableHead className="text-right">Total Advances (₹)</TableHead>
                <TableHead className="text-right">Net Payable (₹)</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {summary.map((s) => (
                <TableRow key={s.operatorId}>
                  <TableCell className="font-medium">{s.operatorName} <span className="text-muted-foreground text-xs">({s.operatorCode})</span></TableCell>
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

export default function OperatorsPage() {
  return (
    <Layout>
      <div className="flex flex-col gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Operators</h1>
          <p className="text-muted-foreground mt-1">Manage operator wages, salary records, advances, and payroll.</p>
        </div>
        <Tabs defaultValue="salary-settings">
          <TabsList>
            <TabsTrigger value="salary-settings">Salary Settings</TabsTrigger>
            <TabsTrigger value="salary-records">Salary Records</TabsTrigger>
            <TabsTrigger value="advances">Advances</TabsTrigger>
            <TabsTrigger value="payroll-summary">Payroll Summary</TabsTrigger>
          </TabsList>
          <TabsContent value="salary-settings" className="mt-4">
            <SalarySettingsTab />
          </TabsContent>
          <TabsContent value="salary-records" className="mt-4">
            <SalaryRecordsTab />
          </TabsContent>
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
