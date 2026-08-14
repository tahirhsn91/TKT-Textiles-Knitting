import { Router, type IRouter } from "express";
import { eq, and, desc, sql, gte, lte } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  machineMaintenanceTable,
  machineMasterTable,
  insertMachineMaintenanceSchema,
} from "../db/index.js";
import { validateBody } from "../lib/validate.js";

const router: IRouter = Router();

// ─── Validation ────────────────────────────────────────────────────────────

const machineSchema = insertMachineMaintenanceSchema.extend({
  maintenanceDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Date (YYYY-MM-DD) is required"),
  machineId: z.coerce.number().int().positive("Machine is required"),
  maintenanceWork: z.string().min(1, "Maintenance work is required"),
  cost: z.coerce.number().min(0, "Cost must be zero or greater").optional().nullable(),
  vendor: z.string().optional().nullable(),
  createdBy: z.string().min(1, "Enter your name"),
  updatedBy: z.string().optional(),
});

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

const STATUSES = z.enum(["submitted", "cancelled"]);

// ─── List (paginated, by date + status) ────────────────────────────────────

router.get("/maintenance/machine", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();
  const statusRaw = typeof req.query.status === "string" ? req.query.status : "submitted";
  const page = Math.max(parseInt(String(req.query.page ?? "1"), 10) || 1, 1);
  const pageSize = Math.min(Math.max(parseInt(String(req.query.pageSize ?? "50"), 10) || 50, 1), 200);

  const status = STATUSES.safeParse(statusRaw).success ? statusRaw : "submitted";

  const where = and(
    eq(machineMaintenanceTable.maintenanceDate, date),
    eq(machineMaintenanceTable.status, status),
  );

  const [{ total }] = await db
    .select({ total: sql<number>`count(*)::int` })
    .from(machineMaintenanceTable)
    .where(where);

  // Cost totals over SUBMITTED records only (cancelled rows are not spend).
  // Day = the selected date; Month = 1st of the month through the selected
  // date, matching the month-to-date convention on the daily-operation pages.
  const monthStart = `${date.slice(0, 7)}-01`;
  const activeStatus = "submitted";
  const [dayCost] = await db
    .select({ sum: sql<string>`coalesce(sum(${machineMaintenanceTable.cost}), 0)` })
    .from(machineMaintenanceTable)
    .where(and(
      eq(machineMaintenanceTable.maintenanceDate, date),
      eq(machineMaintenanceTable.status, activeStatus),
    ));
  const [monthCost] = await db
    .select({ sum: sql<string>`coalesce(sum(${machineMaintenanceTable.cost}), 0)` })
    .from(machineMaintenanceTable)
    .where(and(
      gte(machineMaintenanceTable.maintenanceDate, monthStart),
      lte(machineMaintenanceTable.maintenanceDate, date),
      eq(machineMaintenanceTable.status, activeStatus),
    ));

  // Per-day cost + job count from the 1st of the month through the selected
  // date, for the month trend chart (submitted records only). Frontend fills
  // any day gaps.
  const monthSeries = await db
    .select({
      date: machineMaintenanceTable.maintenanceDate,
      jobs: sql<number>`count(*)::int`,
      cost: sql<string>`coalesce(sum(${machineMaintenanceTable.cost}), 0)`,
    })
    .from(machineMaintenanceTable)
    .where(and(
      gte(machineMaintenanceTable.maintenanceDate, monthStart),
      lte(machineMaintenanceTable.maintenanceDate, date),
      eq(machineMaintenanceTable.status, activeStatus),
    ))
    .groupBy(machineMaintenanceTable.maintenanceDate)
    .orderBy(machineMaintenanceTable.maintenanceDate);

  const rows = await db
    .select({
      id: machineMaintenanceTable.id,
      maintenanceDate: machineMaintenanceTable.maintenanceDate,
      machineId: machineMaintenanceTable.machineId,
      machineNumber: machineMasterTable.machineNumber,
      machineName: machineMasterTable.name,
      maintenanceWork: machineMaintenanceTable.maintenanceWork,
      cost: machineMaintenanceTable.cost,
      vendor: machineMaintenanceTable.vendor,
      status: machineMaintenanceTable.status,
      createdBy: machineMaintenanceTable.createdBy,
    })
    .from(machineMaintenanceTable)
    .leftJoin(machineMasterTable, eq(machineMaintenanceTable.machineId, machineMasterTable.id))
    .where(where)
    .orderBy(desc(machineMaintenanceTable.maintenanceDate), desc(machineMaintenanceTable.id))
    .limit(pageSize)
    .offset((page - 1) * pageSize);

  res.json({
    maintenanceDate: date,
    page,
    pageSize,
    total,
    rows,
    dayTotalCost: dayCost?.sum ?? "0",
    monthToDateCost: monthCost?.sum ?? "0",
    monthSeries,
  });
});

