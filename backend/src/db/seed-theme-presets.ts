/**
 * Seed / refresh the theme preset catalog for ALL existing tenants
 * (issue #219 1.2). Idempotent by (tenant_id, preset_key): inserts any missing
 * preset, and updates color fields so existing presets gain the full colour
 * surface. Run: npm run db:seed:presets
 */
import { eq, and, sql } from "drizzle-orm";
import { db } from "../db/index.js";
import { tenantTable } from "../db/schema/tenants.js";
import { themePresetsTable } from "../db/schema/tenants.js";
import { DEFAULT_THEME_PRESETS } from "../lib/theme-presets.js";

async function seedTenant(tenantId: number): Promise<number> {
  let created = 0;
  for (const p of DEFAULT_THEME_PRESETS) {
    const [existing] = await db
      .select({ id: themePresetsTable.id })
      .from(themePresetsTable)
      .where(and(eq(themePresetsTable.tenantId, tenantId), eq(themePresetsTable.presetKey, p.presetKey)))
      .limit(1);
    if (existing) {
      // Refresh the color surface but keep the tenant's own name/key/isDefault.
      await db
        .update(themePresetsTable)
        .set({
          description: p.description ?? null,
          primaryColor: p.primaryColor ?? null,
          secondaryColor: p.secondaryColor ?? null,
          accentColor: p.accentColor ?? null,
          textColor: p.textColor ?? null,
          backgroundColor: p.backgroundColor ?? null,
          navbarColor: p.navbarColor ?? null,
          navbarTextColor: p.navbarTextColor ?? null,
          sidebarColor: p.sidebarColor ?? null,
          sidebarTextColor: p.sidebarTextColor ?? null,
          accentHoverColor: p.accentHoverColor ?? null,
          updatedAt: new Date().toISOString(),
        })
        .where(eq(themePresetsTable.id, existing.id));
    } else {
      await db.insert(themePresetsTable).values({ tenantId, ...p });
      created += 1;
    }
  }
  return created;
}

async function main() {
  // Optional target: TENANT_ID env overrides (else all tenants).
  const target = process.env.TENANT_ID ? Number(process.env.TENANT_ID) : null;
  const tenants = target
    ? [{ id: target }]
    : await db.select({ id: tenantTable.id }).from(tenantTable).orderBy(tenantTable.id);

  for (const t of tenants) {
    const created = await seedTenant(t.id);
    console.log(`tenant ${t.id}: ${DEFAULT_THEME_PRESETS.length} presets ensured (${created} newly inserted)`);
  }
  await db.execute(sql`select 1`);
  console.log("done");
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
