import { Router, type IRouter } from "express";
import { eq, and, sql, desc, inArray } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  dailyProductionHeaderTable,
  yarnReceiptHeaderTable,
  dailyDeliveryTable,
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
} from "../db/index.js";
import {
  ListTransactionsResponse,
  GetTransactionResponse,
  GetTransactionParams,
  CreateTransactionBody,
  UpdateTransactionParams,
  UpdateTransactionBody,
  UpdateTransactionResponse,
  DeleteTransactionParams,
} from "../api-zod/index.js";

const router: IRouter = Router();

/** Daily-production entries a Fabric Production transaction is claiming. */
const reconcileIdsSchema = z.object({
  reconcileProductionIds: z.array(z.number().int().positive()).optional(),
  /** Yarn receipts a Yarn Receipt transaction is claiming. */
  reconcileReceiptIds: z.array(z.number().int().positive()).optional(),
  /** Daily deliveries a Fabric Delivery transaction is claiming. */
  reconcileDeliveryIds: z.array(z.number().int().positive()).optional(),
});

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

export interface ImportError {
  docNumber: string;
  row: number | null;
  field: string;
  value: string;
  reason: string;
}

/** Returns the ID for a non-empty name, or null if name is blank.
 *  If name is non-empty but not found, returns structured error info. */
