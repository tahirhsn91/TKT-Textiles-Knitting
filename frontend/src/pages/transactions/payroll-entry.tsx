import { NUM_DECIMALS } from "@/lib/format";
import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { useParams, useLocation } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { ArrowLeft, Save, Check, ChevronsUpDown, Eye } from "lucide-react";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import { cn } from "@/lib/utils";

import * as d3 from "d3";

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

async function apiFetch<T = unknown>(path: string, opts?: RequestInit): Promise<T> {
  try {
    return await customFetch<T>(path, opts ?? { method: "GET" });
  } catch (err) {
    throw err instanceof Error ? err : new Error(`HTTP request failed`);
  }
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
  // True when the day is paid purely on attendance (present, but no production
  // transaction that day) — credited the daily basic salary.
  attendanceOnly?: boolean;
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

// Attendance for a month (from the Attendance module). Used to pre-fill
// Present days for non-operators and to gate payroll save.
interface AttendanceMonthResponse {
  month: number; year: number; daysInMonth: number;
  operatorDepartmentId: number | null;
  payrollExists: boolean;
  records: Array<{ employeeId: number; attendanceDate: string; present: boolean }>;
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
  // Absent is derived as the days in the month not present (never below 0).
  const absentDays = Math.max(totalDays - toNum(row.presentDays), 0);
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
      presentDays: String(toNum(row.presentDays)),
      absentDays: String(absentDays),
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
// from production: Present days = max(attendance manual present, transaction
// production days), read-only from attendance. Total Salary comes from the
// transactions plus the present-day adjustment; Absent / Holidays / OT /
// Deductions stay user-entered.
function rowFromOperator(op: Employee, totalDays: number, prod: OperatorProduction, advanceSum = 0, manualPresent = 0): DetailRow {
  const dailyBasic = toNum(op.baseSalary);
  const transactionPresent = prod.presentDays;
  // Operator present = whichever is greater between the attendance manual
  // present and the production days; cannot be reduced below production.
  const present = Math.max(manualPresent, transactionPresent);
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
    presentDays: String(present),
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
  // New salary entry: Present/Absent are derived from attendance (disabled).
  // Edit mode keeps the existing workflow.
  const isNewMode = !isEdit;
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

  // Attendance for the selected month (from the Attendance module). Non-operator
  // Present days are prefilled from here; payroll save is blocked when no
  // attendance exists for the month (operators still resolve max(attendance,
  // production) live via operator-production).
  const attParams = new URLSearchParams({ month, year });
  const { data: attendanceMonth } = useQuery<AttendanceMonthResponse>({
    queryKey: ["attendance-month", month, year],
    queryFn: () => apiFetch(`/api/attendance?${attParams.toString()}`),
    enabled: (!isEdit || initialized),
  });
  // present days per employee from attendance records (count of present rows).
  const attendancePresentByEmployee = useMemo(() => {
    const map = new Map<number, number>();
    for (const r of attendanceMonth?.records ?? []) {
      if (r.present) map.set(r.employeeId, (map.get(r.employeeId) ?? 0) + 1);
    }
    return map;
  }, [attendanceMonth]);
  // Whether any attendance record exists for the month at all.
  const attendanceExists = ((attendanceMonth?.records?.length ?? 0) > 0);

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
  // Rebuild when the selected dept, the loaded advance batch, the loaded
  // operator-production batch, or the loaded attendance changes (all fetch async).
  const advanceLoadToken = `${deptKey}:${advances.length}:${operatorByEmployee.size}:${attendanceExists}:${attendancePresentByEmployee.size}:${month}:${year}`;

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
          if (prod) {
            // Operator present = max(attendance manual present, production days).
            const manualAtt = attendancePresentByEmployee.get(op.id) ?? 0;
            return rowFromOperator(op, td, prod, rowAdvanceSum(op.id), manualAtt);
          }
        }
        // For non-operators: Present comes from the Attendance module. When
        // attendance exists for the month, prefill the employee's present-day
        // count from it; when it does NOT exist, Present defaults to 0 and
        // payroll save is blocked until attendance is entered.
        const attPresent = attendancePresentByEmployee.get(op.id);
        const defaultPresent = attendanceExists && attPresent !== undefined ? attPresent : 0;
        return rowFromEmployee(op, td, rowAdvanceSum(op.id), defaultPresent);
      })
    );
  }, [isEdit, deptKey, allEmployees.length, advanceLoadToken, advanceByEmployee, operatorDeptId, operatorByEmployee, attendancePresentByEmployee, attendanceExists, month, year]); // eslint-disable-line react-hooks/exhaustive-deps

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
    // Attendance is the source of present days: payroll cannot be saved until
    // attendance has been saved for the month (spec: block-on-save).
    if (!attendanceExists) {
      toast({
        variant: "destructive",
        title: "Attendance Required",
        description: `Attendance has not been entered for ${MONTHS[selM - 1]} ${selY}. Save attendance first.`,
      });
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
      <>
        <div className="flex flex-col gap-4">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-64 w-full" />
        </div>
      </>
    );
  }

  return (
    <>
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

        <Tabs defaultValue="entry" className="mt-2">
          <TabsList>
            <TabsTrigger value="entry">Salary Entry</TabsTrigger>
            <TabsTrigger value="logic">Calculation Logic</TabsTrigger>
          </TabsList>
          <TabsContent value="entry" className="mt-4 space-y-4">
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
                  {isNewMode && <> · Present / Absent from Attendance</>}
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
                        {/* Attendance inputs — derived from attendance in new
                            mode (Present & Absent read-only); editable in edit
                            mode. Operator Present floors at transaction-present. */}
                        <TableCell className="py-1">
                          <Input
                            type="number"
                            min={row.isOperator ? (row.operatorTransactionPresent ?? 0) : 0}
                            max={totalDays}
                            step={STEP_ATTENDANCE}
                            className={cn(isNewMode ? ro : inp, attErrCls)}
                            value={row.presentDays}
                            disabled={isPosted || isNewMode}
                            readOnly={isNewMode}
                            onChange={(e) => updateRow(i, "presentDays", e.target.value)}
                            title={isNewMode ? "Calculated from attendance" : undefined}
                          />
                        </TableCell>
                        <TableCell className="py-1">
                          <Input
                            type="number"
                            min="0"
                            max={totalDays}
                            step={STEP_ATTENDANCE}
                            className={cn(isNewMode ? ro : inp, attErrCls)}
                            value={row.absentDays}
                            disabled={isPosted || isNewMode}
                            readOnly={isNewMode}
                            onChange={(e) => updateRow(i, "absentDays", e.target.value)}
                            title={isNewMode ? "Calculated as days minus present" : undefined}
                          />
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
          </TabsContent>

          <TabsContent value="logic" className="mt-4">
            <SalaryCalculationLogic daysInMonth={totalDays} isNewMode={isNewMode} />
          </TabsContent>
        </Tabs>

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
    </>
  );
}

