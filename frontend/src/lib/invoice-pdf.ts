import jsPDF from "jspdf";
import { format } from "date-fns";
import QRCode from "qrcode";
import type { InvoiceDetail } from "@/hooks/use-fbr-invoicing";
import { FBR_INVOICE_LOGO_B64 } from "@/lib/invoice-logo";

/**
 * Build a PDF for a generated FBR invoice, mirroring the government-style FBR
 * "SALES TAX INVOICE" reference layout:
 *   - Header: company logo + name/address (left) and a dark "SALES TAX INVOICE"
 *     box (right).
 *   - Boxed detail sections: SUPPLIER DETAILS + TRANSACTION DETAILS (row 1),
 *     CUSTOMER DETAILS (row 2), each with a shaded title strip and label/value
 *     rows.
 *   - Bordered line-item table: S.# / Description / UOM / Quantity / Price /
 *     Taxes Exclusive Value / Tax Rate / Tax Amount / Taxes Inclusive Value,
 *     followed by an amount-in-words row that also carries the column totals.
 *   - Bottom-left: FBR Digital Invoicing logo + QR code (FBR invoice number).
 *   - Bottom-right: totals summary box (Total Taxes Exclusive Value / Total Tax
 *     Amount @ 18% / Total Taxes Inclusive Value).
 *   - Footer: "computer generated document" note + a 3-column footer strip.
 */
