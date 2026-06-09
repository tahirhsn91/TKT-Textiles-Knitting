import { Router, type IRouter } from "express";
import { eq, sql, desc } from "drizzle-orm";
import { db } from "../db/index.js";
import { transactionHeaderTable, transactionDetailTable } from "../db/index.js";
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
