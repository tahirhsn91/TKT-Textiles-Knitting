import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import type { InvoiceDetail } from "@/hooks/use-fbr-invoicing";

/**
 * Build a PDF for a generated FBR invoice and trigger a download.
 *
 * Follows the app's existing jsPDF + autoTable pattern (see reports). Portrait
 * A4: seller header block, buyer block, line-item table (yarn type / HS code /
 * UOM / quantity / rate / value / tax / total), and a totals footer with the
 * FBR invoice number when posted.
 */
export function downloadInvoicePdf(inv: InvoiceDetail): void {
  const doc = new jsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
  const pageW = doc.internal.pageSize.getWidth();

  // ── Header ─────────────────────────────────────────────────────────────
  doc.setFont("helvetica", "bold");
  doc.setFontSize(16);
  doc.text("TAX INVOICE", 14, 16);
  doc.setFontSize(10);
  doc.setFont("helvetica", "normal");
  doc.text(`Invoice #${inv.id}`, 14, 24);
  doc.text(`Date: ${inv.invoiceDate}`, pageW - 14, 24, { align: "right" });

  // Seller
  doc.setFont("helvetica", "bold");
  doc.setFontSize(11);
  doc.text("Seller", 14, 36);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  let y = 42;
  if (inv.companyName) { doc.text(inv.companyName, 14, y); y += 5; }
  doc.text(`Seller NTN/CNIC: ${inv.companyId ? "—" : "—"}`, 14, y); y += 5;
  doc.text(`FBR Invoice No: ${inv.fbrInvoiceNumber ?? "—"}`, 14, y);

  // Buyer
  doc.setFont("helvetica", "bold");
  doc.setFontSize(11);
  doc.text("Bill To", pageW / 2, 36);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  let by = 42;
  if (inv.partyName) { doc.text(inv.partyName, pageW / 2, by); by += 5; }

  // ── Items table ────────────────────────────────────────────────────────
  autoTable(doc, {
    startY: y + 8,
    head: [["Yarn Type", "HS Code", "UOM", "Qty (kg)", "Rate", "Value", "Tax (18%)", "Total"]],
    body: inv.items.map((it) => [
      it.yarnTypeName ?? "—",
      it.hsCode ?? "—",
      it.uoM ?? "—",
      it.quantity,
      Number(it.ratePerKg).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
      Number(it.valueExcludingTax).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
      Number(it.taxAmount).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
      Number(it.totalValue).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
    ]),
    styles: { fontSize: 8 },
    headStyles: { fillColor: [37, 99, 235] },
    columnStyles: {
      3: { halign: "right" },
      4: { halign: "right" },
      5: { halign: "right" },
      6: { halign: "right" },
      7: { halign: "right" },
    },
    margin: { left: 14, right: 14 },
  });

  // ── Totals footer ──────────────────────────────────────────────────────
  const lastY = (doc as unknown as { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY ?? 60;
  let ty = lastY + 8;
  const money = (n: string) =>
    Number(n).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  doc.setFont("helvetica", "normal");
  doc.text("Subtotal (Value)", pageW - 14 - 40, ty, { align: "right" });
  doc.text(money(inv.totalValue), pageW - 14, ty, { align: "right" });
  ty += 6;
  doc.text("Sales Tax (18%)", pageW - 14 - 40, ty, { align: "right" });
  doc.text(money(inv.totalTax), pageW - 14, ty, { align: "right" });
  ty += 6;
  doc.setFont("helvetica", "bold");
  doc.text("Grand Total", pageW - 14 - 40, ty, { align: "right" });
  doc.text(money(inv.grandTotal), pageW - 14, ty, { align: "right" });

  // ── Footer note ────────────────────────────────────────────────────────
  const pageH = doc.internal.pageSize.getHeight();
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  doc.text(
    inv.status === "posted"
      ? `This invoice has been reported to FBR Digital Invoicing (No: ${inv.fbrInvoiceNumber ?? "—"}).`
      : "Draft invoice — not yet posted to FBR.",
    14,
    pageH - 10,
  );

  doc.save(`invoice-${inv.id}.pdf`);
}
