import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Trash2 } from "lucide-react";
import { Layout } from "@/components/layout";
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

function todayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

interface EmployeeLookup {
  id: number;
  name: string;
  code: string;
  active: boolean;
}

interface Advance {
  id: number;
  employeeId: number;
  employeeName: string;
  date: string;
  amount: string;
  notes: string | null;
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

export default function AdvancesPage() {
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

  const { sorted: sortedAdvances, sort: advSort, toggleSort: toggleAdvSort } = useSort(advances, {
    date: (a: Advance) => a.date,
    employeeName: (a: Advance) => a.employeeName,
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
    <Layout>
      <div className="flex flex-col gap-6">
        <header className="border-b pb-5">
          <p className="eyebrow">Payroll</p>
          <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">Advances</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Employee salary advances — record a new advance or review the history.
          </p>
        </header>

        <div className="space-y-6">
          <Card>
            <CardHeader><CardTitle>Add Advance</CardTitle></CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-4 items-end">
                <div className="flex flex-col gap-1">
                  <Label>Employee</Label>
                  <Select value={form.employeeId} onValueChange={(v) => setForm((p) => ({ ...p, employeeId: v }))}>
                    <SelectTrigger className="h-11 w-full sm:h-9 sm:w-48">
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
                  <DateInput className="h-11 w-full sm:h-9 sm:w-40" value={form.date} onChange={(e) => setForm((p) => ({ ...p, date: e.target.value }))} />
                </div>
                <div className="flex flex-col gap-1">
                  <Label>Amount</Label>
                  <Input type="number" min="0" step="0.01" inputMode="decimal" className="h-11 w-full sm:h-9 sm:w-32" placeholder="0.00"
                    value={form.amount} onChange={(e) => setForm((p) => ({ ...p, amount: e.target.value }))} />
                </div>
                <div className="flex flex-col gap-1 flex-1 min-w-40">
                  <Label>Notes (optional)</Label>
                  <Input className="h-11 sm:h-9" placeholder="e.g. Festival advance" value={form.notes}
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
                  <SelectTrigger className="h-11 w-full sm:h-9 sm:w-48">
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
                  <DateInput className="h-11 w-36 sm:h-8" value={filterFrom} onChange={(e) => setFilterFrom(e.target.value)} />
                </div>
                <div className="flex items-center gap-2">
                  <Label className="text-xs">To</Label>
                  <DateInput className="h-11 w-36 sm:h-8" value={filterTo} onChange={(e) => setFilterTo(e.target.value)} />
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <SortableHead label="Date" sortKey="date" sort={advSort} onSort={toggleAdvSort} />
                    <SortableHead label="Employee" sortKey="employeeName" sort={advSort} onSort={toggleAdvSort} />
                    <SortableHead label="Amount" sortKey="amount" sort={advSort} onSort={toggleAdvSort} right />
                    <SortableHead label="Notes" sortKey="notes" sort={advSort} onSort={toggleAdvSort} />
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
      </div>
    </Layout>
  );
}
