import { Router, type IRouter, type Response } from "express";
import { eq } from "drizzle-orm";
import type { AnyPgTable, PgColumn } from "drizzle-orm/pg-core";
import { db } from "../db/index.js";
import { isUniqueViolation } from "./db-errors.js";

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

/** Loose view of a table exposing its columns — safe at runtime, narrow for types. */
type LooseTable = AnyPgTable & { id: PgColumn; name: PgColumn; [k: string]: unknown };

/** Metadata describing a write the factory just performed (used by optional hooks). */
export interface MasterWriteEvent {
  action: "created" | "updated" | "deleted";
  /** The authenticated actor (req.auth?.username), or 'system' when absent. */
  actor: string;
  /** The row state after the write (create/update) or before the delete. */
  row: Record<string, unknown>;
}

/**
 * A DB client compatible with a single write (the transaction handle is
 * passed to hooks so side effects share the same transaction as the row write).
 */
export type MasterDbClient = Parameters<Parameters<typeof db.transaction>[0]>[0];

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
  /**
   * Optional per-table write hook (e.g. auditing). Runs inside the SAME
   * transaction as the CRUD write, so a hook failure rolls the write back. Use
   * it for side effects that must stay consistent with the row (e.g. machine
   * history). When unset, no hook runs and the write is a single statement.
   */
  afterWrite?: (tx: MasterDbClient, event: MasterWriteEvent) => Promise<void>;
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
      const actor = (req.auth?.username as string | undefined) ?? "system";
      const result = await db.transaction(async (tx) => {
        const [created] = await tx
          .insert(table)
          .values(cfg.buildRow(req.body as Record<string, unknown>) as never)
          .returning();
        if (cfg.afterWrite) {
          await cfg.afterWrite(tx, {
            action: "created",
            actor,
            row: created as Record<string, unknown>,
          });
        }
        return created;
      });
      const out = cfg.fetchOne
        ? await cfg.fetchOne(Number((result as { id: unknown }).id))
        : result;
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
      const actor = (req.auth?.username as string | undefined) ?? "system";
      const result = await db.transaction(async (tx) => {
        const [updated] = await tx
          .update(table)
          .set(cfg.buildRow(req.body as Record<string, unknown>) as never)
          .where(eq(idCol, id))
          .returning();
        if (!updated) { return null; }
        if (cfg.afterWrite) {
          await cfg.afterWrite(tx, {
            action: "updated",
            actor,
            row: updated as Record<string, unknown>,
          });
        }
        return updated;
      });
      if (!result) { res.status(404).json({ error: "Not found" }); return; }
      const out = cfg.fetchOne ? await cfg.fetchOne(id) : result;
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
    try {
      const actor = (req.auth?.username as string | undefined) ?? "system";
      const deleted = await db.transaction(async (tx) => {
        const [row] = await tx.delete(table).where(eq(idCol, id)).returning();
        if (!row) { return null; }
        if (cfg.afterWrite) {
          await cfg.afterWrite(tx, {
            action: "deleted",
            actor,
            row: row as Record<string, unknown>,
          });
        }
        return row;
      });
      if (!deleted) { res.status(404).json({ error: "Not found" }); return; }
      res.status(204).send();
    } catch (err) {
      // Re-raise (delete has no unique-violation path to translate).
      throw err;
    }
  });
}
