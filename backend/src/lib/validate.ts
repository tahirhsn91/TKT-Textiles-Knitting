import type { NextFunction, Request, Response } from "express";

/**
 * Shared request validation middleware (issue #25).
 *
 * Replaces the per-route `.safeParse(req.body)` boilerplate with a reusable
 * middleware that validates a part of the request and, on failure, responds
 * 400 with a consistent `{ error }` shape before the handler runs.
 *
 * The schema param is typed loosely (structural `safeParse`) so it accepts any
 * zod schema used in this app — both locally-defined `z.object(...)` schemas and
 * the generated `api-zod` (`drizzle-zod`) schemas. On valid input the middleware
 * just calls `next()`; handlers then read `req.body` / `req.query` cast to the
 * schema's inferred type.
 *
 * The error shape stays `{ error: <first issue message> }` — the same contract
 * the previous inline handlers produced — so client behaviour is unchanged. A
 * `details` array (field → message) is included for richer feedback/logging.
 */

/** A zod-ish schema that can `.safeParse()` a value. */
export interface ParseableSchema {
  safeParse: (value: unknown) => unknown;
}

type RequestKey = "body" | "params" | "query";

// Reconstruct the zod failure shape from an arbitrary safeParse result.
function isParseSuccess(result: unknown): result is { success: true; data: unknown } {
  return !!result && typeof result === "object" && (result as { success?: boolean }).success === true;
}

function firstIssueMessage(result: { success: false; error: { issues?: Array<{ path: unknown; message: string }> } }): string {
  return result.error.issues?.[0]?.message ?? "Invalid input";
}

function makeValidator(key: RequestKey) {
  return function validate(schema: ParseableSchema) {
    return (req: Request, res: Response, next: NextFunction): void => {
      const result = schema.safeParse(req[key]) as
        | { success: true; data: unknown }
        | { success: false; error: { issues?: Array<{ path: string | number; message: string }> } };
      if (!isParseSuccess(result)) {
        res.status(400).json({
          error: firstIssueMessage(result),
          details: (result.error?.issues ?? []).map((i) => ({ field: String(i.path), message: i.message })),
        });
        return;
      }
      next();
    };
  };
}

/** Validate `req.body`. */
export const validateBody = makeValidator("body");

/** Validate `req.params`. */
export const validateParams = makeValidator("params");

/** Validate `req.query`. */
export const validateQuery = makeValidator("query");
