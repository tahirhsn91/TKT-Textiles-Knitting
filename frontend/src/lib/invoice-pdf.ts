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
  const H = doc.internal.pageSize.getHeight();
  const M = 20; // page margin

  // ── Design tokens (black/white invoice) ────────────────────────────────
  const INK = [20, 20, 20];          // near-black
  const MUTED = [110, 110, 110];     // secondary grey
  const LINE = [200, 200, 200];      // light hairline
  const BAND = [245, 245, 245];      // zebra / soft fill (light grey)
  const HEAD_FILL = [45, 45, 45];    // table header fill (dark grey)
  const TOTAL_FILL = [30, 30, 30];   // grand-total band (near-black)

  const money = (n: string | number) =>
    Number(n).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  const text = (s: string, x: number, y: number, opts?: Parameters<typeof doc.text>[3]) =>
    doc.text(s, x, y, opts);
  const hairline = (y: number, x1 = M, x2 = W - M, color: number[] = LINE, w = 0.6) => {
    doc.setDrawColor(color[0], color[1], color[2]);
    doc.setLineWidth(w);
    doc.line(x1, y, x2, y);
  };

  // ── Header ─────────────────────────────────────────────────────────────
  // Company name (left, black) + address below it; QR top-right corner;
  // DIGITAL INVOICE banner right-aligned below the QR, so nothing overlaps.
  doc.setFont("helvetica", "bold");
  doc.setFontSize(24);
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text(inv.companyName ?? "TKT TEXTILES", M, 74);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(9);
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  if (inv.companyAddress) {
    text(inv.companyAddress.split(",")[0] ?? inv.companyAddress, M, 88);
  }

  // FBR invoice number QR — top-right corner (52x52pt, y 40..92).
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
  if (qrDataUrl) {
    doc.addImage(qrDataUrl, "PNG", W - 72, 40, 52, 52);
  }

  // DIGITAL INVOICE banner — right-aligned below the QR (y 104..126), clear
  // of both the QR (y 40..92) and the address text on the left.
  doc.setFont("helvetica", "bold");
  doc.setFontSize(13);
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text("DIGITAL INVOICE", W - M, 106, { align: "right" });
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8.5);
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  text("S A L E S   T A X", W - M, 118, { align: "right" });
  text(`REG. #: ${inv.companyNtnCnic ?? "—"}`, W - M, 128, { align: "right" });

  // Black header rule below everything (y=138) — clear of all header text.
  hairline(138, M, W - M, [20, 20, 20], 1.2);

  // ── BILL TO / INVOICE blocks ──────────────────────────────────────────
  const blockTop = 150;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(9);
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text("BILL TO", M, blockTop);
  text("INVOICE", W / 2, blockTop);

  const leftX = W / 2 + 8;

  // Bill-to details (left column).
  let by = blockTop + 16;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(12);
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text(inv.partyName ?? "—", M, by); by += 17;
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  if (inv.partyAddress) { text(inv.partyAddress, M, by); by += 14; }
  if (inv.partyProvince) { text(inv.partyProvince.toUpperCase(), M, by); by += 14; }
  text(`NTN/CNIC: ${inv.partyNtnCnic ?? "—"}`, M, by);

  // INVOICE fields (right): number, date, FBR number. Labels muted, values bold.
  const invLabel = (s: string, x: number, y: number, o?: Parameters<typeof text>[3]) => {
    doc.setFont("helvetica", "normal"); doc.setFontSize(7.5); doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]); text(s, x, y, o);
  };
  const invValue = (s: string, x: number, y: number, o?: Parameters<typeof text>[3]) => {
    doc.setFont("helvetica", "bold"); doc.setFontSize(12); doc.setTextColor(INK[0], INK[1], INK[2]); text(s, x, y, o);
  };
  invLabel("INVOICE NUMBER", leftX, blockTop + 12);
  invValue(String(inv.id).padStart(6, "0"), leftX, blockTop + 24);
  invLabel("INVOICE DATE", W - M, blockTop + 12, { align: "right" });
  invValue(format(new Date(inv.invoiceDate + "T00:00:00"), "dd-MM-yyyy"), W - M, blockTop + 24, { align: "right" });
  invLabel("FBR INVOICE #", leftX, blockTop + 42);
  invValue(inv.fbrInvoiceNumber ?? "—", leftX, blockTop + 54);

  // ── Items table ────────────────────────────────────────────────────────
  autoTable(doc, {
    startY: blockTop + 78,
    margin: { left: M, right: M },
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
    styles: { fontSize: 9, cellPadding: 4, textColor: INK as unknown as string },
    headStyles: { fillColor: HEAD_FILL as unknown as string, textColor: [255, 255, 255], fontStyle: "bold", fontSize: 9 },
    alternateRowStyles: { fillColor: BAND as unknown as string },
    columnStyles: {
      0: { cellWidth: 24 },
      1: { cellWidth: 248 },
      2: { halign: "right", cellWidth: 74 },
      3: { halign: "right", cellWidth: 56 },
      4: { halign: "right", cellWidth: 74 },
      5: { halign: "right", cellWidth: 38 },
      6: { halign: "right", cellWidth: 66 },
    },
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
  doc.setFontSize(8);
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  text("AMOUNT IN WORDS", M, lastY + 22);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  doc.setTextColor(INK[0], INK[1], INK[2]);
  const wordsLines = doc.splitTextToSize(words, W - 300);
  let wy = lastY + 34;
  for (const line of wordsLines) {
    text(line, M, wy);
    wy += 13;
  }

  // Totals block (right) with a shaded grand-total band.
  const totX = W - M;
  const totLeft = totX - 170;
  const totTop = lastY + 18;
  doc.setFontSize(9);
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  doc.setFont("helvetica", "normal");
  text("TOTAL VALUE", totLeft, totTop);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text(money(inv.totalValue), totX, totTop, { align: "right" });
  doc.setFont("helvetica", "normal");
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  text("SALES TAX (18%)", totLeft, totTop + 18);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text(money(inv.totalTax), totX, totTop + 18, { align: "right" });

  // Grand total band.
  const bandTop = totTop + 30;
  doc.setFillColor(TOTAL_FILL[0], TOTAL_FILL[1], TOTAL_FILL[2]);
  doc.rect(totLeft, bandTop - 10, totX - totLeft, 24, "F");
  doc.setTextColor(255, 255, 255);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(10);
  text("GRAND TOTAL", totLeft + 10, bandTop + 4);
  doc.setFontSize(12);
  text(money(inv.grandTotal), totX - 10, bandTop + 4, { align: "right" });

  // ── Footer: separator + terms + logo, anchored to the bottom of the page ──
  const pH = doc.internal.pageSize.getHeight();
  const termsY = pH - 74;

  // Separator line above the footer block.
  hairline(termsY - 16, M, W - M, [20, 20, 20], 1.0);

  // TERMS & CONDITIONS (bottom-left).
  doc.setFont("helvetica", "bold");
  doc.setFontSize(9);
  doc.setTextColor(INK[0], INK[1], INK[2]);
  text("TERMS & CONDITIONS", M, termsY);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  text("\u2022  This is a system generated invoice and does not require a signature.", M, termsY + 14);
  text("\u2022  Goods once sold will not be taken back.", M, termsY + 24);
  text("\u2022  Payment due within the agreed credit period; subject to applicable sales tax.", M, termsY + 34);

  // FBR Digital Invoicing logo — bottom-right, raised clear of the footer
  // note below it (logo bottom lands ~pH-30, above the address/note at pH-20).
  doc.addImage(FBR_INVOICE_LOGO_B64, "PNG", W - 108, termsY - 22, 66, 64);

  // Company address + FBR reporting note + version credit at the very bottom.
  hairline(pH - 32, 0, W, LINE, 0.4);
  doc.setFontSize(8);
  doc.setTextColor(MUTED[0], MUTED[1], MUTED[2]);
  text(inv.companyAddress ?? "", M, pH - 20);
  text(
    inv.status === "posted"
      ? `This invoice has been reported to FBR Digital Invoicing (No: ${inv.fbrInvoiceNumber ?? "—"}).`
      : "Draft invoice — not yet posted to FBR.",
    M,
    pH - 12,
  );
  text("DINVOICE System v1.0 by innovrix", W - M, pH - 12, { align: "right" });

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
