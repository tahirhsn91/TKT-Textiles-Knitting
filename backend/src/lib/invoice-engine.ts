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

/** The per-party preview payload (groups + source txs + summed weight). */
export interface UninvoicedPreview {
  groups: InvoiceGroup[];
  transactionHeaderIds: number[];
  totalNetWeight: string;
}

/** Round to 3 decimal places (net-weight precision). */
function round3(n: number): number {
  return Math.round((n + Number.EPSILON) * 1000) / 1000;
}

// ─── Fabric Delivery transaction type id (memoized, 60s TTL) ───────────────
// Resolving the type id is a tiny indexed lookup, but it used to run once per
// preview/party — the "Future Invoices" screen called it N+2 times per load.
// The master row only changes through admin edits (rare), so a short TTL cache
// (same pattern as the dashboard cache) turns that into one query per minute.
const TYPE_ID_CACHE_TTL_MS = 60_000;
let cachedFabricDeliveryTypeId: { id: number | null; expiresAt: number } | null = null;

/** Resolve the Fabric Delivery transaction type id by code (cached, 60s TTL). */
async function findFabricDeliveryTypeId(tenantId: number): Promise<number | null> {
  const now = Date.now();
  if (cachedFabricDeliveryTypeId && cachedFabricDeliveryTypeId.expiresAt > now) {
    return cachedFabricDeliveryTypeId.id;
  }
  const [row] = await db
    .select({ id: transactionTypeMasterTable.id })
    .from(transactionTypeMasterTable)
    .where(and(eq(transactionTypeMasterTable.code, FABRIC_DELIVERY_TRANSACTION_TYPE_CODE), eq(transactionTypeMasterTable.tenantId, tenantId)));
  const id = row?.id ?? null;
  // Cache only a found id, not a null miss, so a Fabric_Delivery row created
  // within the TTL window is picked up immediately instead of showing empty
  // previews for up to 60s (QA finding L3).
  if (id !== null) {
    cachedFabricDeliveryTypeId = { id, expiresAt: now + TYPE_ID_CACHE_TTL_MS };
  }
  return id;
}

/** A detail row as selected by the preview queries below. */
interface PreviewDetailRow {
  headerId: number;
  yarnTypeId: number | null;
  yarnCountId: number | null;
  uomId: number | null;
  netWt: string | null;
  yarnTypeName: string | null;
  hsCode: string | null;
  yarnCountName: string | null;
  uomName: string | null;
}

/**
 * Group detail rows by (yarnTypeId, yarnCountId), summing net weight and
 * collecting the source header ids (deduped). Shared by the single-party
 * preview and the batched all-parties loader so both stay identical.
 */
