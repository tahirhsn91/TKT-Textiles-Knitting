import { useState, useEffect, useCallback, useMemo } from "react";
import { useParams, useLocation } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { ArrowLeft, Save, Check, ChevronsUpDown } from "lucide-react";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";

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

function daysInMonthFn(month: number, year: number): number {
  return new Date(year, month, 0).getDate();
}

function getPrevMonth(): { month: number; year: number } {
  const d = new Date();
  d.setMonth(d.getMonth() - 1);
  return { month: d.getMonth() + 1, year: d.getFullYear() };
}

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

interface Department { id: number; name: string; code: string; }
interface Operator {
  id: number; name: string; code: string; active: boolean;
  departmentId: number | null;
  baseSalary: string | null;
  overtimeRateHr: string | null;
  attAllowance: string | null;
  othAllowance: string | null;
}

interface DetailRow {
  operatorId: number;
  departmentId: number | null;
  operatorName: string;
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

// Fields that, when changed, trigger auto-recalculation of totalSalary
const SALARY_SOURCE_FIELDS = new Set<keyof DetailRow>(["basicSalary", "totalAttendance"]);
// Fields that, when changed, trigger auto-recalculation of otAmount
const OT_SOURCE_FIELDS = new Set<keyof DetailRow>(["otHours", "otRateHr"]);

function recomputePayable(row: DetailRow): DetailRow {
  const payable =
    toNum(row.totalSalary) +
    toNum(row.otAmount) -
    toNum(row.advanceDeduction) -
    toNum(row.loanDeduction) -
    toNum(row.otherDeduction);
  return { ...row, payableSalary: payable.toFixed(2) };
}

function recomputeAll(row: DetailRow, totalDays: number): DetailRow {
  const totalSalary =
    totalDays > 0 ? (toNum(row.basicSalary) / totalDays) * toNum(row.totalAttendance) : 0;
  const otAmount = toNum(row.otHours) * toNum(row.otRateHr);
  return recomputePayable({
    ...row,
    totalSalary: totalSalary.toFixed(2),
    otAmount: otAmount.toFixed(2),
  });
}

function rowFromOperator(op: Operator, totalDays: number): DetailRow {
  const base: DetailRow = {
    operatorId: op.id,
    departmentId: op.departmentId,
    operatorName: op.name,
    basicSalary: toNum(op.baseSalary).toFixed(2),
    otRateHr: toNum(op.overtimeRateHr).toFixed(2),
    attAllowance: toNum(op.attAllowance).toFixed(2),
    othAllowance: toNum(op.othAllowance).toFixed(2),
    presentDays: "0",
    absentDays: "0",
    holidays: "0",
    totalAttendance: "0",
    totalSalary: "0.00",
    otHours: "0",
    otAmount: "0.00",
    advanceDeduction: "0.00",
    loanDeduction: "0.00",
    otherDeduction: "0.00",
    payableSalary: "0.00",
  };
  return recomputeAll(base, totalDays);
}

// ─────────────────────────────────────────────────────────────────────────────

export default function PayrollEntryPage() {
  const params = useParams<{ id?: string }>();
  const headerId = params.id ? parseInt(params.id) : NaN;
  const isEdit = !isNaN(headerId);
  const [, navigate] = useLocation();
  const { toast } = useToast();

  const pm = useMemo(() => getPrevMonth(), []);
  const [month, setMonth] = useState(String(pm.month));
  const [year, setYear] = useState(String(pm.year));
  const [selectedDeptIds, setSelectedDeptIds] = useState<number[]>([]);
  const [rows, setRows] = useState<DetailRow[]>([]);
  const [initialized, setInitialized] = useState(false);
  const [deptPopoverOpen, setDeptPopoverOpen] = useState(false);

  const totalDays = daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR);

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ["dept-lookup"],
    queryFn: () => apiFetch("/api/lookups/department-master"),
  });

  const { data: allOperators = [] } = useQuery<Operator[]>({
    queryKey: ["operator-full-lookup"],
    queryFn: () => apiFetch("/api/lookups/machine-operator-master"),
  });

  const { data: existingEntry, isLoading: loadingEntry } = useQuery<{
    id: number; month: number; year: number; departmentIds: number[]; posted: boolean;
    details: DetailRow[];
  }>({
    queryKey: ["salary-entry", headerId],
    queryFn: () => apiFetch(`/api/salary-entries/${headerId}`),
    enabled: isEdit,
  });

  // Populate form once when loading an existing entry
  useEffect(() => {
    if (!isEdit || !existingEntry || initialized) return;
    setMonth(String(existingEntry.month));
    setYear(String(existingEntry.year));
    setSelectedDeptIds(existingEntry.departmentIds ?? []);
    setRows(existingEntry.details.map((d) => ({ ...d })));
    setInitialized(true);
  }, [isEdit, existingEntry, initialized]);

  // For new mode: rebuild rows when dept selection or operator list changes
  const deptKey = useMemo(
    () => selectedDeptIds.slice().sort().join(","),
    [selectedDeptIds]
  );
  const [builtForKey, setBuiltForKey] = useState<string | null>(null);
  const [builtForOpCount, setBuiltForOpCount] = useState(-1);

  useEffect(() => {
    if (isEdit) return;
    if (deptKey === builtForKey && allOperators.length === builtForOpCount) return;
    setBuiltForKey(deptKey);
    setBuiltForOpCount(allOperators.length);
    if (selectedDeptIds.length === 0) { setRows([]); return; }
    const td = daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR);
    const filtered = allOperators.filter(
      (op) => op.active && op.departmentId !== null && selectedDeptIds.includes(op.departmentId!)
    );
    setRows(filtered.map((op) => rowFromOperator(op, td)));
  }, [isEdit, deptKey, allOperators.length]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Row update with field-aware formula logic ──
  const updateRow = useCallback(
    (idx: number, field: keyof DetailRow, value: string) => {
      setRows((prev) => {
        const next = [...prev];
        const td = daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR);
        const updated = { ...next[idx], [field]: value };

        if (SALARY_SOURCE_FIELDS.has(field) || OT_SOURCE_FIELDS.has(field)) {
          // Source field changed → recompute both derived salary/OT fields and payable
          next[idx] = recomputeAll(updated, td);
        } else {
          // User is directly editing totalSalary, otAmount, or a deduction →
          // honour their override, only recompute payableSalary
          next[idx] = recomputePayable(updated);
        }
        return next;
      });
    },
    [month, year]
  );

  // When month changes: update state and recompute formula fields
  const handleMonthChange = useCallback(
    (m: string) => {
      setMonth(m);
      const td = daysInMonthFn(parseInt(m) || 1, parseInt(year) || CURRENT_YEAR);
      setRows((prev) => prev.map((r) => recomputeAll(r, td)));
    },
    [year]
  );

  // When year changes: update state and recompute formula fields
  const handleYearChange = useCallback(
    (y: string) => {
      setYear(y);
      const td = daysInMonthFn(parseInt(month) || 1, parseInt(y) || CURRENT_YEAR);
      setRows((prev) => prev.map((r) => recomputeAll(r, td)));
    },
    [month]
  );

  const saveMutation = useMutation({
    mutationFn: (body: object) =>
      isEdit
        ? apiFetch(`/api/salary-entries/${headerId}`, { method: "PUT", body: JSON.stringify(body) })
        : apiFetch("/api/salary-entries", { method: "POST", body: JSON.stringify(body) }),
    onSuccess: () => {
      toast({ title: isEdit ? "Record updated." : "Record saved." });
      navigate("/transactions/monthly-salary-entry");
    },
    onError: (e: Error) =>
      toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  function handleSave() {
    if (!month || !year) {
      toast({ variant: "destructive", title: "Validation", description: "Month and year are required." });
      return;
    }
    if (selectedDeptIds.length === 0) {
      toast({ variant: "destructive", title: "Validation", description: "Select at least one department." });
      return;
    }
    if (rows.length === 0) {
      toast({ variant: "destructive", title: "Validation", description: "No employees for selected department(s)." });
      return;
    }
    saveMutation.mutate({
      month: parseInt(month),
      year: parseInt(year),
      departmentIds: selectedDeptIds,
      details: rows,
    });
  }

  function toggleDept(id: number) {
    setSelectedDeptIds((prev) =>
      prev.includes(id) ? prev.filter((d) => d !== id) : [...prev, id]
    );
  }

  const isPosted = existingEntry?.posted ?? false;

  if (isEdit && loadingEntry) {
    return (
      <Layout>
        <div className="flex flex-col gap-4">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-64 w-full" />
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="flex flex-col gap-4">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate("/transactions/monthly-salary-entry")}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">
              {isEdit ? "Edit Salary Entry" : "New Salary Entry"}
            </h1>
            {isPosted && (
              <p className="text-amber-600 font-medium text-sm mt-0.5">
                Posted — read only. Un-post to make changes.
              </p>
            )}
          </div>
        </div>

        {/* Header card */}
        <Card>
          <CardHeader><CardTitle>Entry Header</CardTitle></CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-4 items-end">
              <div className="flex flex-col gap-1">
                <Label>Month</Label>
                <Select value={month} onValueChange={handleMonthChange} disabled={isPosted}>
                  <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {MONTHS.map((name, i) => (
                      <SelectItem key={i + 1} value={String(i + 1)}>{name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex flex-col gap-1">
                <Label>Year</Label>
                <Select value={year} onValueChange={handleYearChange} disabled={isPosted}>
                  <SelectTrigger className="w-28"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {YEARS.map((y) => (
                      <SelectItem key={y} value={String(y)}>{y}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex flex-col gap-1">
                <Label>Department(s)</Label>
                <Popover open={deptPopoverOpen} onOpenChange={setDeptPopoverOpen}>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline" role="combobox" disabled={isPosted}
                      className="w-64 justify-between font-normal"
                    >
                      {selectedDeptIds.length === 0
                        ? "Select departments…"
                        : `${selectedDeptIds.length} department${selectedDeptIds.length > 1 ? "s" : ""} selected`}
                      <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-64 p-2">
                    {departments.map((d) => (
                      <button
                        key={d.id}
                        onClick={() => toggleDept(d.id)}
                        className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-sm hover:bg-muted"
                      >
                        <Check
                          className={cn(
                            "h-4 w-4",
                            selectedDeptIds.includes(d.id) ? "opacity-100" : "opacity-0"
                          )}
                        />
                        {d.name}
                      </button>
                    ))}
                  </PopoverContent>
                </Popover>
              </div>

              <p className="text-xs text-muted-foreground self-end pb-1">
                Days in month: <span className="font-semibold">{totalDays}</span>
              </p>
            </div>

            {selectedDeptIds.length > 0 && (
              <div className="flex flex-wrap gap-1 mt-3">
                {selectedDeptIds.map((id) => {
                  const d = departments.find((dep) => dep.id === id);
                  return d ? <Badge key={id} variant="secondary">{d.name}</Badge> : null;
                })}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Employee detail grid */}
        {rows.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Employee Detail</CardTitle>
              <p className="text-xs text-muted-foreground">
                Auto-formula: Total Salary = (Basic ÷ {totalDays}) × Attendance &nbsp;|&nbsp;
                OT Amount = OT Hours × OT Rate &nbsp;|&nbsp;
                Payable = (Total Salary + OT) − Deductions.
                <span className="ml-1 italic">
                  Total Salary, OT Amount, and deduction fields are directly editable to override.
                </span>
              </p>
            </CardHeader>
            <CardContent className="p-0 overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="text-xs">
                    <TableHead className="min-w-[140px]">Employee</TableHead>
                    <TableHead className="text-right min-w-[90px]">Basic Salary</TableHead>
                    <TableHead className="text-right min-w-[80px]">OT Rate/Hr</TableHead>
                    <TableHead className="text-right min-w-[80px]">Att. Allow.</TableHead>
                    <TableHead className="text-right min-w-[80px]">Oth. Allow.</TableHead>
                    <TableHead className="text-right min-w-[75px]">Present</TableHead>
                    <TableHead className="text-right min-w-[75px]">Absent</TableHead>
                    <TableHead className="text-right min-w-[70px]">Holidays</TableHead>
                    <TableHead className="text-right min-w-[80px]">Total Att.</TableHead>
                    <TableHead className="text-right min-w-[100px]">Total Salary ✎</TableHead>
                    <TableHead className="text-right min-w-[70px]">OT Hrs</TableHead>
                    <TableHead className="text-right min-w-[90px]">OT Amount ✎</TableHead>
                    <TableHead className="text-right min-w-[90px]">Adv. Deduction</TableHead>
                    <TableHead className="text-right min-w-[90px]">Loan Deduction</TableHead>
                    <TableHead className="text-right min-w-[90px]">Other Deduction</TableHead>
                    <TableHead className="text-right min-w-[110px] font-bold">Payable Salary</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rows.map((row, i) => {
                    const inp = "h-7 text-right font-mono text-xs p-1 w-full";
                    const ro = "h-7 text-right font-mono text-xs p-1 w-full bg-muted/40 cursor-not-allowed";
                    return (
                      <TableRow key={row.operatorId} className={i % 2 === 0 ? "bg-muted/10" : ""}>
                        <TableCell className="font-medium text-sm py-1">{row.operatorName}</TableCell>
                        {/* Master snapshot — display only */}
                        <TableCell className="py-1"><Input disabled className={ro} value={row.basicSalary} /></TableCell>
                        <TableCell className="py-1"><Input disabled className={ro} value={row.otRateHr} /></TableCell>
                        <TableCell className="py-1"><Input disabled className={ro} value={row.attAllowance} /></TableCell>
                        <TableCell className="py-1"><Input disabled className={ro} value={row.othAllowance} /></TableCell>
                        {/* Attendance inputs — trigger salary formula */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.5" className={inp}
                            value={row.presentDays} disabled={isPosted}
                            onChange={(e) => updateRow(i, "presentDays", e.target.value)} />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.5" className={inp}
                            value={row.absentDays} disabled={isPosted}
                            onChange={(e) => updateRow(i, "absentDays", e.target.value)} />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.5" className={inp}
                            value={row.holidays} disabled={isPosted}
                            onChange={(e) => updateRow(i, "holidays", e.target.value)} />
                        </TableCell>
                        {/* totalAttendance — triggers totalSalary recalculation */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.5" className={inp}
                            value={row.totalAttendance} disabled={isPosted}
                            onChange={(e) => updateRow(i, "totalAttendance", e.target.value)} />
                        </TableCell>
                        {/* totalSalary — auto-computed but directly editable */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.01" className={`${inp} bg-amber-50`}
                            value={row.totalSalary} disabled={isPosted}
                            onChange={(e) => updateRow(i, "totalSalary", e.target.value)} />
                        </TableCell>
                        {/* otHours — triggers otAmount recalculation */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.5" className={inp}
                            value={row.otHours} disabled={isPosted}
                            onChange={(e) => updateRow(i, "otHours", e.target.value)} />
                        </TableCell>
                        {/* otAmount — auto-computed but directly editable */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.01" className={`${inp} bg-amber-50`}
                            value={row.otAmount} disabled={isPosted}
                            onChange={(e) => updateRow(i, "otAmount", e.target.value)} />
                        </TableCell>
                        {/* Deductions */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.01" className={inp}
                            value={row.advanceDeduction} disabled={isPosted}
                            onChange={(e) => updateRow(i, "advanceDeduction", e.target.value)} />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.01" className={inp}
                            value={row.loanDeduction} disabled={isPosted}
                            onChange={(e) => updateRow(i, "loanDeduction", e.target.value)} />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input type="number" min="0" step="0.01" className={inp}
                            value={row.otherDeduction} disabled={isPosted}
                            onChange={(e) => updateRow(i, "otherDeduction", e.target.value)} />
                        </TableCell>
                        {/* Payable — live computed, read-only display */}
                        <TableCell
                          className={`py-1 pr-2 text-right font-mono text-sm font-semibold ${
                            toNum(row.payableSalary) < 0 ? "text-red-600" : "text-green-700"
                          }`}
                        >
                          {toNum(row.payableSalary).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        )}

        {selectedDeptIds.length > 0 && rows.length === 0 && !isEdit && (
          <p className="text-muted-foreground text-sm text-center py-6">
            No active employees found for the selected department(s).
          </p>
        )}

        <div className="flex gap-3 justify-end pb-4">
          <Button variant="outline" onClick={() => navigate("/transactions/monthly-salary-entry")}>
            Cancel
          </Button>
          {!isPosted && (
            <Button onClick={handleSave} disabled={saveMutation.isPending} className="gap-2">
              <Save className="h-4 w-4" />
              {saveMutation.isPending ? "Saving…" : "Save Entry"}
            </Button>
          )}
        </div>
      </div>
    </Layout>
  );
}
