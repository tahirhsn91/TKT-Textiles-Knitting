import { useBranding } from "@/hooks/useBranding";
import { StitchMark } from "@/components/wordmark";

/**
 * BrandedWordmark — issue #219 1.2 white-labeling.
 * Renders the active tenant's company name (and logo when set) instead of the
 * hardcoded "TKT Textiles" lockup. Falls back to the stitch mark when
 * collapsed.
 */
export function BrandedWordmark({ collapsed = false }: { collapsed?: boolean }) {
  const { branding } = useBranding();
  const stichColor = branding?.config?.primary_color;

  if (collapsed) {
    const color = stichColor ?? "var(--brand-accent, inherit)";
    return (
      <span style={{ color }}>
        <StitchMark className="shrink-0 h-5 w-5" />
      </span>
    );
  }

  const name = branding?.config?.company_name || "Textiles ERP";
  const logoUrl = branding?.config?.logo_url;

  if (logoUrl) {
    return (
      <img
        src={logoUrl}
        alt={name}
        className="h-9 w-auto max-w-[13rem] object-contain"
      />
    );
  }

  // No logo: render the company name (falling back to the stitch mark + name).
  return (
    <span
      className="text-lg font-semibold tracking-tight text-sidebar-foreground"
      style={{ color: stichColor ?? undefined }}
    >
      {name}
    </span>
  );
}

/** Sidebar/organization label that shows the tenant company name. */
export function BrandedOrgLabel({ className }: { className?: string }) {
  const { branding } = useBranding();
  const name = branding?.config?.company_name || "TKT Textiles";
  const short = branding?.config?.company_short_name || "";
  return (
    <span className={className}>
      {short || name}
    </span>
  );
}
