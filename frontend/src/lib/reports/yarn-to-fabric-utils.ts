/**
 * Pure helpers, types and constants for the Yarn-to-Fabric report (issue #17).
 *
 * Extracted out of the ~1,500-line page so the report's data logic can be unit
 * tested in isolation and the page stays a thinner orchestration layer. Nothing
 * in this module touches the DOM or React state — every function is pure.
 */

// ─── Types ───────────────────────────────────────────────────────────────────

export interface ReportRow {
  headerId: number;
  date: string;
  docNumber: string;
  reference: string | null;
  sl: string | null;
  gsm: number | null;
  transactionTypeName: string | null;
  transactionTypeAction: string | null;
  jobName: string | null;
  partyName: string | null;
  locationName: string | null;
  fabricTypeName: string | null;
  detailId: number;
  quantity: string | null;
  netWt: string | null;
  yarnTypeName: string | null;
  yarnCountName: string | null;
  yarnBrandName: string | null;
  uomName: string | null;
  machineName: string | null;
  employeeName: string | null;
  partyWastePercent: string | null;
}

export interface Filters {
  dateFrom: string;
  dateTo: string;
  year: string;
  month: string;
  docNumber: string;
  reference: string;
  transactionTypeId: string[];
  jobId: string[];
  partyId: string[];
  locationId: string[];
  fabricTypeId: string[];
  yarnTypeId: string[];
  yarnCountId: string[];
  yarnBrandId: string[];
  uomId: string[];
  machineId: string[];
  employeeId: string[];
}

export type GroupByKey =
  | "date" | "month" | "docNumber" | "reference" | "transactionTypeName"
  | "partyName" | "jobName" | "locationName" | "fabricTypeName"
  | "machineName" | "employeeName"
  | "yarnTypeName" | "yarnCountName" | "yarnBrandName" | "uomName";

export type SummarySortKey      = "label" | "count" | "qty";
export type PartyBalanceSortKey = "party" | "fabricDelivery" | "fabricReturn" | "netOutstanding";
export type SortDir             = "asc" | "desc";

export type DetailColKey =
  | "date" | "docNumber" | "reference" | "sl" | "gsm" | "transactionTypeName"
  | "jobName" | "partyName" | "locationName" | "fabricTypeName"
  | "yarnTypeName" | "yarnCountName" | "yarnBrandName" | "uomName"
  | "machineName" | "employeeName" | "quantity"
  | "fabricProduction" | "fabricDelivery"
  | "fabricDeliveryReturn" | "runningFabricBalance";

export type Y2FGroupedRow = {
  label: string;
  count: number;
  qty: number;
  fabricProduction: number;
  fabricDelivery: number;
  fabricDeliveryReturn: number;
  fabricDelta: number;
  docNums: string[];
  refs: string[];
};

// ─── Constants ───────────────────────────────────────────────────────────────

export const EMPTY_FILTERS: Filters = {
  dateFrom: "", dateTo: "", year: "", month: "", docNumber: "", reference: "",
  transactionTypeId: [], jobId: [], partyId: [], locationId: [], fabricTypeId: [],
  yarnTypeId: [], yarnCountId: [], yarnBrandId: [], uomId: [],
  machineId: [], employeeId: [],
};

export const GROUP_BY_OPTIONS: { value: GroupByKey; label: string }[] = [
  { value: "date",                label: "Date" },
  { value: "month",               label: "Month" },
  { value: "docNumber",           label: "Doc Number" },
  { value: "reference",           label: "Reference" },
  { value: "transactionTypeName", label: "Transaction Type" },
  { value: "partyName",           label: "Party" },
  { value: "jobName",             label: "Job" },
  { value: "locationName",        label: "Location" },
  { value: "fabricTypeName",      label: "Fabric Type" },
  { value: "machineName",         label: "Machine" },
  { value: "employeeName", label: "Employee" },
  { value: "yarnTypeName",        label: "Yarn Type" },
  { value: "yarnCountName",       label: "Yarn Count" },
  { value: "yarnBrandName",       label: "Yarn Brand" },
  { value: "uomName",             label: "UOM" },
];

export const CHART_COLORS = [
  "#2563eb", "#16a34a", "#dc2626", "#d97706", "#7c3aed",
  "#0891b2", "#be185d", "#65a30d", "#ea580c", "#6d28d9",
];

export const MONTHS = [
  "January","February","March","April","May","June",
  "July","August","September","October","November","December",
];

/** Transaction types shown in this report — all others are excluded. */
export const FABRIC_TX_TYPES = new Set([
  "Fabric Production",
  "Fabric Delivery",
  "Fabric Delivery Return",
]);

export const DETAIL_COLUMNS: { key: DetailColKey; label: string }[] = [
  { key: "date",                  label: "Date" },
  { key: "docNumber",             label: "Doc Number" },
  { key: "reference",             label: "Reference" },
  { key: "sl",                    label: "SL" },
  { key: "gsm",                   label: "GSM" },
  { key: "transactionTypeName",   label: "Trans Type" },
  { key: "jobName",               label: "Job" },
  { key: "partyName",             label: "Party" },
  { key: "locationName",          label: "Location" },
  { key: "fabricTypeName",        label: "Fabric Type" },
  { key: "yarnTypeName",          label: "Yarn Type" },
  { key: "yarnCountName",         label: "Yarn Count" },
  { key: "yarnBrandName",         label: "Yarn Brand" },
  { key: "uomName",               label: "UOM" },
  { key: "machineName",           label: "Machine" },
  { key: "employeeName",   label: "Employee" },
  { key: "quantity",              label: "Qty" },
  { key: "fabricProduction",      label: "Fabric Production" },
  { key: "fabricDelivery",        label: "Fabric Delivery" },
  { key: "fabricDeliveryReturn",  label: "Fab Del Return" },
  { key: "runningFabricBalance",  label: "Run Fabric Bal." },
];

