/**
 * Number to words (Pakistani / Indian lakh-crore grouping).
 *
 * Extracted from invoice-pdf.ts (which carries the heavy jsPDF + qrcode
 * dependencies) so the invoicing screen can render the amount-in-words row
 * without pulling those libraries into the page bundle. The PDF builder
 * imports this module for the same formatting.
 */

// Groups: crore (10^7), lakh (10^5), thousand, hundred. Returns a title-cased
// string ending in "Only", matching the reference invoice's amount-in-words
// style. The amount is rounded to whole rupees before conversion (no paisa).
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
  // Round the amount to zero decimal places (whole rupees) before converting
  // to words, so fractional amounts always produce a clean whole-rupee phrase.
  const whole = Math.round(n);
  let w = whole;
  const crore = Math.floor(w / 10000000); w %= 10000000;
  const lakh = Math.floor(w / 100000); w %= 100000;
  const thousand = Math.floor(w / 1000); w %= 1000;
  const parts: string[] = [];
  if (crore) parts.push(`${threeDigits(crore)} Crore`);
  if (lakh) parts.push(`${threeDigits(lakh)} Lakh`);
  if (thousand) parts.push(`${threeDigits(thousand)} Thousand`);
  if (w) parts.push(threeDigits(w));
  const ru = parts.length ? parts.join(" ") : "Zero";
  return `${ru} Only`;
}

export function amountInWords(amount: string | number): string {
  return rupeesToWordsAmount(amount);
}
