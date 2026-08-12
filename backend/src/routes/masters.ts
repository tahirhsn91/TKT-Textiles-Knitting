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

const router: IRouter = Router();

// ─── helpers ────────────────────────────────────────────────────────────────

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id);
  return isNaN(id) ? null : id;
}

function isUniqueViolation(err: unknown): boolean {
  return (
    typeof err === "object" &&
    err !== null &&
    "code" in err &&
    (err as { code: string }).code === "23505"
  );
}

/**
 * Validates the given fields of `body` against the table's generated insert
 * schema (type-correct, not just truthy) and rejects blank strings the same
 * way the old `if (!name) ...` checks did. Writes the 400 response itself;
 * callers just bail out on a null return.
 */
function requireFields<Shape extends z.ZodRawShape, K extends keyof Shape & string>(
  schema: z.ZodObject<Shape>,
  keys: K[],
  body: unknown,
  res: Response,
): { [P in K]: z.infer<Shape[P]> } | null {
  const shape = Object.fromEntries(keys.map((k) => [k, schema.shape[k]])) as Pick<Shape, K>;
  const parsed = z.object(shape).safeParse(body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid input" });
    return null;
  }
  for (const k of keys) {
    const v = (parsed.data as Record<string, unknown>)[k];
    if (typeof v === "string" && v.trim() === "") {
      res.status(400).json({ error: `${k} is required` });
      return null;
    }
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

// ─── Transaction Type Master ─────────────────────────────────────────────────

router.get("/masters/transaction-type", async (_req, res): Promise<void> => {
  const rows = await db.select().from(transactionTypeMasterTable).orderBy(transactionTypeMasterTable.name);
  res.json(rows);
});

router.post("/masters/transaction-type", async (req, res): Promise<void> => {
  const parsed = requireFields(insertTransactionTypeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { action } = req.body;
  try {
    const [row] = await db.insert(transactionTypeMasterTable).values({ name, code, action: action || null }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ message: "A record with that code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/transaction-type/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertTransactionTypeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { action } = req.body;
  try {
    const [row] = await db.update(transactionTypeMasterTable).set({ name, code, action: action || null }).where(eq(transactionTypeMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ message: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ message: "A record with that code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/transaction-type/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ message: "Invalid id" }); return; }
  const [row] = await db.delete(transactionTypeMasterTable).where(eq(transactionTypeMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ message: "Not found" }); return; }
  res.status(204).send();
});

// ─── Job Master ─────────────────────────────────────────────────────────────

router.get("/masters/job", async (_req, res): Promise<void> => {
  const rows = await db
    .select({
      id:        jobMasterTable.id,
      name:      jobMasterTable.name,
      code:      jobMasterTable.code,
      partyId:   jobMasterTable.partyId,
      partyName: partyMasterTable.name,
    })
    .from(jobMasterTable)
    .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
    .orderBy(partyMasterTable.name, jobMasterTable.name);
  res.json(rows);
});

router.post("/masters/job", async (req, res): Promise<void> => {
  const parsed = requireFields(insertJobMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { partyId } = req.body;
  try {
    const [inserted] = await db.insert(jobMasterTable).values({ name, code, partyId: partyId ?? null }).returning();
    const [row] = await db
      .select({ id: jobMasterTable.id, name: jobMasterTable.name, code: jobMasterTable.code, partyId: jobMasterTable.partyId, partyName: partyMasterTable.name })
      .from(jobMasterTable)
      .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
      .where(eq(jobMasterTable.id, inserted.id));
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists for this party" }); return; }
    throw err;
  }
});

router.put("/masters/job/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertJobMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { partyId } = req.body;
  try {
    await db.update(jobMasterTable).set({ name, code, partyId: partyId ?? null }).where(eq(jobMasterTable.id, id));
    const [row] = await db
      .select({ id: jobMasterTable.id, name: jobMasterTable.name, code: jobMasterTable.code, partyId: jobMasterTable.partyId, partyName: partyMasterTable.name })
      .from(jobMasterTable)
      .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
      .where(eq(jobMasterTable.id, id));
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists for this party" }); return; }
    throw err;
  }
});

router.delete("/masters/job/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(jobMasterTable).where(eq(jobMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Party Master ────────────────────────────────────────────────────────────

router.get("/masters/party", async (_req, res): Promise<void> => {
  const rows = await db.select().from(partyMasterTable).orderBy(partyMasterTable.name);
  res.json(rows);
});

router.post("/masters/party", async (req, res): Promise<void> => {
  const parsed = requireFields(insertPartyMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { wastePercent, ntnCnic, province, address, registrationType } = req.body;
  const waste = wastePercent !== undefined && wastePercent !== "" ? String(parseFloat(wastePercent)) : "1.00";
  try {
    const [row] = await db.insert(partyMasterTable).values({
      name,
      code,
      wastePercent: waste,
      ntnCnic: ntnCnic || null,
      province: province || null,
      address: address || null,
      registrationType: registrationType ?? "Unregistered",
    }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/party/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertPartyMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { wastePercent, ntnCnic, province, address, registrationType } = req.body;
  const waste = wastePercent !== undefined && wastePercent !== "" ? String(parseFloat(wastePercent)) : "1.00";
  try {
    const [row] = await db.update(partyMasterTable).set({
      name,
      code,
      wastePercent: waste,
      ntnCnic: ntnCnic || null,
      province: province || null,
      address: address || null,
      registrationType: registrationType ?? "Unregistered",
    }).where(eq(partyMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/party/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(partyMasterTable).where(eq(partyMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Machine Master ──────────────────────────────────────────────────────────

router.get("/masters/machine", async (_req, res): Promise<void> => {
  const rows = await db.select().from(machineMasterTable).orderBy(machineMasterTable.name);
  res.json(rows);
});

router.post("/masters/machine", async (req, res): Promise<void> => {
  const parsed = requireFields(insertMachineMasterSchema, ["name", "machineNumber"], req.body, res);
  if (!parsed) return;
  const { name, machineNumber } = parsed;
  const { makingRate, needleChangeDate, needleBrand, sinkerChangeDate, sinkerBrand } = req.body;
  try {
    const [row] = await db.insert(machineMasterTable).values({
      name,
      machineNumber,
      makingRate: makingRate != null && makingRate !== "" ? String(parseFloat(makingRate)) : "3.75",
      needleChangeDate: needleChangeDate || null,
      needleBrand: needleBrand || "Sigma",
      sinkerChangeDate: sinkerChangeDate || null,
      sinkerBrand: sinkerBrand || "Kohala",
    }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Machine number already exists" }); return; }
    throw err;
  }
});

router.put("/masters/machine/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertMachineMasterSchema, ["name", "machineNumber"], req.body, res);
  if (!parsed) return;
  const { name, machineNumber } = parsed;
  const { makingRate, needleChangeDate, needleBrand, sinkerChangeDate, sinkerBrand } = req.body;
  try {
    const [row] = await db.update(machineMasterTable).set({
      name,
      machineNumber,
      makingRate: makingRate != null && makingRate !== "" ? String(parseFloat(makingRate)) : "3.75",
      needleChangeDate: needleChangeDate || null,
      needleBrand: needleBrand || "Sigma",
      sinkerChangeDate: sinkerChangeDate || null,
      sinkerBrand: sinkerBrand || "Kohala",
    }).where(eq(machineMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Machine number already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/machine/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(machineMasterTable).where(eq(machineMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Location Master ─────────────────────────────────────────────────────────

router.get("/masters/location", async (_req, res): Promise<void> => {
  const rows = await db.select().from(locationMasterTable).orderBy(locationMasterTable.name);
  res.json(rows);
});

router.post("/masters/location", async (req, res): Promise<void> => {
  const parsed = requireFields(insertLocationMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.insert(locationMasterTable).values({ name, code }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/location/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertLocationMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.update(locationMasterTable).set({ name, code }).where(eq(locationMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/location/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(locationMasterTable).where(eq(locationMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Yarn Type Master ─────────────────────────────────────────────────────────

router.get("/masters/yarn-type", async (_req, res): Promise<void> => {
  const rows = await db.select().from(yarnTypeMasterTable).orderBy(yarnTypeMasterTable.name);
  res.json(rows);
});

router.post("/masters/yarn-type", async (req, res): Promise<void> => {
  const parsed = requireFields(insertYarnTypeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { makeRate, hsCode } = req.body;
  try {
    const [row] = await db.insert(yarnTypeMasterTable).values({
      name, code,
      makeRate: makeRate != null && makeRate !== "" ? String(makeRate) : null,
      hsCode: hsCode || null,
    }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/yarn-type/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertYarnTypeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { makeRate, hsCode } = req.body;
  try {
    const [row] = await db.update(yarnTypeMasterTable).set({
      name, code,
      makeRate: makeRate != null && makeRate !== "" ? String(makeRate) : null,
      hsCode: hsCode || null,
    }).where(eq(yarnTypeMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/yarn-type/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(yarnTypeMasterTable).where(eq(yarnTypeMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Yarn Count Master ────────────────────────────────────────────────────────

router.get("/masters/yarn-count", async (_req, res): Promise<void> => {
  const rows = await db.select().from(yarnCountMasterTable).orderBy(yarnCountMasterTable.name);
  res.json(rows);
});

router.post("/masters/yarn-count", async (req, res): Promise<void> => {
  const parsed = requireFields(insertYarnCountMasterSchema, ["name", "count"], req.body, res);
  if (!parsed) return;
  const { name, count } = parsed;
  try {
    const [row] = await db.insert(yarnCountMasterTable).values({ name, count }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Count already exists" }); return; }
    throw err;
  }
});

router.put("/masters/yarn-count/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertYarnCountMasterSchema, ["name", "count"], req.body, res);
  if (!parsed) return;
  const { name, count } = parsed;
  try {
    const [row] = await db.update(yarnCountMasterTable).set({ name, count }).where(eq(yarnCountMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Count already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/yarn-count/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(yarnCountMasterTable).where(eq(yarnCountMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Yarn Brand Master ────────────────────────────────────────────────────────

router.get("/masters/yarn-brand", async (_req, res): Promise<void> => {
  const rows = await db.select().from(yarnBrandMasterTable).orderBy(yarnBrandMasterTable.name);
  res.json(rows);
});

router.post("/masters/yarn-brand", async (req, res): Promise<void> => {
  const parsed = requireFields(insertYarnBrandMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.insert(yarnBrandMasterTable).values({ name, code }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/yarn-brand/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertYarnBrandMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.update(yarnBrandMasterTable).set({ name, code }).where(eq(yarnBrandMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/yarn-brand/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(yarnBrandMasterTable).where(eq(yarnBrandMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── UOM Master ───────────────────────────────────────────────────────────────

router.get("/masters/uom", async (_req, res): Promise<void> => {
  const rows = await db.select().from(uomMasterTable).orderBy(uomMasterTable.name);
  res.json(rows);
});

router.post("/masters/uom", async (req, res): Promise<void> => {
  const parsed = requireFields(insertUomMasterSchema, ["name", "abbreviation"], req.body, res);
  if (!parsed) return;
  const { name, abbreviation } = parsed;
  try {
    const [row] = await db.insert(uomMasterTable).values({ name, abbreviation }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Abbreviation already exists" }); return; }
    throw err;
  }
});

router.put("/masters/uom/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertUomMasterSchema, ["name", "abbreviation"], req.body, res);
  if (!parsed) return;
  const { name, abbreviation } = parsed;
  try {
    const [row] = await db.update(uomMasterTable).set({ name, abbreviation }).where(eq(uomMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Abbreviation already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/uom/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(uomMasterTable).where(eq(uomMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Fabric Type Master ───────────────────────────────────────────────────────

router.get("/masters/fabric-type", async (_req, res): Promise<void> => {
  const rows = await db.select().from(fabricTypeMasterTable).orderBy(fabricTypeMasterTable.name);
  res.json(rows);
});

router.post("/masters/fabric-type", async (req, res): Promise<void> => {
  const parsed = requireFields(insertFabricTypeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.insert(fabricTypeMasterTable).values({ name, code }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/fabric-type/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertFabricTypeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.update(fabricTypeMasterTable).set({ name, code }).where(eq(fabricTypeMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/fabric-type/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(fabricTypeMasterTable).where(eq(fabricTypeMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Department Master ────────────────────────────────────────────────────────

router.get("/masters/department", async (_req, res): Promise<void> => {
  const rows = await db.select().from(departmentMasterTable).orderBy(departmentMasterTable.name);
  res.json(rows);
});

router.post("/masters/department", async (req, res): Promise<void> => {
  const parsed = requireFields(insertDepartmentMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.insert(departmentMasterTable).values({ name, code }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/department/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertDepartmentMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  try {
    const [row] = await db.update(departmentMasterTable).set({ name, code }).where(eq(departmentMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/department/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(departmentMasterTable).where(eq(departmentMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Machine Employee Master ──────────────────────────────────────────────────

function numOrNull(v: unknown): string | null {
  return v != null && v !== "" ? String(v) : null;
}

router.get("/masters/employee", async (_req, res): Promise<void> => {
  const rows = await db.select().from(employeeMasterTable).orderBy(employeeMasterTable.name);
  res.json(rows);
});

router.post("/masters/employee", async (req, res): Promise<void> => {
  const parsed = requireFields(insertEmployeeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { departmentId, baseSalary, overtimeRateHr, attAllowance, othAllowance, active } = req.body;
  try {
    const [row] = await db.insert(employeeMasterTable).values({
      name,
      code,
      departmentId: departmentId ?? null,
      baseSalary: numOrNull(baseSalary),
      overtimeRateHr: numOrNull(overtimeRateHr),
      attAllowance: numOrNull(attAllowance),
      othAllowance: numOrNull(othAllowance),
      active: active ?? true,
    }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/employee/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const parsed = requireFields(insertEmployeeMasterSchema, ["name", "code"], req.body, res);
  if (!parsed) return;
  const { name, code } = parsed;
  const { departmentId, baseSalary, overtimeRateHr, attAllowance, othAllowance, active } = req.body;
  try {
    const [row] = await db.update(employeeMasterTable).set({
      name,
      code,
      departmentId: departmentId ?? null,
      baseSalary: numOrNull(baseSalary),
      overtimeRateHr: numOrNull(overtimeRateHr),
      attAllowance: numOrNull(attAllowance),
      othAllowance: numOrNull(othAllowance),
      active: active ?? true,
    }).where(eq(employeeMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/employee/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(employeeMasterTable).where(eq(employeeMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

export default router;
