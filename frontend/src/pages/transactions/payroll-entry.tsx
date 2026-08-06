import { NUM_DECIMALS } from "@/lib/format";
import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { useParams, useLocation } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { ArrowLeft, Save, Check, ChevronsUpDown, Eye } from "lucide-react";
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
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
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
const CURRENT_MONTH = new Date().getMonth() + 1; // 1-12
// Years offered in the dropdown: a few past years up to the current year
// (future years are excluded).
const SELECTABLE_YEARS = Array.from({ length: 4 }, (_, i) => CURRENT_YEAR - 3 + i);
// Input step increments for the salary-entry grid.
const STEP_ATTENDANCE = "1";   // Present, Absent, Holidays, Total Att., OT Hours
const STEP_MONEY = "0.01";     // salary, OT amount, and deduction fields
// Maximum allowed holidays per employee per month.
const MAX_HOLIDAYS = "5";
// Total Attendance is a whole number (0 decimals).
const TOTAL_ATTENDANCE_DECIMALS = 0;

function toNum(v: unknown): number {
  const n = parseFloat(String(v ?? ""));
  return isNaN(n) ? 0 : n;
}

function clampNum(v: number, min: number, max: number): number {
  return Math.min(Math.max(v, min), max);
}

function roundToWhole(v: number): number {
  return Math.round(v);
}

// Indian-locale money formatting (2 decimals).
function fmtMoney(v: number): string {
  return v.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// YYYY-MM-DD -> DD Mon YYYY (e.g. 2026-08-01 -> 01 Aug 2026).
function formatDate(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00");
  if (isNaN(d.getTime())) return dateStr;
  const day = String(d.getDate()).padStart(2, "0");
  const mon = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][d.getMonth()];
  return `${day} ${mon} ${d.getFullYear()}`;
}

