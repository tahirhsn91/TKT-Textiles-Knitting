import { useEffect, useState } from "react";
import { useConfiguration, type TenantSettings, type FeatureFlag } from "@/hooks/useConfiguration";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Spinner } from "@/components/ui/spinner";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

/**
 * CompanySettingsTab — issue #219 1.3 Configuration & Settings.
 * Shows the active tenant's company settings (editable) and feature flags
 * (toggleable). Uses the tenant-aware useConfiguration hook.
 */

function maskField(v: string | null | undefined) {
  return v ?? "";
}

export function CompanySettingsTab() {
  const { settings, features, loading, updateSettings, toggleFeature } = useConfiguration();
  const [form, setForm] = useState<Partial<TenantSettings>>({});
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  // Hydrate the form once settings load.
  useEffect(() => {
    if (settings) {
      const f: Partial<TenantSettings> = {};
      (Object.keys(settings) as (keyof TenantSettings)[]).forEach((k) => {
        (f as Record<string, unknown>)[k] = settings[k];
      });
      setForm(f);
    }
  }, [settings]);

  if (loading && !settings) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-24 w-full" />
      </div>
    );
  }

  const set = (k: keyof TenantSettings, v: unknown) => setForm((p) => ({ ...p, [k]: v }));

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      await updateSettings(form);
      setMessage("Settings saved");
    } catch {
      setMessage("Failed to save settings");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Company settings */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Company Settings</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={save} className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Registration No.</Label>
              <Input value={maskField(form.company_registration_number)} onChange={(e) => set("company_registration_number", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Tax ID</Label>
              <Input value={maskField(form.company_tax_id)} onChange={(e) => set("company_tax_id", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Phone</Label>
              <Input value={maskField(form.company_phone)} onChange={(e) => set("company_phone", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Email</Label>
              <Input value={maskField(form.company_email)} onChange={(e) => set("company_email", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Address</Label>
              <Input value={maskField(form.company_address)} onChange={(e) => set("company_address", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>City</Label>
              <Input value={maskField(form.company_city)} onChange={(e) => set("company_city", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Country</Label>
              <Input value={maskField(form.company_country)} onChange={(e) => set("company_country", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Timezone</Label>
              <Select value={maskField(form.timezone)} onValueChange={(v) => set("timezone", v)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="Asia/Karachi">Asia/Karachi</SelectItem>
                  <SelectItem value="Asia/Dubai">Asia/Dubai</SelectItem>
                  <SelectItem value="UTC">UTC</SelectItem>
                  <SelectItem value="Europe/London">Europe/London</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Currency</Label>
              <Select value={maskField(form.currency)} onValueChange={(v) => set("currency", v)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="PKR">PKR</SelectItem>
                  <SelectItem value="USD">USD</SelectItem>
                  <SelectItem value="EUR">EUR</SelectItem>
                  <SelectItem value="AED">AED</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Default Tax Rate (%)</Label>
              <Input
                type="number"
                step="0.01"
                value={maskField(form.default_tax_rate != null ? String(form.default_tax_rate) : "")}
                onChange={(e) => set("default_tax_rate", Number(e.target.value))}
              />
            </div>
            <div className="flex items-end">
              <Button type="submit" disabled={saving}>{saving ? "Saving…" : "Save Settings"}</Button>
            </div>
            {message && <p className="text-sm text-muted-foreground sm:col-span-2">{message}</p>}
          </form>
        </CardContent>
      </Card>

      {/* Feature flags */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Feature Flags</CardTitle>
        </CardHeader>
        <CardContent>
          {features.length === 0 ? (
            <p className="text-sm text-muted-foreground">No feature flags configured.</p>
          ) : (
            <div className="space-y-3">
              {features.map((f: FeatureFlag) => (
                <div key={f.feature_key} className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <p className="text-sm font-medium">{f.feature_name}</p>
                    <p className="font-mono text-xs text-muted-foreground">{f.feature_key}</p>
                  </div>
                  <Switch
                    checked={!!f.is_enabled}
                    onCheckedChange={(on) => toggleFeature(f.feature_key, on)}
                  />
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
