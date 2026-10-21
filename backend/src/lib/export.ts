/**
 * CSV export helpers (issue #219 2.5 reporting & export).
 * Dependency-free: generates RFC-4180-ish CSV that Excel/Sheets open cleanly.
 */

/** Options for a single CSV field. */
export interface CsvFieldOptions {
  /**
   * Force spreadsheet apps to keep the value as text. CSV has no type
   * information, so Excel/Sheets auto-coerce numeric-looking values on open
   * (dropping leading zeros, rendering long ids in scientific notation).
   * A leading TAB makes Excel treat the cell as text while preserving the
   * value exactly as stored.
   */
  asText?: boolean;
}

/** Escape a field per CSV rules (quote if it contains comma, quote, or newline). */
export function csvField(value: unknown, opts: CsvFieldOptions = {}): string {
  if (value === null || value === undefined) return "";
  let s = String(value);
  if (s === "") return "";
  // Prefix before quoting so the TAB stays inside the quoted value too.
  if (opts.asText) s = `\t${s}`;
  // Always quote when special chars are present (RFC-4180).
  if (/[",\n\r]/.test(s)) {
    s = s.replace(/"/g, '""');
    return `"${s}"`;
  }
  return s;
}

/**
 * Build a CSV string from headers + rows.
 * @param headers column names (encode into the first line)
 * @param rows each row is an array of field values aligned to headers
 * @param eol line ending (default CRLF for Excel compatibility)
 * @param textColumns zero-based indexes of columns to force to text, so
 *        Excel preserves identifiers such as document numbers and references
 */
export function toCsv(headers: string[], rows: unknown[][], eol = "\r\n", textColumns: number[] = []): string {
  const text = new Set(textColumns);
  const lines = [headers.map((h) => csvField(h)).join(",")];
  for (const row of rows) {
    lines.push(row.map((v, i) => csvField(v, { asText: text.has(i) })).join(","));
  }
  return lines.join(eol) + eol;
}

/**
 * Express-friendly CSV response. Sets headers + sends the string.
 */
export function sendCsvRows(
  res: { statusCode?: number; setHeader: (k: string, v: string) => void; send: (b: string) => void },
  filename: string,
  headers: string[],
  rows: unknown[][],
  textColumns: number[] = [],
): void {
  res.setHeader("Content-Type", "text/csv; charset=utf-8");
  res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
  res.setHeader("Cache-Control", "no-store");
  res.send(toCsv(headers, rows, "\r\n", textColumns));
}
