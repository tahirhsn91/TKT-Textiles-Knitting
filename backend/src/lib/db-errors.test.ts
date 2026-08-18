import { test } from "node:test";
import assert from "node:assert/strict";
import { isUniqueViolation } from "./db-errors.js";

function pgError(code: string, message: string): Error {
  const e = new Error(message) as Error & { code: string };
  e.code = code;
  return e;
}

test("isUniqueViolation: raw pg unique violation", () => {
  assert.equal(isUniqueViolation(pgError("23505", "duplicate key")), true);
});

test("isUniqueViolation: DrizzleQueryError wrapping pg error in cause", () => {
  // DrizzleQueryError keeps the pg error in `cause` and does NOT copy `code`.
  const drizzleErr = new Error("Failed query: insert ...\nparams: ...") as Error & {
    query: string;
    params: unknown;
  };
  (drizzleErr as Error & { cause?: Error }).cause = pgError(
    "23505",
    'duplicate key value violates unique constraint "yarn_count_master_count_unique"',
  );
  assert.equal(isUniqueViolation(drizzleErr), true);
});

test("isUniqueViolation: nested cause chain", () => {
  const outer = new Error("outer") as Error & { cause?: Error };
  outer.cause = new Error("middle") as Error & { cause?: Error };
  (outer.cause as Error & { cause?: Error }).cause = pgError("23505", "dup");
  assert.equal(isUniqueViolation(outer), true);
});

test("isUniqueViolation: non-unique errors are not flagged", () => {
  assert.equal(isUniqueViolation(pgError("22P02", "invalid input syntax")), false);
  assert.equal(isUniqueViolation(new Error("boom")), false);
  assert.equal(isUniqueViolation(null), false);
  assert.equal(isUniqueViolation("23505"), false);
});
