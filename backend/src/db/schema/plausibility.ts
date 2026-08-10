import {
  pgTable,
  serial,
  integer,
  numeric,
  text,
  timestamp,
  unique,
  index,
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

// ─── Plausibility Baseline ─────────────────────────────────────────────────
// The learned "memory" of the self-tuning validator. One row per
// (operation, field) holding a robust distribution summary and the warn
// bounds derived from it. Recomputed incrementally after every insert and
// fully rebuildable via POST /api/plausibility/retrain.
//
// Robust statistics (median / IQR / MAD) are used deliberately: the historical
// data already contains gross outliers (e.g. a 2,181 kg "roll"), and mean +
// stddev would be poisoned by them. Median-based bounds ignore those rows, so
// the validator is correct from day one without cleaning the data first.
export const plausibilityBaselineTable = pgTable("plausibility_baseline", {
  id: serial("id").primaryKey(),
  // "production" | "receipt" | "delivery"
  operation: text("operation").notNull(),
  // "roll_weight" | "net_weight" | "quantity" | "gsm" | "wt_per_bag" | "wt_per_roll"
  field: text("field").notNull(),
  median: numeric("median", { precision: 18, scale: 6 }).notNull(),
  iqr: numeric("iqr", { precision: 18, scale: 6 }).notNull(),
  mad: numeric("mad", { precision: 18, scale: 6 }).notNull(),
  lowerBound: numeric("lower_bound", { precision: 18, scale: 6 }).notNull(),
  upperBound: numeric("upper_bound", { precision: 18, scale: 6 }).notNull(),
  sampleCount: integer("sample_count").notNull().default(0),
  computedAt: timestamp("computed_at").notNull().defaultNow(),
}, (t) => [
  unique("plausibility_baseline_operation_field_unique").on(t.operation, t.field),
]);

export const insertPlausibilityBaselineSchema = createInsertSchema(plausibilityBaselineTable).omit({
  id: true,
  computedAt: true,
});
export type InsertPlausibilityBaseline = z.infer<typeof insertPlausibilityBaselineSchema>;
export type PlausibilityBaseline = typeof plausibilityBaselineTable.$inferSelect;

// ─── Plausibility Feedback ─────────────────────────────────────────────────
// The learning signal. Every time an operator is warned about a value we log
// what they did with it: "confirmed_anyway" (the value was legitimate) or
// "corrected" (they changed it). Retraining reads this to down-weight values
// operators repeatedly corrected and to keep values they stood behind.
export const plausibilityFeedbackTable = pgTable("plausibility_feedback", {
  id: serial("id").primaryKey(),
  operation: text("operation").notNull(),
  field: text("field").notNull(),
  enteredValue: numeric("entered_value", { precision: 18, scale: 6 }).notNull(),
  expectedLow: numeric("expected_low", { precision: 18, scale: 6 }),
  expectedHigh: numeric("expected_high", { precision: 18, scale: 6 }),
  // "confirmed_anyway" | "corrected"
  outcome: text("outcome").notNull(),
  createdBy: text("created_by"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
}, (t) => [
  index("plausibility_feedback_operation_field_idx").on(t.operation, t.field),
]);

export const insertPlausibilityFeedbackSchema = createInsertSchema(plausibilityFeedbackTable).omit({
  id: true,
  createdAt: true,
});
export type InsertPlausibilityFeedback = z.infer<typeof insertPlausibilityFeedbackSchema>;
export type PlausibilityFeedback = typeof plausibilityFeedbackTable.$inferSelect;
