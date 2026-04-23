import { Router, type IRouter } from "express";
import { eq } from "drizzle-orm";
import { db } from "@workspace/db";
import { transactionHeaderTable, transactionDetailTable } from "@workspace/db";
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

router.get("/transactions", async (_req, res): Promise<void> => {
  const rows = await db
    .select()
    .from(transactionHeaderTable)
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

  const [header] = await db
    .insert(transactionHeaderTable)
    .values(headerData)
    .returning();

  let detailRows: (typeof transactionDetailTable.$inferSelect)[] = [];
  if (details && details.length > 0) {
    detailRows = await db
      .insert(transactionDetailTable)
      .values(details.map((d) => ({ ...d, headerId: header.id })))
      .returning();
  }

  res.status(201).json(
    GetTransactionResponse.parse({ ...header, details: detailRows })
  );
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

  const [header] = await db
    .update(transactionHeaderTable)
    .set(headerData)
    .where(eq(transactionHeaderTable.id, params.data.id))
    .returning();

  if (!header) {
    res.status(404).json({ error: "Transaction not found" });
    return;
  }

  await db
    .delete(transactionDetailTable)
    .where(eq(transactionDetailTable.headerId, params.data.id));

  let detailRows: (typeof transactionDetailTable.$inferSelect)[] = [];
  if (details && details.length > 0) {
    detailRows = await db
      .insert(transactionDetailTable)
      .values(details.map((d) => ({ ...d, headerId: header.id })))
      .returning();
  }

  res.json(UpdateTransactionResponse.parse({ ...header, details: detailRows }));
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
