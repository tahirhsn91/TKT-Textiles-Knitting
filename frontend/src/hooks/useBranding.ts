import { useState, useEffect, useCallback } from "react";
import { customFetch, type ErrorType } from "@/vendor/api-client-react/custom-fetch";
import { buildThemeOverrides, type BrandColors } from "@/lib/branding-theme";

/**
 * useBranding Hook (issue #219 1.2 white-labeling)
 * Fetches and manages the ACTIVE tenant's branding configuration.
 * Uses customFetch so the bearer token + X-Tenant-Id header are attached
 * (the backend branding endpoints are tenant-scoped).
 */

export interface BrandingConfig {
  id: number;
  tenant_id: number;
  company_name: string;
  company_short_name?: string;
  logo_url?: string;
  favicon_url?: string;
  logo_filename?: string;
  logo_storage_path?: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  text_color: string;
  background_color: string;
  navbar_background: string;
  navbar_text_color: string;
  sidebar_background: string;
  sidebar_text_color: string;
  font_family?: string;
  font_size_base?: number;
  border_radius?: number;
  button_style?: string;
}

export interface BrandingPackage {
  config: BrandingConfig;
  presets: Array<{
    id: number;
    preset_name: string;
    preset_key: string;
    description?: string | null;
    primary_color: string | null;
    secondary_color: string | null;
    accent_color: string | null;
    background_color?: string | null;
    sidebar_color?: string | null;
    navbar_color?: string | null;
    is_default: boolean;
  }>;
  css: string;
  colors: {
    primary: string;
    secondary: string;
    accent: string;
    text: string;
    background: string;
    navbar: string;
    sidebar: string;
  };
}

interface UseBrandingReturn {
  branding: BrandingPackage | null;
  loading: boolean;
  error: string | null;
  /** Fetch the active tenant's branding package. */
  refreshBranding: () => Promise<void>;
  /** Update branding config fields (partial). */
  updateBranding: (config: Partial<BrandingConfig>) => Promise<void>;
  /** Apply a theme preset by key. */
  applyTheme: (presetKey: string) => Promise<void>;
  /** Upload a logo image. */
  uploadLogo: (file: File) => Promise<void>;
}

export const DEFAULT_COLORS = {
  primary: "#1F2937",
  secondary: "#3B82F6",
  accent: "#F59E0B",
  text: "#111827",
  background: "#FFFFFF",
  navbar: "#1F2937",
  sidebar: "#F9FAFB",
};

function updateFavicon(url: string | null | undefined) {
  if (!url) return;
  let link = document.querySelector("link[rel*='icon']") as HTMLLinkElement | null;
  if (!link) {
    link = document.createElement("link");
    link.rel = "icon";
    document.head.appendChild(link);
  }
  link.href = url;
}

/** Apply the branding CSS-variable string to <style id="branding-css">. */
function applyBrandingCss(css: string | undefined, colors?: BrandColors | null) {
  const styleId = "branding-css";
  let styleElement = document.getElementById(styleId) as HTMLStyleElement | null;
  if (!styleElement) {
    styleElement = document.createElement("style");
    styleElement.id = styleId;
    document.head.appendChild(styleElement);
  }
  const themeOverrides = colors ? buildThemeOverrides(colors) : "";
  // The backend `:root{--brand-*}` first, then our derived real-token
  // overrides last so they win for the app's Tailwind/UI-kit tokens.
  styleElement.textContent = `${css ?? ""}\n${themeOverrides}`;
}

export const useBranding = (enabled = true): UseBrandingReturn => {
  const [branding, setBranding] = useState<BrandingPackage | null>(null);
  const [loading, setLoading] = useState(enabled);
  const [error, setError] = useState<string | null>(null);

  const refreshBranding = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await customFetch<BrandingPackage>("/api/branding/package", {
        method: "GET",
      });
      setBranding(data);
      applyBrandingCss(data.css, {
        primary: data.config?.primary_color,
        secondary: data.config?.secondary_color,
        accent: data.config?.accent_color,
        text: data.config?.text_color,
        background: data.config?.background_color,
        navbar: data.config?.navbar_background,
        navbarText: data.config?.navbar_text_color,
        sidebar: data.config?.sidebar_background,
        sidebarText: data.config?.sidebar_text_color,
        fontFamily: data.config?.font_family,
        borderRadius: data.config?.border_radius,
      });
      if (data.config?.company_name) document.title = data.config.company_name;
      updateFavicon(data.config?.favicon_url);
    } catch (err) {
      const msg = (err as ErrorType<{ error?: string }>)?.data?.error ?? "Failed to load branding configuration";
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (enabled) void refreshBranding();
  }, [enabled, refreshBranding]);

  const updateBranding = async (config: Partial<BrandingConfig>) => {
    try {
      setLoading(true);
      await customFetch("/api/branding/config", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(config),
      });
      await refreshBranding();
    } catch (err) {
      setError("Failed to update branding");
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const applyTheme = async (presetKey: string) => {
    try {
      setLoading(true);
      await customFetch(`/api/branding/themes/apply/${presetKey}`, {
        method: "POST",
      });
      await refreshBranding();
    } catch (err) {
      setError("Failed to apply theme");
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const uploadLogo = async (file: File) => {
    try {
      setLoading(true);
      const formData = new FormData();
      formData.append("logo", file);
      await customFetch("/api/branding/logo", {
        method: "POST",
        body: formData,
      });
      await refreshBranding();
    } catch (err) {
      setError("Failed to upload logo");
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    branding,
    loading,
    error,
    refreshBranding,
    updateBranding,
    applyTheme,
    uploadLogo,
  };
};

/** Helper to read branding colors (falls back to defaults). */
export const useBrandingColors = () => {
  const { branding } = useBranding();
  return branding?.colors ?? DEFAULT_COLORS;
};
