import { Router, type IRouter } from "express";
import { eq, sql, desc, inArray } from "drizzle-orm";
import { db } from "@workspace/db";
import {
  transactionHeaderTable,
  transactionDetailTable,
  transactionTypeMasterTable,
  jobMasterTable,
  partyMasterTable,
  locationMasterTable,
  fabricTypeMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  uomMasterTable,
  machineMasterTable,
  machineOperatorMasterTable,
} from "@workspace/db";
import {
  ListTransactionsResponse,
  GetTransactionResponse,
  GetTransactionParams,
  CreateTransactionBody,
  UpdateTransactionParams,
  UpdateTransactionBody,
  UpdateTransactionResponse,
  DeleteTransactionParams,
} from "@workspace/api-zod";

const router: IRouter = Router();

function normalizeNumericString(v: string | null | undefined): string | null {
  if (v == null || v === "") return null;
  const trimmed = v.trim();
  if (trimmed === "") return null;
  const n = Number(trimmed);
  if (isNaN(n)) return null;
  return trimmed;
}

type DetailInput = { quantity?: string | null; netWt?: string | null; [key: string]: unknown };

function normalizeDetail<T extends DetailInput>(d: T): T {
  return {
    ...d,
    quantity: normalizeNumericString(d.quantity),
    netWt: normalizeNumericString(d.netWt),
  };
}

// ─── CSV Import helpers ────────────────────────────────────────────────────────

interface ImportCsvRow {
  date?: string;
  docNumber?: string;
  reference?: string;
  sl?: string;
  gsm?: string;
  transTypeName?: string;
  jobName?: string;
  partyName?: string;
  locationName?: string;
  fabricTypeName?: string;
  yarnTypeName?: string;
  yarnCountName?: string;
  yarnBrandName?: string;
  uomName?: string;
  machineName?: string;
  operatorName?: string;
  quantity?: string;
  netWt?: string;
}

/** Returns the ID for a non-empty name, or null if name is blank.
 *  If name is non-empty but not found, returns { id: null, error: message }. */
function resolveLookup(
  map: Map<string, number>,
  name: string | undefined,
  fieldLabel: string,
): { id: number | null; error: string | null } {
  if (!name || !name.trim()) return { id: null, error: null };
  const id = map.get(name.toLowerCase().trim());
  if (id == null) return { id: null, error: `Unknown ${fieldLabel}: "${name.trim()}"` };
  return { id, error: null };
}

function parseImportNumeric(s: string | undefined): string | null {
  if (!s || !s.trim()) return null;
  const clean = s.replace(/,/g, "");
  const n = parseFloat(clean);
  if (isNaN(n)) return null;
  return String(Math.abs(n));
}

async function buildMasterMaps() {
  const [transTypes, jobs, parties, locations, fabricTypes, yarnTypes, yarnCounts, yarnBrands, uoms, machines, operators] =
    await Promise.all([
      db.select({ id: transactionTypeMasterTable.id, name: transactionTypeMasterTable.name }).from(transactionTypeMasterTable),
      db.select({ id: jobMasterTable.id, name: jobMasterTable.name }).from(jobMasterTable),
      db.select({ id: partyMasterTable.id, name: partyMasterTable.name }).from(partyMasterTable),
      db.select({ id: locationMasterTable.id, name: locationMasterTable.name }).from(locationMasterTable),
      db.select({ id: fabricTypeMasterTable.id, name: fabricTypeMasterTable.name }).from(fabricTypeMasterTable),
      db.select({ id: yarnTypeMasterTable.id, name: yarnTypeMasterTable.name }).from(yarnTypeMasterTable),
      db.select({ id: yarnCountMasterTable.id, name: yarnCountMasterTable.name }).from(yarnCountMasterTable),
      db.select({ id: yarnBrandMasterTable.id, name: yarnBrandMasterTable.name }).from(yarnBrandMasterTable),
      db.select({ id: uomMasterTable.id, name: uomMasterTable.name }).from(uomMasterTable),
      db.select({ id: machineMasterTable.id, name: machineMasterTable.name }).from(machineMasterTable),
      db.select({ id: machineOperatorMasterTable.id, name: machineOperatorMasterTable.name }).from(machineOperatorMasterTable),
    ]);

  const toMap = (rows: { id: number; name: string }[]) =>
    new Map(rows.map((r) => [r.name.toLowerCase().trim(), r.id]));

  return {
    transTypes:  toMap(transTypes),
    jobs:        toMap(jobs),
    parties:     toMap(parties),
    locations:   toMap(locations),
    fabricTypes: toMap(fabricTypes),
    yarnTypes:   toMap(yarnTypes),
    yarnCounts:  toMap(yarnCounts),
    yarnBrands:  toMap(yarnBrands),
    uoms:        toMap(uoms),
    machines:    toMap(machines),
    operators:   toMap(operators),
  };
}

