import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Layout } from "@/components/layout";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";
import { Check, X, Pencil, Trash2, Plus, FileDown, Save } from "lucide-react";

const BASE = import.meta.env.BASE_URL;
const api = (path: string) => `${BASE}api/${path}`;

const MONTHS = [
  { value: "1", label: "January" }, { value: "2", label: "February" },
  { value: "3", label: "March" },   { value: "4", label: "April" },
  { value: "5", label: "May" },     { value: "6", label: "June" },
  { value: "7", label: "July" },    { value: "8", label: "August" },
  { value: "9", label: "September" },{ value: "10", label: "October" },
  { value: "11", label: "November" },{ value: "12", label: "December" },
];
const NOW = new Date();
const YEARS = Array.from({ length: 5 }, (_, i) => String(NOW.getFullYear() - 2 + i));
const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function fmt2(n: number) { return String(n).padStart(2, "0"); }
function fmtNum(v: string | number | null | undefined) {
  const n = parseFloat(String(v ?? "0"));
  return isNaN(n) ? "0.00" : n.toFixed(2);
}

function daysInMonth(year: number, month: number) {
  return new Date(year, month, 0).getDate();
}

type Operator = { id: number; name: string; code: string };
type SalarySetting = {
  id: number; operatorId: number; baseDailyWage: string;
  operatorName: string; operatorCode: string;
};
type SalaryRecord = {
  id: number; operatorId: number; date: string;
  baseWage: string; commission: string; finalSalary: string;
};
type Advance = {
  id: number; operatorId: number; date: string;
  amount: string; notes: string | null;
};
type PayrollSummaryRow = {
  operatorId: number; operatorName: string; operatorCode: string;
  daysRecorded: string; totalBaseWage: string; totalCommission: string;
  totalSalary: string; totalAdvances: string; netPayable: string;
  baseDailyWage: string;
};

