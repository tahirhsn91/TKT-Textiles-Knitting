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
export function computeItemAmounts(netWeight: string | number, ratePerKg: string | number): {
  valueExcludingTax: string;
  taxAmount: string;
  totalValue: string;
} {
  const kg = typeof netWeight === "number" ? netWeight : parseFloat(netWeight);
  const rate = typeof ratePerKg === "number" ? ratePerKg : parseFloat(ratePerKg);
  if (!Number.isFinite(kg) || !Number.isFinite(rate) || kg <= 0 || rate <= 0) {
    return { valueExcludingTax: "0.00", taxAmount: "0.00", totalValue: "0.00" };
  }
  const value = round2(kg * rate);
  const tax = round2((value * FBR_SALES_TAX_PERCENT) / 100);
  const total = round2(value + tax);
  return {
    valueExcludingTax: value.toFixed(2),
    taxAmount: tax.toFixed(2),
    totalValue: total.toFixed(2),
  };
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
  const { invoice, items, company, buyerNtnCnic, buyerBusinessName, buyerProvince, buyerAddress, buyerRegistrationType, sandbox } = params;
  const rateStr = `${FBR_SALES_TAX_PERCENT}%`;
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
    items: items.map((it) => ({
      hsCode: it.hsCode ?? "",
      productDescription: it.productDescription ?? "",
      rate: rateStr,
      uoM: it.uoM ?? "",
      quantity: it.quantity,
      totalValues: it.totalValue,
      valueSalesExcludingST: it.valueExcludingTax,
      salesTaxApplicable: it.taxAmount,
      saleType: FBR_DEFAULT_SALE_TYPE,
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
