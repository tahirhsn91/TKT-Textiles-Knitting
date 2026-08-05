import { Router, type IRouter } from "express";
import { eq, and, gte, lte, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  dailyProductionHeaderTable,
  dailyProductionDetailTable,
  machineMasterTable,
  employeeMasterTable,
  partyMasterTable,
} from "../db/index.js";

const router: IRouter = Router();

// ─── Validation schemas ─────────────────────────────────────────────────────
// NOTE: `createdBy` / `updatedBy` are accepted from the request body for now
// because the app has no authentication/session layer yet. Once auth lands,
// these should be derived from `req.user` server-side instead of trusting
// client input (see TDD "Open Questions" — auth & user attribution).

const SHIFT_VALUES = ["Morning", "Night"] as const;
const shiftSchema = z.enum(SHIFT_VALUES, { message: "Shift must be Morning or Night" });

const rollSchema = z.object({
  rollWeight: z.coerce.number().positive("Roll weight must be greater than zero"),
  remarks: z.string().trim().nullable().optional(),
});

const createSchema = z.object({
  productionDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "productionDate must be YYYY-MM-DD"),
  machineId: z.coerce.number().int().positive("Machine is required"),
  employeeId: z.coerce.number().int().positive("Employee is required"),
  partyId: z.coerce.number().int().positive("Party is required"),
  shift: shiftSchema,
  remarks: z.string().trim().nullable().optional(),
  createdBy: z.string().trim().min(1, "createdBy is required"),
  rolls: z.array(rollSchema).min(1, "At least one yarn roll entry is required"),
});

const updateSchema = createSchema.omit({ createdBy: true }).extend({
  updatedBy: z.string().trim().min(1, "updatedBy is required"),
});

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id, 10);
  return isNaN(id) ? null : id;
}

function isFkViolation(err: unknown): boolean {
  return typeof err === "object" && err !== null && "code" in err && (err as { code: string }).code === "23503";
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Reconciled entries are frozen. Enforced here rather than only in the UI —
 * hiding a button stops a user, not a stale browser tab, a retried request or
 * anything calling the API directly.
 *
 * Returns a 409 payload when the entry is locked, or null when it is free.
 */
async function reconciliationBlock(
  id: number,
): Promise<{ error: string; reconciledTransactionId: number | null } | null> {
  const [row] = await db
    .select({
      reconciled: dailyProductionHeaderTable.reconciled,
      reconciledTransactionId: dailyProductionHeaderTable.reconciledTransactionId,
    })
    .from(dailyProductionHeaderTable)
    .where(eq(dailyProductionHeaderTable.id, id));

  if (!row || !row.reconciled) return null;

  return {
    error:
      "This entry has been reconciled into a Fabric Production transaction and can no longer be changed.",
    reconciledTransactionId: row.reconciledTransactionId,
  };
}

// ─── Get production summary by date ────────────────────────────────────────
// Landing-screen grid: SUM(roll_weight) / COUNT(*) grouped by
// Machine + Employee + Party + Shift for the selected Production Date.
// Cancelled entries are excluded from totals but not deleted (Section 4.5 of
// the TDD).
//
// This returns ONE ROW PER HEADER RECORD and deliberately does not group
// across headers. The grid exposes per-row Edit and Delete, and a grouped row
// cannot identify which underlying record an action applies to: two "Save &
// Add" batches for the same machine/shift produce two headers that a grouped
// query collapses into a single visible line, so acting on that line would
// silently hit the wrong record. Roll count and weight are still aggregated
// *within* each header, which is what `group by header.id` gives us.
//
// Grouping by the primary key lets Postgres expose every other column of
// daily_production_header without listing it; the joined lookup names are not
// functionally dependent on that key, so they do have to be grouped.

router.get("/daily-production", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();

  const rows = await db
    .select({
      id: dailyProductionHeaderTable.id,
      machineId: dailyProductionHeaderTable.machineId,
      machineName: machineMasterTable.name,
      employeeId: dailyProductionHeaderTable.employeeId,
      employeeName: employeeMasterTable.name,
      partyId: dailyProductionHeaderTable.partyId,
      partyName: partyMasterTable.name,
      shift: dailyProductionHeaderTable.shift,
      remarks: dailyProductionHeaderTable.remarks,
      createdBy: dailyProductionHeaderTable.createdBy,
      reconciled: dailyProductionHeaderTable.reconciled,
      reconciledTransactionId: dailyProductionHeaderTable.reconciledTransactionId,
      rollCount: sql<number>`count(${dailyProductionDetailTable.id})::int`,
      totalProduction: sql<string>`coalesce(sum(${dailyProductionDetailTable.rollWeight}), 0)`,
      hasHeavyRoll: sql<boolean>`coalesce(max(${dailyProductionDetailTable.rollWeight}) > 30, false)`,
    })
    .from(dailyProductionHeaderTable)
    // leftJoin, not innerJoin: a header that has lost all of its rolls should
    // still be listed so the user can edit or remove it, rather than becoming
    // an invisible orphan.
    .leftJoin(dailyProductionDetailTable, eq(dailyProductionDetailTable.headerId, dailyProductionHeaderTable.id))
    .leftJoin(machineMasterTable, eq(dailyProductionHeaderTable.machineId, machineMasterTable.id))
    .leftJoin(employeeMasterTable, eq(dailyProductionHeaderTable.employeeId, employeeMasterTable.id))
    .leftJoin(partyMasterTable, eq(dailyProductionHeaderTable.partyId, partyMasterTable.id))
    .where(and(
      eq(dailyProductionHeaderTable.productionDate, date),
      eq(dailyProductionHeaderTable.status, "submitted"),
    ))
    .groupBy(
      dailyProductionHeaderTable.id,
      machineMasterTable.name,
      employeeMasterTable.name,
      partyMasterTable.name,
    )
    .orderBy(machineMasterTable.name, dailyProductionHeaderTable.shift, dailyProductionHeaderTable.id);

  // Month-to-date totals: every submitted entry from the 1st of the month
  // through the selected date (inclusive). One aggregate per day view, so the
  // header can show both "today's total" and "where the month stands"
  // without a second round-trip.
  const monthStart = `${date.slice(0, 7)}-01`;
  const [monthToDate] = await db
    .select({
      rollCount: sql<number>`count(${dailyProductionDetailTable.id})::int`,
      totalProduction: sql<string>`coalesce(sum(${dailyProductionDetailTable.rollWeight}), 0)`,
    })
    .from(dailyProductionHeaderTable)
    .leftJoin(dailyProductionDetailTable, eq(dailyProductionDetailTable.headerId, dailyProductionHeaderTable.id))
    .where(and(
      gte(dailyProductionHeaderTable.productionDate, monthStart),
      lte(dailyProductionHeaderTable.productionDate, date),
      eq(dailyProductionHeaderTable.status, "submitted"),
    ));

  res.json({
    productionDate: date,
    rows,
    monthToDate: {
      rollCount: monthToDate?.rollCount ?? 0,
      totalProduction: monthToDate?.totalProduction ?? "0",
    },
  });
});

