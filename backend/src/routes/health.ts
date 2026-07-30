import { Router, type IRouter } from "express";
import { sql } from "drizzle-orm";
import { db } from "../db/index.js";
import { HealthCheckResponse } from "../api-zod/index.js";
import { logger } from "../lib/logger.js";

const router: IRouter = Router();

// The probe must actually touch the database. A liveness-only check reports
// "ok" while every query fails with ECONNREFUSED, which lets docker-compose
// mark the container healthy and lets `depends_on: service_healthy` pass that
// false signal on to the frontend.
router.get("/healthz", async (_req, res) => {
  try {
    await db.execute(sql`select 1`);
    res.json(HealthCheckResponse.parse({ status: "ok" }));
  } catch (err) {
    const cause = (err as { cause?: { code?: string } }).cause;
    const code = cause?.code ?? (err as { code?: string }).code ?? null;
    logger.error({ err, code }, "health check failed: database unreachable");
    res.status(503).json({ status: "degraded", check: "database", code });
  }
});

export default router;
