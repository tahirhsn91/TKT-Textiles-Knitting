import { Router, type IRouter } from "express";
import swaggerUi from "swagger-ui-express";
import { openApiSpec } from "../lib/openapi.js";

/**
 * OpenAPI / Swagger documentation (issue #219 2.4).
 *   GET /api/docs        — Swagger UI
 *   GET /api/docs.json   — raw OpenAPI JSON spec
 */
const router: IRouter = Router();

router.get("/docs.json", (_req, res) => {
  res.json(openApiSpec);
});

router.use("/docs", swaggerUi.serve, swaggerUi.setup(openApiSpec as never));

export default router;
