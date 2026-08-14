import { cn } from "@/lib/utils";

/**
 * The house mark: a single knit stitch. The face of jersey fabric is nothing
 * but this V, repeated a few hundred thousand times per metre.
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

/** Brand wordmark — single source of truth used by the sidebar and top bar. */
export function Wordmark({ collapsed = false }: { collapsed?: boolean }) {
  return (
    <span className="flex items-center gap-2.5">
      <StitchMark className="text-signal" />
      {!collapsed && (
        <span className="flex flex-col leading-none">
          <span className="text-[0.9375rem] font-semibold tracking-[0.12em] text-sidebar-accent-foreground">
            TKT
          </span>
          <span className="mt-1 text-[0.625rem] font-medium uppercase tracking-[0.16em] text-sidebar-foreground/55">
            Textiles
          </span>
        </span>
      )}
    </span>
  );
}