// ─── Unreconciled production for a date + party ────────────────────────────
// Feeds the New Transaction screen when the type is Fabric Production. Only
// returns entries not yet consumed by another transaction, so the same
// production can never be booked twice.
//
// MUST stay above "/daily-production/:id" — Express matches in order, and
// "unreconciled" would otherwise be parsed as an id.

router.get("/daily-production/unreconciled", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" ? req.query.date : "";
  const partyId = parseInt(String(req.query.partyId ?? ""), 10);

  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || isNaN(partyId)) {
    res.status(400).json({ error: "date (YYYY-MM-DD) and partyId are required" });
    return;
  }

  const rows = await db
    .select({
      id: dailyProductionHeaderTable.id,
      productionDate: dailyProductionHeaderTable.productionDate,
      machineId: dailyProductionHeaderTable.machineId,
      machineName: machineMasterTable.name,
      employeeId: dailyProductionHeaderTable.employeeId,
      employeeName: employeeMasterTable.name,
      partyId: dailyProductionHeaderTable.partyId,
      partyName: partyMasterTable.name,
      shift: dailyProductionHeaderTable.shift,
      rollCount: sql<number>`count(${dailyProductionDetailTable.id})::int`,
      totalProduction: sql<string>`coalesce(sum(${dailyProductionDetailTable.rollWeight}), 0)`,
    })
    .from(dailyProductionHeaderTable)
    .leftJoin(dailyProductionDetailTable, eq(dailyProductionDetailTable.headerId, dailyProductionHeaderTable.id))
    .leftJoin(machineMasterTable, eq(dailyProductionHeaderTable.machineId, machineMasterTable.id))
    .leftJoin(employeeMasterTable, eq(dailyProductionHeaderTable.employeeId, employeeMasterTable.id))
    .leftJoin(partyMasterTable, eq(dailyProductionHeaderTable.partyId, partyMasterTable.id))
    .where(and(
      eq(dailyProductionHeaderTable.productionDate, date),
      eq(dailyProductionHeaderTable.partyId, partyId),
      eq(dailyProductionHeaderTable.status, "submitted"),
      eq(dailyProductionHeaderTable.reconciled, false),
    ))
    .groupBy(
      dailyProductionHeaderTable.id,
      machineMasterTable.name,
      employeeMasterTable.name,
      partyMasterTable.name,
    )
    .orderBy(machineMasterTable.name, dailyProductionHeaderTable.shift, dailyProductionHeaderTable.id);

  res.json({ productionDate: date, partyId, rows });
});

// ─── Get one (header + rolls) ───────────────────────────────────────────────
// Kept for the future edit/drill-down UI (Section 8 of the TDD) — not called
// by the current landing-screen summary grid, which is aggregate-only.

router.get("/daily-production/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (id == null) { res.status(400).json({ error: "Invalid id" }); return; }

  const [header] = await db
    .select()
    .from(dailyProductionHeaderTable)
    .where(eq(dailyProductionHeaderTable.id, id));

  if (!header) { res.status(404).json({ error: "Daily production entry not found" }); return; }

  const rolls = await db
    .select()
    .from(dailyProductionDetailTable)
    .where(eq(dailyProductionDetailTable.headerId, id))
    .orderBy(dailyProductionDetailTable.rollNumber);

  res.json({ ...header, rolls });
});

