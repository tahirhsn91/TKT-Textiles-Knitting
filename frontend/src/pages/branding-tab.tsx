import { useEffect, useState } from "react";
import { Palette, Save, Check } from "lucide-react";
import { useBranding, type BrandingConfig } from "@/hooks/useBranding";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const FONT_OPTIONS = ["Inter", "Poppins", "Roboto", "Montserrat", "Open Sans", "Lato", "Georgia", "serif", "system-ui"];
const BUTTON_STYLE_OPTIONS = ["rounded", "square", "pill"];

/** Branding tab — set the tenant's company name, logo, and theme (issue #219 1.2). */
export function BrandingTab() {
  const { branding, loading, error, updateBranding, applyTheme, refreshBranding } = useBranding();
  const [form, setForm] = useState<Partial<BrandingConfig>>({});
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (branding?.config) setForm(branding.config);
    else if (!loading) void refreshBranding().catch(() => undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [branding?.config]);

  if (loading && !branding) {
    return <div className="space-y-3"><Skeleton className="h-24 w-full" /><Skeleton className="h-40 w-full" /></div>;
  }

  const cfg = branding?.config;

  const set = (field: keyof BrandingConfig, value: string | number | null) =>
    setForm((f) => ({ ...f, [field]: value }));

  const save = async () => {
    setSaving(true);
    try {
      await updateBranding(form);
    } catch {
      /* shown via error */
    } finally {
      setSaving(false);
    }
  };

  const applyPreset = async (key: string) => {
    await applyTheme(key).catch(() => undefined);
  };

  const colorFields: Array<{ key: keyof BrandingConfig; label: string }> = [
    { key: "primary_color", label: "Primary" },
    { key: "secondary_color", label: "Secondary" },
    { key: "accent_color", label: "Accent" },
    { key: "text_color", label: "Text" },
    { key: "background_color", label: "Background" },
    { key: "navbar_background", label: "Navbar / Sidebar" },
    { key: "sidebar_background", label: "Sidebar" },
    { key: "navbar_text_color", label: "Navbar text" },
  ];
  // Left-nav (sidebar) foreground text — grouped with the chrome colors.
  const chromeTextFields: Array<{ key: keyof BrandingConfig; label: string }> = [
    { key: "sidebar_text_color", label: "Sidebar text" },
  ];
  const allChromeFields = [...colorFields, ...chromeTextFields];

  return (
    <div className="space-y-6">
      {/* Company identity */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <Palette className="h-4 w-4" /> Company Identity
          </CardTitle>
          <CardDescription>Name, short name, logo and favicon shown across the app.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Company name</Label>
              <Input value={form.company_name ?? ""} onChange={(e) => set("company_name", e.target.value)} placeholder="TKT Textiles" />
            </div>
            <div className="space-y-1.5">
              <Label>Short name</Label>
              <Input value={form.company_short_name ?? ""} onChange={(e) => set("company_short_name", e.target.value)} placeholder="TKT" />
            </div>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Logo URL</Label>
              <Input value={form.logo_url ?? ""} onChange={(e) => set("logo_url", e.target.value)} placeholder="https://…/logo.png" />
            </div>
            <div className="space-y-1.5">
              <Label>Favicon URL</Label>
              <Input value={form.favicon_url ?? ""} onChange={(e) => set("favicon_url", e.target.value)} placeholder="https://…/favicon.ico" />
            </div>
          </div>
          {form.logo_url && (
            <div className="flex items-center gap-3 rounded-md border p-3">
              <img src={form.logo_url} alt="logo preview" className="h-10 w-10 rounded object-contain" onError={(e) => ((e.target as HTMLImageElement).style.opacity = "0.2")} onLoad={(e) => ((e.target as HTMLImageElement).style.opacity = "1")} />
              <span className="text-xs text-muted-foreground">Logo preview.</span>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Theme presets */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Theme Presets</CardTitle>
          <CardDescription>Apply a ready-made color theme.</CardDescription>
        </CardHeader>
        <CardContent>
          {!cfg || (branding?.presets ?? []).length === 0 ? (
            <p className="text-sm text-muted-foreground">No theme presets configured yet.</p>
          ) : (
            <div className="flex flex-wrap gap-3">
              {branding!.presets.map((p) => (
                <button
                  key={p.preset_key}
                  type="button"
                  onClick={() => applyPreset(p.preset_key)}
                  className="group flex flex-col items-start gap-2 rounded-md border p-3 text-left hover:border-primary"
                >
                  <span className="flex h-6 w-full gap-1 overflow-hidden rounded">
                    <span className="flex-1" style={{ background: p.primary_color }} />
                    <span className="flex-1" style={{ background: p.secondary_color }} />
                    <span className="flex-1" style={{ background: p.accent_color }} />
                  </span>
                  <span className="flex items-center gap-1 text-xs font-medium">
                    {p.preset_name}
                    {p.is_default && <Check className="h-3 w-3 text-green-600" />}
                  </span>
                </button>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Custom colors */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Theme Colors</CardTitle>
          <CardDescription>Fine-tune the color palette to your brand.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
            {allChromeFields.map(({ key, label }) => (
              <div key={key} className="space-y-1.5">
                <Label className="capitalize">{label}</Label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={form[key] || "#000000"}
                    onChange={(e) => set(key, e.target.value)}
                    className="h-9 w-10 cursor-pointer rounded border"
                  />
                  <Input value={form[key] ?? ""} onChange={(e) => set(key, e.target.value)} className="font-mono text-xs" />
                </div>
              </div>
            ))}
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Font family</Label>
              <Select value={form.font_family ?? "Inter"} onValueChange={(v) => set("font_family", v)}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {FONT_OPTIONS.map((f) => <SelectItem key={f} value={f}>{f}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Button style</Label>
              <Select value={form.button_style ?? "rounded"} onValueChange={(v) => set("button_style", v)}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {BUTTON_STYLE_OPTIONS.map((b) => <SelectItem key={b} value={b} className="capitalize">{b}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {error && <p className="text-xs text-destructive">{error}</p>}

      <div className="flex justify-end">
        <Button onClick={save} disabled={saving} className="gap-1.5">
          <Save className="h-4 w-4" /> {saving ? "Saving…" : "Save branding"}
        </Button>
      </div>
    </div>
  );
}