// ─── Salary calculation logic reference ───────────────────────────────────────
// Read-only tab that explains, end-to-end, how an employee's salary is derived.
// Centers on an interactive D3 flow diagram (SVG) built declaratively: D3
// provides the layout scales, the curved edge generator and arrow markers, while
// the nodes/edges are rendered as JSX. Hover (or focus) a node to see the live
// formula, with the selected month's day-count substituted.

// Node/edge model for the salary flow diagram.
type FlowNodeKind = "input" | "process" | "output";
interface FlowNode {
  id: string;
  label: string;
  sub?: string;
  formula: string;
  kind: FlowNodeKind;
  // Optional explicit vertical center (SVG y) to override the auto layout, e.g.
  // to align a lone output node with the step it connects from.
  yHint?: number;
}
interface FlowEdge {
  source: string;
  target: string;
  label?: string;
}

const FLOW_NODES: FlowNode[] = [
  // Inputs (sources of data)
  { id: "master", label: "Employee Master", sub: "Basic · OT Rate · Allowances", formula: "Basic Salary, OT Rate/Hr, Att./Oth. Allowance from the employee record (read-only on each row).", kind: "input" },
  { id: "attendance", label: "Attendance", sub: "Present days", formula: "Present / Absent for the month come from the Attendance module (new entries). Absent = days in month − Present.", kind: "input" },
  { id: "production", label: "Fabric Production", sub: "Operator (dept 0002)", formula: "Per row: Net Weight × Machine Making Rate. Operators are paid on production, not attendance.", kind: "input" },
  { id: "advances", label: "Advances", sub: "Auto-filled", formula: "Sum of the employee's advances for the month — auto-fills the Advance Deduction column.", kind: "input" },
  { id: "manual", label: "Manual entry", sub: "Loan · Other", formula: "Loan Deduction and Other Deduction are hand-entered per employee.", kind: "input" },
  // Computation steps
  { id: "otAmt", label: "OT Amount", formula: "OT Hours × OT Rate/Hr", kind: "process" },
  { id: "totalAtt", label: "Total Attendance", formula: "Present + Holidays (Absent derived from days in month − Present)", kind: "process" },
  { id: "dailyCredit", label: "Daily Credit", formula: "max(Daily Production Sum, Daily Basic) — an operator is never paid less than a day's basic.", kind: "process" },
  { id: "totalSalary", label: "Total Salary", formula: "(Basic ÷ DAYS) × Total Attendance + OT Amount", kind: "process" },
  { id: "attBonus", label: "Att. Allowance Bonus", formula: "Full allowance when Present ≥ DAYS (100% attendance), else 0.", kind: "process" },
  { id: "payable", label: "Payable Salary", formula: "Total Salary + Att. Allowance Bonus − Advance − Loan − Other", kind: "process" },
  // Output
  { id: "netPayable", label: "Net Payable", sub: "Per employee", formula: "Final take-home for the month, shown in the grid and payroll summary.", kind: "output", yHint: 560 },
];

