import express, { type Express, type ErrorRequestHandler, type Request, type Response, type NextFunction } from "express";
import cors from "cors";
import { pinoHttp } from "pino-http";
import rateLimit from "express-rate-limit";
import router from "./routes/index.js";
import { logger } from "./lib/logger.js";

const app: Express = express();

const allowedOrigins = (process.env["ALLOWED_ORIGINS"] ?? "http://localhost:3000")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

// Trust the first proxy in the chain so that rate-limiting sees the real
// client IP instead of the proxy's IP. Safe in this setup because the only
// proxy is the Docker bridge or the frontend's nginx, which aren't spoofable
// by external callers.
app.set("trust proxy", 1);

// ── Rate limiting ───────────────────────────────────────────────────────────

/** Shared key-generator: uses IP. Falls back to "anonymous" when the request
 *  arrives with no IP (e.g. direct Docker-internal calls from the healthcheck).
 *  express-rate-limit v7 uses `req.ip` directly when no keyGenerator is given,
 *  but being explicit about the fallback avoids a potential crash on a
 *  misconfigured proxy where `req.ip` is undefined. */
function keyGenerator(req: Request): string {
  return (req.ip as string | undefined) ?? "anonymous";
}

/** Standard rate limiter — applies to all API routes. 100 req/min/IP lets
 *  a single browser tab running the dashboard (which fires 7 queries on load)
 *  refresh several times per minute while still blocking runaway loops. */
const apiLimiter = rateLimit({
  windowMs: 60_000, // 1 minute
  max: 100,
  keyGenerator,
  standardHeaders: true,  // RateLimit-* headers (IETF draft)
  legacyHeaders: false,   // drop deprecated X-RateLimit-* headers
  message: { error: "Too many requests — please slow down", retryAfterSeconds: 60 },
  statusCode: 429,
  skip: (_req: Request) => _req.path === "/api/healthz",
});

/** Strict rate limiter for mutation endpoints. 30 req/min/IP stops
 *  double-click spam without getting in the way of normal form submissions.
 *  Applied selectively to POST / PUT / DELETE routes below. */
const mutationLimiter = rateLimit({
  windowMs: 60_000,
  max: 30,
  keyGenerator,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many write requests — please slow down", retryAfterSeconds: 60 },
  statusCode: 429,
});

// Logging middleware — placed before rate limiting so that even blocked
// requests appear in the access log.
app.use(
  pinoHttp({
    logger,
    serializers: {
      req(req) {
        return {
          id: req.id,
          method: req.method,
          url: req.url?.split("?")[0],
        };
      },
      res(res) {
        return {
          statusCode: res.statusCode,
        };
      },
    },
  }),
);
app.use(
  cors({
    origin(origin, callback) {
      // Same-origin requests (server-to-server, curl, the nginx/Vercel proxy) send no Origin header.
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error(`Origin ${origin} is not allowed`));
    },
  }),
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Apply rate limiting: general limiter on all API routes, stricter limiter
// on mutations. The order matters — apiLimiter runs first (catch-all), then
// mutationLimiter overrides for write endpoints with a lower threshold.
app.use("/api", apiLimiter);
app.use("/api", (req: Request, _res: Response, next: NextFunction) => {
  // Re-apply stricter limit only on write endpoints.
  if (["POST", "PUT", "PATCH", "DELETE"].includes(req.method)) {
    return mutationLimiter(req, _res, next);
  }
  next();
});

app.use("/api", router);

// Terminal error handler. Without it, Express 5 falls back to its default
// handler, which returns an HTML stack page — the frontend's fetch wrapper
// then chokes on non-JSON and surfaces a generic failure. Drizzle also wraps
// driver faults, so the useful part (the pg error code) sits on `err.cause`
// and never reaches the log unless it is unwrapped explicitly.
const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  const e = err as {
    cause?: { code?: string; message?: string };
    code?: string;
    status?: number;
    statusCode?: number;
    expose?: boolean;
    message?: string;
  };

  const cause = e.cause;
  const code = cause?.code ?? e.code ?? null;

  // Middleware such as body-parser throws errors already tagged with a 4xx
  // status (a malformed JSON body is the client's fault, not ours). Reporting
  // those as 500 both misleads the caller and pollutes server error metrics,
  // so honour the tag and only fall back to 500 for genuinely unexpected
  // failures. `expose` is body-parser's own signal that the message is safe to
  // return; anything else gets a generic string so internals don't leak.
  const tagged = e.status ?? e.statusCode;
  const isClientError = typeof tagged === "number" && tagged >= 400 && tagged < 500;
  const status = isClientError ? tagged : 500;

  const logPayload = { err, code, causeMessage: cause?.message, status };
  if (isClientError) logger.warn(logPayload, "bad request");
  else logger.error(logPayload, "unhandled request error");

  if (res.headersSent) return;
  res.status(status).json({
    error: isClientError && e.expose === true
      ? e.message ?? "Bad request"
      : isClientError
        ? "Bad request"
        : "Internal server error",
    code,
  });
};

app.use(errorHandler);

export default app;
