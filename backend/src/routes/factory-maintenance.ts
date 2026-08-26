import { Router, type IRouter } from "express";
import { eq, and, desc, sql, gte, lte } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  factoryMaintenanceTable,
  insertFactoryMaintenanceSchema,
} from "../db/index.js";
import { validateBody } from "../lib/validate.js";
import { activeTenantId } from "../middleware/tenant-context.js";

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
  const tenantId = activeTenantId(req);
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();
  const statusRaw = typeof req.query.status === "string" ? req.query.status : "submitted";
  const page = Math.max(parseInt(String(req.query.page ?? "1"), 10) || 1, 1);
  const pageSize = Math.min(Math.max(parseInt(String(req.query.pageSize ?? "50"), 10) || 50, 1), 200);

  const status = STATUSES.safeParse(statusRaw).success ? statusRaw : "submitted";

  const where = and(
    eq(factoryMaintenanceTable.maintenanceDate, date),
    eq(factoryMaintenanceTable.status, status),
    eq(factoryMaintenanceTable.tenantId, tenantId),
  );

  const [{ total }] = await db
    .select({ total: sql<number>`count(*)::int` })
    .from(factoryMaintenanceTable)
    .where(where);

  // Per-day job count for the month, for the trend chart (submitted only).
  const activeStatus = "submitted";
  const monthStart = `${date.slice(0, 7)}-01`;
  const monthSeries = await db
    .select({
      date: factoryMaintenanceTable.maintenanceDate,
      jobs: sql<number>`count(*)::int`,
    })
    .from(factoryMaintenanceTable)
    .where(and(
      gte(factoryMaintenanceTable.maintenanceDate, monthStart),
      lte(factoryMaintenanceTable.maintenanceDate, date),
      eq(factoryMaintenanceTable.status, activeStatus),
      eq(factoryMaintenanceTable.tenantId, tenantId),
    ))
    .groupBy(factoryMaintenanceTable.maintenanceDate)
    .orderBy(factoryMaintenanceTable.maintenanceDate);

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
    monthSeries,
  });
});

// ─── Detail ────────────────────────────────────────────────────────────────

router.get("/maintenance/factory/:id", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
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
    .where(and(eq(factoryMaintenanceTable.id, id), eq(factoryMaintenanceTable.tenantId, tenantId)));

  if (!row) {
    res.status(404).json({ error: "Factory maintenance record not found" });
    return;
  }
  res.json(row);
});

// ─── Create ────────────────────────────────────────────────────────────────

router.post("/maintenance/factory", validateBody(factorySchema), async (req, res): Promise<void> => {
  const { maintenanceDate, category, maintenanceWork, createdBy } = req.body as unknown as z.infer<typeof factorySchema>;

  const [row] = await db
    .insert(factoryMaintenanceTable)
    .values({
      maintenanceDate,
      category: category.trim() || "Other",
      maintenanceWork,
      createdBy,
      tenantId: activeTenantId(req),
    })
    .returning({ id: factoryMaintenanceTable.id });

  res.status(201).json({ id: row.id });
});

// ─── Update ────────────────────────────────────────────────────────────────

router.put("/maintenance/factory/:id", validateBody(factorySchema), async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }

  const { maintenanceDate, category, maintenanceWork, createdBy, updatedBy } = req.body as unknown as z.infer<typeof factorySchema>;
  const tenantId = activeTenantId(req);

  const [row] = await db
    .update(factoryMaintenanceTable)
    .set({
      maintenanceDate,
      category: category.trim() || "Other",
      maintenanceWork,
      updatedBy: updatedBy ?? createdBy,
      updatedAt: new Date(),
    })
    .where(and(eq(factoryMaintenanceTable.id, id), eq(factoryMaintenanceTable.status, "submitted"), eq(factoryMaintenanceTable.tenantId, tenantId)))
    .returning({ id: factoryMaintenanceTable.id });

  if (!row) {
    res.status(404).json({ error: "Factory maintenance record not found or is cancelled" });
    return;
  }
  res.json({ id });
});

// ─── Soft-delete (cancel) & restore ────────────────────────────────────────

router.patch("/maintenance/factory/:id/status", validateBody(z.object({ status: STATUSES })), async (req, res): Promise<void> => {
  const id = parseInt(String(req.params.id), 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid maintenance id" });
    return;
  }
  const { status } = req.body as unknown as { status: z.infer<typeof STATUSES> };
  const bodyAny = req.body as { updatedBy?: string | null };
  const by = typeof bodyAny.updatedBy === "string" ? bodyAny.updatedBy.trim() : null;

  const [row] = await db
    .update(factoryMaintenanceTable)
    .set({
      status,
      updatedBy: by ?? null,
      updatedAt: new Date(),
    })
    .where(and(eq(factoryMaintenanceTable.id, id), eq(factoryMaintenanceTable.tenantId, activeTenantId(req))))
    .returning({ id: factoryMaintenanceTable.id, status: factoryMaintenanceTable.status });

  if (!row) {
    res.status(404).json({ error: "Factory maintenance record not found" });
    return;
  }
  res.json({ id, status: row.status });
});

export default router;