const FLOW_EDGES: FlowEdge[] = [
  { source: "master", target: "otAmt", label: "OT rate / hrs" },
  { source: "master", target: "totalSalary", label: "Basic salary" },
  { source: "master", target: "attBonus", label: "Allowance" },
  { source: "attendance", target: "totalAtt", label: "Present days" },
  { source: "production", target: "dailyCredit", label: "Production" },
  { source: "production", target: "totalAtt", label: "Present (operators)" },
  { source: "dailyCredit", target: "totalSalary", label: "Credited/day" },
  { source: "totalAtt", target: "totalSalary", label: "Attendance" },
  { source: "otAmt", target: "totalSalary", label: "OT" },
  { source: "totalSalary", target: "payable", label: "Earnings" },
  { source: "attBonus", target: "payable", label: "Bonus" },
  { source: "advances", target: "payable", label: "Advance −" },
  { source: "manual", target: "payable", label: "Loan/Other −" },
  { source: "payable", target: "netPayable", label: "" },
];

// D3-driven flow diagram. Declarative: D3 computes the vertical scale, the
// column x positions and the curved link paths; JSX renders the SVG.
function SalaryFlowDiagram({
  daysInMonth,
  isNewMode,
}: {
  daysInMonth: number;
  isNewMode: boolean;
}) {
  const W = 900;
  const H = 660;
  const [active, setActive] = useState<string | null>(null);
  const [hovered, setHovered] = useState<string | null>(null);
  const shown = hovered ?? active;
  const shownNode = shown ? FLOW_NODES.find((n) => n.id === shown) : undefined;

  // Column x positions (layout).
  const col = { input: 120, process: 430, output: 760 };
  const nodeW = 210;
  const nodeH = 46;

  // Vertically distribute nodes within each column using a D3 point scale.
  const yFor = (kind: FlowNodeKind) => {
    const items = FLOW_NODES.filter((n) => n.kind === kind);
    const pad = 44;
    const span = d3.scalePoint()
      .domain(items.map((n) => n.id))
      .range([pad, H - pad])
      .padding(0.5);
    const pos = new Map(items.map((n) => [n.id, span(n.id)!]));
    return (id: string) => pos.get(id) ?? H / 2;
  };
  const yInput = yFor("input");
  const yProcess = yFor("process");
  const yOutput = yFor("output");

  const nodePos = (id: string): { x: number; y: number } => {
    const n = FLOW_NODES.find((d) => d.id === id)!;
    const baseY = n.kind === "input" ? yInput(id) : n.kind === "process" ? yProcess(id) : yOutput(id);
    const y = n.yHint != null ? n.yHint : baseY;
    return { x: col[n.kind] - nodeW / 2, y: y - nodeH / 2 };
  };

  // Curved connector (D3 cubic bezier), horizontal-dominant, with an arrow at
  // the target. Inset the target a touch so the arrow sits on the node edge.
  const link = d3.linkHorizontal<FlowEdge, { x: number; y: number }>()
    .x((d) => d.x)
    .y((d) => d.y);
  const edgePath = (e: FlowEdge) => {
    const s = nodePos(e.source);
    const t = nodePos(e.target);
    const sx = s.x + nodeW + 2;
    const sy = s.y + nodeH / 2;
    const tx = t.x - 2;
    const ty = t.y + nodeH / 2;
    return link({ source: { x: sx, y: sy }, target: { x: tx, y: ty } } as any) ?? "";
  };

  // Fill/tone per kind (semantic colors, usable in light + dark).
  const fill = { input: "var(--flow-input)", process: "var(--flow-process)", output: "var(--flow-output)" };
  const stroke = { input: "var(--flow-input-edge)", process: "var(--flow-process-edge)", output: "var(--flow-output-edge)" };

  const nodeActive = (id: string) => shown === id;
  const edgeActive = (e: FlowEdge) => shown != null && (e.source === shown || e.target === shown);

  return (
    <div>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full h-auto select-none" role="img" aria-label="Salary calculation flow diagram">
        <defs>
          <marker id="fl-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
            <path d="M0 0 L10 5 L0 10 z" fill="var(--flow-line)" />
          </marker>
        </defs>

        {/* column labels */}
        <text x={col.input} y={20} textAnchor="middle" fontSize="12" fontWeight="600" fill="var(--flow-muted)">INPUTS</text>
        <text x={col.process} y={20} textAnchor="middle" fontSize="12" fontWeight="600" fill="var(--flow-muted)">CALCULATION</text>
        <text x={col.output} y={20} textAnchor="middle" fontSize="12" fontWeight="600" fill="var(--flow-muted)">RESULT</text>

        {/* edges behind nodes */}
        {FLOW_EDGES.map((e) => (
          <g key={`${e.source}-${e.target}`} className={edgeActive(e) ? "" : "edge-dim"}>
            <path d={edgePath(e)} fill="none" stroke="var(--flow-line)" strokeWidth={edgeActive(e) ? 2.4 : 1.4} opacity={edgeActive(e) ? 1 : 0.55} markerEnd="url(#fl-arrow)" />
            {e.label ? (
              <text x={(nodePos(e.source).x + nodePos(e.target).x) / 2} y={(nodePos(e.source).y + nodePos(e.target).y) / 2 + nodeH / 2} textAnchor="middle" fontSize="10" fill="var(--flow-muted)" pointerEvents="none">{e.label}</text>
            ) : null}
          </g>
        ))}

        {/* nodes */}
        {FLOW_NODES.map((n) => {
          const p = nodePos(n.id);
          const isActive = nodeActive(n.id);
          return (
            <g
              key={n.id}
              transform={`translate(${p.x},${p.y})`}
              className={`flow-node${isActive ? " flow-node-active" : ""}`}
              onMouseEnter={() => setHovered(n.id)}
              onMouseLeave={() => setHovered(null)}
              onClick={() => setActive(active === n.id ? null : n.id)}
              style={{ cursor: "pointer" }}
            >
              <rect width={nodeW} height={nodeH} rx={9} fill={fill[n.kind]} stroke={isActive ? "var(--flow-fg)" : stroke[n.kind]} strokeWidth={isActive ? 2 : 1.2} />
              <text x={12} y={20} fontSize="12.5" fontWeight="650" fill="var(--flow-fg)">{n.label}</text>
              {n.sub ? <text x={12} y={36} fontSize="10" fill="var(--flow-muted)">{n.sub}</text> : null}
            </g>
          );
        })}
      </svg>

      {/* hover / selection readout */}
      <div className="mt-3 min-h-[52px] rounded-lg border bg-muted/20 px-3 py-2 text-sm text-muted-foreground">
        {shownNode ? (
          <>
            <span className="font-semibold text-foreground">{shownNode.label}: </span>
            {shownNode.formula.replace(/DAYS/g, String(daysInMonth))}
          </>
        ) : (
          <span>Hover or tap a box to see how that step is calculated.</span>
        )}
      </div>

      {/* legend */}
      <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
        <span className="inline-flex items-center gap-1.5"><span className="inline-block h-3 w-3 rounded" style={{ background: "var(--flow-input)" }} /> Input</span>
        <span className="inline-flex items-center gap-1.5"><span className="inline-block h-3 w-3 rounded" style={{ background: "var(--flow-process)" }} /> Calculation</span>
        <span className="inline-flex items-center gap-1.5"><span className="inline-block h-3 w-3 rounded" style={{ background: "var(--flow-output)" }} /> Result</span>
        <span className="inline-flex items-center gap-1.5">
          <svg width="22" height="8"><line x1="0" y1="4" x2="22" y2="4" stroke="var(--flow-line)" strokeWidth="1.6" /></svg>
          Data flow
        </span>
        {isNewMode && <span className="text-amber-600">New entry: Present / Absent come from Attendance and are read-only.</span>}
      </div>
    </div>
  );
}