export async function downloadInvoicePdf(inv: InvoiceDetail): Promise<void> {
  const doc = new jsPDF({ orientation: "portrait", unit: "pt", format: "a4" });
  const W = doc.internal.pageSize.getWidth();
  const H = doc.internal.pageSize.getHeight();
  const M = 24; // page margin
  const RIGHT = W - M;
  const INNER = RIGHT - M; // printable width

  // ── Design tokens (black/white boxed invoice) ──────────────────────────
  const INK: [number, number, number] = [15, 15, 15]; // near-black text/borders
  const MUTED: [number, number, number] = [90, 90, 90]; // secondary grey
  const BORDER: [number, number, number] = [30, 30, 30]; // box borders
  const TITLE_FILL: [number, number, number] = [235, 235, 235]; // section title strip
  const DARK_FILL: [number, number, number] = [55, 55, 55]; // "SALES TAX INVOICE" box

  const money = (n: string | number) =>
    Math.round(Number(n)).toLocaleString("en-US");
  const money2 = (n: string | number) =>
    Number(n).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  const setInk = (c: [number, number, number]) => doc.setTextColor(c[0], c[1], c[2]);
  const setDraw = (c: [number, number, number]) => doc.setDrawColor(c[0], c[1], c[2]);
  const setFill = (c: [number, number, number]) => doc.setFillColor(c[0], c[1], c[2]);
  const text = (s: string, x: number, y: number, opts?: Parameters<typeof doc.text>[3]) =>
    doc.text(s, x, y, opts);

  // Draw a box; returns nothing. lineWidth default 0.8.
  const box = (x: number, y: number, w: number, h: number, lw = 0.8) => {
    setDraw(BORDER);
    doc.setLineWidth(lw);
    doc.rect(x, y, w, h);
  };
  // Section with a shaded title strip. Returns the y where body content starts.
  const sectionTitle = (x: number, y: number, w: number, title: string, stripH = 20) => {
    setFill(TITLE_FILL);
    setDraw(BORDER);
    doc.setLineWidth(0.8);
    doc.rect(x, y, w, stripH, "FD");
    doc.setFont("helvetica", "bold");
    doc.setFontSize(9);
    setInk(INK);
    text(title, x + 8, y + stripH - 6);
    return y + stripH;
  };
  // A label/value row inside a details box.
  const kvRow = (
    label: string,
    value: string,
    x: number,
    y: number,
    labelW: number,
    valueMaxW: number,
  ): number => {
    doc.setFont("helvetica", "normal");
    doc.setFontSize(8.5);
    setInk(MUTED);
    text(label, x, y);
    doc.setFont("helvetica", "bold");
    setInk(INK);
    const lines = doc.splitTextToSize(value || "\u2014", valueMaxW);
    text(lines, x + labelW, y);
    return y + Math.max(1, lines.length) * 12;
  };

  // ── Header ─────────────────────────────────────────────────────────────
  // Company name/address (left); dark "SALES TAX INVOICE" box (right).
  const headTop = M;
  const nameX = M;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(15);
  setInk(INK);
  text((inv.companyName ?? "TKT TEXTILES").toUpperCase(), nameX, headTop + 16);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8.5);
  setInk(MUTED);
  let hy = headTop + 30;
  if (inv.companyAddress) {
    const addrLines = doc.splitTextToSize(inv.companyAddress, 280);
    text(addrLines, nameX, hy);
    hy += addrLines.length * 11;
  }

  // Dark "SALES TAX INVOICE" box, right-aligned in the header.
  const stiW = 200;
  const stiH = 30;
  const stiX = RIGHT - stiW;
  const stiY = headTop + 4;
  setFill(DARK_FILL);
  doc.rect(stiX, stiY, stiW, stiH, "F");
  doc.setFont("helvetica", "bold");
  doc.setFontSize(13);
  setInk([255, 255, 255]);
  text("SALES TAX INVOICE", stiX + stiW / 2, stiY + stiH / 2 + 4.5, { align: "center" });

  // ── Details grid: SUPPLIER (left) + TRANSACTION (right), then CUSTOMER ──
  const gridTop = Math.max(headTop + 50, hy + 6);
  const gap = 12;
  const colW = (INNER - gap) / 2;
  const leftX = M;
  const rightX = M + colW + gap;

  // SUPPLIER DETAILS (left, top)
  const supTitleY = gridTop;
  const supBodyTop = sectionTitle(leftX, supTitleY, colW, "SUPPLIER DETAILS");
  let sy = supBodyTop + 18;
  const supLabelW = 78;
  const supValW = colW - supLabelW - 24;
  sy = kvRow("Name:", (inv.companyName ?? "\u2014").toUpperCase(), leftX + 12, sy, supLabelW, supValW);
  sy = kvRow("NTN / CNIC:", inv.companyNtnCnic ?? "\u2014", leftX + 12, sy, supLabelW, supValW);
  sy = kvRow("Address:", inv.companyAddress ?? "\u2014", leftX + 12, sy, supLabelW, supValW);
  const supBottom = sy + 6;

  // TRANSACTION DETAILS (right, top)
  const txBodyTop = sectionTitle(rightX, gridTop, colW, "TRANSACTION DETAILS");
  let ty = txBodyTop + 18;
  const txLabelW = 92;
  const txValW = colW - txLabelW - 24;
  const invNo = String(inv.id).padStart(8, "0");
  ty = kvRow("Transaction No.:", invNo, rightX + 12, ty, txLabelW, txValW);
  ty = kvRow(
    "Transaction Date:",
    format(new Date(inv.invoiceDate + "T00:00:00"), "dd-MMM-yyyy").toUpperCase(),
    rightX + 12,
    ty,
    txLabelW,
    txValW,
  );
  ty = kvRow(
    "Transaction Type:",
    inv.items[0]?.saleType ?? "Goods at standard rate (default)",
    rightX + 12,
    ty,
    txLabelW,
    txValW,
  );
  ty = kvRow("FBR Invoice No.:", inv.fbrInvoiceNumber ?? "\u2014", rightX + 12, ty, txLabelW, txValW);
  ty = kvRow("Site Name:", "Head Office", rightX + 12, ty, txLabelW, txValW);
  ty = kvRow("Store Name:", "Store 01", rightX + 12, ty, txLabelW, txValW);
  ty = kvRow("Remarks:", "", rightX + 12, ty, txLabelW, txValW);
  const txBottom = ty + 6;

  // Draw the SUPPLIER + TRANSACTION borders. TRANSACTION has more rows, so both
  // boxes extend to the taller of the two, keeping the row visually aligned.
  const row1Bottom = Math.max(supBottom, txBottom);
  box(leftX, supTitleY, colW, row1Bottom - supTitleY);
  box(rightX, gridTop, colW, row1Bottom - gridTop);

  // CUSTOMER DETAILS (left, second row) — right column of this row is left
  // blank (matching the reference, where the customer box sits under supplier).
  const custTitleY = row1Bottom + gap;
  const custBodyTop = sectionTitle(leftX, custTitleY, colW, "CUSTOMER DETAILS");
  let cy = custBodyTop + 18;
  cy = kvRow("Name:", (inv.partyName ?? "\u2014").toUpperCase(), leftX + 12, cy, supLabelW, supValW);
  cy = kvRow("NTN:", inv.partyNtnCnic ?? "\u2014", leftX + 12, cy, supLabelW, supValW);
  const custAddr = [inv.partyAddress, inv.partyProvince].filter(Boolean).join(", ");
  cy = kvRow("Address:", custAddr || "\u2014", leftX + 12, cy, supLabelW, supValW);
  const custBottom = cy + 6;
  // Match the customer box height to the transaction box on its right so the
  // second row aligns with the bottom of the transaction box above-right.
  const row2Bottom = Math.max(custBottom, row1Bottom); // never taller than needed
  box(leftX, custTitleY, colW, row2Bottom - custTitleY);

  // ── Items table (fully bordered, government style) ──────────────────────
  // Columns sized to sum to INNER. Widths tuned for readability.
  const tableTop = Math.max(row2Bottom, row1Bottom) + gap;
  const cols = [
    { key: "sn", label: "S. #", w: 30, align: "left" as const },
    { key: "desc", label: "Description", w: 150, align: "left" as const },
    { key: "uom", label: "UOM", w: 40, align: "left" as const },
    { key: "qty", label: "Quantity", w: 52, align: "right" as const },
    { key: "price", label: "Price", w: 52, align: "right" as const },
    { key: "excl", label: "Taxes Exclusive Value", w: 72, align: "right" as const },
    { key: "rate", label: "Tax Rate", w: 40, align: "center" as const },
    { key: "tax", label: "Tax Amount", w: 62, align: "right" as const },
    { key: "incl", label: "Taxes Inclusive Value", w: 0, align: "right" as const },
  ];
  // Last column absorbs the remaining width so the table sums exactly to INNER.
  const fixed = cols.reduce((a, c) => a + c.w, 0);
  cols[cols.length - 1].w = INNER - fixed;

  // Column x-offsets.
  const colX: number[] = [];
  let acc = M;
  for (const c of cols) {
    colX.push(acc);
    acc += c.w;
  }
  const cellPad = 5;

  // Header row.
  const headH = 34;
  setFill(TITLE_FILL);
  setDraw(BORDER);
  doc.setLineWidth(0.8);
  doc.rect(M, tableTop, INNER, headH, "FD");
  doc.setFont("helvetica", "bold");
  doc.setFontSize(7.5);
  setInk(INK);
  cols.forEach((c, i) => {
    const lines = doc.splitTextToSize(c.label, c.w - cellPad * 2);
    const startY = tableTop + headH / 2 - (lines.length - 1) * 4 + 2.5;
    if (c.align === "right") {
      text(lines, colX[i] + c.w - cellPad, startY, { align: "right" });
    } else if (c.align === "center") {
      text(lines, colX[i] + c.w / 2, startY, { align: "center" });
    } else {
      text(lines, colX[i] + cellPad, startY);
    }
  });
  // Vertical separators in the header.
  setDraw(BORDER);
  doc.setLineWidth(0.5);
  for (let i = 1; i < cols.length; i++) {
    doc.line(colX[i], tableTop, colX[i], tableTop + headH);
  }

  // Body rows.
  let ry = tableTop + headH;
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  inv.items.forEach((it, idx) => {
    const descParts = [
      (it.hsCode ? `${it.hsCode} - ` : "") + (it.yarnTypeName ?? "\u2014"),
      it.yarnCountName ? `(${it.yarnCountName})` : "",
    ]
      .filter(Boolean)
      .join(" ");
    const descLines = doc.splitTextToSize(descParts, cols[1].w - cellPad * 2);
    const rowH = Math.max(24, descLines.length * 10 + 14);

    // Row border.
    setDraw(BORDER);
    doc.setLineWidth(0.6);
    doc.rect(M, ry, INNER, rowH);
    for (let i = 1; i < cols.length; i++) {
      doc.line(colX[i], ry, colX[i], ry + rowH);
    }

    const midY = ry + rowH / 2 + 2.5;
    setInk(INK);
    // S.# = sequential item number (1, 2, 3, ...).
    doc.setFont("helvetica", "normal");
    doc.setFontSize(8);
    text(String(idx + 1), colX[0] + cols[0].w / 2, midY, { align: "center" });
    // Description (top-aligned, multi-line).
    text(descLines, colX[1] + cellPad, ry + 14);
    // UOM.
    text(it.uoM ?? "KG", colX[2] + cellPad, midY);
    // Quantity.
    text(money2(it.quantity), colX[3] + cols[3].w - cellPad, midY, { align: "right" });
    // Price (rate per kg).
    text(money2(it.ratePerKg), colX[4] + cols[4].w - cellPad, midY, { align: "right" });
    // Taxes Exclusive Value.
    text(money(it.valueExcludingTax), colX[5] + cols[5].w - cellPad, midY, { align: "right" });
    // Tax Rate.
    text("18%", colX[6] + cols[6].w / 2, midY, { align: "center" });
    // Tax Amount.
    text(money(it.taxAmount), colX[7] + cols[7].w - cellPad, midY, { align: "right" });
    // Taxes Inclusive Value.
    text(money(it.totalValue), colX[8] + cols[8].w - cellPad, midY, { align: "right" });

    ry += rowH;
  });

  // Amount-in-words + totals row (spans the desc columns on the left, and
  // shows the summed totals under the Exclusive / Tax / Inclusive columns).
  const wordsRowTop = ry;
  const wordsRowH = 26;
  setDraw(BORDER);
  doc.setLineWidth(0.8);
  doc.rect(M, wordsRowTop, INNER, wordsRowH);
  // Vertical separators only under the numeric total columns (5,7,8).
  [colX[5], colX[6], colX[7], colX[8]].forEach((x) => {
    doc.line(x, wordsRowTop, x, wordsRowTop + wordsRowH);
  });
  const words = amountInWords(inv.grandTotal);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(8);
  setInk(INK);
  const wLines = doc.splitTextToSize(words, colX[5] - M - cellPad * 2);
  text(wLines, M + cellPad, wordsRowTop + wordsRowH / 2 - (wLines.length - 1) * 4 + 2.5);
  // Totals under numeric columns.
  const totMidY = wordsRowTop + wordsRowH / 2 + 2.5;
  text(money(inv.totalValue), colX[5] + cols[5].w - cellPad, totMidY, { align: "right" });
  text(money(inv.totalTax), colX[7] + cols[7].w - cellPad, totMidY, { align: "right" });
  text(money(inv.grandTotal), colX[8] + cols[8].w - cellPad, totMidY, { align: "right" });

  const tableBottom = wordsRowTop + wordsRowH;

  // ── Lower band: FBR logo + QR (left) and totals summary box (right) ─────
  const bandTop = tableBottom + 20;

  // FBR Digital Invoicing logo (left) + QR code beside it.
  const logoW = 58;
  const logoH = 46;
  doc.addImage(FBR_INVOICE_LOGO_B64, "PNG", M, bandTop, logoW, logoH);

  let qrDataUrl: string | null = null;
  if (inv.fbrInvoiceNumber) {
    try {
      qrDataUrl = await QRCode.toDataURL(inv.fbrInvoiceNumber, {
        errorCorrectionLevel: "M",
        margin: 1,
        width: 160,
      });
    } catch {
      qrDataUrl = null;
    }
  }
  if (qrDataUrl) {
    doc.addImage(qrDataUrl, "PNG", M + logoW + 16, bandTop - 4, 62, 62);
  }

  // Totals summary box (right).
  const sumW = 300;
  const sumX = RIGHT - sumW;
  const sumRowH = 26;
  const sumLabelW = sumW - 90;
  const summary: Array<{ label: string; value: string | null; bold?: boolean }> = [
    { label: "Total Taxes Exclusive Value", value: money(inv.totalValue) },
    { label: "Total Tax Amount @ 18%", value: money(inv.totalTax) },
    { label: "", value: null }, // blank spacer row (as in reference)
    { label: "Total Taxes Inclusive Value", value: money(inv.grandTotal), bold: true },
  ];
  let syy = bandTop;
  setDraw(BORDER);
  doc.setLineWidth(0.8);
  summary.forEach((r) => {
    doc.rect(sumX, syy, sumW, sumRowH);
    doc.setLineWidth(0.5);
    doc.line(sumX + sumLabelW, syy, sumX + sumLabelW, syy + sumRowH);
    doc.setLineWidth(0.8);
    if (r.label) {
      doc.setFont("helvetica", r.bold ? "bold" : "normal");
      doc.setFontSize(9);
      setInk(INK);
      text(r.label, sumX + 8, syy + sumRowH / 2 + 3);
      if (r.value != null) {
        doc.setFont("helvetica", "bold");
        text(r.value, sumX + sumW - 8, syy + sumRowH / 2 + 3, { align: "right" });
      }
    }
    syy += sumRowH;
  });

  // ── Footer (pinned to the very bottom of the LAST page) ────────────────
  // Ensure we're on the final page before drawing the footer, then anchor it
  // to the page bottom regardless of how tall the content above is.
  const lastPage = doc.getNumberOfPages();
  doc.setPage(lastPage);

  const footY = H - 30;

  // "Computer generated document" note — sits at the very bottom, just above
  // the footer strip separator.
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  setInk(INK);
  text("This is a computer generated document. No signature is required.", M, footY - 22);

  // Footer strip (3 columns) at the very bottom.
  setDraw(BORDER);
  doc.setLineWidth(0.6);
  doc.line(M, footY - 12, RIGHT, footY - 12);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(7.5);
  setInk(MUTED);
  text("Receipt & Confirmation by Recipient on TKT", M, footY);
  text("Page 1 of 1", W / 2, footY, { align: "center" });
  const printStamp = `Print Date: Server Time: ${format(new Date(), "dd-MMM-yyyy / HH:mm:ss")}`;
  text(printStamp, RIGHT, footY, { align: "right" });

  doc.save(`invoice-${inv.id}.pdf`);
}