// ─── Salary Settings Tab ─────────────────────────────────────────────────────
function SalarySettingsTab({ operators }: { operators: Operator[] }) {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editWage, setEditWage] = useState("");

  const { data: settings = [], isLoading } = useQuery<SalarySetting[]>({
    queryKey: ["operators/salary-settings"],
    queryFn: () => fetch(api("operators/salary-settings")).then((r) => r.json()),
  });

  const settingsMap = useMemo(
    () => new Map(settings.map((s) => [s.operatorId, s])),
    [settings],
  );

  const saveMutation = useMutation({
    mutationFn: (body: { operatorId: number; baseDailyWage: string }) =>
      fetch(api("operators/salary-settings"), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      }).then((r) => r.json()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["operators/salary-settings"] });
      setEditingId(null);
      toast({ title: "Salary setting saved" });
    },
    onError: () => toast({ title: "Failed to save", variant: "destructive" }),
  });

  const handleSave = (opId: number) => {
    const wage = parseFloat(editWage);
    if (isNaN(wage) || wage < 0) {
      toast({ title: "Enter a valid wage", variant: "destructive" });
      return;
    }
    saveMutation.mutate({ operatorId: opId, baseDailyWage: editWage });
  };

  const startEdit = (op: Operator) => {
    const s = settingsMap.get(op.id);
    setEditingId(op.id);
    setEditWage(s ? fmtNum(s.baseDailyWage) : "0.00");
  };

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Salary Settings</h2>
        <p className="text-muted-foreground text-sm mt-0.5">Set base daily wage per operator.</p>
      </div>
      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Operator</TableHead>
              <TableHead>Code</TableHead>
              <TableHead className="w-40">Base Daily Wage (₹)</TableHead>
              <TableHead className="w-24 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <TableRow key={i}>
                {[1,2,3,4].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
              </TableRow>
            ))}
            {!isLoading && operators.map((op) => {
              const s = settingsMap.get(op.id);
              const editing = editingId === op.id;
              return (
                <TableRow key={op.id}>
                  <TableCell className="font-medium">{op.name}</TableCell>
                  <TableCell className="text-muted-foreground">{op.code}</TableCell>
                  <TableCell>
                    {editing ? (
                      <Input
                        className="h-8 text-sm w-32"
                        type="number"
                        step="0.01"
                        min="0"
                        value={editWage}
                        onChange={(e) => setEditWage(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === "Enter") handleSave(op.id);
                          if (e.key === "Escape") setEditingId(null);
                        }}
                        autoFocus
                      />
                    ) : (
                      <span className={s ? "font-mono" : "text-muted-foreground"}>
                        {s ? `₹ ${fmtNum(s.baseDailyWage)}` : "—"}
                      </span>
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    {editing ? (
                      <div className="flex justify-end gap-1">
                        <Button size="icon" variant="ghost" className="h-8 w-8 text-green-600"
                          onClick={() => handleSave(op.id)} disabled={saveMutation.isPending}>
                          <Check className="h-4 w-4" />
                        </Button>
                        <Button size="icon" variant="ghost" className="h-8 w-8"
                          onClick={() => setEditingId(null)}>
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
              );
            })}
            {!isLoading && operators.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} className="text-center py-10 text-muted-foreground">
                  No operators found. Add operators in Master Data first.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}

// ─── Salary Records Tab ───────────────────────────────────────────────────────
function SalaryRecordsTab({ operators }: { operators: Operator[] }) {
  const { toast } = useToast();
  const [operatorId, setOperatorId] = useState<string>("");
  const [month, setMonth] = useState(String(NOW.getMonth() + 1));
  const [year, setYear] = useState(String(NOW.getFullYear()));
  const [commissions, setCommissions] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const { data: settings = [] } = useQuery<SalarySetting[]>({
    queryKey: ["operators/salary-settings"],
    queryFn: () => fetch(api("operators/salary-settings")).then((r) => r.json()),
  });
  const settingsMap = useMemo(
    () => new Map(settings.map((s) => [s.operatorId, s])),
    [settings],
  );

  const ready = !!operatorId && !!month && !!year;

  const { data: records = [], isLoading: recordsLoading, refetch } = useQuery<SalaryRecord[]>({
    queryKey: ["operators/salary-records", operatorId, month, year],
    queryFn: () =>
      fetch(api(`operators/salary-records?operatorId=${operatorId}&month=${month}&year=${year}`))
        .then((r) => r.json()),
    enabled: ready,
    select: (rows) => {
      const map: Record<string, string> = {};
      rows.forEach((r) => { map[r.date] = r.commission; });
      setCommissions((prev) => ({ ...map, ...prev }));
      return rows;
    },
  });

  const recordsMap = useMemo(
    () => new Map(records.map((r) => [r.date, r])),
    [records],
  );

  const days = useMemo(() => {
    if (!ready) return [];
    const count = daysInMonth(parseInt(year), parseInt(month));
    return Array.from({ length: count }, (_, i) => {
      const d = i + 1;
      const dateStr = `${year}-${fmt2(parseInt(month))}-${fmt2(d)}`;
      const dayName = DAY_NAMES[new Date(parseInt(year), parseInt(month) - 1, d).getDay()];
      return { date: dateStr, dayName, day: d };
    });
  }, [ready, year, month]);

  const baseWage = operatorId
    ? fmtNum(settingsMap.get(parseInt(operatorId))?.baseDailyWage ?? "0")
    : "0.00";

  const handleSave = async () => {
    if (!operatorId) return;
    setSaving(true);
    try {
      const rowsToSave = days.map(({ date }) => {
        const comm = parseFloat(commissions[date] ?? "0") || 0;
        const base = parseFloat(baseWage);
        const final = base + comm;
        return {
          date,
          baseWage: baseWage,
          commission: comm.toFixed(2),
          finalSalary: final.toFixed(2),
        };
      });
      const resp = await fetch(api("operators/salary-records/bulk"), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ operatorId: parseInt(operatorId), records: rowsToSave }),
      });
      if (!resp.ok) throw new Error("Failed");
      await refetch();
      toast({ title: "Salary records saved" });
    } catch {
      toast({ title: "Failed to save records", variant: "destructive" });
    } finally {
      setSaving(false);
    }
  };

  const totals = useMemo(() => {
    let totalBase = 0, totalComm = 0, totalFinal = 0;
    days.forEach(({ date }) => {
      const base = parseFloat(baseWage);
      const comm = parseFloat(commissions[date] ?? "0") || 0;
      totalBase += base;
      totalComm += comm;
      totalFinal += base + comm;
    });
    return { totalBase, totalComm, totalFinal };
  }, [days, baseWage, commissions]);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Salary Records</h2>
          <p className="text-muted-foreground text-sm mt-0.5">Enter daily commissions for each operator.</p>
        </div>
        {ready && (
          <Button onClick={handleSave} disabled={saving} size="sm">
            <Save className="mr-2 h-4 w-4" />
            {saving ? "Saving…" : "Save All"}
          </Button>
        )}
      </div>

      <div className="flex gap-3 flex-wrap">
        <Select value={operatorId} onValueChange={(v) => { setOperatorId(v); setCommissions({}); }}>
          <SelectTrigger className="w-52">
            <SelectValue placeholder="Select operator" />
          </SelectTrigger>
          <SelectContent>
            {operators.map((op) => (
              <SelectItem key={op.id} value={String(op.id)}>{op.name} ({op.code})</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={month} onValueChange={setMonth}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Month" />
          </SelectTrigger>
          <SelectContent>
            {MONTHS.map((m) => <SelectItem key={m.value} value={m.value}>{m.label}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={year} onValueChange={setYear}>
          <SelectTrigger className="w-24">
            <SelectValue placeholder="Year" />
          </SelectTrigger>
          <SelectContent>
            {YEARS.map((y) => <SelectItem key={y} value={y}>{y}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      {!ready && (
        <p className="text-muted-foreground text-sm py-8 text-center">
          Select an operator and month to enter salary records.
        </p>
      )}

      {ready && (
        <div className="rounded-md border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-28">Date</TableHead>
                <TableHead className="w-16">Day</TableHead>
                <TableHead className="w-32 text-right">Base Wage (₹)</TableHead>
                <TableHead className="w-40 text-right">Commission (₹)</TableHead>
                <TableHead className="text-right">Final Salary (₹)</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {recordsLoading && Array.from({ length: 7 }).map((_, i) => (
                <TableRow key={i}>
                  {[1,2,3,4,5].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                </TableRow>
              ))}
              {!recordsLoading && days.map(({ date, dayName }) => {
                const comm = parseFloat(commissions[date] ?? recordsMap.get(date)?.commission ?? "0") || 0;
                const base = parseFloat(baseWage);
                const final = base + comm;
                const isSunday = new Date(date).getDay() === 0;
                return (
                  <TableRow key={date} className={isSunday ? "bg-muted/30" : undefined}>
                    <TableCell className="font-mono text-sm">{date}</TableCell>
                    <TableCell className={`text-sm ${isSunday ? "text-red-500 font-medium" : "text-muted-foreground"}`}>{dayName}</TableCell>
                    <TableCell className="text-right font-mono text-sm">₹ {baseWage}</TableCell>
                    <TableCell className="text-right">
                      <Input
                        className="h-7 text-sm text-right w-28 ml-auto font-mono"
                        type="number"
                        step="0.01"
                        min="0"
                        value={commissions[date] ?? (recordsMap.get(date)?.commission ?? "")}
                        onChange={(e) => setCommissions((prev) => ({ ...prev, [date]: e.target.value }))}
                        placeholder="0"
                      />
                    </TableCell>
                    <TableCell className="text-right font-mono text-sm font-medium">
                      ₹ {final.toFixed(2)}
                    </TableCell>
                  </TableRow>
                );
              })}
              {!recordsLoading && (
                <TableRow className="bg-muted/50 font-semibold">
                  <TableCell colSpan={2} className="text-right text-sm">Total</TableCell>
                  <TableCell className="text-right font-mono text-sm">₹ {totals.totalBase.toFixed(2)}</TableCell>
                  <TableCell className="text-right font-mono text-sm">₹ {totals.totalComm.toFixed(2)}</TableCell>
                  <TableCell className="text-right font-mono text-sm">₹ {totals.totalFinal.toFixed(2)}</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}

// ─── Advances Tab ─────────────────────────────────────────────────────────────
function AdvancesTab({ operators }: { operators: Operator[] }) {
  const { toast } = useToast();
  const [operatorId, setOperatorId] = useState<string>("");
  const [month, setMonth] = useState(String(NOW.getMonth() + 1));
  const [year, setYear] = useState(String(NOW.getFullYear()));
  const [newDate, setNewDate] = useState(new Date().toISOString().slice(0, 10));
  const [newAmount, setNewAmount] = useState("");
  const [newNotes, setNewNotes] = useState("");
  const [adding, setAdding] = useState(false);

  const ready = !!operatorId;

  const { data: advances = [], isLoading, refetch } = useQuery<Advance[]>({
    queryKey: ["operators/advances", operatorId, month, year],
    queryFn: () =>
      fetch(api(`operators/advances?operatorId=${operatorId}&month=${month}&year=${year}`))
        .then((r) => r.json()),
    enabled: ready,
  });

  const total = useMemo(
    () => advances.reduce((s, a) => s + parseFloat(a.amount), 0),
    [advances],
  );

  const handleAdd = async () => {
    if (!newAmount || parseFloat(newAmount) <= 0) {
      toast({ title: "Enter a valid amount", variant: "destructive" }); return;
    }
    setAdding(true);
    try {
      const resp = await fetch(api("operators/advances"), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ operatorId: parseInt(operatorId), date: newDate, amount: newAmount, notes: newNotes }),
      });
      if (!resp.ok) throw new Error();
      await refetch();
      setNewAmount("");
      setNewNotes("");
      toast({ title: "Advance added" });
    } catch {
      toast({ title: "Failed to add advance", variant: "destructive" });
    } finally {
      setAdding(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      const resp = await fetch(api(`operators/advances/${id}`), { method: "DELETE" });
      if (!resp.ok && resp.status !== 204) throw new Error();
      await refetch();
      toast({ title: "Advance deleted" });
    } catch {
      toast({ title: "Failed to delete", variant: "destructive" });
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Advances</h2>
        <p className="text-muted-foreground text-sm mt-0.5">Track advance payments to operators.</p>
      </div>

      <div className="flex gap-3 flex-wrap">
        <Select value={operatorId} onValueChange={setOperatorId}>
          <SelectTrigger className="w-52">
            <SelectValue placeholder="Select operator" />
          </SelectTrigger>
          <SelectContent>
            {operators.map((op) => (
              <SelectItem key={op.id} value={String(op.id)}>{op.name} ({op.code})</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={month} onValueChange={setMonth}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Month" />
          </SelectTrigger>
          <SelectContent>
            {MONTHS.map((m) => <SelectItem key={m.value} value={m.value}>{m.label}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={year} onValueChange={setYear}>
          <SelectTrigger className="w-24">
            <SelectValue placeholder="Year" />
          </SelectTrigger>
          <SelectContent>
            {YEARS.map((y) => <SelectItem key={y} value={y}>{y}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      {!ready && (
        <p className="text-muted-foreground text-sm py-8 text-center">Select an operator to view advances.</p>
      )}

      {ready && (
        <>
          <div className="rounded-md border bg-card p-4 flex gap-3 flex-wrap items-end">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-muted-foreground">Date</label>
              <Input type="date" value={newDate} onChange={(e) => setNewDate(e.target.value)} className="h-8 w-40 text-sm" />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-muted-foreground">Amount (₹)</label>
              <Input type="number" step="0.01" min="0" value={newAmount}
                onChange={(e) => setNewAmount(e.target.value)}
                placeholder="0.00" className="h-8 w-32 text-sm font-mono" />
            </div>
            <div className="flex flex-col gap-1 flex-1 min-w-40">
              <label className="text-xs font-medium text-muted-foreground">Notes (optional)</label>
              <Input value={newNotes} onChange={(e) => setNewNotes(e.target.value)}
                placeholder="Reason / description" className="h-8 text-sm" />
            </div>
            <Button size="sm" onClick={handleAdd} disabled={adding}>
              <Plus className="mr-2 h-4 w-4" />
              Add Advance
            </Button>
          </div>

          <div className="rounded-md border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right">Amount (₹)</TableHead>
                  <TableHead>Notes</TableHead>
                  <TableHead className="w-16 text-right">Del</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading && Array.from({ length: 3 }).map((_, i) => (
                  <TableRow key={i}>
                    {[1,2,3,4].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                  </TableRow>
                ))}
                {!isLoading && advances.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">
                      No advances for this period.
                    </TableCell>
                  </TableRow>
                )}
                {!isLoading && advances.map((a) => (
                  <TableRow key={a.id}>
                    <TableCell className="font-mono text-sm">{a.date}</TableCell>
                    <TableCell className="text-right font-mono text-sm">₹ {fmtNum(a.amount)}</TableCell>
                    <TableCell className="text-muted-foreground text-sm">{a.notes ?? "—"}</TableCell>
                    <TableCell className="text-right">
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button size="icon" variant="ghost" className="h-8 w-8 text-muted-foreground hover:text-destructive">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Delete advance?</AlertDialogTitle>
                            <AlertDialogDescription>
                              This will permanently remove the ₹{fmtNum(a.amount)} advance on {a.date}.
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancel</AlertDialogCancel>
                            <AlertDialogAction
                              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                              onClick={() => handleDelete(a.id)}>
                              Delete
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </TableCell>
                  </TableRow>
                ))}
                {!isLoading && advances.length > 0 && (
                  <TableRow className="bg-muted/50 font-semibold">
                    <TableCell className="text-right text-sm">Total</TableCell>
                    <TableCell className="text-right font-mono text-sm">₹ {total.toFixed(2)}</TableCell>
                    <TableCell colSpan={2} />
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </>
      )}
    </div>
  );
}

// ─── Payroll Summary Tab ──────────────────────────────────────────────────────
function PayrollSummaryTab({ operators }: { operators: Operator[] }) {
  const { toast } = useToast();
  const [month, setMonth] = useState(String(NOW.getMonth() + 1));
  const [year, setYear] = useState(String(NOW.getFullYear()));
  const [filterOperatorId, setFilterOperatorId] = useState<string>("all");

  const { data: summary = [], isLoading } = useQuery<PayrollSummaryRow[]>({
    queryKey: ["operators/payroll-summary", month, year, filterOperatorId],
    queryFn: () => {
      const opParam = filterOperatorId !== "all" ? `&operatorId=${filterOperatorId}` : "";
      return fetch(api(`operators/payroll-summary?month=${month}&year=${year}${opParam}`))
        .then((r) => r.json());
    },
    enabled: !!month && !!year,
  });

  const monthLabel = MONTHS.find((m) => m.value === month)?.label ?? month;

  const handleExportPDF = async () => {
    if (summary.length === 0) {
      toast({ title: "No data to export", variant: "destructive" }); return;
    }
    try {
      const { default: jsPDF } = await import("jspdf");
      const { default: autoTable } = await import("jspdf-autotable");
      const doc = new jsPDF({ orientation: "landscape" });

      doc.setFontSize(16);
      doc.text("TKT Textiles (Knitting)", 14, 16);
      doc.setFontSize(11);
      doc.setTextColor(100);
      doc.text(`Payroll Summary — ${monthLabel} ${year}`, 14, 24);
      doc.setTextColor(0);

      const rows = summary.map((r) => [
        r.operatorName,
        r.operatorCode,
        r.daysRecorded,
        `₹ ${fmtNum(r.totalBaseWage)}`,
        `₹ ${fmtNum(r.totalCommission)}`,
        `₹ ${fmtNum(r.totalSalary)}`,
        `₹ ${fmtNum(r.totalAdvances)}`,
        `₹ ${fmtNum(r.netPayable)}`,
      ]);

      autoTable(doc, {
        head: [["Operator", "Code", "Days", "Base Wage", "Commission", "Total Salary", "Advances", "Net Payable"]],
        body: rows,
        startY: 30,
        styles: { fontSize: 9 },
        headStyles: { fillColor: [37, 99, 235] },
        columnStyles: {
          2: { halign: "right" },
          3: { halign: "right" },
          4: { halign: "right" },
          5: { halign: "right" },
          6: { halign: "right" },
          7: { halign: "right", fontStyle: "bold" },
        },
      });

      doc.save(`payroll-${year}-${fmt2(parseInt(month))}.pdf`);
    } catch {
      toast({ title: "PDF export failed", variant: "destructive" });
    }
  };

  const grandTotal = useMemo(() => ({
    days: summary.reduce((s, r) => s + parseInt(r.daysRecorded), 0),
    base: summary.reduce((s, r) => s + parseFloat(r.totalBaseWage), 0),
    comm: summary.reduce((s, r) => s + parseFloat(r.totalCommission), 0),
    salary: summary.reduce((s, r) => s + parseFloat(r.totalSalary), 0),
    advances: summary.reduce((s, r) => s + parseFloat(r.totalAdvances), 0),
    net: summary.reduce((s, r) => s + parseFloat(r.netPayable), 0),
  }), [summary]);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Payroll Summary</h2>
          <p className="text-muted-foreground text-sm mt-0.5">Monthly payroll overview per operator.</p>
        </div>
        <Button variant="outline" size="sm" onClick={handleExportPDF}>
          <FileDown className="mr-2 h-4 w-4" />
          Export PDF
        </Button>
      </div>

      <div className="flex gap-3 flex-wrap">
        <Select value={month} onValueChange={setMonth}>
          <SelectTrigger className="w-36"><SelectValue placeholder="Month" /></SelectTrigger>
          <SelectContent>
            {MONTHS.map((m) => <SelectItem key={m.value} value={m.value}>{m.label}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={year} onValueChange={setYear}>
          <SelectTrigger className="w-24"><SelectValue placeholder="Year" /></SelectTrigger>
          <SelectContent>
            {YEARS.map((y) => <SelectItem key={y} value={y}>{y}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={filterOperatorId} onValueChange={setFilterOperatorId}>
          <SelectTrigger className="w-52"><SelectValue placeholder="All operators" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Operators</SelectItem>
            {operators.map((op) => (
              <SelectItem key={op.id} value={String(op.id)}>{op.name} ({op.code})</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Operator</TableHead>
              <TableHead>Code</TableHead>
              <TableHead className="text-right">Days</TableHead>
              <TableHead className="text-right">Base Wage (₹)</TableHead>
              <TableHead className="text-right">Commission (₹)</TableHead>
              <TableHead className="text-right">Total Salary (₹)</TableHead>
              <TableHead className="text-right">Advances (₹)</TableHead>
              <TableHead className="text-right font-semibold">Net Payable (₹)</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <TableRow key={i}>
                {[1,2,3,4,5,6,7,8].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
              </TableRow>
            ))}
            {!isLoading && summary.length === 0 && (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-10 text-muted-foreground">
                  No payroll data for {monthLabel} {year}.
                </TableCell>
              </TableRow>
            )}
            {!isLoading && summary.map((r) => (
              <TableRow key={r.operatorId}>
                <TableCell className="font-medium">{r.operatorName}</TableCell>
                <TableCell className="text-muted-foreground">{r.operatorCode}</TableCell>
                <TableCell className="text-right font-mono text-sm">{r.daysRecorded}</TableCell>
                <TableCell className="text-right font-mono text-sm">₹ {fmtNum(r.totalBaseWage)}</TableCell>
                <TableCell className="text-right font-mono text-sm">₹ {fmtNum(r.totalCommission)}</TableCell>
                <TableCell className="text-right font-mono text-sm">₹ {fmtNum(r.totalSalary)}</TableCell>
                <TableCell className="text-right font-mono text-sm text-orange-600">
                  ₹ {fmtNum(r.totalAdvances)}
                </TableCell>
                <TableCell className="text-right font-mono text-sm font-bold text-green-700">
                  ₹ {fmtNum(r.netPayable)}
                </TableCell>
              </TableRow>
            ))}
            {!isLoading && summary.length > 0 && (
              <TableRow className="bg-muted/50 font-semibold">
                <TableCell colSpan={2} className="text-right text-sm">Total</TableCell>
                <TableCell className="text-right font-mono text-sm">{grandTotal.days}</TableCell>
                <TableCell className="text-right font-mono text-sm">₹ {grandTotal.base.toFixed(2)}</TableCell>
                <TableCell className="text-right font-mono text-sm">₹ {grandTotal.comm.toFixed(2)}</TableCell>
                <TableCell className="text-right font-mono text-sm">₹ {grandTotal.salary.toFixed(2)}</TableCell>
                <TableCell className="text-right font-mono text-sm text-orange-600">₹ {grandTotal.advances.toFixed(2)}</TableCell>
                <TableCell className="text-right font-mono text-sm text-green-700">₹ {grandTotal.net.toFixed(2)}</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function OperatorsPage() {
  const { data: operators = [], isLoading: opsLoading } = useQuery<Operator[]>({
    queryKey: ["masters/machine-operator"],
    queryFn: () => fetch(api("masters/machine-operator")).then((r) => r.json()),
  });

  return (
    <Layout>
      <div className="flex flex-col gap-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Operators</h1>
          <p className="text-muted-foreground mt-1">
            Manage salary settings, daily records, advances and payroll summaries.
          </p>
        </div>

        {opsLoading ? (
          <div className="flex flex-col gap-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <Skeleton key={i} className="h-8 w-full" />
            ))}
          </div>
        ) : (
          <Tabs defaultValue="salary-settings">
            <TabsList className="mb-2">
              <TabsTrigger value="salary-settings">Salary Settings</TabsTrigger>
              <TabsTrigger value="salary-records">Salary Records</TabsTrigger>
              <TabsTrigger value="advances">Advances</TabsTrigger>
              <TabsTrigger value="payroll-summary">Payroll Summary</TabsTrigger>
            </TabsList>

            <TabsContent value="salary-settings" className="mt-4">
              <SalarySettingsTab operators={operators} />
            </TabsContent>
            <TabsContent value="salary-records" className="mt-4">
              <SalaryRecordsTab operators={operators} />
            </TabsContent>
            <TabsContent value="advances" className="mt-4">
              <AdvancesTab operators={operators} />
            </TabsContent>
            <TabsContent value="payroll-summary" className="mt-4">
              <PayrollSummaryTab operators={operators} />
            </TabsContent>
          </Tabs>
        )}
      </div>
    </Layout>
  );
}
