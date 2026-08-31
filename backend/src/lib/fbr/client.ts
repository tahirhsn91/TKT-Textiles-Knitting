import {
  FBR_DI_ENDPOINTS,
  FBR_INVOICE_TYPE,
  FBR_SALES_TAX_PERCENT,
  FBR_DEFAULT_SALE_TYPE,
  fbrScenarioId,
} from "./constants.js";
import type { CompanyInfoMaster } from "../../db/index.js";
import type { Invoice, InvoiceItem } from "../../db/index.js";

/**
 * FBR Digital Invoicing API client.
 *
 * Builds the `postinvoicedata` payload from a generated invoice + its items and
 * POSTs it to the sandbox or production endpoint with the seller's Bearer
 * token. Sandbox vs production is decided by the caller (via the config
 * toggle) and selects both the URL and the matching per-company token.
 */

export interface FbrPostResult {
  statusCode: number;
  /** Top-level FBR response body on 2xx (may carry "Valid"/"Invalid"). */
  body: {
    invoiceNumber?: string;
    dated?: string;
    validationResponse?: {
      statusCode?: string;
      status?: string;
      errorCode?: string | null;
      error?: string;
      invoiceStatuses?: Array<{
        itemSNo?: string;
        statusCode?: string;
        status?: string;
        invoiceNo?: string | null;
        errorCode?: string;
        error?: string;
      }> | null;
    } | null;
  };
  /** Raw response text (for the audit jsonb). */
  raw: unknown;
}

export interface FbrInvoiceItemInput {
  hsCode: string;
  productDescription: string;
  /** e.g. "18%" */
  rate: string;
  /** FBR field name is `uoM` (camelCase). */
  uoM: string;
  quantity: string;
  totalValues: string;
  valueSalesExcludingST: string;
  salesTaxApplicable: string;
  saleType: string;
  /** FBR's sandbox strictly validates every numeric field, so even the
   *  optional ones must be present as a well-formed 2-dp value (usually
   *  "0.00") rather than omitted (see error 0300/0302). */
  fixedNotifiedValueOrRetailPrice: string;
  salesTaxWithheldAtSource: string;
  extraTax: string;
  furtherTax: string;
  sroScheduleNo: string;
  fedPayable: string;
  discount: string;
  sroItemSerialNo: string;
}

function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

/**
 * Round a numeric-string value to 2 decimal places for FBR (money values).
 * FBR rejects values with more than 2 dp (error 0302).
 */
export function toFbrMoney(value: string | number): string {
  const n = typeof value === "number" ? value : parseFloat(value);
  return Number.isFinite(n) ? round2(n).toFixed(2) : "0.00";
}

/**
 * Compute the FBR item amounts from a summed net weight and a per-KG rate.
 * value = kg * rate; tax = 18% of value; total = value + tax.
 * All money is rounded to 2 decimal places.
 */
/**
 * Compute value-excluding-tax + sales-tax + total for one invoice line.
 *@param netWeight    quantity (kg)
 * @param ratePerKg    unit rate
 * @param taxRatePercent sales-tax percent (defaults to the app-wide FBR rate;
 *                       pass the tenant's configured default_tax_rate to use
 *                       the Company Settings value — issue #219).
 */
export function computeItemAmounts(
  netWeight: string | number,
  ratePerKg: string | number,
  taxRatePercent: number = FBR_SALES_TAX_PERCENT,
): {
  valueExcludingTax: string;
  taxAmount: string;
  totalValue: string;
} {
  const kg = typeof netWeight === "number" ? netWeight : parseFloat(netWeight);
  const rate = typeof ratePerKg === "number" ? ratePerKg : parseFloat(ratePerKg);
  if (!Number.isFinite(kg) || !Number.isFinite(rate) || kg <= 0 || rate <= 0) {
    return { valueExcludingTax: "0.00", taxAmount: "0.00", totalValue: "0.00" };
  }
  const safeRate = Number.isFinite(taxRatePercent) && taxRatePercent >= 0 ? taxRatePercent : FBR_SALES_TAX_PERCENT;
  const value = round2(kg * rate);
  const tax = round2((value * safeRate) / 100);
  const total = round2(value + tax);
  return {
    valueExcludingTax: value.toFixed(2),
    taxAmount: tax.toFixed(2),
    totalValue: total.toFixed(2),
  };
}

/**
 * FBR DI rejects an invoice that contains two or more lines with the same
 * (hsCode + uoM) combination, reporting it as "DUPLICATE INVOICE EXISTS" on
 * the highest-value duplicate line. The ERP generates one line per yarn type
 * and every fabric yarn type maps to the same HS code (6002.9000 / KG), so
 * every multi-line invoice tripped FBR's check while single-line invoices
 * posted fine. Merge lines by (hsCode + uoM) before posting: quantities and
 * money values are summed, the first product description wins.
 */
