// Unit tests for the FBR invoicing pure layer (client amount math + payload
// construction + scenario/constants). No DB, no I/O.
// Run with: npm test  (Node's built-in test runner via tsx).

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  computeItemAmounts,
  toFbrMoney,
  buildFbrInvoicePayload,
} from "./client.js";
import { fbrScenarioId, FBR_DEFAULT_SALE_TYPE } from "./constants.js";

// ─── computeItemAmounts ───────────────────────────────────────────────────

test("computeItemAmounts: value = kg * rate, tax = 18%, total = value + tax", () => {
  // 100 kg @ 100 PKR → value 10000, tax 1800, total 11800
  const r = computeItemAmounts("100.000", "100");
  assert.equal(r.valueExcludingTax, "10000.00");
  assert.equal(r.taxAmount, "1800.00");
  assert.equal(r.totalValue, "11800.00");
});

test("computeItemAmounts: accepts numbers and mixes precision", () => {
  // 25.5 kg @ 45.5 → value 1160.25, tax 208.845 → rounded 208.85, total 1369.10
  const r = computeItemAmounts(25.5, 45.5);
  assert.equal(r.valueExcludingTax, "1160.25");
  assert.equal(r.taxAmount, "208.85");
  assert.equal(r.totalValue, "1369.10");
});

test("computeItemAmounts: rounds money to 2 decimals (half-up)", () => {
  // A value with >2 dp: tax that doesn't land on cents.
  const r = computeItemAmounts("0.333", "100"); // 0.333*100 = 33.3
  assert.equal(r.valueExcludingTax, "33.30");
  // tax = 5.994 → 5.99 (or 5.99 with EPSILON path), total 39.29
  assert.equal(r.taxAmount, "5.99");
  assert.equal(r.totalValue, "39.29");
});

test("computeItemAmounts: zero/negative/invalid → all zeros", () => {
  assert.deepEqual(computeItemAmounts("0", "100"), {
    valueExcludingTax: "0.00",
    taxAmount: "0.00",
    totalValue: "0.00",
  });
  assert.deepEqual(computeItemAmounts("100", "0"), {
    valueExcludingTax: "0.00",
    taxAmount: "0.00",
    totalValue: "0.00",
  });
  assert.deepEqual(computeItemAmounts("abc", "100"), {
    valueExcludingTax: "0.00",
    taxAmount: "0.00",
    totalValue: "0.00",
  });
});

// ─── toFbrMoney ───────────────────────────────────────────────────────────

test("toFbrMoney: formats numbers to 2 decimals", () => {
  assert.equal(toFbrMoney("123.456"), "123.46");
  assert.equal(toFbrMoney(1000), "1000.00");
  assert.equal(toFbrMoney("0"), "0.00");
  assert.equal(toFbrMoney("abc"), "0.00");
});

// ─── fbrScenarioId ────────────────────────────────────────────────────────

test("fbrScenarioId: SN001 for registered, SN002 for unregistered", () => {
  assert.equal(fbrScenarioId("Registered"), "SN001");
  assert.equal(fbrScenarioId("Unregistered"), "SN002");
  assert.equal(fbrScenarioId("anything-else"), "SN002");
});

// ─── buildFbrInvoicePayload ───────────────────────────────────────────────

const baseCompany = {
  id: 1,
  name: "TKT Textiles",
  ntnCnic: "1234567",
  province: "Punjab",
  address: "Faisalabad",
  fbrSandboxToken: "sandbox-token",
  fbrProductionToken: null,
  isDefault: true,
  createdAt: new Date("2026-08-12"),
  updatedAt: new Date("2026-08-12"),
};

const baseInvoice = {
  id: 42,
  invoiceNumber: 255,
  invoiceDate: "2026-08-12",
  companyId: 1,
  partyId: 7,
  status: "draft" as const,
  fbrInvoiceNumber: null,
  fbrStatusCode: null,
  fbrRawResponse: null,
  totalValue: "11800.00",
  totalTax: "1800.00",
  grandTotal: "13600.00",
  createdBy: "test",
  createdAt: new Date("2026-08-12"),
  updatedAt: new Date("2026-08-12"),
  postedAt: null,
};

