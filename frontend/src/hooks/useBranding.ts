import { useState, useEffect } from 'react';
import axios from 'axios';

/**
 * useBranding Hook
 * Fetches and manages tenant branding configuration
 */

export interface BrandingConfig {
  id: number;
  tenant_id: number;
  company_name: string;
  company_short_name?: string;
  logo_url?: string;
  favicon_url?: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  text_color: string;
  background_color: string;
  navbar_background: string;
  navbar_text_color: string;
  sidebar_background: string;
  sidebar_text_color: string;
  custom_css?: string;
  status: string;
}

export interface BrandingPackage {
  config: BrandingConfig;
  presets: Array<{
    id: number;
    preset_name: string;
    preset_key: string;
    primary_color: string;
    secondary_color: string;
    accent_color: string;
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
  updateBranding: (config: Partial<BrandingConfig>) => Promise<void>;
  applyTheme: (presetKey: string) => Promise<void>;
  uploadLogo: (file: File) => Promise<void>;
  refreshBranding: () => Promise<void>;
}

export const useBranding = (): UseBrandingReturn => {
  const [branding, setBranding] = useState<BrandingPackage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch branding package on component mount
  useEffect(() => {
    fetchBranding();
  }, []);

  // Apply CSS variables to document
  useEffect(() => {
    if (branding?.css) {
      const styleId = 'branding-css';
      let styleElement = document.getElementById(styleId) as HTMLStyleElement;

      if (!styleElement) {
        styleElement = document.createElement('style');
        styleElement.id = styleId;
        document.head.appendChild(styleElement);
      }

      styleElement.textContent = branding.css;
    }
  }, [branding]);

  const fetchBranding = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await axios.get('/api/v1/branding/package');
      setBranding(response.data);

      // Update favicon if provided
      if (response.data.config.favicon_url) {
        updateFavicon(response.data.config.favicon_url);
      }

      // Update page title
      if (response.data.config.company_name) {
        document.title = response.data.config.company_name;
      }
    } catch (err) {
      console.error('Error fetching branding:', err);
      setError('Failed to load branding configuration');
    } finally {
      setLoading(false);
    }
  };

  const updateBranding = async (config: Partial<BrandingConfig>) => {
    try {
      setLoading(true);
      await axios.put('/api/v1/branding/config', config);
      await fetchBranding();
    } catch (err) {
      console.error('Error updating branding:', err);
      setError('Failed to update branding');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const applyTheme = async (presetKey: string) => {
    try {
      setLoading(true);
      await axios.post(`/api/v1/branding/themes/apply/${presetKey}`);
      await fetchBranding();
    } catch (err) {
      console.error('Error applying theme:', err);
      setError('Failed to apply theme');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const uploadLogo = async (file: File) => {
    try {
      setLoading(true);
      const formData = new FormData();
      formData.append('logo', file);
      formData.append('logoType', 'primary');

      await axios.post('/api/v1/branding/logo', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      await fetchBranding();
    } catch (err) {
      console.error('Error uploading logo:', err);
      setError('Failed to upload logo');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const updateFavicon = (url: string) => {
    let link = document.querySelector("link[rel*='icon']") as HTMLLinkElement;
    if (!link) {
      link = document.createElement('link');
      link.rel = 'icon';
      document.head.appendChild(link);
    }
    link.href = url;
  };

  return {
    branding,
    loading,
    error,
    updateBranding,
    applyTheme,
    uploadLogo,
    refreshBranding: fetchBranding,
  };
};

/**
 * Helper hook to get branding colors
 */
export const useBrandingColors = () => {
  const { branding } = useBranding();

  return branding?.colors || {
    primary: '#1F2937',
    secondary: '#3B82F6',
    accent: '#F59E0B',
    text: '#111827',
    background: '#FFFFFF',
    navbar: '#1F2937',
    sidebar: '#F9FAFB',
  };
};

/**
 * Helper to apply branding colors to CSS
 */
export const getBrandingColorMap = (branding: BrandingPackage | null) => {
  if (!branding) {
    return {};
  }

  return {
    '--color-primary': branding.colors.primary,
    '--color-secondary': branding.colors.secondary,
    '--color-accent': branding.colors.accent,
    '--color-text': branding.colors.text,
    '--color-background': branding.colors.background,
    '--color-navbar': branding.colors.navbar,
    '--color-sidebar': branding.colors.sidebar,
  } as React.CSSProperties;
};
