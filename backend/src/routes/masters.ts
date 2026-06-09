import { Router, type IRouter } from "express";
import { eq } from "drizzle-orm";
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
  machineOperatorMasterTable,
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

// ─── Transaction Type Master ─────────────────────────────────────────────────

router.get("/masters/transaction-type", async (_req, res): Promise<void> => {
  const rows = await db.select().from(transactionTypeMasterTable).orderBy(transactionTypeMasterTable.name);
  res.json(rows);
});

router.post("/masters/transaction-type", async (req, res): Promise<void> => {
  const { name, code, action } = req.body;
  if (!name || !code) { res.status(400).json({ message: "name and code are required" }); return; }
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
  if (!id) { res.status(400).json({ message: "Invalid id" }); return; }
  const { name, code, action } = req.body;
  if (!name || !code) { res.status(400).json({ message: "name and code are required" }); return; }
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
  const { name, code, partyId } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, code, partyId } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, code, wastePercent } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
  const waste = wastePercent !== undefined && wastePercent !== "" ? String(parseFloat(wastePercent)) : "1.00";
  try {
    const [row] = await db.insert(partyMasterTable).values({ name, code, wastePercent: waste }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/party/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const { name, code, wastePercent } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
  const waste = wastePercent !== undefined && wastePercent !== "" ? String(parseFloat(wastePercent)) : "1.00";
  try {
    const [row] = await db.update(partyMasterTable).set({ name, code, wastePercent: waste }).where(eq(partyMasterTable.id, id)).returning();
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
  const { name, machineNumber } = req.body;
  if (!name || !machineNumber) { res.status(400).json({ error: "name and machineNumber are required" }); return; }
  try {
    const [row] = await db.insert(machineMasterTable).values({ name, machineNumber }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Machine number already exists" }); return; }
    throw err;
  }
});

router.put("/masters/machine/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const { name, machineNumber } = req.body;
  if (!name || !machineNumber) { res.status(400).json({ error: "name and machineNumber are required" }); return; }
  try {
    const [row] = await db.update(machineMasterTable).set({ name, machineNumber }).where(eq(machineMasterTable.id, id)).returning();
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
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, code, makeRate } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
  try {
    const [row] = await db.insert(yarnTypeMasterTable).values({
      name, code,
      makeRate: makeRate != null && makeRate !== "" ? String(makeRate) : null,
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
  const { name, code, makeRate } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
  try {
    const [row] = await db.update(yarnTypeMasterTable).set({
      name, code,
      makeRate: makeRate != null && makeRate !== "" ? String(makeRate) : null,
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
  const { name, count } = req.body;
  if (!name || !count) { res.status(400).json({ error: "name and count are required" }); return; }
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
  const { name, count } = req.body;
  if (!name || !count) { res.status(400).json({ error: "name and count are required" }); return; }
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
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, abbreviation } = req.body;
  if (!name || !abbreviation) { res.status(400).json({ error: "name and abbreviation are required" }); return; }
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
  const { name, abbreviation } = req.body;
  if (!name || !abbreviation) { res.status(400).json({ error: "name and abbreviation are required" }); return; }
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
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
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

// ─── Machine Operator Master ──────────────────────────────────────────────────

router.get("/masters/machine-operator", async (_req, res): Promise<void> => {
  const rows = await db.select().from(machineOperatorMasterTable).orderBy(machineOperatorMasterTable.name);
  res.json(rows);
});

router.post("/masters/machine-operator", async (req, res): Promise<void> => {
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
  try {
    const [row] = await db.insert(machineOperatorMasterTable).values({ name, code }).returning();
    res.status(201).json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.put("/masters/machine-operator/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const { name, code } = req.body;
  if (!name || !code) { res.status(400).json({ error: "name and code are required" }); return; }
  try {
    const [row] = await db.update(machineOperatorMasterTable).set({ name, code }).where(eq(machineOperatorMasterTable.id, id)).returning();
    if (!row) { res.status(404).json({ error: "Not found" }); return; }
    res.json(row);
  } catch (err) {
    if (isUniqueViolation(err)) { res.status(409).json({ error: "Code already exists" }); return; }
    throw err;
  }
});

router.delete("/masters/machine-operator/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db.delete(machineOperatorMasterTable).where(eq(machineOperatorMasterTable.id, id)).returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

export default router;