export const ALL_DETAIL_KEYS = DETAIL_COLUMNS.map((c) => c.key);

export const RIGHT_ALIGNED: Set<DetailColKey> = new Set([
  "quantity", "fabricProduction", "fabricDelivery",
  "fabricDeliveryReturn", "runningFabricBalance",
]);

// ─── Helpers ─────────────────────────────────────────────────────────────────

export function toISODate(d: Date): string {
  const y  = d.getFullYear();
  const m  = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

export function defaultFilters(): Filters {
  return {
    dateFrom: "", dateTo: "", year: "", month: "", docNumber: "", reference: "",
    transactionTypeId: [], jobId: [], partyId: [], locationId: [], fabricTypeId: [],
    yarnTypeId: [], yarnCountId: [], yarnBrandId: [], uomId: [],
    machineId: [], employeeId: [],
  };
}

export function loadSavedFilters(storageKey: string): Filters {
  try {
    const saved = localStorage.getItem(storageKey);
    if (saved) {
      const parsed = JSON.parse(saved);
      if (parsed && typeof parsed === "object") {
        const defaults = defaultFilters();
        const result: Filters = { ...defaults };
        for (const k of Object.keys(defaults) as (keyof Filters)[]) {
          if (k in parsed) (result as unknown as Record<string, unknown>)[k] = parsed[k];
        }
        return result;
      }
    }
  } catch {}
  return defaultFilters();
}

export function toNum(s: string | null | undefined): number {
  const n = parseFloat(s ?? "");
  return isNaN(n) ? 0 : n;
}

export function getMultiplier(action: string | null | undefined): number {
  if (!action) return 1;
  return action.trim().toLowerCase() === "minus" ? -1 : 1;
}

export function signedQty(row: ReportRow): number {
  return toNum(row.quantity) * getMultiplier(row.transactionTypeAction);
}

export function signedNetWt(row: ReportRow): number {
  return toNum(row.netWt) * getMultiplier(row.transactionTypeAction);
}

/** Fabric stock change for a single row. Only fabric-related types contribute. */
export function fabricBalanceDelta(row: ReportRow): number {
  const name = row.transactionTypeName;
  if (name === "Fabric Production") return signedNetWt(row);
  if (name === "Fabric Delivery" || name === "Fabric Delivery Return") {
    return signedNetWt(row);
  }
  return 0;
}

/**
 * Returns signedNetWt if the row matches the given transaction type name, else null.
 * Fabric Delivery rows will return a negative value (action = Minus).
 * Fabric Delivery Return rows will return a positive value (action = Add).
 */
export function signedNetWtIfType(row: ReportRow, typeName: string): number | null {
  return row.transactionTypeName === typeName ? signedNetWt(row) : null;
}

export function fmt(n: number): string {
  return n.toLocaleString("en-US", { minimumFractionDigits: 3, maximumFractionDigits: 3 });
}

export function getMonthLabel(dateStr: string): string {
  const d = new Date(dateStr);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

export function getGroupLabel(row: ReportRow, key: GroupByKey): string {
  if (key === "month") return getMonthLabel(row.date);
  return String((row as unknown as Record<string, unknown>)[key] ?? "—");
}

export function abbrev(arr: string[], max = 3): string {
  if (arr.length === 0) return "—";
  const shown = arr.slice(0, max).join(", ");
  return arr.length > max ? `${shown} …` : shown;
}

export function buildQueryString(f: Filters): string {
  const params = new URLSearchParams();
  Object.entries(f).forEach(([k, v]) => {
    if (Array.isArray(v)) {
      if (v.length > 0) params.set(k, v.join(","));
    } else if (v) {
      params.set(k, v as string);
    }
  });
  return params.toString();
}

export function groupRows(rows: ReportRow[], key: GroupByKey): Y2FGroupedRow[] {
  const map = new Map<string, {
    count: number; qty: number;
    fabricProduction: number; fabricDelivery: number;
    fabricDeliveryReturn: number;
    fabricDelta: number;
    docNumSet: Set<string>; refSet: Set<string>;
  }>();

  for (const row of rows) {
    const rawKey = key === "month" ? getMonthLabel(row.date) : (row[key] ?? "—");
    const k = String(rawKey);
    const e = map.get(k) ?? {
      count: 0, qty: 0,
      fabricProduction: 0, fabricDelivery: 0,
      fabricDeliveryReturn: 0,
      fabricDelta: 0,
      docNumSet: new Set<string>(), refSet: new Set<string>(),
    };
    e.count += 1;
    e.qty   += signedQty(row);
    e.fabricDelta += fabricBalanceDelta(row);
    const name = row.transactionTypeName;
    if (name === "Fabric Production")      e.fabricProduction     += signedNetWt(row);
    if (name === "Fabric Delivery")        e.fabricDelivery       += signedNetWt(row);
    if (name === "Fabric Delivery Return") e.fabricDeliveryReturn += signedNetWt(row);
    if (row.docNumber) e.docNumSet.add(row.docNumber);
    if (row.reference) e.refSet.add(row.reference);
    map.set(k, e);
  }

  return Array.from(map.entries())
    .map(([label, v]) => ({
      label, count: v.count, qty: v.qty,
      fabricProduction: v.fabricProduction,
      fabricDelivery: v.fabricDelivery,
      fabricDeliveryReturn: v.fabricDeliveryReturn,
      fabricDelta: v.fabricDelta,
      docNums: [...v.docNumSet], refs: [...v.refSet],
    }))
    .sort((a, b) => a.label.localeCompare(b.label));
}
