/**
 * FBR Digital Invoicing (DI) constants.
 *
 * Endpoint URLs are fixed constants per the FBR technical documentation
 * (v1.12): the same path serves sandbox and production, differing only by the
 * `_sb` suffix. Routing between environments is decided by the global
 * configuration toggle (code "0002") — when enabled → sandbox, when disabled →
 * production — and the matching per-company security token is read at post
 * time.
 */

/** Configuration code for the FBR DI sandbox toggle (see Configuration master). */
export const FBR_DI_SANDBOX_CODE = "0002";

/** The Fabric Delivery transaction type code (source of invoice generation). */
export const FABRIC_DELIVERY_TRANSACTION_TYPE_CODE = "Fabric_Dispatch";

/** Official FBR province names (validated against these; error codes 0073/0074). */
export const FBR_PROVINCES = [
  "Punjab",
  "Sindh",
  "KPK",
  "Balochistan",
  "Islamabad",
] as const;

/** Official FBR saleType strings (only the standard-rate default is used in v1). */
export const FBR_SALE_TYPES = [
  "Goods at standard rate (default)",
  "Goods at Reduced Rate",
  "Goods at zero-rate",
  "Exempt Goods",
  "3rd Schedule Goods",
  "Goods (FED in ST Mode)",
  "Goods as per SRO.297(I)/2023",
  "Non-Adjustable Supplies",
  "Cotton Ginners",
  "Steel Melting and Re-Rolling",
  "Ship Breaking",
  "Toll Manufacturing",
  "Processing/Conversion of Goods",
  "Mobile Phones",
  "Petroleum Products",
  "Electricity Supply to Retailers",
  "Gas to CNG Stations",
  "CNG Sales",
  "Cement/Concrete Block",
  "Potassium Chlorate",
  "Electric Vehicle",
  "Telecommunication Services",
  "Services",
  "Services (FED in ST Mode)",
] as const;

/** The default saleType used for all v1 fabric invoices. */
export const FBR_DEFAULT_SALE_TYPE = "Processing/Conversion of Goods";

/** Fixed sales-tax rate (%) applied on top of the value (v1 constant). */
export const FBR_SALES_TAX_PERCENT = 18;

/** FBR invoiceType for fabric deliveries. */
export const FBR_INVOICE_TYPE = "Sale Invoice";

/** FBR post-invoice endpoints. Sandbox gets the `_sb` suffix. */
export const FBR_DI_ENDPOINTS = {
  sandbox: "https://gw.fbr.gov.pk/di_data/v1/di/postinvoicedata_sb",
  production: "https://gw.fbr.gov.pk/di_data/v1/di/postinvoicedata",
} as const;

/** Sandbox scenarioId by buyer registration type (per FBR scenario table). */
export function fbrScenarioId(registrationType: string): string {
  return registrationType === "Registered" ? "SN001" : "SN002";
}