async function processImport(rows: ImportCsvRow[], doInsert: boolean) {
  const maps = await buildMasterMaps();

  const totalRows = rows.length;

  // Group by docNumber — each group becomes one header + N details
  const groups = new Map<string, { first: ImportCsvRow; rows: ImportCsvRow[] }>();
  for (const row of rows) {
    const key = (row.docNumber ?? "").trim();
    if (!key) continue;
    if (!groups.has(key)) groups.set(key, { first: row, rows: [] });
    groups.get(key)!.rows.push(row);
  }

  const docNumbers = [...groups.keys()];

  // Duplicate check
  let existingSet = new Set<string>();
  if (docNumbers.length > 0) {
    const existing = await db
      .select({ docNumber: transactionHeaderTable.docNumber })
      .from(transactionHeaderTable)
      .where(inArray(transactionHeaderTable.docNumber, docNumbers));
    existingSet = new Set(existing.map((r) => r.docNumber));
  }

  let toImport   = 0;
  let imported   = 0;
  let duplicates = 0;
  const errors: { docNumber: string; message: string }[] = [];

  for (const [docNum, group] of groups) {
    if (existingSet.has(docNum)) { duplicates++; continue; }

    const first = group.first;

    if (!first.date || !first.date.trim()) {
      errors.push({ docNumber: docNum, message: "Missing date" });
      continue;
    }

    // Resolve all header lookups — non-empty names that can't be matched are errors
    const transTypeId = maps.transTypes.get((first.transTypeName ?? "").toLowerCase().trim());
    if (!transTypeId) {
      errors.push({ docNumber: docNum, message: `Unknown transaction type: "${first.transTypeName ?? ""}"` });
      continue;
    }

    const jobR         = resolveLookup(maps.jobs,        first.jobName,        "job");
    const partyR       = resolveLookup(maps.parties,     first.partyName,      "party");
    const locationR    = resolveLookup(maps.locations,   first.locationName,   "location");
    const fabricTypeR  = resolveLookup(maps.fabricTypes, first.fabricTypeName, "fabric type");

    // Resolve detail lookups per-row — collect all resolution errors across all detail rows
    const detailResults = group.rows.map((r, ri) => {
      const yarnTypeR  = resolveLookup(maps.yarnTypes,  r.yarnTypeName,  "yarn type");
      const yarnCountR = resolveLookup(maps.yarnCounts, r.yarnCountName, "yarn count");
      const yarnBrandR = resolveLookup(maps.yarnBrands, r.yarnBrandName, "yarn brand");
      const uomR       = resolveLookup(maps.uoms,       r.uomName,       "UOM");
      const machineR   = resolveLookup(maps.machines,   r.machineName,   "machine");
      const operatorR  = resolveLookup(maps.operators,  r.operatorName,  "operator");
      const rowErrors  = [yarnTypeR, yarnCountR, yarnBrandR, uomR, machineR, operatorR]
        .filter((x) => x.error)
        .map((x) => `(row ${ri + 1}) ${x.error}`);
      return { yarnTypeR, yarnCountR, yarnBrandR, uomR, machineR, operatorR, rowErrors };
    });

    const allErrors = [
      ...[jobR, partyR, locationR, fabricTypeR].filter((x) => x.error).map((x) => x.error as string),
      ...detailResults.flatMap((d) => d.rowErrors),
    ];

    if (allErrors.length > 0) {
      errors.push({ docNumber: docNum, message: allErrors.join("; ") });
      continue;
    }

    toImport++;

    if (doInsert) {
      try {
        await db.transaction(async (tx) => {
          const gsmVal = first.gsm ? parseInt(first.gsm, 10) : null;
          const [header] = await tx
            .insert(transactionHeaderTable)
            .values({
              transactionTypeId: transTypeId,
              date:              first.date!.trim(),
              docNumber:         docNum,
              reference:         first.reference?.trim() || null,
              sl:                first.sl?.trim() || null,
              gsm:               gsmVal && !isNaN(gsmVal) ? gsmVal : null,
              jobId:             jobR.id,
              partyId:           partyR.id,
              locationId:        locationR.id,
              fabricTypeId:      fabricTypeR.id,
            })
            .returning();

          if (group.rows.length > 0) {
            await tx.insert(transactionDetailTable).values(
              detailResults.map((d, i) => ({
                headerId:          header.id,
                yarnTypeId:        d.yarnTypeR.id,
                yarnCountId:       d.yarnCountR.id,
                yarnBrandId:       d.yarnBrandR.id,
                uomId:             d.uomR.id,
                machineId:         d.machineR.id,
                machineOperatorId: d.operatorR.id,
                quantity:          parseImportNumeric(group.rows[i].quantity),
                netWt:             parseImportNumeric(group.rows[i].netWt),
              }))
            );
          }
        });
        imported++;
      } catch (err) {
        errors.push({ docNumber: docNum, message: `Insert failed: ${err instanceof Error ? err.message : String(err)}` });
      }
    }
  }

  return { totalRows, toImport, imported, duplicates, errors, previewRows: rows.slice(0, 10) };
}

