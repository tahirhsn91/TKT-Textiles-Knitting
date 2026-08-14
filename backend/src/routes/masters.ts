import { Router, type IRouter, type Response } from "express";
import { eq } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  transactionTypeMasterTable,
  jobMasterTable,
  partyMasterTable,
  machineMasterTable,
  locationMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  uomMasterTable,
  fabricTypeMasterTable,
  employeeMasterTable,
  departmentMasterTable,
  configurationTable,
  insertTransactionTypeMasterSchema,
  insertJobMasterSchema,
  insertPartyMasterSchema,
  insertMachineMasterSchema,
  insertLocationMasterSchema,
  insertYarnTypeMasterSchema,
  insertYarnCountMasterSchema,
  insertYarnBrandMasterSchema,
  insertUomMasterSchema,
  insertFabricTypeMasterSchema,
  insertDepartmentMasterSchema,
  insertEmployeeMasterSchema,
} from "../db/index.js";
import {
  DEFAULT_NEEDLE_BRAND,
  DEFAULT_SINKER_BRAND,
  normaliseMakingRate,
} from "../lib/factory-defaults.js";
import { addMasterCrud } from "../lib/master-crud.js";

const router: IRouter = Router();

// ─── helpers ────────────────────────────────────────────────────────────────

function numOrNull(v: unknown): string | null {
  return v != null && v !== "" ? String(v) : null;
}

/**
 * Pure validation: return only the named required fields from `body`, or null
 * if any required field is missing/blank. Does NOT write a response — the
 * caller (the master CRUD factory) writes the 400 so messages stay consistent.
 */
function validateRequired<Shape extends z.ZodRawShape, K extends keyof Shape & string>(
  schema: z.ZodObject<Shape>,
  keys: K[],
  body: unknown,
): { [P in K]: z.infer<Shape[P]> } | null {
  if (!body || typeof body !== "object") return null;
  const shape = Object.fromEntries(keys.map((k) => [k, schema.shape[k]])) as Pick<Shape, K>;
  const parsed = z.object(shape).safeParse(body);
  if (!parsed.success) return null;
  for (const k of keys) {
    const v = (parsed.data as Record<string, unknown>)[k];
    if (typeof v === "string" && v.trim() === "") return null;
  }
  return parsed.data as { [P in K]: z.infer<Shape[P]> };
}

// ─── System Configuration ─────────────────────────────────────────────────────
// Read-only by design: records are added only via database migration, so this
// table deliberately exposes GET only — no POST/PUT/DELETE routes exist.

router.get("/masters/configuration", async (_req, res): Promise<void> => {
  const rows = await db.select().from(configurationTable).orderBy(configurationTable.code);
  res.json(rows);
});

// ─── Generic CRUD via the shared factory (issue #9) ─────────────────────────

// Transaction Type
addMasterCrud(router, {
  path: "transaction-type",
  table: transactionTypeMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertTransactionTypeMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    const { action } = body;
    return { name, code, action: action || null };
  },
  uniqueError: "A record with that code already exists",
});

// Job (joined to party)
addMasterCrud(router, {
  path: "job",
  table: jobMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertJobMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    const { partyId } = body;
    return { name, code, partyId: partyId ?? null };
  },
  uniqueError: "Code already exists for this party",
  listQuery: async () =>
    db
      .select({
        id: jobMasterTable.id,
        name: jobMasterTable.name,
        code: jobMasterTable.code,
        partyId: jobMasterTable.partyId,
        partyName: partyMasterTable.name,
      })
      .from(jobMasterTable)
      .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
      .orderBy(partyMasterTable.name, jobMasterTable.name),
  fetchOne: async (id) => {
    const [row] = await db
      .select({
        id: jobMasterTable.id,
        name: jobMasterTable.name,
        code: jobMasterTable.code,
        partyId: jobMasterTable.partyId,
        partyName: partyMasterTable.name,
      })
      .from(jobMasterTable)
      .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
      .where(eq(jobMasterTable.id, id));
    return row;
  },
});

