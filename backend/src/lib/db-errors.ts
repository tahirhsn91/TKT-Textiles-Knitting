/**
 * Shared DB error helpers.
 *
 * Drizzle wraps the underlying Postgres error in a `DrizzleQueryError` whose
 * `cause` is the raw pg error — the pg error carries `code` (e.g. "23505" for
 * unique violations), but the wrapper does NOT copy `code` onto itself. Any
 * check that reads `err.code` directly therefore never matches and the error
 * escapes as an unhandled 500 instead of a clean 409.
 *
 * Walk the cause chain so both raw pg errors and Drizzle-wrapped errors are
 * recognized.
 */
export function isUniqueViolation(err: unknown): boolean {
  let e: { code?: unknown; cause?: unknown } | null = err as
    | { code?: unknown; cause?: unknown }
    | null;
  while (e && typeof e === "object") {
    if (e.code === "23505") return true;
    e = (e.cause ?? null) as { code?: unknown; cause?: unknown } | null;
  }
  return false;
}
