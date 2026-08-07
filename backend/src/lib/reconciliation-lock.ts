import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
import { configurationTable } from "../db/index.js";

/** Configuration code for the Reconciliation lock (see Configuration master data). */
export const RECONCILED_LOCK_CODE = "0001";

/**
 * Whether the Reconciliation lock (configuration code "0001") is enabled.
 *
 * Mirrors the frontend's global configuration state: the daily-operation routes
 * gate their reconciled-record lock on this flag. When the flag is enabled,
 * reconciled records are frozen (409 on edit/delete); when it is disabled they
 * stay editable.
 *
 * Defaults to `true` when the configuration row is missing so a missing/mis-set
 * flag never silently unlocks reconciled records.
 */
export async function isReconciliationLockEnabled(): Promise<boolean> {
  const [config] = await db
    .select({ enabled: configurationTable.enabled })
    .from(configurationTable)
    .where(eq(configurationTable.code, RECONCILED_LOCK_CODE));

  return config?.enabled ?? true;
}
