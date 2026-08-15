import { cn } from "@/lib/utils";

/**
 * The house mark: a single knit stitch. The face of jersey fabric is nothing
 * but this V, repeated a few hundred thousand times per metre.
 *
 * Used as the collapsed-sidebar glyph (a wide lockup has no room in the
 * w-16 rail) and as the favicon-adjacent mark.
 */
export function StitchMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 40 40" aria-hidden="true" className={cn("h-5 w-5 shrink-0", className)}>
      <path
        d="M7 11 Q 14 14 20 27 Q 26 14 33 11"
        fill="none"
        stroke="currentColor"
        strokeWidth="5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

/**
 * Brand wordmark — single source of truth used by the sidebar header (desktop)
 * and mobile drawer header.
 *
 * Expanded: renders the full TKT lockup. The sidebar surface is dark graphite,
 * so we use the light-on-dark variant (logo-dark.png) — charcoal letterforms
 * would disappear on it. Collapsed: falls back to the stitch mark, since the
 * w-16 rail has no room for the wide lockup.
 */
export function Wordmark({ collapsed = false }: { collapsed?: boolean }) {
  if (collapsed) {
    return <StitchMark className="text-signal" />;
  }
  return (
    <img
      src="/logo-dark.png"
      alt="TKT Textiles"
      className="h-9 w-auto max-w-[13rem] object-contain"
    />
  );
}
