import { Router, type IRouter } from "express";
import { z } from "zod/v4";
import {
  validateEntry,
  validateList,
  recordFeedback,
  retrainAll,
  getAllBaselines,
} from "../lib/plausibility/engine.js";
import { type Operation } from "../lib/plausibility/config.js";

const router: IRouter = Router();

const operationSchema = z.enum(["production", "receipt", "delivery"]);

// ─── Validate a single entry (insert-time, warn-only) ──────────────────────
// The add-dialogs POST the values a user is about to save; we reply with any
// plausibility warnings. This never blocks — the client decides whether to
// surface a "save anyway" prompt.

const entrySchema = z.object({
  operation: operationSchema,
  values: z.object({
    rollWeights: z.array(z.coerce.number()).optional(),
    netWeight: z.coerce.number().optional(),
    quantity: z.coerce.number().optional(),
    gsm: z.coerce.number().nullable().optional(),
  }),
});

router.post("/validate/daily-entry", async (req, res): Promise<void> => {
  const parsed = entrySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid input" });
    return;
  }
  const { operation, values } = parsed.data;
  const warnings = await validateEntry(operation as Operation, values);
  res.json({ warnings, abnormal: warnings.length > 0 });
});

// ─── Validate a listing's unreconciled rows ────────────────────────────────
// Powers the top-of-page banner + per-row markers. Only non-reconciled,
// non-cancelled rows are checked (the engine enforces this).

const listSchema = z.object({
  operation: operationSchema,
  dateFrom: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  dateTo: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

router.post("/validate/daily-list", async (req, res): Promise<void> => {
  const parsed = listSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid input" });
    return;
  }
  const { operation, dateFrom, dateTo } = parsed.data;
  const result = await validateList(operation as Operation, { dateFrom, dateTo });
  res.json(result);
});

// ─── Record operator feedback (fuels self-tuning) ──────────────────────────

const feedbackSchema = z.object({
  items: z.array(z.object({
    operation: operationSchema,
    field: z.enum([
      "roll_weight", "net_weight", "quantity", "gsm", "wt_per_bag", "wt_per_roll",
    ]),
    enteredValue: z.coerce.number(),
    expectedLow: z.coerce.number().nullable().optional(),
    expectedHigh: z.coerce.number().nullable().optional(),
    outcome: z.enum(["confirmed_anyway", "corrected"]),
    createdBy: z.string().trim().nullable().optional(),
  })).min(1),
});

router.post("/plausibility/feedback", async (req, res): Promise<void> => {
  const parsed = feedbackSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid feedback" });
    return;
  }
  await recordFeedback(parsed.data.items.map((i) => ({
    operation: i.operation as Operation,
    field: i.field,
    enteredValue: i.enteredValue,
    expectedLow: i.expectedLow ?? null,
    expectedHigh: i.expectedHigh ?? null,
    outcome: i.outcome,
    createdBy: i.createdBy ?? null,
  })));
  res.status(201).json({ recorded: parsed.data.items.length });
});

// ─── Manual full retrain (Option C manual path) ────────────────────────────

router.post("/plausibility/retrain", async (_req, res): Promise<void> => {
  const result = await retrainAll();
  res.json({ retrained: result });
});

// ─── Introspection: current learned baselines (seed check / debugging) ──────

router.get("/plausibility/baselines", async (_req, res): Promise<void> => {
  const baselines = await getAllBaselines();
  res.json({ baselines });
});

export default router;
