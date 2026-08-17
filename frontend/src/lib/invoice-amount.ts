/**
 * Number to words (Pakistani / Indian lakh-crore grouping).
 *
 * Extracted from invoice-pdf.ts (which carries the heavy jsPDF + qrcode
 * dependencies) so the invoicing screen can render the amount-in-words row
 * without pulling those libraries into the page bundle. The PDF builder
 * imports this module for the same formatting.
 */

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

export function amountInWords(amount: string | number): string {
  return rupeesToWordsAmount(amount);
}
