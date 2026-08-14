import { useState, useRef } from "react";
import * as XLSX from "xlsx";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import { Upload, AlertCircle, CheckCircle2, SkipForward, XCircle, FileText, Download } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { toast } from "@/hooks/use-toast";

// ─── CSV Column mapping ──────────────────────────────────────────────────────

const HEADER_MAP: Record<string, string> = {
  "date":          "date",
  "doc number":    "docNumber",
  "reference":     "reference",
  "sl":            "sl",
  "gsm":           "gsm",
  "trans type":    "transTypeName",
  "job":           "jobName",
  "party":         "partyName",
  "location":      "locationName",
  "fabric type":   "fabricTypeName",
  "yarn type":     "yarnTypeName",
  "yarn count":    "yarnCountName",
  "yarn brand":    "yarnBrandName",
  "uom":           "uomName",
  "machine":       "machineName",
  "employee":      "employeeName",
  "qty":           "quantity",
  "net wt":        "netWt",
};

export interface CsvRow {
  date?: string;
  docNumber?: string;
  reference?: string;
  sl?: string;
  gsm?: string;
  transTypeName?: string;
  jobName?: string;
  partyName?: string;
  locationName?: string;
  fabricTypeName?: string;
  yarnTypeName?: string;
  yarnCountName?: string;
  yarnBrandName?: string;
  uomName?: string;
  machineName?: string;
  employeeName?: string;
  quantity?: string;
  netWt?: string;
}

export interface ImportError {
  docNumber: string;
  row: number | null;
  field: string;
  value: string;
  reason: string;
}

export interface ImportPreview {
  totalRows: number;
  toImport: number;
  duplicates: number;
  errors: ImportError[];
  previewRows: CsvRow[];
}

export interface ImportResult {
  totalRows: number;
  imported: number;
  skipped: number;
  errors: ImportError[];
}

// ─── Excel parser ────────────────────────────────────────────────────────────

/**
 * Normalise an Excel-sourced date string to YYYY-MM-DD.
 * SheetJS with raw:false formats dates using the cell's own format string,
 * which can vary (M/D/YYYY, DD-MM-YYYY, etc.).  We parse common patterns
 * and re-emit a canonical YYYY-MM-DD string the server expects.
 * Returns the input unchanged if it already looks like YYYY-MM-DD or
 * cannot be parsed (graceful degradation).
 */
