import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import { format } from "date-fns";
import QRCode from "qrcode";
import type { InvoiceDetail } from "@/hooks/use-fbr-invoicing";
import { FBR_INVOICE_LOGO_B64 } from "@/lib/invoice-logo";

/**
 * Build a PDF for a generated FBR invoice, mirroring the reference "DIGITAL
 * INVOICE" layout (see Lucky_Invoice sample): TKT TEXTILES header with sales
 * tax banner, BILL TO + INVOICE blocks, a line-item table (# / ITEM / QTY /
 * RATE / VALUE / ST % / SALES TAX, with HS Code + Item Code per line), TOTAL
 * VALUE / SALES TAX / GRAND TOTAL, amount in words, and terms/footer.
 */
export async function downloadInvoicePdf(inv: InvoiceDetail): Promise<void> {
  const doc = new jsPDF({ orientation: "portrait", unit: "pt", format: "a4" });
  const W = doc.internal.pageSize.getWidth();

  const money = (n: string | number) =>
    Number(n).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const moneyRaw = (n: string | number) => Number(n).toFixed(2);

  // ── Header: TKT TEXTILES (left) + DIGITAL INVOICE banner (right) ──────
  doc.setFont("helvetica", "bold");
  doc.setFontSize(22);
  doc.text(inv.companyName ?? "TKT TEXTILES", 20, 78);

  // QR code of the FBR invoice number — top-right corner (mirrors the sample
  // invoice header icon placement; the FBR spec prints a QR on each invoice).
  let qrDataUrl: string | null = null;
  if (inv.fbrInvoiceNumber) {
    try {
      qrDataUrl = await QRCode.toDataURL(inv.fbrInvoiceNumber, {
        errorCorrectionLevel: "M",
        margin: 1,
        width: 120,
      });
    } catch {
      qrDataUrl = null;
    }
  }
  const bannerRight = W - 20;
  if (qrDataUrl) {
    doc.addImage(qrDataUrl, "PNG", W - 72, 28, 52, 52);
  }

  doc.setFont("helvetica", "bold");
  doc.setFontSize(16);
  doc.text("DIGITAL INVOICE", bannerRight, 96, { align: "right" });
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  doc.text("S A L E S   T A X", bannerRight, 112, { align: "right" });
  doc.text(`REG. #: ${inv.companyNtnCnic ?? "—"}`, bannerRight, 126, { align: "right" });

  // ── BILL TO (left) + INVOICE (right) blocks ───────────────────────────
  doc.setFont("helvetica", "bold");
  doc.setFontSize(9);
  doc.text("BILL TO", 20, 148);
  doc.text("INVOICE", W / 2, 148);

  let by = 164;
  doc.setFontSize(12);
  doc.text(inv.partyName ?? "—", 20, by); by += 18;
  doc.setFontSize(10);
  doc.setFont("helvetica", "normal");
  if (inv.partyAddress) { doc.text(inv.partyAddress, 20, by); by += 14; }
  if (inv.partyProvince) { doc.text(inv.partyProvince.toUpperCase(), 20, by); by += 14; }
  doc.text(`NTN/CNIC: ${inv.partyNtnCnic ?? "—"}`, 20, by);

  // INVOICE block (right): internal invoice number, date, FBR number.
  const leftX = W / 2 + 8;
  doc.setFontSize(8);
  doc.setFont("helvetica", "normal");
  doc.text("INVOICE NUMBER", leftX, 164);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(12);
  doc.text(String(inv.id).padStart(6, "0"), leftX, 176);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  doc.text("INVOICE DATE", W - 20, 164, { align: "right" });
  doc.setFont("helvetica", "bold");
  doc.setFontSize(12);
  doc.text(format(new Date(inv.invoiceDate + "T00:00:00"), "dd-MM-yyyy"), W - 20, 176, { align: "right" });
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  doc.text("FBR INVOICE #", leftX, 192);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(11);
  doc.text(inv.fbrInvoiceNumber ?? "—", leftX, 204);

  // ── Items table ────────────────────────────────────────────────────────
  autoTable(doc, {
    startY: 220,
    margin: { left: 20, right: 20 },
    head: [["#", "ITEM", "QTY", "RATE", "VALUE", "ST %", "SALES TAX"]],
    body: inv.items.map((it, idx) => [
      String(idx + 1),
      [
        (it.yarnTypeName ?? "—") + (it.yarnCountName ? ` (${it.yarnCountName})` : ""),
        it.yarnTypeName ?? "",
        `HS Code: ${it.hsCode ?? ""}`.trim(),
        `Item Code: ${it.yarnTypeName ?? ""} ${it.yarnCountName ?? ""}`.trim(),
      ],
      `${Number(it.quantity).toLocaleString("en-PK", { minimumFractionDigits: 3, maximumFractionDigits: 3 })} (${it.uoM ?? "KG"})`,
      money(it.ratePerKg),
      money(it.valueExcludingTax),
      "18%",
      money(it.taxAmount),
    ]),
    theme: "grid",
    styles: { fontSize: 9, cellPadding: 3 },
    headStyles: { fillColor: [245, 245, 245], textColor: [15, 15, 15], fontStyle: "bold" },
    columnStyles: {
      0: { cellWidth: 24 },
      1: { cellWidth: 240 },
      2: { halign: "right", cellWidth: 72 },
      3: { halign: "right", cellWidth: 56 },
      4: { halign: "right", cellWidth: 72 },
      5: { halign: "right", cellWidth: 40 },
      6: { halign: "right", cellWidth: 66 },
    },
    // Multi-line item cell: title / description / HS code / item code.
    didParseCell: (data) => {
      if (data.section === "body" && data.column.index === 1 && Array.isArray(data.cell.raw)) {
        data.cell.text = data.cell.raw as string[];
        data.cell.styles.valign = "middle";
      }
      if (data.section === "body" && [2, 3, 4, 5, 6].includes(data.column.index)) {
        data.cell.styles.halign = "right";
      }
    },
  });

  const lastY = (doc as unknown as { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY ?? 260;

  // ── AMOUNT IN WORDS (left) + totals (right) ───────────────────────────
  const words = amountInWords(inv.grandTotal);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(9);
  doc.text("AMOUNT IN WORDS", 20, lastY + 24);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  const wordsLines = doc.splitTextToSize(words, W - 280);
  let wy = lastY + 38;
  for (const line of wordsLines) {
    doc.text(line, 20, wy);
    wy += 13;
  }

  const totX = W - 20;
  doc.setFontSize(9);
  doc.text("TOTAL VALUE", totX - 150, lastY + 26, { align: "right" });
  doc.text(money(inv.totalValue), totX, lastY + 26, { align: "right" });
  doc.text("SALES TAX", totX - 150, lastY + 46, { align: "right" });
  doc.text(money(inv.totalTax), totX, lastY + 46, { align: "right" });
  doc.setFont("helvetica", "bold");
  doc.setFontSize(12);
  doc.text("GRAND TOTAL", totX - 150, lastY + 74, { align: "right" });
  doc.text(money(inv.grandTotal), totX, lastY + 74, { align: "right" });

  // ── Terms + footer ─────────────────────────────────────────────────────
  const termsY = Math.max(wy, lastY + 24) + 60;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(9);
  doc.text("TERMS & CONDITIONS", 20, termsY);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  doc.text("- This is a system generated invoice and does not require a signature.", 20, termsY + 12);
  doc.text("- Goods once sold will not be taken back.", 20, termsY + 22);
  doc.text("- Payment due within the agreed credit period; subject to applicable sales tax.", 20, termsY + 32);

  // FBR Digital Invoicing logo — right of the TERMS & CONDITIONS block,
  // matching the sample invoice footer placement.
  doc.addImage(FBR_INVOICE_LOGO_B64, "PNG", W - 110, termsY - 8, 66, 64);

  const pH = doc.internal.pageSize.getHeight();
  doc.setFontSize(8);
  doc.text(inv.companyAddress ?? "", 20, pH - 30);
  doc.text(
    inv.status === "posted"
      ? `This invoice has been reported to FBR Digital Invoicing (No: ${inv.fbrInvoiceNumber ?? "—"}).`
      : "Draft invoice — not yet posted to FBR.",
    20,
    pH - 18,
  );

  doc.save(`invoice-${inv.id}.pdf`);
}

// ─── Number to words (Pakistani / Indian lakh-crore grouping) ─────────────
// Groups: crore (10^7), lakh (10^5), thousand, hundred. Returns "AND X AND
// YY PAISAS ONLY" when there are paisa (fractional) rupees.
const ONES = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE",
  "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN",
  "EIGHTEEN", "NINETEEN"];
const TENS = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY"];

function twoDigits(n: number): string {
  if (n < 20) return ONES[n];
  return `${TENS[Math.floor(n / 10)]}${n % 10 ? " " + ONES[n % 10] : ""}`;
}

function threeDigits(n: number): string {
  const hundreds = Math.floor(n / 100);
  const rest = n % 100;
  let s = "";
  if (hundreds) s += `${ONES[hundreds]} HUNDRED`;
  if (rest) s += (s ? " " : "") + twoDigits(rest);
  return s;
}

function rupeesToWordsAmount(amount: string | number): string {
  const n = typeof amount === "number" ? amount : parseFloat(amount);
  if (!Number.isFinite(n) || n <= 0) return "ZERO";
  const paise = Math.round((n % 1) * 100);
  let whole = Math.floor(n);
  const crore = Math.floor(whole / 10000000); whole %= 10000000;
  const lakh = Math.floor(whole / 100000); whole %= 100000;
  const thousand = Math.floor(whole / 1000); whole %= 1000;
  const parts: string[] = [];
  if (crore) parts.push(`${threeDigits(crore)} CRORE`);
  if (lakh) parts.push(`${threeDigits(lakh)} LAKH`);
  if (thousand) parts.push(`${threeDigits(thousand)} THOUSAND`);
  if (whole) parts.push(threeDigits(whole));
  const ru = parts.length ? parts.join(" ") : "ZERO";
  if (paise) return `${ru} AND ${twoDigits(paise)} PAISAS ONLY`;
  return `${ru} ONLY`;
}

function amountInWords(amount: string | number): string {
  return rupeesToWordsAmount(amount);
}