// Read-only reference text that accompanies the D3 flow diagram.
function SalaryCalculationLogic({
  daysInMonth,
  isNewMode,
}: {
  daysInMonth: number;
  isNewMode: boolean;
}) {
  const term = "font-mono text-xs mt-0.5";
  const formula = "flex flex-col gap-1 rounded-lg border bg-muted/20 px-3 py-2";
  return (
    <div className="flex flex-col gap-5">
      <Card>
        <CardHeader><CardTitle>How salary is calculated — end to end</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          <SalaryFlowDiagram daysInMonth={daysInMonth} isNewMode={isNewMode} />
        </CardContent>
      </Card>

      {/* 1. Inputs */}
      <Card>
        <CardHeader><CardTitle>1 · Where the inputs come from</CardTitle></CardHeader>
        <CardContent className="space-y-3 text-sm">
          <ul className="list-disc pl-5 space-y-1.5 text-muted-foreground">
            <li><span className="text-foreground font-medium">Basic Salary, OT Rate/Hr, Att. Allowance, Oth. Allowance</span> — pulled from the <em>Employee Master</em> (read-only snapshot on each row).</li>
            <li><span className="text-foreground font-medium">Present / Absent days</span> — in a <em>new</em> entry these come from the <em>Attendance</em> module for the selected month. Edit mode lets you adjust them; Present + Absent are kept linked to the days in the month.</li>
            <li><span className="text-foreground font-medium">Advance Deduction</span> — auto-filled from the sum of the employee&apos;s advances for the month.</li>
            <li><span className="text-foreground font-medium">Loan / Other deduction</span> — hand-entered per employee.</li>
            <li><span className="text-foreground font-medium">Operator (dept 0002)</span> — present days and the base salary come from <em>Fabric Production transactions</em> instead of attendance alone (see §3).</li>
          </ul>
        </CardContent>
      </Card>

      {/* 2. Non-operator */}
      <Card>
        <CardHeader><CardTitle>2 · Regular employee (non-operator)</CardTitle></CardHeader>
        <CardContent className="space-y-3 text-sm">
          <div className="grid gap-3 sm:grid-cols-2">
            <div className={formula}>
              <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Total Attendance</span>
              <code className={term}>Present + Holidays</code>
              <span className="text-xs text-muted-foreground">Absent is derived: days in month − Present (never below 0).</span>
            </div>
            <div className={formula}>
              <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">OT Amount</span>
              <code className={term}>OT Hours × OT Rate/Hr</code>
              <span className="text-xs text-muted-foreground">Zero when the employee has no OT rate set.</span>
            </div>
            <div className={formula}>
              <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Total Salary</span>
              <code className={term}>(Basic ÷ {daysInMonth}) × Total Attendance + OT Amount</code>
              <span className="text-xs text-muted-foreground">Basic prorated to the days actually attended, plus OT.</span>
            </div>
            <div className={formula}>
              <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Attendance Allowance Bonus</span>
              <code className={term}>Full allowance if Present ≥ {daysInMonth} (100% attendance)</code>
              <span className="text-xs text-muted-foreground">Otherwise 0.</span>
            </div>
          </div>
          <div className={formula}>
            <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Payable Salary</span>
            <code className={term}>Total Salary + Att. Allowance Bonus − Advance − Loan − Other</code>
          </div>
        </CardContent>
      </Card>

      {/* 3. Operator */}
      <Card>
        <CardHeader>
          <CardTitle>3 · Operator (dept 0002) — paid on production</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3 text-sm">
          <p className="text-muted-foreground">
            Operators are paid per day on <em>Fabric Production</em> output rather than attendance, using each machine&apos;s making rate.
          </p>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className={formula}>
              <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Production per row</span>
              <code className={term}>Net Weight × Machine Making Rate</code>
            </div>
            <div className={formula}>
              <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Credited per day</span>
              <code className={term}>max(Daily Production Sum, Daily Basic)</code>
              <span className="text-xs text-muted-foreground">Employee is never paid less than a day&apos;s basic even if production is low.</span>
            </div>
          </div>
          <div className={formula}>
            <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Present days / total salary</span>
            <code className={term}>Sum of credited days across presenting (production OR attendance) days</code>
          </div>
          <p className="text-xs text-muted-foreground">
            <span className="text-indigo-600 font-medium">Attendance-only rule:</span> if an operator is marked Present in Attendance on a day with no production transaction, that day is still credited the daily basic salary ({isNewMode ? "applied live from Attendance" : "in the saved breakdown"}).
          </p>
        </CardContent>
      </Card>

      {/* 4. Save flow + guards */}
      <Card>
        <CardHeader><CardTitle>4 · Save flow &amp; guards</CardTitle></CardHeader>
        <CardContent className="space-y-3 text-sm">
          <ol className="list-decimal pl-5 space-y-1.5 text-muted-foreground">
            <li>On <span className="text-foreground font-medium">Save</span>, the page validates: month &amp; year present, not a future period, ≥1 department, at least one employee, <span className="text-foreground font-medium">attendance exists</span> for the month, and Present + Absent ≤ {daysInMonth}.</li>
            <li>POST <code className={term}>/api/salary-entries</code> with {`{ month, year, departmentIds, details[] }`}.</li>
            <li>Backend runs a <span className="text-foreground font-medium">DB transaction</span>: duplicate guard on (employee, month, year) → insert one header (posted=false) → insert detail rows → returns 201.</li>
            <li>Until <span className="text-foreground font-medium">posted</span>, the entry can be edited (PUT) or deleted. Once posted it becomes read-only; un-post to modify.</li>
          </ol>
        </CardContent>
      </Card>
    </div>
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
                {d.attendanceOnly ? (
                  <span className="text-[11px] sm:text-xs font-medium text-indigo-600 bg-indigo-100/70 dark:bg-indigo-900/40 dark:text-indigo-300 px-2 py-0.5 rounded-full">Attendance only</span>
                ) : (
                  <span className="text-xs sm:text-sm text-muted-foreground">{d.machines?.length ?? 0} machine{(d.machines?.length ?? 0) === 1 ? "" : "s"}</span>
                )}
              </div>
              {d.attendanceOnly ? (
                <div className="divide-y divide-border/60">
                  <div className="px-3 py-2 sm:px-4 sm:py-2.5 text-sm text-muted-foreground">
                    No production transaction this day — marked Present in Attendance, so credited the daily basic salary.
                  </div>
                  <div className="flex items-center justify-between gap-2 px-3 py-2 sm:px-4 sm:py-2.5">
                    <span className="text-xs sm:text-sm text-muted-foreground">Daily basic salary</span>
                    <span className="text-sm sm:text-base font-mono font-semibold">{fmtMoney(d.dailyBasic)}</span>
                  </div>
                  <div className="flex items-center justify-between gap-2 bg-muted/20 px-3 py-2 sm:px-4 sm:py-2.5">
                    <span className="text-xs sm:text-sm text-muted-foreground">Credited (attendance only)</span>
                    <span className="text-sm sm:text-base font-mono font-bold text-green-700">{fmtMoney(d.credited)}</span>
                  </div>
                </div>
              ) : (
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
              )}
            </div>
          ))}
        </div>

        <p className="text-xs sm:text-sm text-muted-foreground">
          Per machine: production = net weight × machine making rate. Credited per day =
          max(daily production sum, daily basic salary). Days marked "Attendance only" have no
          production that day — present in Attendance — and are credited the daily basic salary.
          Total salary = sum of credited days. Daily basic salary: <span className="font-medium">{fmtMoney(toNum(row?.basicSalary ?? 0))}</span>.
        </p>
      </DialogContent>
    </Dialog>
  );
}
