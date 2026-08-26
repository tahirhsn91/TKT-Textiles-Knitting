import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
import { tenantSettingsTable } from "../db/schema/tenants.js";
import { FBR_SALES_TAX_PERCENT } from "./fbr/constants.js";

/**
 * Load the tenant's configured sales-tax rate (%) from Company Settings
 * (tenant_settings.default_tax_rate, edited in the Company Settings tab).
 *
 * Falls back to the app-wide default (FBR_SALES_TAX_PERCENT) when the tenant
 * has no explicit setting. The value is stored as a numeric string; we parse
 * it and clamp to a sane non-negative range.
 *
 * Issue #219: tax percentage should come from the configured value, not a
 * hardcoded constant.
 */
export async function loadDefaultTaxRate(tenantId: number): Promise<number> {
  try {
    const [row] = await db
      .select({ rate: tenantSettingsTable.defaultTaxRate })
      .from(tenantSettingsTable)
      .where(eq(tenantSettingsTable.tenantId, tenantId))
      .limit(1);
    if (row?.rate !== null && row?.rate !== undefined && row?.rate !== "") {
      const parsed = Number(row.rate);
      if (Number.isFinite(parsed) && parsed >= 0) {
        return parsed;
      }
    }
  } catch (err) {
    // Never fail tax derivation because the setting lookup failed — fall back.
  }
  return FBR_SALES_TAX_PERCENT;
}
