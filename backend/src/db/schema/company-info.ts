import { pgTable, serial, text, boolean, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

// ─── Company Info (seller) ─────────────────────────────────────────────────
// The seller side of an FBR invoice. Multiple companies can exist, but exactly
// one is marked default (enforced at the app layer: setting one clears the
// others). Invoice generation picks the default record.
//
// FBR tokens are per-company because FBR ties a token to the seller's NTN/CNIC
// (error codes 0401/0402). Sandbox vs production routing at post time is
// controlled by the global configuration toggle (code "0002"); the matching
// token for the selected environment is read from the default company.
export const companyInfoMasterTable = pgTable("company_info_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  // Seller NTN (7 digits) or CNIC (13 digits), as required by FBR.
  ntnCnic: text("ntn_cnic").notNull(),
  // One of the official provinces (validated against FBR_PROVINCES const).
  province: text("province").notNull(),
  address: text("address").notNull(),
  fbrSandboxToken: text("fbr_sandbox_token"),
  fbrProductionToken: text("fbr_production_token"),
  // Exactly one company should be default (app-enforced; see route logic).
  isDefault: boolean("is_default").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const insertCompanyInfoMasterSchema = createInsertSchema(companyInfoMasterTable).omit({
  id: true,
  isDefault: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertCompanyInfoMaster = z.infer<typeof insertCompanyInfoMasterSchema>;
export type CompanyInfoMaster = typeof companyInfoMasterTable.$inferSelect;
