/**
 * CSV export helpers (issue #219 2.5 reporting & export).
 * Dependency-free: generates RFC-4180-ish CSV that Excel/Sheets open cleanly.
 */

/** Escape a field per CSV rules (quote if it contains comma, quote, or newline). */
export function csvField(value: unknown): string {
  if (value === null || value === undefined) return "";
  let s = String(value);
  // Keep numeric-ish strings unquoted when safe; always quote when special chars.
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
 */
export function toCsv(headers: string[], rows: unknown[][], eol = "\r\n"): string {
  const lines = [headers.map(csvField).join(",")];
  for (const row of rows) {
    lines.push(row.map(csvField).join(","));
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
): void {
  res.setHeader("Content-Type", "text/csv; charset=utf-8");
  res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
  res.setHeader("Cache-Control", "no-store");
  res.send(toCsv(headers, rows));
}
