import { useState, useEffect, useMemo, useCallback } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Save, Lock, CalendarDays, Users, Sun } from "lucide-react";
import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
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
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];
const CURRENT_YEAR = new Date().getFullYear();
const CURRENT_MONTH = new Date().getMonth() + 1; // 1-12
// Years offered in the dropdown: a few past years up to the current year
// (future years are excluded) — same range as Payroll Maintenance.
const SELECTABLE_YEARS = Array.from({ length: 4 }, (_, i) => CURRENT_YEAR - 3 + i);

function toNum(v: unknown): number {
  const n = parseFloat(String(v ?? ""));
  return isNaN(n) ? 0 : n;
}

// YYYY-MM-DD formatted date for the nth day of a month (1-based).
function dateForDay(year: number, month: number, day: number): string {
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}
// True when the given day is a Sunday.
function isSunday(year: number, month: number, day: number): boolean {
  return new Date(year, month - 1, day).getDay() === 0;
}
// Today as YYYY-MM-DD (used to disable future dates within a month).
function todayIso(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}
// Days in a month.
function daysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

// Weekday short label for a day of a month (0=Sun ... 6=Sat).
const WEEKDAYS = ["S", "M", "T", "W", "T", "F", "S"];
function weekdayOf(year: number, month: number, day: number): string {
  return WEEKDAYS[new Date(year, month - 1, day).getDay()];
}

async function apiFetch<T = unknown>(path: string, opts?: RequestInit): Promise<T> {
  try {
    return await customFetch<T>(path, opts ?? { method: "GET" });
  } catch (err) {
    throw err instanceof Error ? err : new Error(`HTTP request failed`);
  }
}

interface Department { id: number; name: string; code: string; }
interface Employee {
  id: number; name: string; code: string; active: boolean;
  departmentId: number | null; baseSalary: string | null;
}
interface AttendanceRecord {
  employeeId: number;
  attendanceDate: string;
  present: boolean;
}
interface AttendanceMonth {
  month: number; year: number; daysInMonth: number;
  operatorDepartmentId: number | null;
  payrollExists: boolean;
  records: AttendanceRecord[];
}
// Cell state keyed by `${employeeId}:${date}` → present boolean.
type CellMap = Map<string, boolean>;

