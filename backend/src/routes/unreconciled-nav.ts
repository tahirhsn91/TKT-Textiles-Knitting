import { Router, type IRouter } from "express";
import { z } from "zod/v4";
import { pool } from "../db/index.js";
import { validateQuery } from "../lib/validate.js";
import {
  findNearestUnreconciledDates,
} from "../lib/unreconciled-nav.js";

const router: IRouter = Router();

const navSchema = z.object({
  operation: z.enum(["production", "receipt", "delivery"]),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "date must be YYYY-MM-DD"),
});

// ─── Prev / next date with unconciled data ─────────────────────────────────
// For the daily operations screens (Daily Production, Yarn Receipt, Daily
// Delivery). Given the currently displayed date, returns the nearest date
// strictly before (`prev`) and strictly after (`next`) that holds at least one
// unreconciled row (reconciled=false, status<>'cancelled'), or null when none
// exists in that direction. The frontend uses the null targets to disable the
// corresponding navigation button (issue #120).
router.get(
  "/daily-ops/unreconciled/prev-next",
  validateQuery(navSchema),
  async (req, res): Promise<void> => {
    const { operation, date } = req.query as unknown as { operation: "production" | "receipt" | "delivery"; date: string };
    try {
      const result = await findNearestUnreconciledDates(pool, operation, date);
      res.json(result);
    } catch (err) {
      // Surface a server error without leaking internals.
      res.status(500).json({ error: "Failed to resolve unreconciled dates" });
    }
  },
);

export default router;