// ─── Create (header + rolls, single DB transaction) ────────────────────────
// Backs both the "Save" and "Save & Add" actions in the Add Production
// modal — each click is one independent call to this endpoint; "Save & Add"
// simply keeps the modal open and fires it again for the next batch.

router.post("/daily-production", async (req, res): Promise<void> => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid input" });
    return;
  }
  const { rolls, ...headerData } = parsed.data;

  try {
    const result = await db.transaction(async (tx) => {
      const [header] = await tx
        .insert(dailyProductionHeaderTable)
        .values({ ...headerData, remarks: headerData.remarks || null })
        .returning();

      const detailRows = await tx
        .insert(dailyProductionDetailTable)
        .values(
          rolls.map((r, i) => ({
            headerId: header.id,
            rollNumber: i + 1,
            rollWeight: String(r.rollWeight),
            remarks: r.remarks || null,
          })),
        )
        .returning();

      return { ...header, rolls: detailRows };
    });

    res.status(201).json(result);
  } catch (err) {
    if (isFkViolation(err)) { res.status(400).json({ error: "Machine, Employee, or Party does not exist" }); return; }
    throw err;
  }
});

// ─── Update (header + full roll replace, single DB transaction) ───────────
// Future support per requirements — not wired to the current UI, which only
// exposes Add. Rolls are replaced wholesale (delete-then-reinsert) so
// roll_number stays a contiguous 1..N sequence after edits.

router.put("/daily-production/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (id == null) { res.status(400).json({ error: "Invalid id" }); return; }

  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid input" });
    return;
  }

  const blocked = await reconciliationBlock(id);
  if (blocked) { res.status(409).json(blocked); return; }

  const { rolls, ...headerData } = parsed.data;

  try {
    const result = await db.transaction(async (tx) => {
      const [header] = await tx
        .update(dailyProductionHeaderTable)
        .set({ ...headerData, remarks: headerData.remarks || null, updatedAt: new Date() })
        .where(eq(dailyProductionHeaderTable.id, id))
        .returning();

      if (!header) return null;

      await tx.delete(dailyProductionDetailTable).where(eq(dailyProductionDetailTable.headerId, id));

      const detailRows = await tx
        .insert(dailyProductionDetailTable)
        .values(
          rolls.map((r, i) => ({
            headerId: header.id,
            rollNumber: i + 1,
            rollWeight: String(r.rollWeight),
            remarks: r.remarks || null,
          })),
        )
        .returning();

      return { ...header, rolls: detailRows };
    });

    if (!result) { res.status(404).json({ error: "Daily production entry not found" }); return; }
    res.json(result);
  } catch (err) {
    if (isFkViolation(err)) { res.status(400).json({ error: "Machine, Employee, or Party does not exist" }); return; }
    throw err;
  }
});

// ─── Cancel (soft delete) — the "Delete" requirement, future support ──────
// No hard DELETE endpoint by design: production entries can be referenced by
// downstream yarn-consumption / payroll calculations, so rows are cancelled
// (status flag) rather than removed, preserving the audit trail. Not yet
// wired to the current UI.

router.post("/daily-production/:id/cancel", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (id == null) { res.status(400).json({ error: "Invalid id" }); return; }

  const body = z.object({ updatedBy: z.string().trim().min(1) }).safeParse(req.body);
  if (!body.success) { res.status(400).json({ error: "updatedBy is required" }); return; }

  const [row] = await db
    .update(dailyProductionHeaderTable)
    .set({ status: "cancelled", updatedBy: body.data.updatedBy, updatedAt: new Date() })
    .where(eq(dailyProductionHeaderTable.id, id))
    .returning();

  if (!row) { res.status(404).json({ error: "Daily production entry not found" }); return; }
  res.json(row);
});

// ─── Delete (hard) ─────────────────────────────────────────────────────────
// Removes the header outright; daily_production_detail rows follow via the
// FK's ON DELETE CASCADE, so the rolls do not need to be cleared first.
//
// NOTE: this is irreversible and discards the audit trail the `status` column
// was designed to preserve. It is safe today because nothing else in the
// schema references daily_production_header — verified by search across
// backend/src. If yarn-consumption or payroll ever start reading these rows,
// this endpoint must be revisited and the soft-cancel path above preferred.

router.delete("/daily-production/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (id == null) { res.status(400).json({ error: "Invalid id" }); return; }

  const blocked = await reconciliationBlock(id);
  if (blocked) { res.status(409).json(blocked); return; }

  const [row] = await db
    .delete(dailyProductionHeaderTable)
    .where(eq(dailyProductionHeaderTable.id, id))
    .returning({ id: dailyProductionHeaderTable.id });

  if (!row) { res.status(404).json({ error: "Daily production entry not found" }); return; }
  res.status(204).end();
});

export default router;
