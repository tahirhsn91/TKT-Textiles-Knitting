import { Router, type IRouter } from "express";
import { eq, and, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  companyInfoMasterTable,
  insertCompanyInfoMasterSchema,
} from "../db/index.js";
import { FBR_PROVINCES } from "../lib/fbr/constants.js";
import { validateBody } from "../lib/validate.js";
import { isUniqueViolation } from "../lib/db-errors.js";
import { activeTenantId } from "../middleware/tenant-context.js";

const router: IRouter = Router();

function idParam(req: { params: Record<string, string | string[] | undefined> }) {
  const id = parseInt(String(req.params.id), 10);
  return isNaN(id) ? null : id;
}

const provinceSchema = z.string().refine(
  (v) => (FBR_PROVINCES as readonly string[]).includes(v),
  { message: `Province must be one of: ${FBR_PROVINCES.join(", ")}` },
);

const companySchema = insertCompanyInfoMasterSchema.extend({
  ntnCnic: z.string().min(1, "NTN/CNIC is required"),
  province: provinceSchema,
  address: z.string().min(1, "Address is required"),
  name: z.string().min(1, "Company name is required"),
  fbrSandboxToken: z.string().optional().nullable(),
  fbrProductionToken: z.string().optional().nullable(),
});

// ─── List ────────────────────────────────────────────────────────────────

router.get("/masters/company-info", async (req, res): Promise<void> => {
  const rows = await db
    .select()
    .from(companyInfoMasterTable)
    .where(eq(companyInfoMasterTable.tenantId, activeTenantId(req)))
    .orderBy(sql`${companyInfoMasterTable.isDefault} DESC`, companyInfoMasterTable.name);
  res.json(rows);
});

// ─── Set default ─────────────────────────────────────────────────────────
// Clears isDefault on all companies, then sets the selected one. Enforced in a
// single transaction so "exactly one default" always holds.

router.post("/masters/company-info/:id/default", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  await db.transaction(async (tx) => {
    await tx.update(companyInfoMasterTable).set({ isDefault: false }).where(eq(companyInfoMasterTable.tenantId, tenantId));
    await tx
      .update(companyInfoMasterTable)
      .set({ isDefault: true })
      .where(and(eq(companyInfoMasterTable.id, id), eq(companyInfoMasterTable.tenantId, tenantId)));
  });

  const [row] = await db
    .select()
    .from(companyInfoMasterTable)
    .where(and(eq(companyInfoMasterTable.id, id), eq(companyInfoMasterTable.tenantId, tenantId)));
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.json(row);
});

// ─── Create ──────────────────────────────────────────────────────────────

router.post(
  "/masters/company-info",
  validateBody(companySchema),
  async (req, res): Promise<void> => {
    const tenantId = activeTenantId(req);
    const { name, ntnCnic, province, address, fbrSandboxToken, fbrProductionToken } = req.body as unknown as z.infer<typeof companySchema>;

    // First company → auto default (within the tenant).
    const [{ count }] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(companyInfoMasterTable)
      .where(eq(companyInfoMasterTable.tenantId, tenantId));
    const isDefault = count === 0;

    try {
      const [row] = await db
        .insert(companyInfoMasterTable)
        .values({
          name,
          ntnCnic,
          province,
          address,
          fbrSandboxToken: fbrSandboxToken || null,
          fbrProductionToken: fbrProductionToken || null,
          isDefault,
          tenantId,
        })
        .returning();
      res.status(201).json(row);
    } catch (err) {
      if (isUniqueViolation(err)) { res.status(409).json({ error: "A record with duplicate value already exists" }); return; }
      throw err;
    }
  },
);

// ─── Update ──────────────────────────────────────────────────────────────

router.put(
  "/masters/company-info/:id",
  validateBody(companySchema),
  async (req, res): Promise<void> => {
    const id = idParam(req);
    if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
    const tenantId = activeTenantId(req);
    const { name, ntnCnic, province, address, fbrSandboxToken, fbrProductionToken } = req.body as unknown as z.infer<typeof companySchema>;
    const [row] = await db
      .update(companyInfoMasterTable)
      .set({
        name,
        ntnCnic,
        province,
        address,
        fbrSandboxToken: fbrSandboxToken || null,
        fbrProductionToken: fbrProductionToken || null,
        updatedAt: new Date(),
      })
      .where(and(eq(companyInfoMasterTable.id, id), eq(companyInfoMasterTable.tenantId, tenantId)))
      .returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  },
);

// ─── Delete ──────────────────────────────────────────────────────────────
// Only allowed when not the default company (the default must always exist
// for invoice generation). Prevents deleting the sole/default seller.

router.delete("/masters/company-info/:id", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [existing] = await db
    .select().from(companyInfoMasterTable).where(and(eq(companyInfoMasterTable.id, id), eq(companyInfoMasterTable.tenantId, tenantId)));
  if (!existing) { res.status(404).json({ error: "Not found" }); return; }

  if (existing.isDefault) {
    res.status(409).json({ error: "Cannot delete the default company. Set another company as default first." });
    return;
  }

  await db.delete(companyInfoMasterTable).where(and(eq(companyInfoMasterTable.id, id), eq(companyInfoMasterTable.tenantId, tenantId)));
  res.sendStatus(204);
});

export default router;