function resolveLookup(
  map: Map<string, number>,
  name: string | undefined,
  fieldLabel: string,
): { id: number | null; field: string | null; value: string | null } {
  if (!name || !name.trim()) return { id: null, field: null, value: null };
  const id = map.get(name.toLowerCase().trim());
  if (id == null) return { id: null, field: fieldLabel, value: name.trim() };
  return { id, field: null, value: null };
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
  const errors: ImportError[] = [];

  for (const [docNum, group] of groups) {
    if (existingSet.has(docNum)) { duplicates++; continue; }

    const first = group.first;

    if (!first.date || !first.date.trim()) {
      errors.push({ docNumber: docNum, row: null, field: "Date", value: "", reason: "Missing date" });
      continue;
    }

    // Resolve all header lookups — non-empty names that can't be matched are errors
    const transTypeId = maps.transTypes.get((first.transTypeName ?? "").toLowerCase().trim());
    if (!transTypeId) {
      errors.push({
        docNumber: docNum,
        row: null,
        field: "Trans Type",
        value: first.transTypeName?.trim() ?? "",
        reason: "Not found in master list",
      });
      continue;
    }

    const jobR         = resolveLookup(maps.jobs,        first.jobName,        "Job");
    const partyR       = resolveLookup(maps.parties,     first.partyName,      "Party");
    const locationR    = resolveLookup(maps.locations,   first.locationName,   "Location");
    const fabricTypeR  = resolveLookup(maps.fabricTypes, first.fabricTypeName, "Fabric Type");

    // Resolve detail lookups per-row — collect all resolution errors across all detail rows
    const detailResults = group.rows.map((r, ri) => {
      const yarnTypeR  = resolveLookup(maps.yarnTypes,  r.yarnTypeName,  "Yarn Type");
      const yarnCountR = resolveLookup(maps.yarnCounts, r.yarnCountName, "Yarn Count");
      const yarnBrandR = resolveLookup(maps.yarnBrands, r.yarnBrandName, "Yarn Brand");
      const uomR       = resolveLookup(maps.uoms,       r.uomName,       "UOM");
      const machineR   = resolveLookup(maps.machines,   r.machineName,   "Machine");
      const operatorR  = resolveLookup(maps.operators,  r.operatorName,  "Operator");
      const rowErrors: ImportError[] = [yarnTypeR, yarnCountR, yarnBrandR, uomR, machineR, operatorR]
        .filter((x) => x.field !== null)
        .map((x) => ({
          docNumber: docNum,
          row: ri + 1,
          field: x.field as string,
          value: x.value as string,
          reason: "Not found in master list",
        }));
      return { yarnTypeR, yarnCountR, yarnBrandR, uomR, machineR, operatorR, rowErrors };
    });

    const headerErrors: ImportError[] = [
      { r: jobR,        field: "Job" },
      { r: partyR,      field: "Party" },
      { r: locationR,   field: "Location" },
      { r: fabricTypeR, field: "Fabric Type" },
    ]
      .filter(({ r }) => r.field !== null)
      .map(({ r }) => ({
        docNumber: docNum,
        row: null,
        field: r.field as string,
        value: r.value as string,
        reason: "Not found in master list",
      }));

    const allErrors = [...headerErrors, ...detailResults.flatMap((d) => d.rowErrors)];

    if (allErrors.length > 0) {
      errors.push(...allErrors);
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
        errors.push({
          docNumber: docNum,
          row: null,
          field: "",
          value: "",
          reason: `Insert failed: ${err instanceof Error ? err.message : String(err)}`,
        });
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

  // Parsed separately from CreateTransactionBody, which is generated from the
  // OpenAPI spec and must not be hand-edited. Ids are optional: only the
  // Fabric Production flow sends them.
  const reconcile = reconcileIdsSchema.safeParse(req.body);
  if (!reconcile.success) {
    res.status(400).json({ error: "reconcileProductionIds must be an array of positive integers" });
    return;
  }
  const reconcileIds = reconcile.data.reconcileProductionIds ?? [];
  const reconcileReceiptIds = reconcile.data.reconcileReceiptIds ?? [];
  const reconcileDeliveryIds = reconcile.data.reconcileDeliveryIds ?? [];

  let conflict: { error: string } | null = null;

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

    if (reconcileIds.length > 0) {
      // `reconciled = false` in the WHERE is the concurrency guard. Two users
      // booking the same production day at once would otherwise both succeed
      // and the output would be counted twice. The update claims only rows
      // still free; if any were taken in between, the count comes up short and
      // the whole transaction — header, details and all — rolls back.
      const claimed = await tx
        .update(dailyProductionHeaderTable)
        .set({
          reconciled: true,
          reconciledTransactionId: header.id,
          reconciledAt: new Date(),
        })
        .where(and(
          inArray(dailyProductionHeaderTable.id, reconcileIds),
          eq(dailyProductionHeaderTable.reconciled, false),
        ))
        .returning({ id: dailyProductionHeaderTable.id });

      if (claimed.length !== reconcileIds.length) {
        conflict = {
          error:
            "Some of the selected production entries were reconciled by another transaction. Reload the production list and try again.",
        };
        tx.rollback();
      }
    }

    if (reconcileReceiptIds.length > 0) {
      // Same concurrency guard as production: claim only receipts still free,
      // roll back everything if any were already consumed.
      const claimed = await tx
        .update(yarnReceiptHeaderTable)
        .set({
          reconciled: true,
          reconciledTransactionId: header.id,
          reconciledAt: new Date(),
        })
        .where(and(
          inArray(yarnReceiptHeaderTable.id, reconcileReceiptIds),
          eq(yarnReceiptHeaderTable.reconciled, false),
        ))
        .returning({ id: yarnReceiptHeaderTable.id });

      if (claimed.length !== reconcileReceiptIds.length) {
        conflict = {
          error:
            "Some of the selected yarn receipts were already booked into another transaction. Reload the receipts and try again.",
        };
        tx.rollback();
      }
    }

    if (reconcileDeliveryIds.length > 0) {
      // Same concurrency guard: claim only deliveries still free, roll back
      // everything if any were already consumed.
      const claimed = await tx
        .update(dailyDeliveryTable)
        .set({
          reconciled: true,
          reconciledTransactionId: header.id,
          reconciledAt: new Date(),
        })
        .where(and(
          inArray(dailyDeliveryTable.id, reconcileDeliveryIds),
          eq(dailyDeliveryTable.reconciled, false),
        ))
        .returning({ id: dailyDeliveryTable.id });

      if (claimed.length !== reconcileDeliveryIds.length) {
        conflict = {
          error:
            "Some of the selected daily deliveries were already booked into another transaction. Reload the deliveries and try again.",
        };
        tx.rollback();
      }
    }

    return { ...header, details: detailRows };
  }).catch((err) => {
    if (conflict) return null;
    throw err;
  });

  if (conflict) { res.status(409).json(conflict); return; }

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
