import { Router, type IRouter } from "express";
import { eq, and, inArray, gte, lte, sql } from "drizzle-orm";
import { db } from "../db/index.js";
import { isUniqueViolation } from "../lib/db-errors.js";
import {
  salaryHeaderTable,
  salaryDetailTable,
  employeeMasterTable,
  departmentMasterTable,
  transactionHeaderTable,
  transactionDetailTable,
  transactionTypeMasterTable,
  machineMasterTable,
} from "../db/index.js";

const router: IRouter = Router();

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id);
  return isNaN(id) ? null : id;
}


function toNum(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

// ─── List headers ─────────────────────────────────────────────────────────────

router.get("/salary-entries", async (req, res): Promise<void> => {
  const { month, year, departmentId } = req.query as Record<string, string | undefined>;

  // Push the filters into SQL instead of loading every header ever saved and
  // filtering in JS (the list screen would otherwise grow unbounded). The
  // `sql false` branches preserve the old in-memory behaviour for malformed
  // query params: a NaN month/year (or an unknown department) matched nothing.
  const conditions = [];
  if (month) {
    const m = parseInt(month, 10);
    conditions.push(Number.isNaN(m) ? sql`false` : eq(salaryHeaderTable.month, m));
  }
  if (year) {
    const y = parseInt(year, 10);
    conditions.push(Number.isNaN(y) ? sql`false` : eq(salaryHeaderTable.year, y));
  }
  if (departmentId) {
    const did = parseInt(departmentId, 10);
    // department_ids is an int[] column; @> is the "array contains" test.
    conditions.push(Number.isNaN(did) ? sql`false` : sql`${salaryHeaderTable.departmentIds} @> ARRAY[${did}]::int[]`);
  }

  const headers = await db
    .select()
    .from(salaryHeaderTable)
    .where(conditions.length > 0 ? and(...conditions) : undefined)
    .orderBy(salaryHeaderTable.year, salaryHeaderTable.month);

  const depts = await db.select().from(departmentMasterTable);
  const deptMap = Object.fromEntries(depts.map((d) => [d.id, d.name]));

  const result = headers.map((h) => ({
    ...h,
    departmentNames: (h.departmentIds ?? []).map((id) => deptMap[id] ?? String(id)),
  }));

  res.json(result);
});

// ─── Operator production-based salary ──────────────────────────────────────────
// Employees in department code "0002" (Operator) are paid on production rather
// than attendance: for each Fabric Production transaction in the selected
// month, a row's value = netWt × machine.makingRate. Per (employee, day) the
// credited amount is max(daily production sum, the operator's daily basic
// salary). Present days = number of distinct days with production. Total salary
// = sum of per-day credited. Returns both the per-employee aggregate and the
// per-day breakdown.
// NOTE: declared before /:id so Express routes this specific path correctly.
router.get("/salary-entries/operator-production", async (req, res): Promise<void> => {
  const { month, year } = req.query as Record<string, string>;
  if (!month || !year) {
    res.status(400).json({ error: "month and year are required" });
    return;
  }
  const m = parseInt(month);
  const y = parseInt(year);
  const dateFrom = `${y}-${String(m).padStart(2, "0")}-01`;
  const lastDay = new Date(y, m, 0).getDate();
  const dateTo = `${y}-${String(m).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

  // Resolve the Fabric Production transaction type and the Operator department.
  const [fabricProd] = await db
    .select()
    .from(transactionTypeMasterTable)
    .where(eq(transactionTypeMasterTable.code, "Fabric_Production"));
  const [operatorDept] = await db
    .select()
    .from(departmentMasterTable)
    .where(eq(departmentMasterTable.code, "0002"));
  if (!fabricProd || !operatorDept) {
    res.status(500).json({ error: "Fabric Production type or Operator department is not configured" });
    return;
  }

  // Operators (employees in the Operator department).
  const operators = await db
    .select({ id: employeeMasterTable.id, name: employeeMasterTable.name, baseSalary: employeeMasterTable.baseSalary })
    .from(employeeMasterTable)
    .where(eq(employeeMasterTable.departmentId, operatorDept.id));

  // Fabric Production headers within the selected month.
  const headers = await db
    .select()
    .from(transactionHeaderTable)
    .where(
      and(
        eq(transactionHeaderTable.transactionTypeId, fabricProd.id),
        gte(transactionHeaderTable.date, dateFrom),
        lte(transactionHeaderTable.date, dateTo)
      )
    );
  const headerIds = headers.map((h) => h.id);
  const headerDateById = new Map(headers.map((h) => [h.id, h.date]));

  // Machine making rates (netWt × makingRate per row).
  const machines = await db
    .select()
    .from(machineMasterTable);
  const rateByMachineId = new Map(machines.map((mc) => [mc.id, toNum(mc.makingRate)]));
  const nameByMachineId = new Map(machines.map((mc) => [mc.id, mc.name ?? mc.machineNumber]));

  // Detail rows for those headers.
  const details = headerIds.length
    ? await db
        .select()
        .from(transactionDetailTable)
        .where(inArray(transactionDetailTable.headerId, headerIds))
    : [];

  // Daily breakdown keyed by employeeId -> date -> { sum, machines[] }.
  const dailyByEmployee = new Map<number, Map<string, { sum: number; machines: Array<{ machineId: number; machineName: string; netWt: number; rate: number; amount: number }> }>>();
  for (const d of details) {
    if (!d.employeeId) continue;
    const netWt = toNum(d.netWt);
    if (netWt <= 0) continue; // skip null/zero net weight rows
    const rate = rateByMachineId.get(d.machineId ?? -1) ?? 0;
    const date = headerDateById.get(d.headerId) ?? "";
    if (!date) continue;
    let emp = dailyByEmployee.get(d.employeeId);
    if (!emp) { emp = new Map(); dailyByEmployee.set(d.employeeId, emp); }
    const day = emp.get(date) ?? { sum: 0, machines: [] };
    const machineId = d.machineId ?? -1;
    const amount = netWt * rate;
    day.sum += amount;
    day.machines.push({
      machineId,
      machineName: nameByMachineId.get(machineId) ?? String(machineId),
      netWt: Number(netWt.toFixed(3)),
      rate: Number(rate.toFixed(2)),
      amount: Number(amount.toFixed(2)),
    });
    emp.set(date, day);
  }

  const result = operators.map((op) => {
    const daily = dailyByEmployee.get(op.id) ?? new Map<string, { sum: number; machines: Array<{ machineId: number; machineName: string; netWt: number; rate: number; amount: number }> }>();
    const baseSalary = toNum(op.baseSalary); // operator baseSalary is a daily wage
    const days = [...daily.entries()]
      .map(([date, d]) => {
        const credited = Math.max(d.sum, baseSalary);
        return {
          date,
          dailyProductionSum: Number(d.sum.toFixed(2)),
          dailyBasic: baseSalary,
          credited: Number(credited.toFixed(2)),
          machines: d.machines,
        };
      })
      .sort((a, b) => a.date.localeCompare(b.date));
    const totalSalary = days.reduce((acc, d) => acc + d.credited, 0);
    return {
      employeeId: op.id,
      employeeName: op.name,
      presentDays: days.length,
      totalSalary: Number(totalSalary.toFixed(2)),
      days,
    };
  });

  res.json(result);
});

// ─── Get one header + details ──────────────────────────────────────────────────

router.get("/salary-entries/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [header] = await db.select().from(salaryHeaderTable).where(eq(salaryHeaderTable.id, id));
  if (!header) { res.status(404).json({ error: "Not found" }); return; }

  const details = await db
    .select()
    .from(salaryDetailTable)
    .where(eq(salaryDetailTable.headerId, id))
    .orderBy(salaryDetailTable.employeeName);

  const depts = await db.select().from(departmentMasterTable);
  const deptMap = Object.fromEntries(depts.map((d) => [d.id, d.name]));

  res.json({
    ...header,
    departmentNames: (header.departmentIds ?? []).map((did) => deptMap[did] ?? String(did)),
    details,
  });
});

// ─── Create header + details ───────────────────────────────────────────────────

router.post("/salary-entries", async (req, res): Promise<void> => {
  const { month, year, departmentIds, details } = req.body as {
    month: number;
    year: number;
    departmentIds: number[];
    details: Array<{
      employeeId: number;
      departmentId?: number | null;
      employeeName: string;
      basicSalary: number;
      otRateHr: number;
      attAllowance: number;
      othAllowance: number;
      presentDays: number;
      absentDays: number;
      holidays: number;
      totalAttendance: number;
      totalSalary: number;
      otHours: number;
      otAmount: number;
      advanceDeduction: number;
      loanDeduction: number;
      otherDeduction: number;
      payableSalary: number;
    }>;
  };

  if (!month || !year || !Array.isArray(departmentIds) || departmentIds.length === 0) {
    res.status(400).json({ error: "month, year, and departmentIds are required" });
    return;
  }
  if (!Array.isArray(details) || details.length === 0) {
    res.status(400).json({ error: "At least one employee detail row is required" });
    return;
  }

  const employeeIds = details.map((d) => d.employeeId);

  // Enforce DB-level uniqueness inside a single transaction so two concurrent
  // saves for the same employees can't both pass the app-level check. If a
  // duplicate slips through (race), the unique constraint (23505) is caught
  // here and surfaced as a friendly 409 instead of a generic 500 (issue #20).
  try {
    const result = await db.transaction(async (tx) => {
      // Best-effort check — the constraint below is the real backstop.
      const existingDetails = await tx
        .select({ employeeId: salaryDetailTable.employeeId })
        .from(salaryDetailTable)
        .where(
          and(
            eq(salaryDetailTable.month, month),
            eq(salaryDetailTable.year, year),
            inArray(salaryDetailTable.employeeId, employeeIds)
          )
        );

      if (existingDetails.length > 0) {
        const ops = await tx
          .select({ id: employeeMasterTable.id, name: employeeMasterTable.name })
          .from(employeeMasterTable)
          .where(inArray(employeeMasterTable.id, existingDetails.map((e) => e.employeeId)));
        const names = ops.map((o) => o.name).join(", ");
        return { conflict: `Duplicate: salary already entered for ${names} in ${month}/${year}` } as const;
      }

      const [header] = await tx
        .insert(salaryHeaderTable)
        .values({ month, year, departmentIds, posted: false })
        .returning();

      const detailRows = details.map((d) => ({
        headerId: header.id,
        employeeId: d.employeeId,
        month,
        year,
        departmentId: d.departmentId ?? null,
        employeeName: d.employeeName,
        basicSalary: String(toNum(d.basicSalary)),
        otRateHr: String(toNum(d.otRateHr)),
        attAllowance: String(toNum(d.attAllowance)),
        othAllowance: String(toNum(d.othAllowance)),
        presentDays: String(toNum(d.presentDays)),
        absentDays: String(toNum(d.absentDays)),
        holidays: String(toNum(d.holidays)),
        totalAttendance: String(toNum(d.totalAttendance)),
        totalSalary: String(toNum(d.totalSalary)),
        otHours: String(toNum(d.otHours)),
        otAmount: String(toNum(d.otAmount)),
        advanceDeduction: String(toNum(d.advanceDeduction)),
        loanDeduction: String(toNum(d.loanDeduction)),
        otherDeduction: String(toNum(d.otherDeduction)),
        payableSalary: String(toNum(d.payableSalary)),
      }));

      const insertedDetails = await tx.insert(salaryDetailTable).values(detailRows).returning();
      return { header, details: insertedDetails } as const;
    });

    if ("conflict" in result) {
      res.status(409).json({ error: result.conflict });
      return;
    }
    res.status(201).json({ ...result.header, details: result.details });
  } catch (err) {
    if (isUniqueViolation(err)) {
      // A concurrent save won the race — the constraint caught it. Surface the
      // conflicting employees so the user knows exactly what to fix.
      const conflictRows = await db
        .select({ employeeId: salaryDetailTable.employeeId })
        .from(salaryDetailTable)
        .where(
          and(
            eq(salaryDetailTable.month, month),
            eq(salaryDetailTable.year, year),
            inArray(salaryDetailTable.employeeId, employeeIds)
          )
        );
      const ops =
        conflictRows.length > 0
          ? await db
              .select({ id: employeeMasterTable.id, name: employeeMasterTable.name })
              .from(employeeMasterTable)
              .where(inArray(employeeMasterTable.id, conflictRows.map((e) => e.employeeId)))
          : [];
      const conflicting = ops.map((o) => o.name).join(", ") || "this employee(s)";
      res.status(409).json({ error: `Duplicate: salary already entered for ${conflicting} in ${month}/${year}` });
      return;
    }
    throw err;
  }
});

// ─── Update header + details ───────────────────────────────────────────────────

router.put("/salary-entries/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [existing] = await db.select().from(salaryHeaderTable).where(eq(salaryHeaderTable.id, id));
  if (!existing) { res.status(404).json({ error: "Not found" }); return; }
  if (existing.posted) { res.status(409).json({ error: "Cannot edit a posted record. Un-post it first." }); return; }

  const { month, year, departmentIds, details } = req.body as {
    month: number;
    year: number;
    departmentIds: number[];
    details: Array<{
      employeeId: number;
      departmentId?: number | null;
      employeeName: string;
      basicSalary: number;
      otRateHr: number;
      attAllowance: number;
      othAllowance: number;
      presentDays: number;
      absentDays: number;
      holidays: number;
      totalAttendance: number;
      totalSalary: number;
      otHours: number;
      otAmount: number;
      advanceDeduction: number;
      loanDeduction: number;
      otherDeduction: number;
      payableSalary: number;
    }>;
  };

  if (!month || !year || !Array.isArray(departmentIds) || departmentIds.length === 0) {
    res.status(400).json({ error: "month, year, and departmentIds are required" });
    return;
  }

  const employeeIds = details.map((d) => d.employeeId);

  // Duplicate check: same (employeeId, month, year) on a DIFFERENT header's details
  const existingDetails = await db
    .select({ employeeId: salaryDetailTable.employeeId, headerId: salaryDetailTable.headerId })
    .from(salaryDetailTable)
    .where(
      and(
        eq(salaryDetailTable.month, month),
        eq(salaryDetailTable.year, year),
        inArray(salaryDetailTable.employeeId, employeeIds)
      )
    );

  const conflicts = existingDetails.filter((e) => e.headerId !== id);
  if (conflicts.length > 0) {
    const ops = await db
      .select({ id: employeeMasterTable.id, name: employeeMasterTable.name })
      .from(employeeMasterTable)
      .where(inArray(employeeMasterTable.id, conflicts.map((e) => e.employeeId)));
    const names = ops.map((o) => o.name).join(", ");
    res.status(409).json({ error: `Duplicate: salary already entered for ${names} in ${month}/${year}` });
    return;
  }

  const [updated] = await db
    .update(salaryHeaderTable)
    .set({ month, year, departmentIds, updatedAt: new Date() })
    .where(eq(salaryHeaderTable.id, id))
    .returning();

  // Delete existing details and re-insert
  await db.delete(salaryDetailTable).where(eq(salaryDetailTable.headerId, id));

  const detailRows = details.map((d) => ({
    headerId: id,
    employeeId: d.employeeId,
    month,
    year,
    departmentId: d.departmentId ?? null,
    employeeName: d.employeeName,
    basicSalary: String(toNum(d.basicSalary)),
    otRateHr: String(toNum(d.otRateHr)),
    attAllowance: String(toNum(d.attAllowance)),
    othAllowance: String(toNum(d.othAllowance)),
    presentDays: String(toNum(d.presentDays)),
    absentDays: String(toNum(d.absentDays)),
    holidays: String(toNum(d.holidays)),
    totalAttendance: String(toNum(d.totalAttendance)),
    totalSalary: String(toNum(d.totalSalary)),
    otHours: String(toNum(d.otHours)),
    otAmount: String(toNum(d.otAmount)),
    advanceDeduction: String(toNum(d.advanceDeduction)),
    loanDeduction: String(toNum(d.loanDeduction)),
    otherDeduction: String(toNum(d.otherDeduction)),
    payableSalary: String(toNum(d.payableSalary)),
  }));

  const insertedDetails = detailRows.length > 0
    ? await db.insert(salaryDetailTable).values(detailRows).returning()
    : [];

  res.json({ ...updated, details: insertedDetails });
});

// ─── Delete header (cascades to details) ─────────────────────────────────────

router.delete("/salary-entries/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [existing] = await db.select().from(salaryHeaderTable).where(eq(salaryHeaderTable.id, id));
  if (!existing) { res.status(404).json({ error: "Not found" }); return; }
  if (existing.posted) { res.status(409).json({ error: "Cannot delete a posted record. Un-post it first." }); return; }

  await db.delete(salaryHeaderTable).where(eq(salaryHeaderTable.id, id));
  res.sendStatus(204);
});

// ─── Post ─────────────────────────────────────────────────────────────────────

router.post("/salary-entries/:id/post", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [row] = await db
    .update(salaryHeaderTable)
    .set({ posted: true, updatedAt: new Date() })
    .where(eq(salaryHeaderTable.id, id))
    .returning();

  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.json(row);
});

// ─── Unpost ───────────────────────────────────────────────────────────────────

router.post("/salary-entries/:id/unpost", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [row] = await db
    .update(salaryHeaderTable)
    .set({ posted: false, updatedAt: new Date() })
    .where(eq(salaryHeaderTable.id, id))
    .returning();

  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.json(row);
});

export default router;