function normalizeExcelDate(raw: string): string {
  const s = raw.trim();
  if (!s) return s;

  // Already YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;

  // MM/DD/YYYY or M/D/YYYY
  const mdy = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (mdy) {
    const [, m, d, y] = mdy;
    return `${y}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
  }

  // DD-MM-YYYY or DD/MM/YYYY with 2-digit day/month (European)
  const dmy = s.match(/^(\d{2})[\/\-](\d{2})[\/\-](\d{4})$/);
  if (dmy) {
    const [, d, m, y] = dmy;
    const month = parseInt(m, 10);
    const day   = parseInt(d, 10);
    // Heuristic: if day > 12 it can only be day-first
    if (day > 12) return `${y}-${m}-${d}`;
  }

  // D-MMM-YYYY or D MMM YYYY (e.g. "5 Jan 2024")
  const dmonthy = s.match(/^(\d{1,2})[\s\-]([A-Za-z]{3})[\s\-](\d{4})$/);
  if (dmonthy) {
    const months: Record<string, string> = {
      jan:"01", feb:"02", mar:"03", apr:"04", may:"05", jun:"06",
      jul:"07", aug:"08", sep:"09", oct:"10", nov:"11", dec:"12",
    };
    const [, d, mon, y] = dmonthy;
    const m = months[mon.toLowerCase()];
    if (m) return `${y}-${m}-${d.padStart(2, "0")}`;
  }

  return s;
}

async function parseXlsx(file: File): Promise<CsvRow[]> {
  const arrayBuffer = await file.arrayBuffer();
  // cellDates: false keeps dates as numeric serials so we can reformat them
  // via dateNF after detecting which cells are dates.
  const workbook = XLSX.read(arrayBuffer, { type: "array", cellDates: false });
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  if (!sheet) return [];

  // raw:false + dateNF tells SheetJS to format ALL cells as strings, using
  // "yyyy-mm-dd" for any cell whose type is 'd' (date serial) — this prevents
  // date serials like 45234 from being returned as bare numbers.
  const raw = XLSX.utils.sheet_to_json<string[]>(sheet, {
    header: 1,
    defval: "",
    raw: false,
    dateNF: "yyyy-mm-dd",
  });

  // Find the header row: the first row whose cells contain known column names
  let headerRowIdx = -1;
  let fieldNames: (string | null)[] = [];

  for (let i = 0; i < Math.min(raw.length, 10); i++) {
    const candidates = (raw[i] as unknown[]).map((c) =>
      String(c ?? "").trim().toLowerCase()
    );
    const mapped = candidates.map((h) => HEADER_MAP[h] ?? null);
    const matchCount = mapped.filter(Boolean).length;
    if (matchCount >= 3) {
      headerRowIdx = i;
      fieldNames = mapped;
      break;
    }
  }

  if (headerRowIdx === -1) return [];

  const rows: CsvRow[] = [];
  for (let i = headerRowIdx + 1; i < raw.length; i++) {
    const cells = raw[i] as unknown[];
    const firstVal = String(cells[0] ?? "").trim();

    if (
      firstVal === "Opening Balance" ||
      firstVal.startsWith("Subtotal:") ||
      firstVal === "Grand Total" ||
      firstVal === ""
    ) continue;

    const row: Record<string, string> = {};
    fieldNames.forEach((name, idx) => {
      if (name) {
        let val = String(cells[idx] ?? "").trim();
        // Normalise date fields to YYYY-MM-DD regardless of cell format
        if (name === "date" && val) val = normalizeExcelDate(val);
        if (val !== "") row[name] = val;
      }
    });

    if (!row.date && !row.docNumber) continue;
    rows.push(row as CsvRow);
  }

  return rows;
}

// ─── CSV parser ──────────────────────────────────────────────────────────────

function parseCsvField(line: string, start: number): { value: string; end: number } {
  if (line[start] === '"') {
    let i = start + 1;
    let value = "";
    while (i < line.length) {
      if (line[i] === '"') {
        if (line[i + 1] === '"') { value += '"'; i += 2; }
        else { i++; break; }
      } else {
        value += line[i++];
      }
    }
    while (i < line.length && line[i] !== ',') i++;
    return { value, end: i + 1 };
  }
  const end = line.indexOf(',', start);
  if (end === -1) return { value: line.slice(start), end: line.length + 1 };
  return { value: line.slice(start, end), end: end + 1 };
}

function parseCsvLine(line: string): string[] {
  const fields: string[] = [];
  let pos = 0;
  while (pos <= line.length) {
    const { value, end } = parseCsvField(line, pos);
    fields.push(value);
    pos = end;
    if (pos > line.length + 1) break;
  }
  return fields;
}

function parseCsv(text: string): CsvRow[] {
  const lines = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n");
  if (lines.length < 3) return [];

  // Line 0: company name, Line 1: date range, Line 2: column headers
  const headers = parseCsvLine(lines[2]).map((h) => h.trim().toLowerCase());
  const fieldNames = headers.map((h) => HEADER_MAP[h] ?? null);

  const rows: CsvRow[] = [];
  for (let i = 3; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const fields = parseCsvLine(line);
    const firstVal = (fields[0] ?? "").trim();

    if (
      firstVal === "Opening Balance" ||
      firstVal.startsWith("Subtotal:") ||
      firstVal === "Grand Total"
    ) continue;

    const row: Record<string, string> = {};
    fieldNames.forEach((name, idx) => {
      if (name && fields[idx] != null) row[name] = fields[idx].trim();
    });

    if (!row.date && !row.docNumber) continue;
    rows.push(row as CsvRow);
  }

  return rows;
}

// ─── Component ───────────────────────────────────────────────────────────────

interface ImportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
}

export function ImportDialog({ open, onOpenChange, onSuccess }: ImportDialogProps) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [step, setStep]       = useState<"idle" | "preview" | "importing" | "done">("idle");
  const [fileName, setFileName] = useState("");
  const [parsedRows, setParsedRows] = useState<CsvRow[]>([]);
  const [preview, setPreview]   = useState<ImportPreview | null>(null);
  const [result, setResult]     = useState<ImportResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [parseError, setParseError] = useState("");

  function handleClose() {
    onOpenChange(false);
    setTimeout(reset, 300);
  }

  function reset() {
    setStep("idle");
    setFileName("");
    setParsedRows([]);
    setPreview(null);
    setResult(null);
    setIsLoading(false);
    setParseError("");
    if (fileRef.current) fileRef.current.value = "";
  }

  async function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    setFileName(file.name);
    setParseError("");
    setPreview(null);

    const isXlsx = file.name.toLowerCase().endsWith(".xlsx");
    let rows: CsvRow[];

    try {
      if (isXlsx) {
        rows = await parseXlsx(file);
      } else {
        const text = await file.text();
        rows = parseCsv(text);
      }
    } catch {
      setParseError("Failed to read the file. Make sure it is a valid CSV or Excel (.xlsx) file.");
      return;
    }

    if (rows.length === 0) {
      setParseError("No data rows found. Make sure you upload a Detailed CSV or Excel file exported from this app.");
      return;
    }

    setParsedRows(rows);
    setIsLoading(true);

    try {
      const data = await customFetch<ImportPreview>("/api/transactions/import/preview", {
        method: "POST",
        body: JSON.stringify({ rows }),
      });
      setPreview(data);
      setStep("preview");
    } catch (err) {
      setParseError(`Preview failed: ${err instanceof Error ? err.message : "Unknown error"}`);
    } finally {
      setIsLoading(false);
    }
  }

  async function handleImport() {
    if (!parsedRows.length) return;
    setIsLoading(true);
    setStep("importing");

    try {
      const data = await customFetch<ImportResult>("/api/transactions/import", {
        method: "POST",
        body: JSON.stringify({ rows: parsedRows }),
      });
      setResult(data);
      setStep("done");

      toast({
        title: "Import complete",
        description: `${data.imported} transaction${data.imported !== 1 ? "s" : ""} imported, ${data.skipped} duplicate${data.skipped !== 1 ? "s" : ""} skipped${data.errors.length > 0 ? `, ${data.errors.length} lookup error${data.errors.length !== 1 ? "s" : ""}` : ""}.`,
      });

      onSuccess();
    } catch (err) {
      toast({
        title: "Import failed",
        description: err instanceof Error ? err.message : "Unknown error",
        variant: "destructive",
      });
      setStep("preview");
    } finally {
      setIsLoading(false);
    }
  }

  function downloadErrorReport(errors: ImportError[]) {
    const csvEscape = (v: string) => `"${String(v ?? "").replace(/"/g, '""')}"`;
    const header = ["Doc Number", "Row", "Field", "Value", "Reason"];
    const lines = [
      header.map(csvEscape).join(","),
      ...errors.map((e) =>
        [
          e.docNumber,
          e.row != null ? String(e.row) : "",
          e.field,
          e.value,
          e.reason,
        ]
          .map(csvEscape)
          .join(",")
      ),
    ];
    const blob = new Blob([lines.join("\r\n")], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "import-errors.csv";
    a.click();
    URL.revokeObjectURL(url);
  }

  const canImport = preview && preview.toImport > 0 && step === "preview";

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>Import from CSV or Excel</DialogTitle>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto space-y-4 py-2">
          {/* File picker */}
          <div
            className="border-2 border-dashed rounded-lg p-6 text-center cursor-pointer hover:border-primary/50 hover:bg-muted/30 transition-colors"
            onClick={() => fileRef.current?.click()}
          >
            <Upload className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
            <p className="text-sm font-medium">
              {fileName ? fileName : "Click to select a CSV or Excel file"}
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Upload a Detailed CSV or Excel (.xlsx) file exported using the Export button
            </p>
            <input
              ref={fileRef}
              type="file"
              accept=".csv,text/csv,.xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
              className="hidden"
              onChange={handleFileChange}
            />
          </div>

          {/* Parse error */}
          {parseError && (
            <div className="flex items-start gap-2 text-sm text-destructive bg-destructive/10 rounded-md p-3">
              <XCircle className="h-4 w-4 mt-0.5 shrink-0" />
              <span>{parseError}</span>
            </div>
          )}

          {/* Loading */}
          {isLoading && (
            <p className="text-sm text-muted-foreground text-center animate-pulse">Analysing file…</p>
          )}

          {/* Preview summary */}
          {preview && step !== "idle" && (
            <div className="space-y-3">
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="rounded-md border p-3 text-center">
                  <FileText className="h-4 w-4 mx-auto mb-1 text-muted-foreground" />
                  <p className="text-xl font-semibold">{preview.totalRows}</p>
                  <p className="text-xs text-muted-foreground">Total rows</p>
                </div>
                <div className="rounded-md border p-3 text-center">
                  <CheckCircle2 className="h-4 w-4 mx-auto mb-1 text-green-600" />
                  <p className="text-xl font-semibold text-green-700">{preview.toImport}</p>
                  <p className="text-xs text-muted-foreground">Ready to import</p>
                </div>
                <div className="rounded-md border p-3 text-center">
                  <SkipForward className="h-4 w-4 mx-auto mb-1 text-yellow-600" />
                  <p className="text-xl font-semibold text-yellow-700">{preview.duplicates}</p>
                  <p className="text-xs text-muted-foreground">Duplicates (skip)</p>
                </div>
                <div className="rounded-md border p-3 text-center">
                  <AlertCircle className="h-4 w-4 mx-auto mb-1 text-red-500" />
                  <p className="text-xl font-semibold text-red-600">{preview.errors.length}</p>
                  <p className="text-xs text-muted-foreground">Lookup errors</p>
                </div>
              </div>

              {/* Errors list */}
              {preview.errors.length > 0 && (
                <div className="rounded-md border border-destructive/30 bg-destructive/5 p-3 space-y-1">
                  <div className="flex items-center justify-between mb-1">
                    <p className="text-xs font-semibold text-destructive">Lookup errors (these rows will be skipped):</p>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="h-6 px-2 text-xs text-destructive hover:text-destructive"
                      onClick={() => downloadErrorReport(preview.errors)}
                    >
                      <Download className="h-3 w-3 mr-1" />
                      Download error report
                    </Button>
                  </div>
                  <div className="max-h-36 overflow-y-auto space-y-0.5">
                    {preview.errors.map((e, i) => (
                      <p key={i} className="text-xs text-destructive">
                        Doc #{e.docNumber}{e.row != null ? ` row ${e.row}` : ""} — {e.field}{e.value ? `: "${e.value}"` : ""} — {e.reason}
                      </p>
                    ))}
                  </div>
                </div>
              )}

              {/* Preview rows table */}
              {preview.previewRows.length > 0 && (
                <div>
                  <p className="text-xs font-medium text-muted-foreground mb-1">
                    Preview (first {preview.previewRows.length} rows):
                  </p>
                  <div className="rounded-md border overflow-auto max-h-48">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="text-xs whitespace-nowrap">Date</TableHead>
                          <TableHead className="text-xs whitespace-nowrap">Doc #</TableHead>
                          <TableHead className="text-xs whitespace-nowrap">Trans Type</TableHead>
                          <TableHead className="text-xs whitespace-nowrap">Party</TableHead>
                          <TableHead className="text-xs whitespace-nowrap">Qty</TableHead>
                          <TableHead className="text-xs whitespace-nowrap">Net Wt</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {preview.previewRows.map((r, i) => (
                          <TableRow key={i}>
                            <TableCell className="text-xs">{r.date ?? "—"}</TableCell>
                            <TableCell className="text-xs">{r.docNumber ?? "—"}</TableCell>
                            <TableCell className="text-xs">{r.transTypeName ?? "—"}</TableCell>
                            <TableCell className="text-xs">{r.partyName ?? "—"}</TableCell>
                            <TableCell className="text-xs">{r.quantity ?? "—"}</TableCell>
                            <TableCell className="text-xs">{r.netWt ?? "—"}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Done state */}
          {step === "done" && result && (
            <div className="space-y-3">
              <div className="rounded-md border border-green-200 bg-green-50 p-4 text-center space-y-1">
                <CheckCircle2 className="h-8 w-8 mx-auto text-green-600" />
                <p className="font-semibold text-green-700">Import complete!</p>
                <p className="text-sm text-muted-foreground">
                  {result.imported} transaction{result.imported !== 1 ? "s" : ""} imported
                  {result.skipped > 0 ? ` · ${result.skipped} duplicate${result.skipped !== 1 ? "s" : ""} skipped` : ""}
                  {result.errors.length > 0 ? ` · ${result.errors.length} row${result.errors.length !== 1 ? "s" : ""} rejected` : ""}
                </p>
              </div>

              {result.errors.length > 0 && (
                <div className="rounded-md border border-destructive/30 bg-destructive/5 p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <p className="text-xs font-semibold text-destructive">
                      {result.errors.length} row{result.errors.length !== 1 ? "s" : ""} were rejected — fix and re-import:
                    </p>
                    <Button
                      variant="outline"
                      size="sm"
                      className="h-7 px-3 text-xs border-destructive/40 text-destructive hover:text-destructive hover:bg-destructive/10"
                      onClick={() => downloadErrorReport(result.errors)}
                    >
                      <Download className="h-3 w-3 mr-1.5" />
                      Download error report
                    </Button>
                  </div>
                  <div className="max-h-40 overflow-y-auto space-y-0.5">
                    {result.errors.map((e, i) => (
                      <p key={i} className="text-xs text-destructive">
                        Doc #{e.docNumber}{e.row != null ? ` row ${e.row}` : ""} — {e.field}{e.value ? `: "${e.value}"` : ""} — {e.reason}
                      </p>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        <DialogFooter className="gap-2 flex-shrink-0">
          {step === "done" ? (
            <Button onClick={handleClose}>Close</Button>
          ) : (
            <>
              <Button variant="outline" onClick={handleClose} disabled={isLoading}>Cancel</Button>
              <Button
                onClick={handleImport}
                disabled={!canImport || isLoading}
              >
                {isLoading && step === "importing" ? "Importing…" : `Import ${preview?.toImport ?? ""} transaction${preview?.toImport !== 1 ? "s" : ""}`}
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