function daysInMonthFn(month: number, year: number): number {
  return new Date(year, month, 0).getDate();
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
interface Advance {
  id: number;
  employeeId: number;
  amount: string;
}
interface OperatorMachine {
  machineId: number;
  machineName: string;
  netWt: number;
  rate: number;
  amount: number;
}
interface OperatorDay {
  date: string;
  dailyProductionSum: number;
  dailyBasic: number;
  credited: number;
  machines?: OperatorMachine[];
}
interface OperatorProduction {
  employeeId: number;
  employeeName: string;
  presentDays: number;
  totalSalary: number;
  days: OperatorDay[];
}
interface Employee {
  id: number; name: string; code: string; active: boolean;
  departmentId: number | null;
  baseSalary: string | null;
  overtimeRateHr: string | null;
  attAllowance: string | null;
  othAllowance: string | null;
}

interface DetailRow {
  employeeId: number;
  departmentId: number | null;
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
  // Operator rows (dept 0002) are paid on production: Present + Total Salary
  // come from transactions and are read-only.
  isOperator?: boolean;
  // Per-day production breakdown for the operator salary popup.
  operatorDays?: OperatorDay[];
  // Operator salary baseline (production-derived total) and the transaction
  // present-day floor; used to compute the present-day adjustment.
  operatorBaseTotal?: number;
  operatorTransactionPresent?: number;
  operatorDailyBasic?: number;
}

// Fields that, when changed, trigger auto-recalculation of totalSalary
const SALARY_SOURCE_FIELDS = new Set<keyof DetailRow>([
  "basicSalary",
  "presentDays",
  "absentDays",
  "holidays",
]);
// Fields that, when changed, trigger auto-recalculation of otAmount
const OT_SOURCE_FIELDS = new Set<keyof DetailRow>(["otHours", "otRateHr"]);

function recomputePayable(row: DetailRow, totalDays: number): DetailRow {
  // Total Salary already includes OT (see recomputeAll), so payable is
  // total salary, plus a 100%-attendance bonus (Att. Allowance) when the
  // employee worked the full month, minus the deductions. For operators each
  // holiday day adds one daily basic to payable (increase adds, decrease
  // deducts relative to the entered count).
  const fullAttendance = totalDays > 0 && toNum(row.presentDays) >= totalDays;
  const attAllowance = fullAttendance ? toNum(row.attAllowance) : 0;
  const holidaysBonus = row.isOperator ? toNum(row.holidays) * toNum(row.operatorDailyBasic) : 0;
  const payable =
    toNum(row.totalSalary) +
    attAllowance +
    holidaysBonus -
    toNum(row.advanceDeduction) -
    toNum(row.loanDeduction) -
    toNum(row.otherDeduction);
  return { ...row, payableSalary: payable.toFixed(NUM_DECIMALS) };
}

// Present + Absent must not exceed the actual number of days in the month.
// Returns true when the row violates the rule.
function attendanceExceedsMonth(row: DetailRow, totalDays: number): boolean {
  return toNum(row.presentDays) + toNum(row.absentDays) > totalDays;
}

function recomputeAll(row: DetailRow, totalDays: number): DetailRow {
  // Total Attendance = Present + Holidays (derived, not hand-entered), kept
  // as a whole number to match the other attendance fields.
  const totalAttendance = roundToWhole(toNum(row.presentDays) + toNum(row.holidays));
  // OT Amount = OT Hrs × the employee's OT rate (from the master table). If no
  // OT rate is set for the employee (rate ≤ 0), OT Amount is zero.
  const otRate = toNum(row.otRateHr);
  const otAmount = otRate > 0 ? toNum(row.otHours) * otRate : 0;
  // Total Salary = prorated basic for attendance PLUS the OT amount.
  const baseSalary =
    totalDays > 0 ? (toNum(row.basicSalary) / totalDays) * totalAttendance : 0;
  const totalSalary = baseSalary + otAmount;
  return recomputePayable(
    {
      ...row,
      totalAttendance: totalAttendance.toFixed(TOTAL_ATTENDANCE_DECIMALS),
      totalSalary: totalSalary.toFixed(NUM_DECIMALS),
      otAmount: otAmount.toFixed(NUM_DECIMALS),
    },
    totalDays
  );
}

// Operator (dept 0002) recompute: Total Salary is the production-derived
// baseline plus a present-day adjustment (each present day above the
// transaction-present floor adds one daily basic). OT, allowances, and
// deductions behave as usual.
function recomputeOperatorAll(row: DetailRow, totalDays: number): DetailRow {
  const totalAttendance = roundToWhole(toNum(row.presentDays) + toNum(row.holidays));
  const otRate = toNum(row.otRateHr);
  const otAmount = otRate > 0 ? toNum(row.otHours) * otRate : 0;
  // Present-day adjustment relative to the transaction-present floor.
  const base = toNum(row.operatorBaseTotal);
  const floor = toNum(row.operatorTransactionPresent);
  const dailyBasic = toNum(row.operatorDailyBasic);
  const present = Math.max(toNum(row.presentDays), floor); // never below the floor
  const totalSalary = base + (present - floor) * dailyBasic + otAmount;
  // Absent is derived for operators: days in the month minus present.
  const absentDays = Math.max(totalDays - present, 0);
  return recomputePayable(
    {
      ...row,
      presentDays: String(present),
      absentDays: String(absentDays),
      totalAttendance: totalAttendance.toFixed(TOTAL_ATTENDANCE_DECIMALS),
      totalSalary: totalSalary.toFixed(NUM_DECIMALS),
      otAmount: otAmount.toFixed(NUM_DECIMALS),
    },
    totalDays
  );
}

function rowFromEmployee(op: Employee, totalDays: number, advanceSum = 0, defaultPresent?: number): DetailRow {
  const base: DetailRow = {
    employeeId: op.id,
    departmentId: op.departmentId,
    employeeName: op.name,
    basicSalary: toNum(op.baseSalary).toFixed(NUM_DECIMALS),
    otRateHr: toNum(op.overtimeRateHr).toFixed(NUM_DECIMALS),
    attAllowance: toNum(op.attAllowance).toFixed(NUM_DECIMALS),
    othAllowance: toNum(op.othAllowance).toFixed(NUM_DECIMALS),
    presentDays: String(defaultPresent ?? totalDays),
    absentDays: "0",
    holidays: "0",
    totalAttendance: "0",
    totalSalary: "0.00",
    otHours: "0",
    otAmount: "0.00",
    advanceDeduction: advanceSum.toFixed(NUM_DECIMALS),
    loanDeduction: "0.00",
    otherDeduction: "0.00",
    payableSalary: "0.00",
  };
  return recomputeAll(base, totalDays);
}

// Builds a row for an Operator (dept 0002) employee whose salary is derived
// from production: Present days and Total Salary come from the transactions
// (read-only), while Absent / Holidays / OT / Deductions stay user-entered.
function rowFromOperator(op: Employee, totalDays: number, prod: OperatorProduction, advanceSum = 0): DetailRow {
  const dailyBasic = toNum(op.baseSalary);
  const transactionPresent = prod.presentDays;
  // Base total = production-derived salary. Present-day adjustment adds one
  // daily basic for each present day above the transaction-present floor.
  const baseTotal = prod.totalSalary;
  const base: DetailRow = {
    employeeId: op.id,
    departmentId: op.departmentId,
    employeeName: op.name,
    basicSalary: dailyBasic.toFixed(NUM_DECIMALS),
    otRateHr: toNum(op.overtimeRateHr).toFixed(NUM_DECIMALS),
    attAllowance: toNum(op.attAllowance).toFixed(NUM_DECIMALS),
    othAllowance: toNum(op.othAllowance).toFixed(NUM_DECIMALS),
    presentDays: String(transactionPresent),
    absentDays: "0",
    holidays: "0",
    totalAttendance: "0",
    totalSalary: baseTotal.toFixed(NUM_DECIMALS),
    otHours: "0",
    otAmount: "0.00",
    advanceDeduction: advanceSum.toFixed(NUM_DECIMALS),
    loanDeduction: "0.00",
    otherDeduction: "0.00",
    payableSalary: "0.00",
    isOperator: true,
    operatorDays: prod.days,
    operatorBaseTotal: baseTotal,
    operatorTransactionPresent: transactionPresent,
    operatorDailyBasic: dailyBasic,
  };
  // Apply the present-day adjustment (default present = floor → no change).
  return recomputeOperatorAll(base, totalDays);
}

// ─────────────────────────────────────────────────────────────────────────────

export default function PayrollEntryPage() {
  const params = useParams<{ id?: string }>();
  const headerId = params.id ? parseInt(params.id) : NaN;
  const isEdit = !isNaN(headerId);
  const [, navigate] = useLocation();
  const { toast } = useToast();

  const [month, setMonth] = useState(String(CURRENT_MONTH));
  const [year, setYear] = useState(String(CURRENT_YEAR));
  const [selectedDeptIds, setSelectedDeptIds] = useState<number[]>([]);
  const [rows, setRows] = useState<DetailRow[]>([]);
  const [initialized, setInitialized] = useState(false);
  const [deptPopoverOpen, setDeptPopoverOpen] = useState(false);
  // Operator row whose salary detail popup is open (employeeId), or null.
  const [operatorDetail, setOperatorDetail] = useState<number | null>(null);

  const totalDays = daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR);

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ["dept-lookup"],
    queryFn: () => apiFetch("/api/lookups/department-master"),
  });

  // The Operator department (code 0002) uses production-based salary.
  const operatorDeptId = useMemo(
    () => departments.find((d) => d.code === "0002")?.id ?? null,
    [departments]
  );

  const { data: allEmployees = [] } = useQuery<Employee[]>({
    queryKey: ["employee-full-lookup"],
    queryFn: () => apiFetch("/api/lookups/employee-master"),
  });

  // Sum of each employee's advances for the selected month/year, keyed by
  // employeeId. Used to auto-fill the Advance Deduction column.
  const advanceParams = new URLSearchParams({ month, year });
  const { data: advances = [] } = useQuery<Advance[]>({
    queryKey: ["salary-entry-advances", month, year],
    queryFn: () => apiFetch(`/api/employees/advances?${advanceParams.toString()}`),
    enabled: !isEdit || initialized,
  });
  const advanceByEmployee = useMemo(() => {
    const map = new Map<number, number>();
    for (const a of advances) {
      map.set(a.employeeId, toNum(map.get(a.employeeId)) + toNum(a.amount));
    }
    return map;
  }, [advances]);
  const rowAdvanceSum = useCallback(
    (employeeId: number) => advanceByEmployee.get(employeeId) ?? 0,
    [advanceByEmployee]
  );

  // Operator (dept 0002) production-based salary for the selected month.
  const opParams = new URLSearchParams({ month, year });
  const { data: operatorProductions = [] } = useQuery<OperatorProduction[]>({
    queryKey: ["salary-entry-operator-production", month, year],
    queryFn: () => apiFetch(`/api/salary-entries/operator-production?${opParams.toString()}`),
    enabled: !isEdit || initialized,
  });
  const operatorByEmployee = useMemo(() => {
    if (operatorDeptId === null || operatorProductions.length === 0) return new Map<number, OperatorProduction>();
    return new Map(operatorProductions.map((p) => [p.employeeId, p]));
  }, [operatorDeptId, operatorProductions]);

  const { data: existingEntry, isLoading: loadingEntry } = useQuery<{
    id: number; month: number; year: number; departmentIds: number[]; posted: boolean;
    details: DetailRow[];
  }>({
    queryKey: ["salary-entry", headerId],
    queryFn: () => apiFetch(`/api/salary-entries/${headerId}`),
    enabled: isEdit,
  });

  // In new mode, select all departments by default once they load.
  const defaultedDepts = useRef(false);
  useEffect(() => {
    if (isEdit || departments.length === 0 || defaultedDepts.current) return;
    defaultedDepts.current = true;
    setSelectedDeptIds(departments.map((d) => d.id));
  }, [isEdit, departments]);

  // Populate form once when loading an existing entry
  useEffect(() => {
    if (!isEdit || !existingEntry || initialized) return;
    setMonth(String(existingEntry.month));
    setYear(String(existingEntry.year));
    setSelectedDeptIds(existingEntry.departmentIds ?? []);
    setRows(existingEntry.details.map((d) => {
      const isOperator = operatorDeptId !== null && d.departmentId === operatorDeptId;
      return {
        ...d,
        // Operator present/total come from transactions (read-only).
        ...(isOperator ? { isOperator: true } : {}),
        presentDays: String(roundToWhole(toNum(d.presentDays))),
        absentDays: String(roundToWhole(toNum(d.absentDays))),
        holidays: String(roundToWhole(toNum(d.holidays))),
        totalAttendance: String(roundToWhole(toNum(d.totalAttendance))),
        otHours: String(roundToWhole(toNum(d.otHours))),
      };
    }));
    setInitialized(true);
  }, [isEdit, existingEntry, initialized, operatorDeptId]);

  // In edit mode, once the period's advance totals have loaded, sync the
  // Advance Deduction column to the sum of each employee's advances.
  useEffect(() => {
    if (!isEdit || !initialized || advanceByEmployee.size === 0) return;
    setRows((prev) =>
      prev.map((r) => ({ ...r, advanceDeduction: rowAdvanceSum(r.employeeId).toFixed(NUM_DECIMALS) }))
    );
  }, [isEdit, initialized, advanceByEmployee, rowAdvanceSum]);

  // In edit mode, once the operator-production data has loaded, refresh the
  // operator baseline (transaction-present floor, production base total, daily
  // basic) and recompute total salary so the present-day adjustment is correct.
  useEffect(() => {
    if (!isEdit || !initialized || operatorByEmployee.size === 0) return;
    setRows((prev) =>
      prev.map((r) => {
        if (!r.isOperator) return r;
        const op = operatorByEmployee.get(r.employeeId);
        if (!op) return r;
        const base: DetailRow = {
          ...r,
          presentDays: String(op.presentDays),
          totalSalary: op.totalSalary.toFixed(NUM_DECIMALS),
          operatorBaseTotal: op.totalSalary,
          operatorTransactionPresent: op.presentDays,
          operatorDailyBasic: toNum(r.basicSalary),
          operatorDays: op.days,
        };
        return recomputeOperatorAll(base, daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR));
      })
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEdit, initialized, operatorByEmployee, month, year]);

  // For new mode: rebuild rows when dept selection, employee list, or the
  // loaded advance totals change (advances fetch async, so they may arrive
  // after rows are first built).
  const deptKey = useMemo(
    () => selectedDeptIds.slice().sort().join(","),
    [selectedDeptIds]
  );
  const [builtForKey, setBuiltForKey] = useState<string | null>(null);
  const [builtForOpCount, setBuiltForOpCount] = useState(-1);
  const [builtForLoadState, setBuiltForLoadState] = useState<string>("");
  // Rebuild when the selected dept, the loaded advance batch, or the loaded
  // operator-production batch changes (all fetch async).
  const advanceLoadToken = `${deptKey}:${advances.length}:${operatorByEmployee.size}:${month}:${year}`;

  useEffect(() => {
    if (isEdit) return;
    if (deptKey === builtForKey && allEmployees.length === builtForOpCount && advanceLoadToken === builtForLoadState) return;
    setBuiltForKey(deptKey);
    setBuiltForOpCount(allEmployees.length);
    setBuiltForLoadState(advanceLoadToken);
    if (selectedDeptIds.length === 0) { setRows([]); return; }
    const td = daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR);
    const filtered = allEmployees.filter(
      (op) => op.active && op.departmentId !== null && selectedDeptIds.includes(op.departmentId!)
    );
    setRows(
      filtered.map((op) => {
        if (operatorDeptId !== null && op.departmentId === operatorDeptId) {
          const prod = operatorByEmployee.get(op.id);
          if (prod) return rowFromOperator(op, td, prod, rowAdvanceSum(op.id));
        }
        // For non-operators on the current month, default Present to the number
        // of days elapsed so far this month; otherwise the full days in month.
        const isCurrentMonth =
          parseInt(month) === new Date().getMonth() + 1 &&
          parseInt(year) === new Date().getFullYear();
        const defaultPresent = isCurrentMonth ? new Date().getDate() : td;
        return rowFromEmployee(op, td, rowAdvanceSum(op.id), defaultPresent);
      })
    );
  }, [isEdit, deptKey, allEmployees.length, advanceLoadToken, advanceByEmployee, operatorDeptId, operatorByEmployee, month, year]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Row update with field-aware formula logic ──
  const updateRow = useCallback(
    (idx: number, field: keyof DetailRow, value: string) => {
      setRows((prev) => {
        const next = [...prev];
        const td = daysInMonthFn(parseInt(month) || 1, parseInt(year) || CURRENT_YEAR);
        let updated = { ...next[idx], [field]: value };

        // Present and Absent are linked so they always sum to the days in the
        // month: editing one keeps the other at totalDays - the edited value.
        // Operators skip the linkage: their Present is a standalone adjustment
        // (floored at the transaction-present count), so editing Absent or
        // Present must not rewrite the other.
        if (!next[idx].isOperator) {
          if (field === "presentDays") {
            const abs = clampNum(td - toNum(value), 0, td);
            updated = { ...updated, absentDays: String(abs) };
          } else if (field === "absentDays") {
            const pre = clampNum(td - toNum(value), 0, td);
            updated = { ...updated, presentDays: String(pre) };
          }
        }

        // Operator Present is a manual adjustment: floor = transaction-present
        // days, ceiling = days in the month.
        if (next[idx].isOperator && field === "presentDays") {
          const floor = toNum(next[idx].operatorTransactionPresent);
          const clamped = clampNum(toNum(value), floor, td);
          updated = { ...updated, presentDays: String(clamped) };
        }

        // Holidays are capped at MAX_HOLIDAYS (5) per month regardless of input.
        if (field === "holidays") {
          const clamped = clampNum(toNum(value), 0, toNum(MAX_HOLIDAYS));
          updated = { ...updated, holidays: String(clamped) };
        }

        // Attendance-style fields are whole numbers (0 decimals).
        if (field === "presentDays" || field === "absentDays" || field === "holidays" || field === "otHours") {
          updated = { ...updated, [field]: String(roundToWhole(toNum(updated[field]))) };
        }

        if (SALARY_SOURCE_FIELDS.has(field) || OT_SOURCE_FIELDS.has(field)) {
          // Source or OT field changed → recompute salary/OT fields and payable.
          // Operator rows use their own formula (production + present adjustment).
          next[idx] = updated.isOperator ? recomputeOperatorAll(updated, td) : recomputeAll(updated, td);
        } else {
          // User is editing a directly-entered value (holidays, loan/other
          // deductions) → only recompute payableSalary (operator-aware)
          next[idx] = updated.isOperator ? recomputeOperatorAll(updated, td) : recomputePayable(updated, td);
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
      setRows((prev) =>
        prev.map((r) => {
          const rr = { ...r, advanceDeduction: rowAdvanceSum(r.employeeId).toFixed(NUM_DECIMALS) };
          return rr.isOperator ? recomputeOperatorAll(rr, td) : recomputeAll(rr, td);
        })
      );
    },
    [year, advanceByEmployee]
  );

  // When year changes: update state and recompute formula fields
  const handleYearChange = useCallback(
    (y: string) => {
      setYear(y);
      const td = daysInMonthFn(parseInt(month) || 1, parseInt(y) || CURRENT_YEAR);
      setRows((prev) =>
        prev.map((r) => {
          const rr = { ...r, advanceDeduction: rowAdvanceSum(r.employeeId).toFixed(NUM_DECIMALS) };
          return rr.isOperator ? recomputeOperatorAll(rr, td) : recomputeAll(rr, td);
        })
      );
    },
    [month, advanceByEmployee]
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
    // Don't allow saving a future period (belt-and-braces guard alongside the
    // disabled dropdown options).
    const selY = parseInt(year);
    const selM = parseInt(month);
    if (selY > CURRENT_YEAR || (selY === CURRENT_YEAR && selM > CURRENT_MONTH)) {
      toast({ variant: "destructive", title: "Validation", description: "Future month/year cannot be selected." });
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
    // Present + Absent can't exceed the days in the selected month.
    const invalid = rows.filter((r) => attendanceExceedsMonth(r, totalDays));
    if (invalid.length > 0) {
      const names = invalid.slice(0, 3).map((r) => r.employeeName).join(", ");
      const suffix = invalid.length > 3 ? ` (+${invalid.length - 3} more)` : "";
      toast({
        variant: "destructive",
        title: "Validation",
        description: `Present + Absent exceeds ${totalDays} days for: ${names}${suffix}.`,
      });
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

  // Column totals for the grid footer (matching the numeric column order).
  // Whole-number columns (attendance) sum to 0 decimals; money columns to 2.
  const numericColumns: Array<{ key: keyof DetailRow; decimals: number }> = [
    { key: "basicSalary", decimals: 2 },
    { key: "otRateHr", decimals: 2 },
    { key: "attAllowance", decimals: 2 },
    { key: "othAllowance", decimals: 2 },
    { key: "presentDays", decimals: 0 },
    { key: "absentDays", decimals: 0 },
    { key: "holidays", decimals: 0 },
    { key: "totalAttendance", decimals: 0 },
    { key: "otHours", decimals: 0 },
    { key: "otAmount", decimals: 2 },
    { key: "totalSalary", decimals: 2 },
    { key: "advanceDeduction", decimals: 2 },
    { key: "loanDeduction", decimals: 2 },
    { key: "otherDeduction", decimals: 2 },
    { key: "payableSalary", decimals: 2 },
  ];
  const columnTotals = numericColumns.map((col) =>
    rows.reduce((acc, row) => acc + toNum(row[col.key]), 0)
  );
  const fmtTotal = (v: number, decimals: number) =>
    v.toLocaleString("en-IN", {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });

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
                    {MONTHS.map((name, i) => {
                      const m = i + 1;
                      // No future months when the current year is selected.
                      const isFutureMon = parseInt(year) === CURRENT_YEAR && m > CURRENT_MONTH;
                      return (
                        <SelectItem key={m} value={String(m)} disabled={isFutureMon}>
                          {name}
                        </SelectItem>
                      );
                    })}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex flex-col gap-1">
                <Label>Year</Label>
                <Select value={year} onValueChange={handleYearChange} disabled={isPosted}>
                  <SelectTrigger className="w-28"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {SELECTABLE_YEARS.map((y) => (
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
              {/* Compact legend: editable vs computed, plus the key formulas. */}
              <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
                <span className="inline-flex items-center gap-1.5">
                  <span className="inline-block h-3 w-3 rounded border border-input"></span>
                  Editable
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <span className="inline-block h-3 w-3 rounded bg-muted/40"></span>
                  Computed / read-only
                </span>
                <span className="text-muted-foreground/70">
                  Total Att. = Present + Holidays · Total Salary = (Basic ÷ {totalDays}) × Att. + OT ·
                  Payable = Total Salary + Att. Allow. (when Present = {totalDays}) − Deductions
                </span>
              </div>
            </CardHeader>
            <CardContent className="p-0 overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="text-xs">
                    <TableHead className="sticky left-0 z-10 bg-card min-w-[140px] border-r border-border/60">Employee</TableHead>
                    <TableHead className="text-right min-w-[90px]" title="Base salary from the employee master">Basic Salary</TableHead>
                    <TableHead className="text-right min-w-[80px]" title="Overtime rate per hour (employee master)">OT Rate/Hr</TableHead>
                    <TableHead className="text-right min-w-[80px]" title="Attendance allowance — added on full attendance">Att. Allow.</TableHead>
                    <TableHead className="text-right min-w-[80px]" title="Other allowance">Oth. Allow.</TableHead>
                    <TableHead className="text-right min-w-[75px]">Present</TableHead>
                    <TableHead className="text-right min-w-[75px]">Absent</TableHead>
                    <TableHead className="text-right min-w-[70px]">Holidays</TableHead>
                    <TableHead className="text-right min-w-[80px]" title="Present + Holidays (computed)">Total Att.</TableHead>
                    <TableHead className="text-right min-w-[70px]">OT Hrs</TableHead>
                    <TableHead className="text-right min-w-[90px]" title="OT Hours × OT Rate (computed)">OT Amount</TableHead>
                    <TableHead className="text-right min-w-[100px]" title="(Basic ÷ days) × Attendance + OT (computed)">Total Salary</TableHead>
                    <TableHead className="text-right min-w-[90px]" title="Advances for the month (auto-loaded)">Adv. Deduction</TableHead>
                    <TableHead className="text-right min-w-[90px]">Loan Deduction</TableHead>
                    <TableHead className="text-right min-w-[90px]">Other Deduction</TableHead>
                    <TableHead className="sticky right-0 z-10 bg-card min-w-[110px] font-bold border-l border-border/60" title="Total Salary + Att. Allowance − Deductions">Payable Salary</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rows.map((row, i) => {
                    const inp = "h-7 text-right font-mono text-xs p-1 w-full";
                    const ro = "h-7 text-right font-mono text-xs p-1 w-full bg-muted/40 cursor-not-allowed";
                    const attExceeded = attendanceExceedsMonth(row, totalDays);
                    const attErrCls = attExceeded ? "border-destructive focus-visible:ring-destructive" : "";
                    const striped = i % 2 === 0;
                    // Solid backgrounds for row striping and the frozen columns
                    // (Employee, Payable) so nothing is transparent.
                    const rowBg = striped ? "bg-[hsl(var(--muted))]" : "bg-card";
                    const stickyBg = rowBg;
                    return (
                      <TableRow key={row.employeeId} className={rowBg}>
                        {/* Sticky-left employee name so the numbers never
                            scroll away from whose row they belong to (P9).
                            Operator rows get an eye icon that opens the
                            transaction/salary breakdown popup. */}
                        <TableCell className={`sticky left-0 z-10 ${stickyBg} border-r border-border/60 font-medium text-sm py-1`}>
                          <div className="flex items-center gap-1">
                            {row.isOperator && (
                              <button
                                type="button"
                                title="View salary calculation"
                                onClick={() => setOperatorDetail(row.employeeId)}
                                className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                              >
                                <Eye className="h-4 w-4" />
                              </button>
                            )}
                            <span className="truncate">{row.employeeName}</span>
                          </div>
                          {attExceeded && (
                            <p className="mt-0.5 max-w-[180px] text-[10px] leading-tight text-red-600">
                              Present + Absent ({toNum(row.presentDays) + toNum(row.absentDays)}) exceeds {totalDays} days
                            </p>
                          )}
                        </TableCell>
                        {/* Master snapshot — display only */}
                        <TableCell className="py-1"><Input disabled className={ro} value={row.basicSalary} /></TableCell>
                        <TableCell className="py-1"><Input disabled className={ro} value={row.otRateHr} /></TableCell>
                        <TableCell className="py-1"><Input disabled className={ro} value={row.attAllowance} /></TableCell>
                        <TableCell className="py-1"><Input disabled className={ro} value={row.othAllowance} /></TableCell>
                        {/* Attendance inputs — trigger salary formula. Operator
                            Present is editable from the transaction-present floor
                            up to the days in the month; each day above the floor
                            adds one daily basic to their salary. */}
                        <TableCell className="py-1">
                          {row.isOperator ? (
                            <Input type="number" min={row.operatorTransactionPresent ?? 0} max={totalDays} step={STEP_ATTENDANCE} className={inp}
                              value={row.presentDays} disabled={isPosted}
                              onChange={(e) => updateRow(i, "presentDays", e.target.value)} />
                          ) : (
                            <Input type="number" min="0" max={totalDays} step={STEP_ATTENDANCE} className={cn(inp, attErrCls)}
                              value={row.presentDays} disabled={isPosted}
                              onChange={(e) => updateRow(i, "presentDays", e.target.value)} />
                          )}
                        </TableCell>
                        <TableCell className="py-1">
                          {row.isOperator ? (
                            <Input type="number" min="0" max={totalDays} step={STEP_ATTENDANCE} className={ro}
                              value={row.absentDays} disabled readOnly />
                          ) : (
                            <Input type="number" min="0" max={totalDays} step={STEP_ATTENDANCE} className={cn(inp, attErrCls)}
                              value={row.absentDays} disabled={isPosted}
                              onChange={(e) => updateRow(i, "absentDays", e.target.value)} />
                          )}
                        </TableCell>
                        <TableCell className="py-1">
                          {row.isOperator ? (
                            <Input type="number" min="0" max={MAX_HOLIDAYS} step={STEP_ATTENDANCE} className={inp}
                              value={row.holidays} disabled={isPosted}
                              onChange={(e) => updateRow(i, "holidays", e.target.value)} />
                          ) : (
                            <Input type="number" min="0" max={MAX_HOLIDAYS} step={STEP_ATTENDANCE} className={ro}
                              value={row.holidays} disabled readOnly />
                          )}
                        </TableCell>
                        {/* totalAttendance = Present + Holidays (derived, read-only) */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step={STEP_ATTENDANCE} className={ro}
                            value={row.totalAttendance} disabled readOnly />
                        </TableCell>
                        {/* otHours — triggers otAmount recalculation. Disabled when
                            the employee has no OT rate (rate zero), since OT
                            Amount = OT Hrs × rate is then always 0. */}
                        <TableCell className="py-1">
                          {toNum(row.otRateHr) > 0 ? (
                            <Input type="number" min="0" step={STEP_ATTENDANCE} className={inp}
                              value={row.otHours} disabled={isPosted}
                              onChange={(e) => updateRow(i, "otHours", e.target.value)} />
                          ) : (
                            <Input type="number" min="0" step={STEP_ATTENDANCE} className={ro}
                              value={row.otHours} disabled readOnly />
                          )}
                        </TableCell>
                        {/* otAmount — auto-computed; display only (no manual override) */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step={STEP_MONEY} className={ro}
                            value={row.otAmount} disabled readOnly />
                        </TableCell>
                        {/* totalSalary — auto-computed; display only (no manual override) */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step={STEP_MONEY} className={ro}
                            value={row.totalSalary} disabled readOnly />
                        </TableCell>
                        {/* Deductions — Advance Deduction is auto-loaded from the
                            advances table for the selected month, so it's read-only. */}
                        <TableCell className="py-1">
                          <Input type="number" min="0" step={STEP_MONEY} className={ro}
                            value={row.advanceDeduction} disabled readOnly />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input type="number" min="0" step={STEP_MONEY} className={inp}
                            value={row.loanDeduction} disabled={isPosted}
                            onChange={(e) => updateRow(i, "loanDeduction", e.target.value)} />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input type="number" min="0" step={STEP_MONEY} className={inp}
                            value={row.otherDeduction} disabled={isPosted}
                            onChange={(e) => updateRow(i, "otherDeduction", e.target.value)} />
                        </TableCell>
                        {/* Payable — live computed, read-only display. Sticky on
                            the right so the final total stays visible while the
                            grid scrolls; solid bg so nothing shows through. */}
                        <TableCell
                          className={`sticky right-0 z-10 py-1 pr-2 text-right font-mono text-sm font-semibold ${stickyBg} border-l border-border/60 ${
                            toNum(row.payableSalary) < 0 ? "text-red-600" : "text-green-700"
                          }`}
                        >
                          {toNum(row.payableSalary).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
                {rows.length > 1 && (
                  <TableFooter>
                    <TableRow className="bg-[hsl(var(--muted))]">
                      <TableCell className="sticky left-0 z-10 bg-[hsl(var(--muted))] border-r border-border/60 font-semibold text-sm">
                        Total ({rows.length})
                      </TableCell>
                      {columnTotals.map((t, idx) => {
                        const isPayable = idx === numericColumns.length - 1;
                        return (
                          <TableCell
                            key={idx}
                            className={`py-1 px-2 text-right font-mono text-xs font-semibold ${
                              isPayable ? "sticky right-0 z-10 bg-[hsl(var(--muted))] border-l border-border/60" : ""
                            }`}
                          >
                            {fmtTotal(t, numericColumns[idx]?.decimals ?? 2)}
                          </TableCell>
                        );
                      })}
                    </TableRow>
                  </TableFooter>
                )}
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

      {/* Operator salary calculation popup */}
      <OperatorDetailDialog
        row={rows.find((r) => r.employeeId === operatorDetail)}
        month={(parseInt(month) || 0).toString()}
        year={(parseInt(year) || 0).toString()}
        onClose={() => setOperatorDetail(null)}
      />
    </Layout>
  );
}

// ─── Operator salary detail popup ─────────────────────────────────────────────
// Shows the per-day transaction production and how the operator's salary was
// derived (max of daily production sum vs daily basic), plus the rolled-up
// present days and total salary.
function OperatorDetailDialog({
  row,
  month,
  year,
  onClose,
}: {
  row: DetailRow | undefined;
  month: string;
  year: string;
  onClose: () => void;
}) {
  const monthName = MONTHS[parseInt(month) - 1] || month;
  const days = row?.operatorDays ?? [];
  const totalProduction = days.reduce((acc, d) => acc + d.dailyProductionSum, 0);
  const totalCredited = days.reduce((acc, d) => acc + d.credited, 0);

  return (
    <Dialog open={!!row} onOpenChange={(open) => { if (!open) onClose(); }}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto p-4 sm:p-6">
        <DialogHeader className="pr-6">
          <DialogTitle className="text-base sm:text-lg">Salary Calculation — {row?.employeeName ?? ""}</DialogTitle>
          <DialogDescription className="text-xs sm:text-sm">
            Production-based salary for {monthName} {year} (Operator, dept code 0002).
            Daily basic salary: <span className="font-medium">{fmtMoney(toNum(row?.basicSalary ?? 0))}</span>.
          </DialogDescription>
        </DialogHeader>

        {/* Summary banner */}
        {days.length > 0 && (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 sm:gap-3 rounded-lg border bg-muted/20 p-3 sm:p-4">
            <div>
              <p className="text-[11px] sm:text-xs text-muted-foreground">Present days</p>
              <p className="text-base sm:text-lg font-semibold">{days.length}</p>
            </div>
            <div>
              <p className="text-[11px] sm:text-xs text-muted-foreground">Total production (gross)</p>
              <p className="text-base sm:text-lg font-semibold">{fmtMoney(totalProduction)}</p>
            </div>
            <div className="col-span-2 sm:col-span-1">
              <p className="text-[11px] sm:text-xs text-muted-foreground">Total salary (credited)</p>
              <p className="text-base sm:text-lg font-bold text-green-700">{fmtMoney(totalCredited)}</p>
            </div>
          </div>
        )}

        {/* Day cards (all screen sizes) */}
        <div className="space-y-3">
          {days.length === 0 && (
            <p className="text-center text-muted-foreground text-sm py-6">
              No production days in this month.
            </p>
          )}
          {days.map((d) => (
            <div key={d.date} className="rounded-lg border bg-card overflow-hidden">
              {/* Day header */}
              <div className="flex items-center justify-between gap-2 border-b bg-muted/30 px-3 py-2 sm:px-4 sm:py-2.5">
                <span className="font-medium text-sm sm:text-base">{formatDate(d.date)}</span>
                <span className="text-xs sm:text-sm text-muted-foreground">{d.machines?.length ?? 0} machine{(d.machines?.length ?? 0) === 1 ? "" : "s"}</span>
              </div>
              {/* Machine lines */}
              <div className="divide-y divide-border/60">
                {(d.machines ?? []).map((m, mi) => (
                  <div key={mi} className="flex items-center gap-3 px-3 py-2 sm:px-4 sm:py-2.5">
                    <span className="min-w-0 flex-1 truncate text-sm text-muted-foreground">{m.machineName}</span>
                    <span className="shrink-0 text-xs sm:text-sm text-muted-foreground">{m.netWt} × {m.rate}</span>
                    <span className="shrink-0 text-sm sm:text-base font-mono font-semibold">{fmtMoney(m.amount)}</span>
                  </div>
                ))}
                {/* Day totals row */}
                <div className="flex items-center justify-between gap-2 bg-muted/20 px-3 py-2 sm:px-4 sm:py-2.5">
                  <span className="text-xs sm:text-sm text-muted-foreground">Daily production</span>
                  <span className="text-sm sm:text-base font-mono font-semibold">{fmtMoney(d.dailyProductionSum)}</span>
                </div>
                <div className="flex items-center justify-between gap-2 px-3 py-2 sm:px-4 sm:py-2.5">
                  <span className="text-xs sm:text-sm text-muted-foreground">Credited (max of prod &amp; basic)</span>
                  <span className="text-sm sm:text-base font-mono font-bold text-green-700">{fmtMoney(d.credited)}</span>
                </div>
              </div>
            </div>
          ))}
        </div>

        <p className="text-xs sm:text-sm text-muted-foreground">
          Per machine: production = net weight × machine making rate. Credited per day =
          max(daily production sum, daily basic salary). Total salary = sum of credited
          days. Daily basic salary: <span className="font-medium">{fmtMoney(toNum(row?.basicSalary ?? 0))}</span>.
        </p>
      </DialogContent>
    </Dialog>
  );
}
