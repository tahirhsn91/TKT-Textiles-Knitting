/**
 * Pure helpers for invoice payment & receivables (issue #189).
 *
 * Derived state (paid/overdue/outstanding) is always *computed* from the
 * stored payments + the snapshot due date — never stored as a flag — so the
 * badge and the money never drift apart.
 */

import type { InvoicePayment } from "../db/schema/index.js";

/** Effectively `amount - tax_deduction` (net amount applied to the invoice). */
export function paymentNetApplied(p: { amount: string | number; taxDeduction: string | number }): number {
  return toNum(p.amount) - toNum(p.taxDeduction);
}

/** Sum of net-applied amounts for a set of payments. */
export function sumNetApplied(payments: { amount: string | number; taxDeduction: string | number }[]): number {
  return payments.reduce((s, p) => s + paymentNetApplied(p), 0);
}

/** Sum of tax deductions (WHT) across payments. */
export function sumTaxDeduction(payments: { taxDeduction: string | number }[]): number {
  return payments.reduce((s, p) => s + toNum(p.taxDeduction), 0);
}

/**
 * Convert a Date at local midnight to an ISO date string (YYYY-MM-DD).
 * Invoices/dates are date-only; the post timestamp's date part is what we use
 * as the posting date for due-date math.
 */
export function toISODate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

/** Add `days` calendar days to an ISO date and return an ISO date string. */
export function addDays(isoDate: string, days: number): string {
  const d = new Date(isoDate + "T00:00:00");
  d.setDate(d.getDate() + days);
  return toISODate(d);
}

/** Number of whole days from `isoDate` to `asOfIso` (positive = past). */
export function daysBetween(asOfIso: string, isoDate: string): number {
  const a = new Date(asOfIso + "T00:00:00").getTime();
  const b = new Date(isoDate + "T00:00:00").getTime();
  return Math.round((a - b) / 86_400_000);
}

export interface InvoicePaymentStateInput {
  grandTotal: string | number;
  /** Snapshot credit days at post time; null/0 = untracked (never overdue). */
  dueDays: number | null | undefined;
  /** Posted date (ISO). For backdated invoices this is the entered date. */
  postedDateIso: string;
  payments: Pick<InvoicePayment, "amount" | "taxDeduction">[];
}

export interface InvoicePaymentState {
  paidAmount: number;
  outstanding: number;
  dueDateIso: string | null;
  overdue: boolean;
  paid: boolean;
  overpaid: number;
  totalTaxDeduction: number;
}

/**
 * Compute the derived payment state for an invoice as-of a given date.
 * - tracked (dueDays > 0): dueDate = postedDate + dueDays.
 * - untracked (dueDays null/0): never overdue, no due date.
 * - paid when outstanding <= 0; overpaid shows the surplus.
 */
export function computePaymentState(input: InvoicePaymentStateInput): InvoicePaymentState {
  const grandTotal = toNum(input.grandTotal);
  const paidAmount = sumNetApplied(input.payments);
  const outstanding = grandTotal - paidAmount;
  const totalTaxDeduction = sumTaxDeduction(input.payments);

  const tracked = (input.dueDays ?? 0) > 0;
  const dueDateIso = tracked ? addDays(input.postedDateIso, input.dueDays ?? 0) : null;

  const asOfIso = toISODate(new Date());
  const overdue = tracked && outstanding > 0 && (input.dueDays ?? 0) > 0 && daysBetween(asOfIso, dueDateIso!) > 0;

  return {
    paidAmount,
    outstanding,
    dueDateIso,
    overdue,
    paid: outstanding <= 0,
    overpaid: paidAmount > grandTotal ? paidAmount - grandTotal : 0,
    totalTaxDeduction,
  };
}

export function toNum(v: unknown): number {
  const n = typeof v === "string" ? parseFloat(v) : Number(v ?? 0);
  return Number.isFinite(n) ? n : 0;
}
