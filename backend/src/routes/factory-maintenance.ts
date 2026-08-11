import { Router, type IRouter } from "express";
import { eq, and, desc, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  factoryMaintenanceTable,
  insertFactoryMaintenanceSchema,
} from "../db/index.js";

const router: IRouter = Router();

// ─── Validation ────────────────────────────────────────────────────────────

const factorySchema = insertFactoryMaintenanceSchema.extend({
  maintenanceDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Date (YYYY-MM-DD) is required"),
  category: z.string().min(1, "Category is required"),
  maintenanceWork: z.string().min(1, "Maintenance work is required"),
  createdBy: z.string().min(1, "Enter your name"),
  updatedBy: z.string().optional(),
});

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

const STATUSES = z.enum(["submitted", "cancelled"]);

// ─── List (paginated, by date + status) ────────────────────────────────────

router.get("/maintenance/factory", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();
  const statusRaw = typeof req.query.status === "string" ? req.query.status : "submitted";
  const page = Math.max(parseInt(String(req.query.page ?? "1"), 10) || 1, 1);
  const pageSize = Math.min(Math.max(parseInt(String(req.query.pageSize ?? "50"), 10) || 50, 1), 200);

  const status = STATUSES.safeParse(statusRaw).success ? statusRaw : "submitted";

  const where = and(
    eq(factoryMaintenanceTable.maintenanceDate, date),
    eq(factoryMaintenanceTable.status, status),
  );

  const [{ total }] = await db
    .select({ total: sql<number>`count(*)::int` })
    .from(factoryMaintenanceTable)
    .where(where);

  const rows = await db
    .select({
      id: factoryMaintenanceTable.id,
      maintenanceDate: factoryMaintenanceTable.maintenanceDate,
      category: factoryMaintenanceTable.category,
      maintenanceWork: factoryMaintenanceTable.maintenanceWork,
      status: factoryMaintenanceTable.status,
      createdBy: factoryMaintenanceTable.createdBy,
    })
    .from(factoryMaintenanceTable)
    .where(where)
    .orderBy(desc(factoryMaintenanceTable.maintenanceDate), desc(factoryMaintenanceTable.id))
    .limit(pageSize)
    .offset((page - 1) * pageSize);

  res.json({
    maintenanceDate: date,
    page,
    pageSize,
    total,
    rows,
  });
});

// ─── Detail ────────────────────────────────────────────────────────────────

router.get("/maintenance/factory/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }

  const [row] = await db
    .select({
      id: factoryMaintenanceTable.id,
      maintenanceDate: factoryMaintenanceTable.maintenanceDate,
      category: factoryMaintenanceTable.category,
      maintenanceWork: factoryMaintenanceTable.maintenanceWork,
      status: factoryMaintenanceTable.status,
      createdBy: factoryMaintenanceTable.createdBy,
      updatedBy: factoryMaintenanceTable.updatedBy,
      createdAt: factoryMaintenanceTable.createdAt,
      updatedAt: factoryMaintenanceTable.updatedAt,
    })
    .from(factoryMaintenanceTable)
    .where(eq(factoryMaintenanceTable.id, id));

  if (!row) {
    res.status(404).json({ error: "Factory maintenance record not found" });
    return;
  }
  res.json(row);
});

// ─── Create ────────────────────────────────────────────────────────────────

router.post("/maintenance/factory", async (req, res): Promise<void> => {
  const parsed = factorySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid factory maintenance" });
    return;
  }
  const { maintenanceDate, category, maintenanceWork, createdBy } = parsed.data;

  const [row] = await db
    .insert(factoryMaintenanceTable)
    .values({
      maintenanceDate,
      category: category.trim() || "Other",
      maintenanceWork,
      createdBy,
    })
    .returning({ id: factoryMaintenanceTable.id });

  res.status(201).json({ id: row.id });
});

// ─── Update ────────────────────────────────────────────────────────────────

router.put("/maintenance/factory/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }

  const parsed = factorySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid factory maintenance" });
    return;
  }
  const { maintenanceDate, category, maintenanceWork, createdBy, updatedBy } = parsed.data;

  const [row] = await db
    .update(factoryMaintenanceTable)
    .set({
      maintenanceDate,
      category: category.trim() || "Other",
      maintenanceWork,
      updatedBy: updatedBy ?? createdBy,
      updatedAt: new Date(),
    })
    .where(and(eq(factoryMaintenanceTable.id, id), eq(factoryMaintenanceTable.status, "submitted")))
    .returning({ id: factoryMaintenanceTable.id });

  if (!row) {
    res.status(404).json({ error: "Factory maintenance record not found or is cancelled" });
    return;
  }
  res.json({ id });
});

// ─── Soft-delete (cancel) & restore ────────────────────────────────────────

router.patch("/maintenance/factory/:id/status", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }
  const parsed = z.object({ status: STATUSES }).safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Status must be 'submitted' or 'cancelled'" });
    return;
  }
  const { status } = parsed.data;
  const by = typeof req.body.updatedBy === "string" ? req.body.updatedBy.trim() : null;

  const [row] = await db
    .update(factoryMaintenanceTable)
    .set({
      status,
      updatedBy: by ?? null,
      updatedAt: new Date(),
    })
    .where(eq(factoryMaintenanceTable.id, id))
    .returning({ id: factoryMaintenanceTable.id, status: factoryMaintenanceTable.status });

  if (!row) {
    res.status(404).json({ error: "Factory maintenance record not found" });
    return;
  }
  res.json({ id, status: row.status });
});

export default router;