const baseItems = [
  {
    id: 1,
    invoiceId: 42,
    yarnTypeId: 20,
    yarnCountId: null,
    hsCode: "6001.2100",
    uoM: "KG",
    productDescription: "3-Fleece fabric",
    quantity: "100.000",
    ratePerKg: "100.00",
    valueExcludingTax: "10000.00",
    taxAmount: "1800.00",
    totalValue: "11800.00",
    saleType: FBR_DEFAULT_SALE_TYPE,
  },
];

test("buildFbrInvoicePayload: maps seller/buyer/items and adds scenarioId in sandbox", () => {
  const p = buildFbrInvoicePayload({
    invoice: baseInvoice,
    items: baseItems,
    company: baseCompany,
    buyerNtnCnic: "7654321",
    buyerBusinessName: "Acme Buyer",
    buyerProvince: "Sindh",
    buyerAddress: "Karachi",
    buyerRegistrationType: "Registered",
    sandbox: true,
  });

  assert.equal(p.invoiceType, "Sale Invoice");
  assert.equal(p.invoiceDate, "2026-08-12");
  assert.equal(p.sellerNTNCNIC, "1234567");
  assert.equal(p.sellerBusinessName, "TKT Textiles");
  assert.equal(p.sellerProvince, "Punjab");
  assert.equal(p.sellerAddress, "Faisalabad");
  assert.equal(p.buyerNTNCNIC, "7654321");
  assert.equal(p.buyerBusinessName, "Acme Buyer");
  assert.equal(p.buyerRegistrationType, "Registered");
  assert.equal(p.scenarioId, "SN001");
  assert.equal(p.items[0].hsCode, "6001.2100");
  assert.equal(p.items[0].uoM, "KG");
  assert.equal(p.items[0].rate, "18%");
  assert.equal(p.items[0].quantity, "100.000");
  assert.equal(p.items[0].valueSalesExcludingST, "10000.00");
  assert.equal(p.items[0].salesTaxApplicable, "1800.00");
  assert.equal(p.items[0].totalValues, "11800.00");
  assert.equal(p.items[0].saleType, FBR_DEFAULT_SALE_TYPE);
});

test("buildFbrInvoicePayload: emits every optional numeric FBR field as 2-dp zero", () => {
  // FBR's sandbox rejects items that omit the optional numeric fields
  // (error 0300/0302), so they must all be present as "0.00".
  const p = buildFbrInvoicePayload({
    invoice: baseInvoice,
    items: baseItems,
    company: baseCompany,
    buyerNtnCnic: "7654321",
    buyerBusinessName: "Acme Buyer",
    buyerProvince: "Sindh",
    buyerAddress: "Karachi",
    buyerRegistrationType: "Registered",
    sandbox: true,
  });

  const it = p.items[0];
  assert.equal(it.fixedNotifiedValueOrRetailPrice, "0.00");
  assert.equal(it.salesTaxWithheldAtSource, "0.00");
  assert.equal(it.extraTax, "0.00");
  assert.equal(it.furtherTax, "0.00");
  assert.equal(it.sroScheduleNo, "");
  assert.equal(it.fedPayable, "0.00");
  assert.equal(it.discount, "0.00");
  assert.equal(it.sroItemSerialNo, "");
});

test("buildFbrInvoicePayload: unregistered buyer → SN002, empty NTN, no scenario in production", () => {
  const p = buildFbrInvoicePayload({
    invoice: baseInvoice,
    items: baseItems,
    company: baseCompany,
    buyerNtnCnic: null,
    buyerBusinessName: "Walk-in Customer",
    buyerProvince: "KPK",
    buyerAddress: "Peshawar",
    buyerRegistrationType: "Unregistered",
    sandbox: false,
  });

  assert.equal(p.buyerNTNCNIC, "");
  assert.equal(p.buyerRegistrationType, "Unregistered");
  assert.ok(!("scenarioId" in p), "production payload must not carry scenarioId");
});
