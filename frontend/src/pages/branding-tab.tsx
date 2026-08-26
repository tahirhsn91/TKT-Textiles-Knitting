import { useEffect, useState } from "react";
import { Palette, Save, Check, Upload } from "lucide-react";
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

/** Normalize a #RGB / #RRGGBB hex string, or null if invalid. */
function normalizeHex(value: string): string | null {
  let v = value.trim();
  if (!v) return null;
  if (v[0] !== "#") v = "#" + v;
  if (!/^#[0-9a-fA-F]{3}$/.test(v) && !/^#[0-9a-fA-F]{6}$/.test(v)) return null;
  if (v.length === 4) {
    // Expand #RGB -> #RRGGBB
    v = "#" + v.slice(1).split("")
      .map((c) => c + c)
      .join("");
  }
  return v.toUpperCase();
}

const HEX_RE = /^#[0-9a-fA-F]{0,6}$/;

/**
 * ColorPickerField — a polished inline colour control (ui-ux-pro-max): a
 * visible swatch that opens the native colour picker, plus a validated hex
 * text field so the user can either pick OR type a colour. Invalid/partial
 * input is allowed while editing (kept in the field) but flagged; the stored
 * value only updates on a valid hex.
 */
function ColorPickerField({
  value,
  onChange,
  id,
}: {
  value?: string | null;
  onChange: (v: string) => void;
  id?: string;
}) {
  const [draft, setDraft] = useState<string>(value ?? "");
  const [focused, setFocused] = useState(false);

  // Keep the draft in sync when the saved value changes externally (e.g. a
  // preset was applied).
  useEffect(() => {
    if (!focused && value) setDraft(value);
  }, [value, focused]);

  const valid = draft === "" || normalizeHex(draft) !== null;
  const normalized = normalizeHex(draft);

  const handlePicker = (hex: string) => {
    setDraft(hex);
    const norm = normalizeHex(hex);
    if (norm) onChange(norm);
  };

  return (
    <div className="flex items-center gap-2">
      <label
        title="Pick a color"
        className="relative h-9 w-9 shrink-0 cursor-pointer overflow-hidden rounded-md border shadow-sm transition-shadow focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-1"
        style={{
          background: "conic-gradient(from 0deg, #f22, #fc8d03, #d4e60b, #0c9, #08f, #90c, #f22)",
        }}
      >
        {/* Inner swatch shows the current colour; a gap of the rainbow ring
            reads as a picker affordance rather than a plain solid swatch. */}
        <span
          className="absolute inset-[3px] rounded-[4px]"
          style={{ background: normalized ?? "#ffffff" }}
        />
        <input
          id={id}
          type="color"
          value={normalized ?? "#000000"}
          onChange={(e) => handlePicker(e.target.value)}
          className="absolute inset-0 cursor-pointer opacity-0"
          aria-label="Pick a color"
        />
      </label>
      <Input
        value={draft}
        onChange={(e) => {
          const next = e.target.value;
          // Allow typing hex chars only (keep it forgiving while editing).
          if (HEX_RE.test(next) || next === "") setDraft(next);
        }}
        onBlur={() => {
          setFocused(false);
          const norm = normalizeHex(draft);
          if (norm) {
            onChange(norm);
            setDraft(norm);
          } else if (draft !== "" && value) {
            setDraft(value); // revert invalid to last good value
          }
        }}
        onFocus={() => setFocused(true)}
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            setFocused(false);
            const norm = normalizeHex(draft);
            if (norm) { onChange(norm); setDraft(norm); }
            (e.target as HTMLInputElement).blur();
          }
        }}
        className={`font-mono text-xs ${valid ? "" : "border-destructive focus-visible:ring-destructive"}`}
        aria-invalid={!valid}
        placeholder={normalized ?? "#RRGGBB"}
        maxLength={7}
      />
    </div>
  );
}

/** Branding tab — set the tenant's company name, logo, and theme (issue #219 1.2). */
export function BrandingTab() {
  const { branding, loading, error, updateBranding, applyTheme, refreshBranding, uploadLogo, uploadFavicon } = useBranding();
  const [form, setForm] = useState<Partial<BrandingConfig>>({});
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState<"logo" | "favicon" | null>(null);

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

  const uploadAsset = async (kind: "logo" | "favicon", file: File) => {
    setUploading(kind);
    try {
      if (kind === "logo") await uploadLogo(file);
      else await uploadFavicon(file);
    } catch {
      /* shown via error */
    } finally {
      setUploading(null);
    }
  };

  const onPickLogo = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (f) void uploadAsset("logo", f);
    e.target.value = "";
  };

  const onPickFavicon = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (f) void uploadAsset("favicon", f);
    e.target.value = "";
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
    { key: "navbar_background", label: "Navbar" },
    { key: "sidebar_background", label: "Sidebar" },
  ];

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
              <Label>Logo</Label>
              <div className="flex items-center gap-2">
                <Input value={form.logo_url ?? ""} onChange={(e) => set("logo_url", e.target.value)} placeholder="https://…/logo.png" className="flex-1" />
                <Button type="button" variant="outline" size="sm" disabled={uploading !== null} onClick={() => document.getElementById("branding-logo-input")?.click()} className="gap-1 whitespace-nowrap">
                  <Upload className="h-3.5 w-3.5" /> {uploading === "logo" ? "Uploading…" : "Upload"}
                </Button>
                <input id="branding-logo-input" type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif,image/x-icon" className="hidden" onChange={onPickLogo} />
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Favicon</Label>
              <div className="flex items-center gap-2">
                <Input value={form.favicon_url ?? ""} onChange={(e) => set("favicon_url", e.target.value)} placeholder="https://…/favicon.ico" className="flex-1" />
                <Button type="button" variant="outline" size="sm" disabled={uploading !== null} onClick={() => document.getElementById("branding-favicon-input")?.click()} className="gap-1 whitespace-nowrap">
                  <Upload className="h-3.5 w-3.5" /> {uploading === "favicon" ? "Uploading…" : "Upload"}
                </Button>
                <input id="branding-favicon-input" type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif,image/x-icon" className="hidden" onChange={onPickFavicon} />
              </div>
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
                  className="group flex w-44 flex-col items-start gap-2 rounded-md border p-3 text-left hover:border-primary"
                >
                  <span className="flex h-7 w-full gap-1 overflow-hidden rounded">
                    <span className="flex-1" style={{ background: p.primary_color || "#ccc" }} title="Primary" />
                    <span className="flex-1" style={{ background: p.accent_color || "#ccc" }} title="Accent" />
                    <span className="flex-1" style={{ background: p.background_color || "#fff" }} title="Background" />
                    <span className="flex-1" style={{ background: p.sidebar_color || "#333" }} title="Sidebar" />
                  </span>
                  <span className="flex items-center gap-1 text-xs font-medium">
                    {p.preset_name}
                    {p.is_default && <Check className="h-3 w-3 text-green-600" />}
                  </span>
                  {p.description && <span className="text-[11px] text-muted-foreground">{p.description}</span>}
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
            {colorFields.map(({ key, label }) => (
              <div key={key} className="space-y-1.5">
                <Label className="capitalize">{label}</Label>
                <ColorPickerField
                  value={form[key] as string}
                  onChange={(hex) => set(key, hex)}
                  id={`branding-color-${key}`}
                />
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