// ─── Routes ───────────────────────────────────────────────────────────────────

router.get("/transactions", async (_req, res): Promise<void> => {
  const rows = await db
    .select({
      id:                transactionHeaderTable.id,
      transactionTypeId: transactionHeaderTable.transactionTypeId,
      date:              transactionHeaderTable.date,
      docNumber:         transactionHeaderTable.docNumber,
      jobId:             transactionHeaderTable.jobId,
      partyId:           transactionHeaderTable.partyId,
      locationId:        transactionHeaderTable.locationId,
      fabricTypeId:      transactionHeaderTable.fabricTypeId,
      sl:                transactionHeaderTable.sl,
      gsm:               transactionHeaderTable.gsm,
      reference:         transactionHeaderTable.reference,
      yarnBrandIds:      sql<number[]>`array_remove(array_agg(DISTINCT ${transactionDetailTable.yarnBrandId}), NULL)`,
    })
    .from(transactionHeaderTable)
    .leftJoin(transactionDetailTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .groupBy(transactionHeaderTable.id)
    .orderBy(transactionHeaderTable.id);
  res.json(ListTransactionsResponse.parse(rows));
});

router.post("/transactions", async (req, res): Promise<void> => {
  const parsed = CreateTransactionBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.message });
    return;
  }

  const { details, ...headerData } = parsed.data;

  const result = await db.transaction(async (tx) => {
    const [header] = await tx
      .insert(transactionHeaderTable)
      .values(headerData)
      .returning();

    let detailRows: (typeof transactionDetailTable.$inferSelect)[] = [];
    if (details && details.length > 0) {
      detailRows = await tx
        .insert(transactionDetailTable)
        .values(details.map((d) => ({ ...normalizeDetail(d), headerId: header.id })))
        .returning();
    }

    return { ...header, details: detailRows };
  });

  res.status(201).json(GetTransactionResponse.parse(result));
});

