/**
 * branding-theme.ts — bridge the tenant's Branding screen colors (hex) to the
 * app's real theme tokens (HSL triplets consumed by Tailwind + the UI kit).
 *
 * Problem: the Branding screen writes `--brand-*` hex variables that almost
 * nothing consumes — the app's actual UI reads `--primary`, `--accent`,
 * `--muted`, `--background`, `--sidebar-*`, … as HSL triplets. So theme colors
 * chosen in Branding never reached the rest of the application.
 *
 * This module derives HSL values + WCAG-safe foregrounds from the brand hex
 * colours and builds `:root` overrides for those tokens, so the whole app
 * re-themes from one source of truth (the Branding config).
 */

export interface BrandColors {
  primary?: string | null;
  secondary?: string | null;
  accent?: string | null;
  text?: string | null;
  background?: string | null;
  navbar?: string | null;
  navbarText?: string | null;
  sidebar?: string | null;
  sidebarText?: string | null;
  fontFamily?: string | null;
  borderRadius?: number | null;
}

/** Convert a #rrggbb / #rgb hex to an HSL triplet string "H S% L%". */
export function hexToHsl(hex: string | null | undefined): string {
  let h = (hex ?? "#000000").replace("#", "");
  if (h.length === 3) h = h.split("").map((c) => c + c).join("");
  const num = parseInt(h, 16);
  if (Number.isNaN(num) || h.length !== 6) return "0 0% 0%";
  const r = ((num >> 16) & 255) / 255;
  const g = ((num >> 8) & 255) / 255;
  const b = (num & 255) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  let s = 0;
  let hue = 0;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: hue = (g - b) / d + (g < b ? 6 : 0); break;
      case g: hue = (b - r) / d + 2; break;
      default: hue = (r - g) / d + 4;
    }
    hue *= 60;
  }
  return `${Math.round(hue)} ${Math.round(s * 100)}% ${Math.round(l * 100)}%`;
}

/** Relative luminance (WCAG) of a hex colour, 0..1. */
function luminance(hex: string | null | undefined): number {
  let h = (hex ?? "#000000").replace("#", "");
  if (h.length === 3) h = h.split("").map((c) => c + c).join("");
  const num = parseInt(h, 16);
  if (Number.isNaN(num) || h.length !== 6) return 0;
  const chan = (v: number) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  };
  const r = chan((num >> 16) & 255);
  const g = chan((num >> 8) & 255);
  const b = chan(num & 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/**
 * Pick a readable foreground for a given background: near-black on light
 * surfaces, near-white on dark ones (≥ ~4.5:1 contrast).
 */
export function readableHsl(backgroundHex: string | null | undefined): string {
  return luminance(backgroundHex) > 0.35
    ? "89 10% 12%"   // near-black (Graphite)
    : "0 0% 100%";   // near-white
}

/** A small delta applied to lighten a colour for `-border` / card surfaces. */
function shiftLightness(hsl: string, delta: number): string {
  const m = hsl.match(/(-?\d+)\s+(\d+)%\s+(\d+)%/);
  if (!m) return hsl;
  const h = m[1];
  const s = m[2];
  let l = Math.round(parseFloat(m[3]) + delta);
  l = Math.max(0, Math.min(100, l));
  return `${h} ${s}% ${l}%`;
}

/**
 * Build the `:root { … }` overrides that push Branding colours into the real
 * theme tokens. Only tokens whose brand value is provided are overridden.
 *
 * NOTE: each override is emitted with `!important` because the app's bundle
 * (Vite/Tailwind v4) appends its own unlayered `:root { --sidebar: … }` etc.
 * AFTER runtime-injected styles, so a plain unlayered override loses by
 * source order. `!important` on the custom property makes `var(--…)` resolve
 * the Branding value app-wide — the explicit requirement (theme colors must
 * apply to the whole application, including the left navbar/sidebar).
 */
export function buildThemeOverrides(colors: BrandColors): string {
  const decls: string[] = [];

  const set = (token: string, value: string) => decls.push(`  ${token}: ${value} !important;`);
  const hsl = (hex?: string | null) => (hex ? hexToHsl(hex) : null);

  const primary = hsl(colors.primary);
  const secondary = hsl(colors.secondary);
  const accent = hsl(colors.accent);
  const text = hsl(colors.text);
  const background = hsl(colors.background);
  const sidebar = hsl(colors.sidebar);
  const sidebarText = hsl(colors.sidebarText);
  const navbar = hsl(colors.navbar);
  const navbarText = hsl(colors.navbarText);

  if (primary) {
    set("--primary", primary);
    set("--ring", primary);
    set("--sidebar-primary", primary);
    set("--primary-foreground", readableHsl(colors.primary));
    set("--sidebar-primary-foreground", readableHsl(colors.primary));
  }
  if (secondary) {
    set("--secondary", secondary);
    set("--secondary-foreground", readableHsl(colors.secondary));
  }
  if (accent) {
    set("--accent", accent);
    set("--accent-foreground", readableHsl(colors.accent));
  }
  if (text) {
    set("--foreground", text);
    set("--card-foreground", text);
    set("--popover-foreground", text);
  }
  if (background) {
    set("--background", background);
    set("--card", shiftLightness(hexToHsl(colors.background!), 3));
    set("--popover", shiftLightness(hexToHsl(colors.background!), 3));
  }
  if (sidebar) {
    set("--sidebar", sidebar);
    const fg = sidebarText ?? readableHsl(colors.sidebar);
    set("--sidebar-foreground", fg);
    // Coherent hover/active + border surfaces derived from the sidebar tone so
    // the chrome stays readable on a light OR dark sidebar (ui-ux-pro-max:
    // cover component states, not just the base surface).
    const accentSurface = shiftLightness(sidebar, readableHsl(colors.sidebar) === "0 0% 100%" ? 6 : -6);
    set("--sidebar-accent", accentSurface);
    set("--sidebar-accent-foreground", fg);
    set("--sidebar-border", shiftLightness(sidebar, 4));
    set("--sidebar-ring", primary ?? sidebar);
  }
  if (navbar) {
    // Navbar reuses the sidebar surface tokens in this app.
    set("--navbar", navbar);
    set("--navbar-foreground", navbarText ?? readableHsl(colors.navbar));
  }
  if (colors.fontFamily && colors.fontFamily !== ",") {
    set("--app-font-sans", colors.fontFamily);
    set("--brand-font", colors.fontFamily);
  }

  // When no explicit sidebar colour is given, a dark primary should still
  // drive a coherent dark chrome (the sidebar block above already handles the
  // explicit-sidebar case).
  const chromeDark = !colors.sidebar && colors.primary ? readableHsl(colors.primary) === "0 0% 100%" : false;
  if (chromeDark && primary) {
    decls.push(`  --sidebar: ${primary} !important;`);
    decls.push(`  --sidebar-foreground: ${readableHsl(colors.primary)} !important;`);
  }

  return `:root {\n${decls.join("\n")}\n}`;
}