// ─── Detail ────────────────────────────────────────────────────────────────

router.get("/maintenance/machine/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }

  const [row] = await db
    .select({
      id: machineMaintenanceTable.id,
      maintenanceDate: machineMaintenanceTable.maintenanceDate,
      machineId: machineMaintenanceTable.machineId,
      machineNumber: machineMasterTable.machineNumber,
      machineName: machineMasterTable.name,
      maintenanceWork: machineMaintenanceTable.maintenanceWork,
      cost: machineMaintenanceTable.cost,
      vendor: machineMaintenanceTable.vendor,
      status: machineMaintenanceTable.status,
      createdBy: machineMaintenanceTable.createdBy,
      updatedBy: machineMaintenanceTable.updatedBy,
      createdAt: machineMaintenanceTable.createdAt,
      updatedAt: machineMaintenanceTable.updatedAt,
    })
    .from(machineMaintenanceTable)
    .leftJoin(machineMasterTable, eq(machineMaintenanceTable.machineId, machineMasterTable.id))
    .where(eq(machineMaintenanceTable.id, id));

  if (!row) {
    res.status(404).json({ error: "Machine maintenance record not found" });
    return;
  }
  res.json(row);
});

// ─── Create ────────────────────────────────────────────────────────────────

router.post("/maintenance/machine", validateBody(machineSchema), async (req, res): Promise<void> => {
  const { maintenanceDate, machineId, maintenanceWork, cost, vendor, createdBy } = req.body as unknown as z.infer<typeof machineSchema>;

  const [row] = await db
    .insert(machineMaintenanceTable)
    .values({
      maintenanceDate,
      machineId,
      maintenanceWork,
      cost: cost != null ? String(cost) : null,
      vendor: vendor?.trim() ? vendor.trim() : null,
      createdBy,
    })
    .returning({ id: machineMaintenanceTable.id });

  res.status(201).json({ id: row.id });
});

// ─── Update ────────────────────────────────────────────────────────────────

router.put("/maintenance/machine/:id", validateBody(machineSchema), async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }

  const { maintenanceDate, machineId, maintenanceWork, cost, vendor, createdBy, updatedBy } = req.body as unknown as z.infer<typeof machineSchema>;

  const [row] = await db
    .update(machineMaintenanceTable)
    .set({
      maintenanceDate,
      machineId,
      maintenanceWork,
      cost: cost != null ? String(cost) : null,
      vendor: vendor?.trim() ? vendor.trim() : null,
      updatedBy: updatedBy ?? createdBy,
      updatedAt: new Date(),
    })
    .where(and(eq(machineMaintenanceTable.id, id), eq(machineMaintenanceTable.status, "submitted")))
    .returning({ id: machineMaintenanceTable.id });

  if (!row) {
    // Either the record doesn't exist, or it's cancelled (read-only).
    res.status(404).json({ error: "Machine maintenance record not found or is cancelled" });
    return;
  }
  res.json({ id });
});

// ─── Soft-delete (cancel) & restore ────────────────────────────────────────

router.patch("/maintenance/machine/:id/status", validateBody(z.object({ status: STATUSES })), async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }
  const { status } = req.body as unknown as { status: z.infer<typeof STATUSES> };
  const bodyAny = req.body as { updatedBy?: string | null };
  const by = typeof bodyAny.updatedBy === "string" ? bodyAny.updatedBy.trim() : null;

  const [row] = await db
    .update(machineMaintenanceTable)
    .set({
      status,
      updatedBy: by ?? null,
      updatedAt: new Date(),
    })
    .where(eq(machineMaintenanceTable.id, id))
    .returning({ id: machineMaintenanceTable.id, status: machineMaintenanceTable.status });

  if (!row) {
    res.status(404).json({ error: "Machine maintenance record not found" });
    return;
  }
  res.json({ id, status: row.status });
});

export default router;