export default function AttendancePage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isMobile = useIsMobile();
  const [month, setMonth] = useState(String(CURRENT_MONTH));
  const [year, setYear] = useState(String(CURRENT_YEAR));

  const { data: employees = [] } = useQuery<Employee[]>({
    queryKey: ["employee-full-lookup"],
    queryFn: () => apiFetch("/api/lookups/employee-master"),
  });
  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ["dept-lookup"],
    queryFn: () => apiFetch("/api/lookups/department-master"),
  });
  const deptNameById = useMemo(() => {
    const m = new Map<number, string>();
    for (const d of departments) m.set(d.id, d.name);
    return m;
  }, [departments]);

  const m = parseInt(month) || 1;
  const y = parseInt(year) || CURRENT_YEAR;
  const daysInThisMonth = daysInMonth(y, m);
  const tIso = todayIso();
  // days 1..daysInThisMonth as "YYYY-MM-DD"; future (after today) excluded.
  const dayList = useMemo(() => {
    const out: string[] = [];
    for (let d = 1; d <= daysInThisMonth; d++) {
      const iso = dateForDay(y, m, d);
      if (iso > tIso) break;
      out.push(iso);
    }
    return out;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [m, y, daysInThisMonth, tIso]);

  // Loaded attendance for the month (from server).
  const { data: att, isLoading, refetch } = useQuery<AttendanceMonth>({
    queryKey: ["attendance", month, year],
    queryFn: () => apiFetch(`/api/attendance?month=${month}&year=${year}`),
  });

  // operatorDepartmentId from the server; used to decide Sunday auto-check.
  const operatorDeptId = att?.operatorDepartmentId ?? null;
  // Active employees, grouped by department for the department filter.
  const activeEmployees = useMemo(
    () => employees.filter((e) => e.active),
    [employees]
  );
  const [deptFilter, setDeptFilter] = useState<string>("all");

  // Local cell state seeded from server records once they load.
  const [cells, setCells] = useState<CellMap>(new Map());
  useEffect(() => {
    if (!att) return;
    const map = new Map<string, boolean>();
    for (const r of att.records) {
      map.set(`${r.employeeId}:${r.attendanceDate}`, r.present);
    }
    setCells(map);
  }, [att]);

  const isEditDisabled = att?.payrollExists === true;

  // Toggle a single day cell (present <-> absent). Disabled for future dates.
  const toggleCell = useCallback(
    (employeeId: number, date: string) => {
      if (isEditDisabled || date > tIso) return;
      setCells((prev) => {
        const key = `${employeeId}:${date}`;
        const next = new Map(prev);
        next.set(key, !(prev.get(key) ?? false));
        return next;
      });
    },
    [isEditDisabled, tIso]
  );

  const saveMutation = useMutation({
    mutationFn: (body: object) =>
      apiFetch("/api/attendance", { method: "PUT", body: JSON.stringify(body) }),
    onSuccess: async () => {
      toast({ title: "Attendance saved." });
      await queryClient.invalidateQueries({ queryKey: ["attendance", month, year] });
      await refetch();
    },
    onError: (e: Error) =>
      toast({ variant: "destructive", title: "Error", description: e.message }),
  });

  function handleSave() {
    if (isEditDisabled) {
      toast({ variant: "destructive", title: "Error", description: "Attendance for this month is locked because a payroll entry exists." });
      return;
    }
    const selY = parseInt(year);
    const selM = parseInt(month);
    if (selY > CURRENT_YEAR || (selY === CURRENT_YEAR && selM > CURRENT_MONTH)) {
      toast({ variant: "destructive", title: "Validation", description: "Future month/year cannot be selected." });
      return;
    }
    // Build the whole-month record set (saved Sundays included, per spec only
    // the disabled future days are excluded).
    const records: Array<{ employeeId: number; attendanceDate: string; present: boolean }> = [];
    for (const emp of activeEmployees) {
      for (const date of dayList) {
        const key = `${emp.id}:${date}`;
        records.push({ employeeId: emp.id, attendanceDate: date, present: cells.get(key) ?? false });
      }
    }
    saveMutation.mutate({ month: selM, year: selY, records });
  }

  // Filtered rows: only active employees, plus the department filter.
  const rows = useMemo(() => {
    return deptFilter === "all"
      ? activeEmployees
      : activeEmployees.filter((e) => e.departmentId !== null && String(e.departmentId) === deptFilter);
  }, [activeEmployees, deptFilter]);

  if (isLoading) {
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
      <div className="flex flex-col gap-4 pb-16 md:pb-0">
        {/* Header with period context */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Attendance</h1>
            <p className="text-muted-foreground text-sm mt-0.5">
              Mark daily presence. Sundays auto-check as Present for non-operators.
              Operators are shown for manual attendance only.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Badge variant="secondary" className="gap-1.5 text-xs">
              <CalendarDays className="h-3.5 w-3.5" />
              {MONTHS[m - 1]} {y}
            </Badge>
            <Badge variant="secondary" className="gap-1.5 text-xs">
              <Users className="h-3.5 w-3.5" />
              {rows.length} emp
            </Badge>
            <Badge variant="secondary" className="gap-1.5 text-xs">
              <Sun className="h-3.5 w-3.5 text-amber-500" />
              {dayList.length}/{daysInThisMonth} days
            </Badge>
            {isEditDisabled && (
              <Badge variant="outline" className="gap-1.5 text-xs text-amber-600 border-amber-300">
                <Lock className="h-3.5 w-3.5" /> Payroll exists
              </Badge>
            )}
          </div>
        </div>

        {/* Controls: month, year, department filter, save */}
        <Card>
          <CardContent className="pt-4">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:flex-wrap">
              <div className="grid grid-cols-2 gap-3 sm:flex sm:flex-wrap sm:items-end sm:gap-4 grow">
                <div className="flex flex-col gap-1">
                  <Label>Month</Label>
                  <Select value={month} onValueChange={setMonth}>
                    <SelectTrigger className="w-full sm:w-40"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {MONTHS.map((name, i) => {
                        const mm = i + 1;
                        const isFutureMon = parseInt(year) === CURRENT_YEAR && mm > CURRENT_MONTH;
                        return (
                          <SelectItem key={mm} value={String(mm)} disabled={isFutureMon}>{name}</SelectItem>
                        );
                      })}
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex flex-col gap-1">
                  <Label>Year</Label>
                  <Select value={year} onValueChange={setYear}>
                    <SelectTrigger className="w-full sm:w-28"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {SELECTABLE_YEARS.map((yy) => (
                        <SelectItem key={yy} value={String(yy)}>{yy}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex flex-col gap-1 col-span-2 sm:col-span-1">
                  <Label>Department</Label>
                  <Select value={deptFilter} onValueChange={setDeptFilter}>
                    <SelectTrigger className="w-full sm:w-48"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Departments</SelectItem>
                      {departments.map((d) => (
                        <SelectItem key={d.id} value={String(d.id)}>{d.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              {/* Desktop save */}
              <Button
                onClick={handleSave}
                disabled={isEditDisabled || saveMutation.isPending}
                className="hidden md:inline-flex"
              >
                <Save className="mr-2 h-4 w-4" />
                {isEditDisabled ? "Locked" : "Save Attendance"}
              </Button>
            </div>
            {isEditDisabled && (
              <p className="mt-3 text-xs text-amber-600 flex items-center gap-1.5">
                <Lock className="h-3.5 w-3.5" />
                A payroll entry exists for {MONTHS[month ? parseInt(month) - 1 : 0]} {year}, so attendance is locked.
              </p>
            )}

            {/* Legend */}
            <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
              <span className="inline-flex items-center gap-1.5">
                <span className="inline-block h-3.5 w-3.5 rounded bg-green-600"></span> Present
              </span>
              <span className="inline-flex items-center gap-1.5">
                <span className="inline-block h-3.5 w-3.5 rounded bg-muted/60 border border-border"></span> Absent
              </span>
              <span className="inline-flex items-center gap-1.5">
                <span className="inline-block h-3.5 w-3.5 rounded bg-amber-100 ring-1 ring-amber-400"></span> Sunday (auto)
              </span>
              <span className="inline-flex items-center gap-1 text-muted-foreground/70">
                Days shown: <span className="font-semibold">{dayList.length}</span> of {daysInThisMonth} (future disabled)
              </span>
            </div>
          </CardContent>
        </Card>

        {/* Attendance grid: employees as rows, one column per day */}
        <Card className="overflow-hidden">
          <CardContent className="p-0 overflow-x-auto">
            <Table className="border-collapse">
              <TableHeader>
                {/* Weekday + day-number header */}
                <TableRow className="text-[10px] uppercase tracking-wide text-muted-foreground">
                  <TableHead className="sticky left-0 z-20 bg-card min-w-[150px] md:min-w-[170px] border-r border-border/60">Employee</TableHead>
                  {dayList.map((date) => {
                    const dayNum = parseInt(date.slice(8, 10), 10);
                    const sun = isSunday(y, m, dayNum);
                    const wd = weekdayOf(y, m, dayNum);
                    return (
                      <TableHead
                        key={date}
                        className={cn("text-center min-w-[34px] md:min-w-[38px] px-0 py-1", sun && "text-amber-600")}
                      >
                        <span className="block text-[9px] font-semibold">{wd}</span>
                        <span className="block">{dayNum}</span>
                      </TableHead>
                    );
                  })}
                  <TableHead
                    className="sticky right-0 z-20 bg-card min-w-[72px] border-l border-border/60 text-right"
                    title="Total present days for the month"
                  >
                    Present
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((emp, i) => {
                  const isOperator = operatorDeptId !== null && emp.departmentId === operatorDeptId;
                  const striped = i % 2 === 0;
                  const rowBg = striped ? "bg-[hsl(var(--muted))]" : "bg-card";
                  const presentCount = dayList.filter((d) => cells.get(`${emp.id}:${d}`)).length;
                  return (
                    <TableRow key={emp.id} className={rowBg}>
                      <TableCell className={`sticky left-0 z-10 ${rowBg} border-r border-border/60 font-medium text-sm py-1`}>
                        <div className="flex flex-col leading-tight">
                          <span className="truncate">{emp.name}</span>
                          <span className="text-[10px] text-muted-foreground font-normal">
                            {deptNameById.get(emp.departmentId ?? -1) ?? "No Dept"}
                            {isOperator && <span className="text-amber-600"> · Operator</span>}
                          </span>
                        </div>
                      </TableCell>
                      {dayList.map((date) => {
                        const dayNum = parseInt(date.slice(8, 10), 10);
                        const sun = isOperator ? false : isSunday(y, m, dayNum);
                        const checked = cells.get(`${emp.id}:${date}`) ?? false;
                        const isFuture = date > tIso;
                        // Pre-check Sundays for non-operators even when not yet saved
                        // (visual default; saved only on Save). Use saved value if a
                        // record already exists for the cell.
                        const effective = cells.has(`${emp.id}:${date}`)
                          ? checked
                          : isEditDisabled
                            ? checked
                            : sun ? true : false;
                        const cellCls = cn(
                          // Swell the tap target on touch devices for accurate toggles.
                          "flex items-center justify-center rounded transition-colors select-none",
                          isMobile
                            ? "h-9 w-9 text-sm"
                            : "h-7 w-7 text-xs",
                          effective
                            ? "bg-green-600 text-white hover:bg-green-700"
                            : "bg-muted/60 text-muted-foreground hover:bg-muted",
                          sun && !effective && !isFuture && "ring-1 ring-amber-400 bg-amber-50",
                          isFuture && "opacity-30 cursor-not-allowed hover:bg-muted/60",
                          isEditDisabled && "opacity-70 cursor-not-allowed"
                        );
                        return (
                          <TableCell key={date} className="py-1 px-0.5 md:px-1 text-center">
                            <button
                              type="button"
                              disabled={isEditDisabled || isFuture}
                              onClick={() => toggleCell(emp.id, date)}
                              aria-pressed={effective}
                              aria-label={`${emp.name}, ${MONTHS[m - 1]} ${dayNum}${sun ? " (Sunday)" : ""}: ${effective ? "Present" : "Absent"}`}
                              className={cellCls}
                              title={effective ? "Present" : "Absent"}
                            >
                              {effective ? "✓" : sun ? "" : ""}
                            </button>
                          </TableCell>
                        );
                      })}
                      <TableCell className={`sticky right-0 z-10 ${rowBg} border-l border-border/60 py-1 px-2 text-right font-mono text-sm font-semibold`}>
                        {presentCount}
                      </TableCell>
                    </TableRow>
                  );
                })}
                {rows.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={dayList.length + 2} className="text-center text-muted-foreground py-6">
                      No active employees for the selected filter.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>

        {/* Mobile sticky save bar */}
        <div className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-background/95 backdrop-blur p-3 md:hidden">
          <Button
            onClick={handleSave}
            disabled={isEditDisabled || saveMutation.isPending}
            className="w-full"
          >
            <Save className="mr-2 h-4 w-4" />
            {isEditDisabled ? "Attendance Locked" : "Save Attendance"}
          </Button>
        </div>
      </div>
    </Layout>
  );
}