function groupDetails(details: PreviewDetailRow[]): InvoiceGroup[] {
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

  return [...map.values()].map((g) => ({
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
}

/**
 * Batched un-invoiced preview loader.
 *
 * Previously every party preview ran its own type lookup + header query +
 * detail query (3 round-trips per party). This does the whole job in 2
 * queries for ALL parties at once and groups in memory: the "Future Invoices"
 * screen went from ~3N+3 queries to 2.
 *
 * Returns a map keyed by party id. Each entry carries both the preview
 * payload and the raw summed weight so `listUninvoicedParties` keeps its
 * historical raw-sum total while the preview keeps its group-rounded total
 * (they can differ by 0.001 in rare rounding cases — preserved on purpose).
 */
async function loadUninvoicedPreviews(tenantId: number, partyIds?: number[]): Promise<
  Map<number, UninvoicedPreview & { partyName: string; totalNetWeightRaw: string }>
> {
  const previews = new Map<number, UninvoicedPreview & { partyName: string; totalNetWeightRaw: string }>();
  const typeId = await findFabricDeliveryTypeId(tenantId);
  if (!typeId) return previews;

  // Un-invoiced Fabric_Dispatch headers for the requested parties (or all):
  // anti-join on invoice_transaction (LEFT JOIN + NULL filter = NOT EXISTS).
  const headerWhere = and(
    eq(transactionHeaderTable.transactionTypeId, typeId),
    eq(transactionHeaderTable.tenantId, tenantId),
    isNull(invoiceTransactionTable.id),
    partyIds != null ? inArray(transactionHeaderTable.partyId, partyIds) : undefined,
  );
  const headerRows = await db
    .select({
      id: transactionHeaderTable.id,
      partyId: transactionHeaderTable.partyId,
      partyName: partyMasterTable.name,
    })
    .from(transactionHeaderTable)
    .innerJoin(partyMasterTable, eq(transactionHeaderTable.partyId, partyMasterTable.id))
    .leftJoin(invoiceTransactionTable, eq(invoiceTransactionTable.transactionHeaderId, transactionHeaderTable.id))
    .where(headerWhere)
    .orderBy(transactionHeaderTable.date, transactionHeaderTable.id);

  if (headerRows.length === 0) return previews;

  const headerIds = headerRows.map((h) => h.id);

  // Detail rows for all those headers, joined with yarn type / count / uom.
  // ORDER BY detail id makes group order deterministic across calls.
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
    .where(and(inArray(transactionDetailTable.headerId, headerIds), eq(transactionDetailTable.tenantId, tenantId)))
    .orderBy(transactionDetailTable.id);

  // Index the detail rows by their header so each party's slice is a cheap
  // look-up instead of repeated filtering.
  const detailsByHeader = new Map<number, PreviewDetailRow[]>();
  for (const d of details) {
    const arr = detailsByHeader.get(d.headerId);
    if (arr) arr.push(d);
    else detailsByHeader.set(d.headerId, [d]);
  }

  const partyNameByParty = new Map<number, string>();
  const headersByParty = new Map<number, number[]>();
  for (const h of headerRows) {
    const pid = h.partyId as number; // party_id on a Fabric_Dispatch header is always set
    partyNameByParty.set(pid, h.partyName ?? `Party #${pid}`);
    const arr = headersByParty.get(pid);
    if (arr) arr.push(h.id);
    else headersByParty.set(pid, [h.id]);
  }

  for (const [pid, hids] of headersByParty) {
    const partyDetails: PreviewDetailRow[] = [];
    let rawWeight = 0;
    for (const hid of hids) {
      const ds = detailsByHeader.get(hid);
      if (!ds) continue;
      for (const d of ds) {
        partyDetails.push(d);
        rawWeight += parseFloat(d.netWt ?? "0") || 0;
      }
    }
    const groups = groupDetails(partyDetails);
    // Preview total: summed from the ROUNDED group quantities (historical
    // getUninvoicedPreview semantics).
    const totalNetWeight = round3(groups.reduce((a, g) => a + parseFloat(g.quantity), 0)).toFixed(3);
    previews.set(pid, {
      partyName: partyNameByParty.get(pid) ?? `Party #${pid}`,
      groups,
      transactionHeaderIds: hids,
      totalNetWeight,
      totalNetWeightRaw: round3(rawWeight).toFixed(3),
    });
  }

  return previews;
}

/**
 * List parties that have at least one un-invoiced Fabric_Dispatch transaction.
 * Used by the Invoicing screen's party selector.
 */
export async function listUninvoicedParties(tenantId: number): Promise<UninvoicedParty[]> {
  const map = await loadUninvoicedPreviews(tenantId);
  return [...map.entries()]
    .map(([partyId, p]) => ({
      partyId,
      partyName: p.partyName,
      transactionCount: p.transactionHeaderIds.length,
      totalNetWeight: p.totalNetWeightRaw,
    }))
    .sort((a, b) => a.partyName.localeCompare(b.partyName));
}

/**
 * Fetch the aggregation preview (items) for a party's un-invoiced
 * Fabric_Dispatch transactions. Returns the item groups plus the source
 * transaction header ids so generation can claim exactly those.
 */
export async function getUninvoicedPreview(tenantId: number, partyId: number): Promise<UninvoicedPreview> {
  const map = await loadUninvoicedPreviews(tenantId, [partyId]);
  const p = map.get(partyId);
  if (!p) return { groups: [], transactionHeaderIds: [], totalNetWeight: "0.000" };
  return {
    groups: p.groups,
    transactionHeaderIds: p.transactionHeaderIds,
    totalNetWeight: p.totalNetWeight,
  };
}

/**
 * Batch previews for every party with un-invoiced transactions — the
 * "Future Invoices" projection loads all of them at once instead of looping
 * per-party previews (2 queries total vs ~2N).
 */
export async function getAllUninvoicedPreviews(tenantId: number): Promise<
  Map<number, UninvoicedPreview & { partyName: string }>
> {
  return loadUninvoicedPreviews(tenantId);
}

// Re-export the amount computation for the route layer / tests.
export { computeItemAmounts };