// Party
addMasterCrud(router, {
  path: "party",
  table: partyMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertPartyMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    const { wastePercent, ntnCnic, province, address, registrationType } = body;
    const waste = wastePercent !== undefined && wastePercent !== "" ? String(parseFloat(String(wastePercent))) : "1.00";
    return {
      name,
      code,
      wastePercent: waste,
      ntnCnic: ntnCnic || null,
      province: province || null,
      address: address || null,
      registrationType: registrationType ?? "Unregistered",
    };
  },
  uniqueError: "Code already exists",
});

// Machine
addMasterCrud(router, {
  path: "machine",
  table: machineMasterTable,
  required: ["name", "machineNumber"],
  validate: (body) => validateRequired(insertMachineMasterSchema, ["name", "machineNumber"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, machineNumber } = body;
    const { makingRate, needleChangeDate, needleBrand, sinkerChangeDate, sinkerBrand } = body;
    return {
      name,
      machineNumber,
      makingRate: normaliseMakingRate(makingRate),
      needleChangeDate: needleChangeDate || null,
      needleBrand: needleBrand || DEFAULT_NEEDLE_BRAND,
      sinkerChangeDate: sinkerChangeDate || null,
      sinkerBrand: sinkerBrand || DEFAULT_SINKER_BRAND,
    };
  },
  uniqueError: "Machine number already exists",
});

// Location
addMasterCrud(router, {
  path: "location",
  table: locationMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertLocationMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    return { name, code };
  },
  uniqueError: "Code already exists",
});

// Yarn Type
addMasterCrud(router, {
  path: "yarn-type",
  table: yarnTypeMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertYarnTypeMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    const { makeRate, hsCode } = body;
    return {
      name,
      code,
      makeRate: makeRate != null && makeRate !== "" ? String(makeRate) : null,
      hsCode: hsCode || null,
    };
  },
  uniqueError: "Code already exists",
});

// Yarn Count
addMasterCrud(router, {
  path: "yarn-count",
  table: yarnCountMasterTable,
  required: ["name", "count"],
  validate: (body) => validateRequired(insertYarnCountMasterSchema, ["name", "count"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, count } = body;
    return { name, count };
  },
  uniqueError: "Count already exists",
});

// Yarn Brand
addMasterCrud(router, {
  path: "yarn-brand",
  table: yarnBrandMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertYarnBrandMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    return { name, code };
  },
  uniqueError: "Code already exists",
});

// UOM
addMasterCrud(router, {
  path: "uom",
  table: uomMasterTable,
  required: ["name", "abbreviation"],
  validate: (body) => validateRequired(insertUomMasterSchema, ["name", "abbreviation"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, abbreviation } = body;
    return { name, abbreviation };
  },
  uniqueError: "Abbreviation already exists",
});

// Fabric Type
addMasterCrud(router, {
  path: "fabric-type",
  table: fabricTypeMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertFabricTypeMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    return { name, code };
  },
  uniqueError: "Code already exists",
});

// Department
addMasterCrud(router, {
  path: "department",
  table: departmentMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertDepartmentMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    return { name, code };
  },
  uniqueError: "Code already exists",
});

// Employee
addMasterCrud(router, {
  path: "employee",
  table: employeeMasterTable,
  required: ["name", "code"],
  validate: (body) => validateRequired(insertEmployeeMasterSchema, ["name", "code"], body) as unknown as Record<string, unknown>,
  buildRow: (body) => {
    const { name, code } = body;
    const { departmentId, baseSalary, overtimeRateHr, attAllowance, othAllowance, active } = body;
    return {
      name,
      code,
      departmentId: departmentId ?? null,
      baseSalary: numOrNull(baseSalary),
      overtimeRateHr: numOrNull(overtimeRateHr),
      attAllowance: numOrNull(attAllowance),
      othAllowance: numOrNull(othAllowance),
      active: active ?? true,
    };
  },
  uniqueError: "Code already exists",
});

export default router;
