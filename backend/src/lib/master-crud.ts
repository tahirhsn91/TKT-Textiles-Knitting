import { Router, type IRouter, type Response } from "express";
import { eq } from "drizzle-orm";
import type { AnyPgTable, PgColumn } from "drizzle-orm/pg-core";
import { db } from "../db/index.js";

/**
 * Generic CRUD factory for master tables (issue #9).
 *
 * The 12 master routers in `routes/masters.ts` were copy-pasted handlers that
 * differed only in the table, the required field names, and a handful of extra
 * fields per table. This factory generates the list/create/update/delete routes
 * for a master table from a small config, keeping the subtle per-table
 * differences (extra field transforms, joined selects) in the config rather
 * than in duplicated handler bodies.
 *
 * Error responses are unified to `{ error: string }` (400 invalid id / missing
 * fields, 404 not found, 409 duplicate) so clients get a consistent contract.
 *
 * Drizzle's table types are deeply generic; internally we bridge to the
 * concrete table/column at runtime via narrow casts, mirroring how the
 * original hand-written handlers used the same Drizzle methods.
 */

function isUniqueViolation(err: unknown): boolean {
  return (
    typeof err === "object" &&
    err !== null &&
    "code" in err &&
    (err as { code: string }).code === "23505"
  );
}

/** Loose view of a table exposing its columns — safe at runtime, narrow for types. */
type LooseTable = AnyPgTable & { id: PgColumn; name: PgColumn; [k: string]: unknown };

/** Configuration for one master table's generic CRUD factory. */
export interface MasterConfig {
  /** Route path segment, e.g. "transaction-type" → /masters/transaction-type. */
  path: string;
  /** Table (for insert/update/delete/list). */
  table: AnyPgTable;
  /** Required field names on create/update (for the generic validation message). */
  required: string[];
  /** Validate body → return the validated body or null. */
  validate: (body: unknown) => Record<string, unknown> | null;
  /** Build the DB insert/update row from `body`. */
  buildRow: (body: Record<string, unknown>) => unknown;
  /** 409 message on unique violation. */
  uniqueError: string;
  /** Ordered list query (for joined shapes, e.g. job). */
  listQuery?: () => Promise<unknown>;
  /** Re-fetch a single row after a write (for joined shapes). */
  fetchOne?: (id: number) => Promise<unknown>;
}

/**
 * Register the four CRUD routes for a master table on `router`.
 */
export function addMasterCrud(
  router: IRouter,
  cfg: MasterConfig,
): void {
  const table = cfg.table as LooseTable;
  const idCol = table.id;
  const nameCol = table.name;
  // Masters routes carry the /masters prefix (the router is mounted at the root,
  // so each route declares its absolute path, matching the original handlers).
  const base = `/masters/${cfg.path}`;
  // ── List ──────────────────────────────────────────────────────────────────
  router.get(base, async (_req, res): Promise<void> => {
    if (cfg.listQuery) {
      res.json(await cfg.listQuery());
      return;
    }
    const rows = await db
      .select()
      .from(table)
      .orderBy(nameCol);
    res.json(rows);
  });

  // ── Create ─────────────────────────────────────────────────────────────────
  router.post(base, async (req, res): Promise<void> => {
    const body = cfg.validate(req.body);
    if (!body) {
      res.status(400).json({ error: `Missing required fields: ${cfg.required.join(", ")}` });
      return;
    }
    try {
      const [created] = await db
        .insert(table)
        .values(cfg.buildRow(req.body as Record<string, unknown>) as never)
        .returning();
      const out = cfg.fetchOne
        ? await cfg.fetchOne(Number((created as { id: unknown }).id))
        : created;
      res.status(201).json(out);
    } catch (err) {
      if (isUniqueViolation(err)) { res.status(409).json({ error: cfg.uniqueError }); return; }
      throw err;
    }
  });

  // ── Update ─────────────────────────────────────────────────────────────────
  router.put(`${base}/:id`, async (req, res): Promise<void> => {
    const id = Number(req.params.id);
    if (!id || Number.isNaN(id)) { res.status(400).json({ error: "Invalid id" }); return; }
    const body = cfg.validate(req.body);
    if (!body) {
      res.status(400).json({ error: `Missing required fields: ${cfg.required.join(", ")}` });
      return;
    }
    try {
      const [updated] = await db
        .update(table)
        .set(cfg.buildRow(req.body as Record<string, unknown>) as never)
        .where(eq(idCol, id))
        .returning();
      if (!updated) { res.status(404).json({ error: "Not found" }); return; }
      const out = cfg.fetchOne ? await cfg.fetchOne(id) : updated;
      res.json(out);
    } catch (err) {
      if (isUniqueViolation(err)) { res.status(409).json({ error: cfg.uniqueError }); return; }
      throw err;
    }
  });

  // ── Delete ─────────────────────────────────────────────────────────────────
  router.delete(`${base}/:id`, async (req, res): Promise<void> => {
    const id = Number(req.params.id);
    if (!id || Number.isNaN(id)) { res.status(400).json({ error: "Invalid id" }); return; }
    const [deleted] = await db
      .delete(table)
      .where(eq(idCol, id))
      .returning();
    if (!deleted) { res.status(404).json({ error: "Not found" }); return; }
    res.status(204).send();
  });
}
