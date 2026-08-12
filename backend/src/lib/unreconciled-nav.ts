// ─── Unreconciled-date navigation ─────────────────────────────────────────
// Powers the "prev / next date with unconciled data" buttons on the three
// daily operations screens (Daily Production, Yarn Receipt, Daily Delivery).
//
// A date "has unconciled data" when it holds at least one row with
//   reconciled = false AND status <> 'cancelled'
// (abnormal or not — see issue #120). Given a reference date we return the
// nearest unreconciled date strictly before and strictly after it, or null
// when none exists in that direction.
//
// The SQL is built as a plain parameterized `{ sql, params }` pair by a pure
// function so it can be unit-tested without a live database (issue #120, Q9).

import type { Pool } from "pg";

export type UnreconciledOperation = "production" | "receipt" | "delivery";

interface TableSpec {
  table: string;
  dateColumn: string;
}

/** Per-operation mapping: the table to query and its date column name. */
export const UNRECONCILED_TABLE_MAP: Record<UnreconciledOperation, TableSpec> = {
  production: { table: "daily_production_header", dateColumn: "production_date" },
  receipt: { table: "yarn_receipt_header", dateColumn: "receipt_date" },
  delivery: { table: "daily_delivery", dateColumn: "delivery_date" },
};

export interface Params {
  sql: string;
  params: [string];
}

/**
 * Pure SQL builder. Returns the parameterized SQL for the nearest unreconciled
 * date in one direction (strictly before or strictly after `date`), ordered so
 * the single result is the nearest match. Table and column names come from the
 * static per-operation map (not user input); only the `date` is parameterized.
 */
export function buildUnreconciledNearestSql(
  operation: UnreconciledOperation,
  date: string,
  direction: "prev" | "next",
): Params {
  const { table, dateColumn } = UNRECONCILED_TABLE_MAP[operation];
  const comparator = direction === "prev" ? "<" : ">";
  const order = direction === "prev" ? "DESC" : "ASC";
  return {
    sql: `
      SELECT to_char(${dateColumn}::date, 'YYYY-MM-DD') AS "date"
      FROM ${table}
      WHERE reconciled = false
        AND status <> 'cancelled'
        AND ${dateColumn}::date ${comparator} $1::date
      ORDER BY ${dateColumn}::date ${order}
      LIMIT 1
    `,
    params: [date],
  };
}

/** Nearest unreconciled dates strictly before and strictly after `date`, or
 *  null when none exists in that direction. Runs two single-row queries. */
export async function findNearestUnreconciledDates(
  pool: Pool,
  operation: UnreconciledOperation,
  date: string,
): Promise<{ prev: string | null; next: string | null }> {
  const [prevRes, nextRes] = await Promise.all([
    pool.query<{ date: string }>(...toQuery(buildUnreconciledNearestSql(operation, date, "prev"))),
    pool.query<{ date: string }>(...toQuery(buildUnreconciledNearestSql(operation, date, "next"))),
  ]);
  return {
    prev: prevRes.rows[0]?.date ?? null,
    next: nextRes.rows[0]?.date ?? null,
  };
}

function toQuery(p: Params): [string, string[]] {
  return [p.sql, p.params];
}
