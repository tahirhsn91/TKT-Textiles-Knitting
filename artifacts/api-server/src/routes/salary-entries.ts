import { Router, type IRouter } from "express";
import { eq, and, inArray } from "drizzle-orm";
import { db } from "@workspace/db";
import {
  salaryHeaderTable,
  salaryDetailTable,
  machineOperatorMasterTable,
  departmentMasterTable,
} from "@workspace/db";

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

  const allHeaders = await db
    .select()
    .from(salaryHeaderTable)
    .orderBy(salaryHeaderTable.year, salaryHeaderTable.month);

  const depts = await db.select().from(departmentMasterTable);
  const deptMap = Object.fromEntries(depts.map((d) => [d.id, d.name]));

  let filtered = allHeaders;
  if (month) filtered = filtered.filter((h) => h.month === parseInt(month));
  if (year) filtered = filtered.filter((h) => h.year === parseInt(year));
  if (departmentId) {
    const did = parseInt(departmentId);
    filtered = filtered.filter((h) => (h.departmentIds ?? []).includes(did));
  }

  const result = filtered.map((h) => ({
    ...h,
    departmentNames: (h.departmentIds ?? []).map((id) => deptMap[id] ?? String(id)),
  }));

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
    .orderBy(salaryDetailTable.operatorName);

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
      operatorId: number;
      departmentId?: number | null;
      operatorName: string;
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

  const operatorIds = details.map((d) => d.operatorId);

  // Enforce DB-level uniqueness: check if any (operatorId, month, year) already exists
  const existingDetails = await db
    .select({ operatorId: salaryDetailTable.operatorId })
    .from(salaryDetailTable)
    .where(
      and(
        eq(salaryDetailTable.month, month),
        eq(salaryDetailTable.year, year),
        inArray(salaryDetailTable.operatorId, operatorIds)
      )
    );

  if (existingDetails.length > 0) {
    const ops = await db
      .select({ id: machineOperatorMasterTable.id, name: machineOperatorMasterTable.name })
      .from(machineOperatorMasterTable)
      .where(inArray(machineOperatorMasterTable.id, existingDetails.map((e) => e.operatorId)));
    const names = ops.map((o) => o.name).join(", ");
    res.status(409).json({ error: `Duplicate: salary already entered for ${names} in ${month}/${year}` });
    return;
  }

  const [header] = await db
    .insert(salaryHeaderTable)
    .values({ month, year, departmentIds, posted: false })
    .returning();

  const detailRows = details.map((d) => ({
    headerId: header.id,
    operatorId: d.operatorId,
    month,
    year,
    departmentId: d.departmentId ?? null,
    operatorName: d.operatorName,
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

  const insertedDetails = await db.insert(salaryDetailTable).values(detailRows).returning();
  res.status(201).json({ ...header, details: insertedDetails });
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
      operatorId: number;
      departmentId?: number | null;
      operatorName: string;
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

  const operatorIds = details.map((d) => d.operatorId);

  // Duplicate check: same (operatorId, month, year) on a DIFFERENT header's details
  const existingDetails = await db
    .select({ operatorId: salaryDetailTable.operatorId, headerId: salaryDetailTable.headerId })
    .from(salaryDetailTable)
    .where(
      and(
        eq(salaryDetailTable.month, month),
        eq(salaryDetailTable.year, year),
        inArray(salaryDetailTable.operatorId, operatorIds)
      )
    );

  const conflicts = existingDetails.filter((e) => e.headerId !== id);
  if (conflicts.length > 0) {
    const ops = await db
      .select({ id: machineOperatorMasterTable.id, name: machineOperatorMasterTable.name })
      .from(machineOperatorMasterTable)
      .where(inArray(machineOperatorMasterTable.id, conflicts.map((e) => e.operatorId)));
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
    operatorId: d.operatorId,
    month,
    year,
    departmentId: d.departmentId ?? null,
    operatorName: d.operatorName,
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