router.get("/transactions/suggestions", async (_req, res): Promise<void> => {
  const rows = await db
    .select({ docNumber: transactionHeaderTable.docNumber, reference: transactionHeaderTable.reference })
    .from(transactionHeaderTable)
    .orderBy(desc(transactionHeaderTable.id));

  let maxNumeric = 0;
  for (const r of rows) {
    const n = parseInt(r.docNumber ?? "", 10);
    if (!isNaN(n) && n > maxNumeric) maxNumeric = n;
  }

  const lastReference = rows.find((r) => r.reference != null && r.reference.trim() !== "")?.reference ?? null;

  res.json({ nextDocNumber: String(maxNumeric + 1), lastReference });
});

// ─── CSV Import endpoints (must be before /:id) ───────────────────────────────

router.post("/transactions/import/preview", async (req, res): Promise<void> => {
  const { rows } = req.body as { rows?: unknown };
  if (!Array.isArray(rows)) {
    res.status(400).json({ error: "rows must be an array" });
    return;
  }
  const result = await processImport(rows as ImportCsvRow[], false);
  res.json({
    totalRows:   result.totalRows,
    toImport:    result.toImport,
    duplicates:  result.duplicates,
    errors:      result.errors,
    previewRows: result.previewRows,
  });
});

router.post("/transactions/import", async (req, res): Promise<void> => {
  const { rows } = req.body as { rows?: unknown };
  if (!Array.isArray(rows)) {
    res.status(400).json({ error: "rows must be an array" });
    return;
  }
  const result = await processImport(rows as ImportCsvRow[], true);
  res.json({
    totalRows: result.totalRows,
    imported:  result.imported,
    skipped:   result.duplicates,
    errors:    result.errors,
  });
});

// ─── Single-transaction CRUD ──────────────────────────────────────────────────

router.get("/transactions/:id", async (req, res): Promise<void> => {
  const params = GetTransactionParams.safeParse(req.params);
  if (!params.success) {
    res.status(400).json({ error: params.error.message });
    return;
  }

  const [header] = await db
    .select()
    .from(transactionHeaderTable)
    .where(eq(transactionHeaderTable.id, params.data.id));

  if (!header) {
    res.status(404).json({ error: "Transaction not found" });
    return;
  }

  const details = await db
    .select()
    .from(transactionDetailTable)
    .where(eq(transactionDetailTable.headerId, params.data.id))
    .orderBy(transactionDetailTable.id);

  res.json(GetTransactionResponse.parse({ ...header, details }));
});

router.put("/transactions/:id", async (req, res): Promise<void> => {
  const params = UpdateTransactionParams.safeParse(req.params);
  if (!params.success) {
    res.status(400).json({ error: params.error.message });
    return;
  }

  const parsed = UpdateTransactionBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.message });
    return;
  }

  const { details, ...headerData } = parsed.data;

  const result = await db.transaction(async (tx) => {
    const [header] = await tx
      .update(transactionHeaderTable)
      .set(headerData)
      .where(eq(transactionHeaderTable.id, params.data.id))
      .returning();

    if (!header) return null;

    await tx
      .delete(transactionDetailTable)
      .where(eq(transactionDetailTable.headerId, params.data.id));

    let detailRows: (typeof transactionDetailTable.$inferSelect)[] = [];
    if (details && details.length > 0) {
      detailRows = await tx
        .insert(transactionDetailTable)
        .values(details.map((d) => ({ ...normalizeDetail(d), headerId: header.id })))
        .returning();
    }

    return { ...header, details: detailRows };
  });

  if (!result) {
    res.status(404).json({ error: "Transaction not found" });
    return;
  }

  res.json(UpdateTransactionResponse.parse(result));
});

router.delete("/transactions/:id", async (req, res): Promise<void> => {
  const params = DeleteTransactionParams.safeParse(req.params);
  if (!params.success) {
    res.status(400).json({ error: params.error.message });
    return;
  }

  const [deleted] = await db
    .delete(transactionHeaderTable)
    .where(eq(transactionHeaderTable.id, params.data.id))
    .returning();

  if (!deleted) {
    res.status(404).json({ error: "Transaction not found" });
    return;
  }

  res.sendStatus(204);
});

export default router;