function mergeItemsByHsCode(items: InvoiceItem[]): Array<{
  hsCode: string;
  productDescription: string;
  uoM: string;
  quantity: string;
  valueExcludingTax: string;
  taxAmount: string;
  totalValue: string;
  saleType: string;
}> {
  const groups = new Map<string, {
    hsCode: string;
    productDescription: string;
    uoM: string;
    saleType: string;
    quantity: number;
    valueExcludingTax: number;
    taxAmount: number;
    totalValue: number;
  }>();
  for (const it of items) {
    const key = `${it.hsCode ?? ""}|${it.uoM ?? ""}`;
    const g = groups.get(key) ?? {
      hsCode: it.hsCode ?? "",
      productDescription: it.productDescription ?? "",
      uoM: it.uoM ?? "",
      saleType: it.saleType ?? FBR_DEFAULT_SALE_TYPE,
      quantity: 0,
      valueExcludingTax: 0,
      taxAmount: 0,
      totalValue: 0,
    };
    g.quantity += parseFloat(it.quantity) || 0;
    g.valueExcludingTax += parseFloat(it.valueExcludingTax) || 0;
    g.taxAmount += parseFloat(it.taxAmount) || 0;
    g.totalValue += parseFloat(it.totalValue) || 0;
    groups.set(key, g);
  }
  return [...groups.values()].map((g) => ({
    hsCode: g.hsCode,
    productDescription: g.productDescription,
    uoM: g.uoM,
    quantity: round2(g.quantity).toFixed(3),
    valueExcludingTax: toFbrMoney(g.valueExcludingTax),
    taxAmount: toFbrMoney(g.taxAmount),
    totalValue: toFbrMoney(g.totalValue),
    saleType: g.saleType,
  }));
}

/**
 * Build the FBR `postinvoicedata` payload for one invoice.
 * `sandbox` selects the scenarioId (SN001/SN002 by buyer registration type)
 * which FBR requires for sandbox only.
 */
export function buildFbrInvoicePayload(params: {
  invoice: Invoice;
  items: InvoiceItem[];
  company: CompanyInfoMaster;
  buyerNtnCnic: string | null;
  buyerBusinessName: string;
  buyerProvince: string;
  buyerAddress: string;
  buyerRegistrationType: string;
  sandbox: boolean;
  /** Sales-tax percent for the declared rate string (defaults to the FBR rate). */
  taxRatePercent?: number;
}): {
  invoiceType: string;
  invoiceDate: string;
  sellerNTNCNIC: string;
  sellerBusinessName: string;
  sellerProvince: string;
  sellerAddress: string;
  buyerNTNCNIC: string;
  buyerBusinessName: string;
  buyerProvince: string;
  buyerAddress: string;
  buyerRegistrationType: string;
  invoiceRefNo: string;
  scenarioId?: string;
  items: FbrInvoiceItemInput[];
} {
  const { invoice, items, company, buyerNtnCnic, buyerBusinessName, buyerProvince, buyerAddress, buyerRegistrationType, sandbox, taxRatePercent } = params;
  const ratePercent = Number.isFinite(taxRatePercent) && taxRatePercent! >= 0 ? taxRatePercent! : FBR_SALES_TAX_PERCENT;
  const rateStr = `${ratePercent}%`;
  const body: ReturnType<typeof buildFbrInvoicePayload> = {
    invoiceType: FBR_INVOICE_TYPE,
    invoiceDate: invoice.invoiceDate,
    sellerNTNCNIC: company.ntnCnic,
    sellerBusinessName: company.name,
    sellerProvince: company.province,
    sellerAddress: company.address,
    buyerNTNCNIC: buyerNtnCnic ?? "",
    buyerBusinessName,
    buyerProvince,
    buyerAddress,
    buyerRegistrationType,
    invoiceRefNo: "",
    items: mergeItemsByHsCode(items).map((it) => ({
      hsCode: it.hsCode ?? "",
      productDescription: it.productDescription ?? "",
      rate: rateStr,
      uoM: it.uoM ?? "",
      quantity: it.quantity,
      totalValues: it.totalValue,
      valueSalesExcludingST: it.valueExcludingTax,
      salesTaxApplicable: it.taxAmount,
      saleType: FBR_DEFAULT_SALE_TYPE,
      // FBR's sandbox validates every numeric field strictly, so the optional
      // ones must be present as 2-dp values (zero here because fabric sales at
      // the standard rate carry no discount / FED / extra / further tax /
      // withholding). Sending "0.00" avoids error 0300/0302.
      fixedNotifiedValueOrRetailPrice: "0.00",
      salesTaxWithheldAtSource: "0.00",
      extraTax: "0.00",
      furtherTax: "0.00",
      sroScheduleNo: "",
      fedPayable: "0.00",
      discount: "0.00",
      sroItemSerialNo: "",
    })),
  };
  if (sandbox) {
    body.scenarioId = fbrScenarioId(buyerRegistrationType);
  }
  return body;
}

/**
 * POST an invoice to FBR. Picks the endpoint + token by environment.
 * Returns the HTTP status, parsed body, and raw body. Does NOT throw on FBR
 * validation errors — a 200 with an "Invalid" validationResponse is a normal
 * outcome the caller surfaces.
 */
export async function postInvoiceToFbr(params: {
  payload: ReturnType<typeof buildFbrInvoicePayload>;
  token: string | null;
  sandbox: boolean;
}): Promise<FbrPostResult> {
  const { payload, token, sandbox } = params;
  const url = sandbox ? FBR_DI_ENDPOINTS.sandbox : FBR_DI_ENDPOINTS.production;

  let raw: unknown;
  let body: FbrPostResult["body"] = {};
  let statusCode = 0;

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token ?? ""}`,
      },
      body: JSON.stringify(payload),
    });
    statusCode = res.status;
    const text = await res.text();
    raw = text;
    try {
      body = JSON.parse(text) as FbrPostResult["body"];
    } catch {
      body = { validationResponse: { status: "Invalid", error: text } };
    }
  } catch (err) {
    // Network/transport failure — no FBR validation response. Caller treats
    // this as a retryable draft (per Q21).
    raw = err instanceof Error ? err.message : String(err);
    body = { validationResponse: { status: "Invalid", error: err instanceof Error ? err.message : String(err) } };
    statusCode = 0;
  }

  return { statusCode, body, raw };
}
