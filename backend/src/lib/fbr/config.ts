import { eq } from "drizzle-orm";
import { db } from "../../db/index.js";
import { configurationTable } from "../../db/index.js";
import { FBR_DI_SANDBOX_CODE } from "./constants.js";

/**
 * Whether the FBR DI sandbox environment is enabled (configuration code
 * "0002"). Defaults to `true` (sandbox) when the row is missing so a missing
 * flag never silently routes live invoices to production.
 */
export async function isFbrSandboxEnabled(): Promise<boolean> {
  const [config] = await db
    .select({ enabled: configurationTable.enabled })
    .from(configurationTable)
    .where(eq(configurationTable.code, FBR_DI_SANDBOX_CODE));

  return config?.enabled ?? true;
}