// ─── Number to words (Pakistani / Indian lakh-crore grouping) ─────────────
// Groups: crore (10^7), lakh (10^5), thousand, hundred. Returns a title-cased
// string ending in "Only" (with "And N Paisa Only" when paisa are present),
// matching the reference invoice's amount-in-words style.
const ONES = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
  "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
  "Eighteen", "Nineteen"];
const TENS = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

function twoDigits(n: number): string {
  if (n < 20) return ONES[n];
  return `${TENS[Math.floor(n / 10)]}${n % 10 ? "-" + ONES[n % 10] : ""}`;
}

function threeDigits(n: number): string {
  const hundreds = Math.floor(n / 100);
  const rest = n % 100;
  let s = "";
  if (hundreds) s += `${ONES[hundreds]} Hundred`;
  if (rest) s += (s ? " " : "") + twoDigits(rest);
  return s;
}

function rupeesToWordsAmount(amount: string | number): string {
  const n = typeof amount === "number" ? amount : parseFloat(amount);
  if (!Number.isFinite(n) || n <= 0) return "Zero Only";
  const paise = Math.round((n % 1) * 100);
  let whole = Math.floor(n);
  const crore = Math.floor(whole / 10000000); whole %= 10000000;
  const lakh = Math.floor(whole / 100000); whole %= 100000;
  const thousand = Math.floor(whole / 1000); whole %= 1000;
  const parts: string[] = [];
  if (crore) parts.push(`${threeDigits(crore)} Crore`);
  if (lakh) parts.push(`${threeDigits(lakh)} Lakh`);
  if (thousand) parts.push(`${threeDigits(thousand)} Thousand`);
  if (whole) parts.push(threeDigits(whole));
  const ru = parts.length ? parts.join(" ") : "Zero";
  if (paise) return `${ru} And ${twoDigits(paise)} Paisa Only`;
  return `${ru} Only`;
}

function amountInWords(amount: string | number): string {
  return rupeesToWordsAmount(amount);
}
