/**
 * CSV helpers for client-side report exports.
 *
 * CSV has no type metadata, so spreadsheet apps coerce numeric-looking cells
 * on open. Document numbers and references can contain commas (e.g.
 * "3751,3752") — Excel strips those commas and stores the cell as a number.
 * Prefixing a field with a TAB makes Excel keep it as text while preserving
 * the exact value.
 */

export function csvField(value: unknown, asText = false): string {
  if (value === null || value === undefined) return "";
  let s = String(value);
  if (s === "") return "";
  if (asText) s = `\t${s}`;
  if (/[",\n\r]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

/**
 * Build CSV text (CRLF, Excel-friendly).
 *
 * @param headers     column labels for the first row
 * @param rows        data rows aligned to headers
 * @param textColumns header NAMES whose data cells must be forced to text
 *                    (e.g. ["Doc Number", "Reference"]). Unknown names are
 *                    ignored, and the header row itself is never prefixed.
 */
export function toCSV(
  headers: string[],
  rows: (string | number | null | undefined)[][],
  textColumns: string[] = [],
): string {
  const text = new Set(
    textColumns.map((name) => headers.indexOf(name)).filter((i) => i >= 0),
  );
  return [headers, ...rows]
    .map((row, rowIndex) =>
      row.map((v, i) => csvField(v, rowIndex > 0 && text.has(i))).join(","),
    )
    .join("\r\n");
}
