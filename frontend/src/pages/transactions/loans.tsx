import { useState, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { DateInput } from "@/components/ui/date-input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
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
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

function toNum(v: string | number | null | undefined): number {
  const n = parseFloat(String(v ?? ""));
  return isNaN(n) ? 0 : n;
}

function fmtMoney(n: number) {
  return n.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDate(dateStr: string) {
  const d = new Date(dateStr + "T00:00:00");
  const day = String(d.getDate()).padStart(2, "0");
  const mon = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][d.getMonth()];
  return `${day}/${mon}/${d.getFullYear()}`;
}

function todayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function firstDayOfThisMonth() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-01`;
}

function currentMonthKey() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

interface EmployeeLookup {
  id: number;
  name: string;
  code: string;
  active: boolean;
}

interface LoanRow {
  id: number;
  employeeId: number;
  employeeName: string;
  date: string;
  amount: string;
  notes: string | null;
}

interface LoanSummaryEmployee {
  employeeId: number;
  employeeName: string;
  employeeCode: string | null;
  totalLoaned: number;
  totalRecovered: number;
  remaining: number;
}

interface LoanSummary {
  employees: LoanSummaryEmployee[];
  totals: { loaned: number; recovered: number; outstanding: number };
}

interface LedgerEntry {
  id: string;
  type: "loan" | "deduction";
  date: string;
  amount: number;
  notes: string | null;
  period: string | null;
  balance: number;
}

interface Ledger {
  employeeId: number;
  employeeName: string;
  employeeCode: string | null;
  totalLoaned: number;
  totalRecovered: number;
  remaining: number;
  entries: LedgerEntry[];
}

async function apiFetch<T = unknown>(path: string, opts?: RequestInit): Promise<T> {
  return customFetch<T>(path, opts ?? { method: "GET" });
}

function KpiStrip({ summary, isLoading }: { summary?: LoanSummary; isLoading: boolean }) {
  const kpis = [
    { label: "Total Loaned", value: summary?.totals.loaned ?? 0 },
    { label: "Total Recovered", value: summary?.totals.recovered ?? 0 },
    { label: "Total Outstanding", value: summary?.totals.outstanding ?? 0 },
  ];
  return (
    <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
      {kpis.map((k) => (
        <div key={k.label} className="rounded-md border border-border px-3 py-2">
          <p className="text-xs text-muted-foreground">{k.label}</p>
          {isLoading
            ? <Skeleton className="mt-1 h-6 w-24" />
            : <p className="mt-1 text-lg font-semibold tabular-nums">{fmtMoney(k.value)}</p>}
        </div>
      ))}
    </div>
  );
}

export default function LoansPage() {
  const { toast } = useToast();
  const qc = useQueryClient();

  const [form, setForm] = useState({ employeeId: "", date: todayStr(), amount: "", notes: "" });
  const [formError, setFormError] = useState<string | null>(null);
  const [filterOp, setFilterOp] = useState("__all__");

  const { data: employees = [] } = useQuery<EmployeeLookup[]>({
    queryKey: ["employee-lookup"],
    queryFn: () => apiFetch("/api/lookups/employee-master"),
  });

  const { data: summary, isLoading: summaryLoading } = useQuery<LoanSummary>({
    queryKey: ["employee-loans-summary"],
    queryFn: () => apiFetch("/api/employees/loans/summary"),
  });

  const loanParams = new URLSearchParams();
  if (filterOp !== "__all__") loanParams.set("employeeId", filterOp);
  const qs = loanParams.toString();

  const { data: loans = [], isLoading } = useQuery<LoanRow[]>({
    queryKey: ["employee-loans", filterOp],
    queryFn: () => apiFetch(`/api/employees/loans${qs ? `?${qs}` : ""}`),
  });

  // The all-time running ledger only makes sense for one employee at a time.
  const selectedEmployeeId = filterOp !== "__all__" ? filterOp : null;
  const { data: ledger, isLoading: ledgerLoading } = useQuery<Ledger>({
    queryKey: ["employee-loan-ledger", selectedEmployeeId],
    queryFn: () => apiFetch(`/api/employees/loans/ledger?employeeId=${selectedEmployeeId}`),
    enabled: selectedEmployeeId != null,
  });

  const invalidateAll = () => {
    qc.invalidateQueries({ queryKey: ["employee-loans"] });
    qc.invalidateQueries({ queryKey: ["employee-loans-summary"] });
    qc.invalidateQueries({ queryKey: ["employee-loan-ledger"] });
  };

  const addMutation = useMutation({
    mutationFn: (data: object) =>
      apiFetch("/api/employees/loans", { method: "POST", body: JSON.stringify(data) }),
    onSuccess: () => {
      invalidateAll();
      // Chained entry: keep the employee + date, clear amount/notes, refocus.
      setForm((p) => ({ ...p, amount: "", notes: "" }));
      toast({ title: "Loan recorded." });
      amountRef.current?.focus();
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiFetch(`/api/employees/loans/${id}`, { method: "DELETE" }),
    onSuccess: () => {
      invalidateAll();
      toast({ title: "Loan deleted." });
    },
    onError: (e: Error) => toast({ variant: "destructive", title: "Could not delete", description: e.message }),
  });

  const amountRef = useRef<HTMLInputElement>(null);
  const deletableMonth = currentMonthKey();

  function handleAdd() {
    if (!form.employeeId || !form.date || form.amount === "") {
      setFormError("Employee, date, and amount are required.");
      return;
    }
    const amt = parseFloat(form.amount);
    if (isNaN(amt) || amt <= 0) {
      setFormError("Amount must be greater than zero.");
      return;
    }
    setFormError(null);
    addMutation.mutate({
      employeeId: parseInt(form.employeeId),
      date: form.date,
      amount: amt,
      notes: form.notes || null,
    });
  }

  const canDelete = (date: string) => date.slice(0, 7) === deletableMonth;

  return (
    <div className="flex flex-col gap-6">
      <header className="border-b pb-5">
        <p className="eyebrow">Payroll</p>
        <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">Loans</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Employee loans — record an amount given, and track every recovery deducted through payroll.
        </p>
      </header>

      <KpiStrip summary={summary} isLoading={summaryLoading} />

      <Card>
        <CardHeader><CardTitle>Add Loan</CardTitle></CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 items-end gap-4 sm:flex sm:flex-wrap">
            <div className="col-span-2 flex flex-col gap-1 sm:col-auto sm:w-48">
              <Label>Employee</Label>
              <Select value={form.employeeId} onValueChange={(v) => { setFormError(null); setForm((p) => ({ ...p, employeeId: v })); }}>
                <SelectTrigger className="h-11 w-full sm:h-9">
                  <SelectValue placeholder="Select employee" />
                </SelectTrigger>
                <SelectContent>
                  {employees.filter((op) => op.active).map((op) => (
                    <SelectItem key={op.id} value={String(op.id)}>{op.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex flex-col gap-1 sm:w-40">
              <Label>Date</Label>
              <DateInput
                className="h-11 w-full sm:h-9"
                value={form.date}
                // Loans are recorded for the current month only (mirrors Advances).
                min={firstDayOfThisMonth()}
                max={todayStr()}
                onChange={(e) => { setFormError(null); setForm((p) => ({ ...p, date: e.target.value })); }}
              />
            </div>
            <div className="flex flex-col gap-1 sm:w-32">
              <Label>Amount</Label>
              <Input
                ref={amountRef}
                type="number"
                min="0"
                step="0.01"
                inputMode="decimal"
                className="h-11 w-full sm:h-9"
                placeholder="0.00"
                value={form.amount}
                onChange={(e) => { setFormError(null); setForm((p) => ({ ...p, amount: e.target.value })); }}
                onKeyDown={(e) => {
                  if (e.key === "Enter") { e.preventDefault(); handleAdd(); }
                }}
              />
            </div>
            <div className="col-span-2 flex flex-col gap-1 sm:col-auto sm:min-w-40 sm:flex-1">
              <Label>Notes (optional)</Label>
              <Input className="h-11 w-full sm:h-9" placeholder="e.g. Festival loan" value={form.notes}
                onChange={(e) => { setFormError(null); setForm((p) => ({ ...p, notes: e.target.value })); }} />
            </div>
            <Button onClick={handleAdd} disabled={addMutation.isPending} className="col-span-2 sm:col-auto">
              {addMutation.isPending ? "Adding…" : "Add Loan"}
            </Button>
          </div>
          {formError && (
            <p role="alert" className="mt-3 text-sm font-medium text-destructive">{formError}</p>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Loan History</CardTitle>
          <div className="mt-2 flex flex-col gap-1 sm:w-72">
            <Label className="text-xs">Employee</Label>
            <Select value={filterOp} onValueChange={setFilterOp}>
              <SelectTrigger className="h-11 w-full sm:h-8">
                <SelectValue placeholder="All employees" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Employees</SelectItem>
                {employees.map((op) => (
                  <SelectItem key={op.id} value={String(op.id)}>{op.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {selectedEmployeeId == null ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Employee</TableHead>
                  <TableHead className="text-right">Loan Amount</TableHead>
                  <TableHead className="hidden sm:table-cell">Notes</TableHead>
                  <TableHead className="sticky right-0 w-16 bg-background"></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading && Array.from({ length: 4 }).map((_, i) => (
                  <TableRow key={i}>
                    {[1,2,3,4,5].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                  </TableRow>
                ))}
                {!isLoading && loans.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="py-8 text-center text-muted-foreground">
                      No loans recorded yet. Add one above, or pick an employee to see their ledger.
                    </TableCell>
                  </TableRow>
                )}
                {!isLoading && loans.map((a) => {
                  const deletable = canDelete(a.date);
                  return (
                    <TableRow key={a.id}>
                      <TableCell className="font-mono text-sm">{formatDate(a.date)}</TableCell>
                      <TableCell>{a.employeeName}</TableCell>
                      <TableCell className="text-right font-mono">{fmtMoney(toNum(a.amount))}</TableCell>
                      <TableCell className="hidden text-sm text-muted-foreground sm:table-cell">{a.notes || "—"}</TableCell>
                      <TableCell className="sticky right-0 bg-background">
                        <DeleteLoanButton
                          loan={a}
                          deletable={deletable}
                          onDelete={() => deleteMutation.mutate(a.id)}
                        />
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          ) : (
            <div className="space-y-4 p-4">
              <div className="flex flex-wrap items-center gap-x-6 gap-y-2 rounded-md border border-border bg-muted/30 px-3 py-2 text-sm">
                <span className="font-medium">{ledger?.employeeName ?? "…"}</span>
                <span className="text-muted-foreground">Loaned <span className="font-semibold text-foreground tabular-nums">{fmtMoney(ledger?.totalLoaned ?? 0)}</span></span>
                <span className="text-muted-foreground">Recovered <span className="font-semibold text-foreground tabular-nums">{fmtMoney(ledger?.totalRecovered ?? 0)}</span></span>
                <span className="text-muted-foreground">Remaining <span className="font-semibold text-foreground tabular-nums">{fmtMoney(ledger?.remaining ?? 0)}</span></span>
              </div>
              <div className="overflow-x-auto rounded-md border border-border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Date</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead className="hidden sm:table-cell">Reference</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                      <TableHead className="text-right">Balance</TableHead>
                      <TableHead className="sticky right-0 w-16 bg-background"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {ledgerLoading && Array.from({ length: 3 }).map((_, i) => (
                      <TableRow key={i}>
                        {[1,2,3,4,5,6].map((c) => <TableCell key={c}><Skeleton className="h-5 w-full" /></TableCell>)}
                      </TableRow>
                    ))}
                    {!ledgerLoading && ledger && ledger.entries.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={6} className="py-8 text-center text-muted-foreground">
                          No loans or deductions for {ledger.employeeName} yet.
                        </TableCell>
                      </TableRow>
                    )}
                    {!ledgerLoading && ledger && ledger.entries.map((e) => {
                      const deletable = e.type === "loan" && canDelete(e.date);
                      return (
                        <TableRow key={e.id}>
                          <TableCell className="font-mono text-sm">{formatDate(e.date)}</TableCell>
                          <TableCell>
                            <span className={e.type === "loan"
                              ? "inline-flex items-center rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-300"
                              : "inline-flex items-center rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300"}>
                              {e.type === "loan" ? "Loan" : "Payroll deduction"}
                            </span>
                          </TableCell>
                          <TableCell className="hidden text-sm text-muted-foreground sm:table-cell">
                            {e.type === "loan" ? (e.notes || "—") : (e.period ? `Payroll ${e.period}` : "—")}
                          </TableCell>
                          <TableCell className="text-right font-mono">
                            {e.type === "loan" ? fmtMoney(e.amount) : `−${fmtMoney(e.amount)}`}
                          </TableCell>
                          <TableCell className="text-right font-mono tabular-nums">{fmtMoney(e.balance)}</TableCell>
                          <TableCell className="sticky right-0 bg-background">
                            {e.type === "loan" ? (
                              <DeleteLoanButton
                                loan={{ id: Number(e.id.replace("loan-", "")), date: e.date, amount: String(e.amount), employeeName: ledger.employeeName, employeeId: ledger.employeeId, notes: e.notes }}
                                deletable={deletable}
                                onDelete={() => deleteMutation.mutate(Number(e.id.replace("loan-", "")))}
                              />
                            ) : null}
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </div>
              <p className="text-xs text-muted-foreground">
                Deductions are committed when the month's salary entry is Posted and reversed if it is Un-posted.
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function DeleteLoanButton({
  loan,
  deletable,
  onDelete,
}: {
  loan: LoanRow;
  deletable: boolean;
  onDelete: () => void;
}) {
  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>
        <Button
          size="icon"
          variant="ghost"
          disabled={!deletable}
          className="h-11 w-11 text-destructive disabled:opacity-30 sm:h-8 sm:w-8"
          aria-label={deletable
            ? `Delete ${fmtMoney(toNum(loan.amount))} loan for ${loan.employeeName}`
            : "Loans from previous months can't be deleted"}
          title={deletable ? undefined : "Loans from previous months can't be deleted"}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete Loan</AlertDialogTitle>
          <AlertDialogDescription>
            Delete {fmtMoney(toNum(loan.amount))} loan for {loan.employeeName} on {formatDate(loan.date)}? This cannot be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={onDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
            Delete
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
