import { eq, and, inArray, isNull } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  transactionHeaderTable,
  transactionDetailTable,
  transactionTypeMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  uomMasterTable,
  partyMasterTable,
  invoiceTransactionTable,
} from "../db/index.js";
import { FABRIC_DELIVERY_TRANSACTION_TYPE_CODE } from "./fbr/constants.js";
import { computeItemAmounts } from "./fbr/client.js";

/**
 * Invoice generation engine.
 *
 * Generates one FBR invoice per party from ALL not-yet-invoiced
 * Fabric_Dispatch transactions for that party (across all dates), grouped by
 * (party, yarn type, yarn count); sum(net weight) becomes the item quantity.
 *
 * "Not-yet-invoiced" = a transaction header with no row in `invoice_transaction`
 * (the junction is the single source of truth for consumption). Generation
 * creates a draft invoice + items and inserts junction rows, marking the
 * transactions consumed. Deleting a draft invoice removes its junction rows,
 * making them available again.
 */

export interface InvoiceGroup {
  yarnTypeId: number;
  yarnTypeName: string | null;
  yarnCountId: number | null;
  yarnCountName: string | null;
  hsCode: string | null;
  uoM: string | null;
  productDescription: string | null;
  /** Summed net weight, 3 dp. */
  quantity: string;
  transactionHeaderIds: number[];
}

export interface UninvoicedParty {
  partyId: number;
  partyName: string;
  transactionCount: number;
  totalNetWeight: string;
}

/** Round to 3 decimal places (net-weight precision). */
function round3(n: number): number {
  return Math.round((n + Number.EPSILON) * 1000) / 1000;
}

/** Resolve the Fabric Delivery transaction type id by code. */
async function findFabricDeliveryTypeId(): Promise<number | null> {
  const [row] = await db
    .select({ id: transactionTypeMasterTable.id })
    .from(transactionTypeMasterTable)
    .where(eq(transactionTypeMasterTable.code, FABRIC_DELIVERY_TRANSACTION_TYPE_CODE));
  return row?.id ?? null;
}

/** Un-invoiced Fabric_Dispatch header rows for a party. */
async function findUninvoicedHeaders(partyId: number): Promise<{ id: number; date: string }[]> {
  const typeId = await findFabricDeliveryTypeId();
  if (!typeId) return [];

  // Fabric_Dispatch headers for the party whose transaction is NOT consumed:
  // an anti-join on invoice_transaction. `isNull` on the junction fk surfaces
  // headers with no junction row (LEFT JOIN + NULL filter = NOT EXISTS).
  const rows = await db
    .select({
      id: transactionHeaderTable.id,
      date: transactionHeaderTable.date,
      consumed: invoiceTransactionTable.id,
    })
    .from(transactionHeaderTable)
    .leftJoin(invoiceTransactionTable, eq(invoiceTransactionTable.transactionHeaderId, transactionHeaderTable.id))
    .where(and(
      eq(transactionHeaderTable.transactionTypeId, typeId),
      eq(transactionHeaderTable.partyId, partyId),
      isNull(invoiceTransactionTable.id),
    ))
    .orderBy(transactionHeaderTable.date);

  return rows.map((r) => ({ id: r.id, date: r.date }));
}

/**
 * List parties that have at least one un-invoiced Fabric_Dispatch transaction.
 * Used by the Invoicing screen's party selector.
 */
export async function listUninvoicedParties(): Promise<UninvoicedParty[]> {
  const typeId = await findFabricDeliveryTypeId();
  if (!typeId) return [];

  // Un-invoiced Fabric_Dispatch headers (anti-join on invoice_transaction),
  // aggregated per party for count + total net weight (via their details).
  const uninvoiced = await db
    .select({
      id: transactionHeaderTable.id,
      partyId: transactionHeaderTable.partyId,
      partyName: partyMasterTable.name,
    })
    .from(transactionHeaderTable)
    .innerJoin(partyMasterTable, eq(transactionHeaderTable.partyId, partyMasterTable.id))
    .leftJoin(invoiceTransactionTable, eq(invoiceTransactionTable.transactionHeaderId, transactionHeaderTable.id))
    .where(and(
      eq(transactionHeaderTable.transactionTypeId, typeId),
      isNull(invoiceTransactionTable.id),
    ));

  if (uninvoiced.length === 0) return [];

  const headerIds = uninvoiced.map((h) => h.id).filter((x): x is number => x != null);
  const detailSums = await db
    .select({
      headerId: transactionDetailTable.headerId,
      netWt: transactionDetailTable.netWt,
    })
    .from(transactionDetailTable)
    .where(inArray(transactionDetailTable.headerId, headerIds));

  const weightByHeader = new Map<number, number>();
  for (const d of detailSums) {
    const hdrId = d.headerId as number;
    weightByHeader.set(hdrId, (weightByHeader.get(hdrId) ?? 0) + (parseFloat(d.netWt ?? "0") || 0));
  }

  // Aggregate per party (party_id on a Fabric_Dispatch header is always set).
  const byParty = new Map<number, { partyName: string; count: number; weight: number }>();
  for (const h of uninvoiced) {
    const partyId = h.partyId as number;
    let p = byParty.get(partyId);
    if (!p) { p = { partyName: h.partyName, count: 0, weight: 0 }; byParty.set(partyId, p); }
    p.count += 1;
    p.weight += weightByHeader.get(h.id as number) ?? 0;
  }

  return [...byParty.entries()]
    .map(([partyId, p]) => ({
      partyId,
      partyName: p.partyName,
      transactionCount: p.count,
      totalNetWeight: round3(p.weight).toFixed(3),
    }))
    .sort((a, b) => a.partyName.localeCompare(b.partyName));
}

