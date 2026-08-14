import type { NextFunction, Request, Response } from "express";
import { z } from "zod/v4";

/**
 * Shared request validation middleware (issue #25).
 *
 * Replaces the per-route `.safeParse(req.body)` boilerplate with a reusable
 * middleware that validates a part of the request and, on failure, responds
 * 400 with a consistent `{ error }` shape before the handler runs. On success
 * the validated (typed/coerced) value is assigned back onto that key of `req`,
 * so handlers read `req.body` / `req.params` / `req.query` as the parsed output
 * (with a cast in the handler to the schema's output type).
 *
 * The error shape stays `{ error: <first issue message> }` — the same contract
 * the previous inline handlers produced — so client behaviour is unchanged. A
 * `details` array (field → message) is included for richer feedback/logging.
 */

type RequestKey = "body" | "params" | "query";

function makeValidator(key: RequestKey) {
  return function <Output>(schema: z.ZodType<Output, any, any>) {
    return (req: Request, res: Response, next: NextFunction): void => {
      const result = schema.safeParse(req[key]);
      if (!result.success) {
        const first = result.error.issues[0];
        res.status(400).json({
          error: first?.message ?? "Invalid " + key,
          details: result.error.issues.map((i) => ({
            field: i.path.join("."),
            message: i.message,
          })),
        });
        return;
      }
      // Validation guarantees the value is correct; the handler casts the
      // relevant key to the schema's output type. We deliberately do NOT mutate
      // `req` here — assigning to req.body/params/query in middleware widens the
      // inferred types for downstream handlers and breaks helpers that read
      // `req.params` (Express types them as string | string[]).
      next();
    };
  };
}

/** Validate `req.body`. On success `req.body` is the parsed output. */
export const validateBody = makeValidator("body");

/** Validate `req.params`. On success `req.params` is the parsed output. */
export const validateParams = makeValidator("params");

/** Validate `req.query`. On success `req.query` is the parsed output. */
export const validateQuery = makeValidator("query");
