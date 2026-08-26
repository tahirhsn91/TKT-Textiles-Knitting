import { useState } from "react";
import { Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

interface ExportCsvButtonProps {
  qs?: string | null;
  filename?: string;
  className?: string;
  disabled?: boolean;
}

/**
 * ExportCsvButton — issue #219 2.5. Downloads the report CSV for the current
 * filter query string (same `qs` the JSON report query uses), authenticated
 * through customFetch (which attaches the bearer token + tenant header), then
 * triggers a client-side file save.
 */
export function ExportCsvButton({ qs, filename = "report.csv", className, disabled }: ExportCsvButtonProps) {
  const [busy, setBusy] = useState(false);

  const download = async () => {
    setBusy(true);
    try {
      const res = await customFetch<Blob>(`/api/reports/export/csv${qs ? `?${qs}` : ""}`, {
        method: "GET",
        responseType: "blob",
      });
      const blob = res instanceof Blob ? res : new Blob([String(res)], { type: "text/csv;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error("CSV export failed", err);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Button variant="outline" size="sm" onClick={download} disabled={disabled || busy} className={className}>
      <Download className="h-4 w-4" /> {busy ? "Exporting…" : "Export CSV"}
    </Button>
  );
}