/**
 * Fetch the aggregation preview (items) for a party's un-invoiced
 * Fabric_Dispatch transactions. Returns the item groups plus the source
 * transaction header ids so generation can claim exactly those.
 */
export async function getUninvoicedPreview(partyId: number): Promise<{
  groups: InvoiceGroup[];
  transactionHeaderIds: number[];
  totalNetWeight: string;
}> {
  const headers = await findUninvoicedHeaders(partyId);
  const transactionHeaderIds = headers.map((h) => h.id);

  if (transactionHeaderIds.length === 0) {
    return { groups: [], transactionHeaderIds, totalNetWeight: "0.000" };
  }

  // Detail rows for those headers, joined with yarn type / count / uom.
  const details = await db
    .select({
      headerId: transactionDetailTable.headerId,
      yarnTypeId: transactionDetailTable.yarnTypeId,
      yarnCountId: transactionDetailTable.yarnCountId,
      uomId: transactionDetailTable.uomId,
      netWt: transactionDetailTable.netWt,
      yarnTypeName: yarnTypeMasterTable.name,
      hsCode: yarnTypeMasterTable.hsCode,
      yarnCountName: yarnCountMasterTable.count,
      uomName: uomMasterTable.name,
    })
    .from(transactionDetailTable)
    .leftJoin(yarnTypeMasterTable, eq(transactionDetailTable.yarnTypeId, yarnTypeMasterTable.id))
    .leftJoin(yarnCountMasterTable, eq(transactionDetailTable.yarnCountId, yarnCountMasterTable.id))
    .leftJoin(uomMasterTable, eq(transactionDetailTable.uomId, uomMasterTable.id))
    .where(inArray(transactionDetailTable.headerId, transactionHeaderIds));

  // Group by (yarnTypeId, yarnCountId), sum net weight, collect header ids.
  const map = new Map<string, InvoiceGroup & { sum: number; uomId: number | null }>();
  for (const d of details) {
    const key = `${d.yarnTypeId ?? "null"}|${d.yarnCountId ?? "null"}`;
    let g = map.get(key);
    if (!g) {
      g = {
        yarnTypeId: d.yarnTypeId ?? 0,
        yarnTypeName: d.yarnTypeName,
        yarnCountId: d.yarnCountId,
        yarnCountName: d.yarnCountName,
        hsCode: d.hsCode,
        uoM: d.uomName,
        productDescription: d.yarnTypeName ? `${d.yarnTypeName} fabric` : "Fabric",
        quantity: "0.000",
        transactionHeaderIds: [],
        sum: 0,
        uomId: d.uomId,
      };
      map.set(key, g);
    }
    g.sum += parseFloat(d.netWt ?? "0") || 0;
    if (!g.transactionHeaderIds.includes(d.headerId)) g.transactionHeaderIds.push(d.headerId);
    if (g.uomId == null && d.uomId != null) { g.uomId = d.uomId; g.uoM = d.uomName; }
    if (g.uoM == null) g.uoM = d.uomName;
  }

  const groups: InvoiceGroup[] = [...map.values()].map((g) => ({
    yarnTypeId: g.yarnTypeId,
    yarnTypeName: g.yarnTypeName,
    yarnCountId: g.yarnCountId,
    yarnCountName: g.yarnCountName,
    hsCode: g.hsCode,
    uoM: g.uoM,
    productDescription: g.productDescription,
    quantity: round3(g.sum).toFixed(3),
    transactionHeaderIds: g.transactionHeaderIds,
  }));

  const totalNetWeight = round3(groups.reduce((a, g) => a + parseFloat(g.quantity), 0)).toFixed(3);

  return { groups, transactionHeaderIds, totalNetWeight };
}

// Re-export the amount computation for the route layer / tests.
export { computeItemAmounts };
