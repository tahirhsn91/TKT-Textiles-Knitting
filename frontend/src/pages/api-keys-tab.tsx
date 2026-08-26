import { useEffect, useState } from "react";
import { KeyRound, Plus, X, ExternalLink, Copy } from "lucide-react";
import { useApiKeys } from "@/hooks/useApiKeys";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";

/**
 * ApiKeysTab — issue #219 2.4 programmatic access. Admins create API keys for
 * the active tenant and revoke them. The raw secret is shown once at creation.
 */
export function ApiKeysTab() {
  const { keys, loading, error, list, create, revoke } = useApiKeys();
  const [label, setLabel] = useState("");
  const [busy, setBusy] = useState(false);
  const [revealed, setRevealed] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    void list().catch(() => undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!label.trim()) return;
    setBusy(true);
    setNotice(null);
    try {
      const created = await create(label.trim());
      setLabel("");
      setRevealed(created.apiKey ?? null);
      setNotice("Copy this secret now — it will not be shown again.");
    } catch {
      setNotice("Failed to create API key");
    } finally {
      setBusy(false);
    }
  };

  const handleRevoke = async (id: number, lbl: string) => {
    if (!window.confirm(`Revoke API key "${lbl}"? Revoked keys stop working immediately.`)) return;
    await revoke(id);
  };

  const copy = async (v: string) => {
    try {
      await navigator.clipboard.writeText(v);
      setNotice("Copied to clipboard.");
    } catch {
      /* clipboard unavailable */
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <KeyRound className="h-4 w-4" /> API Keys
          </CardTitle>
          <CardDescription>
            Create keys for programmatic access to this tenant via{" "}
            <code className="rounded bg-muted px-1">/api/v1</code> (send as{" "}
            <code className="rounded bg-muted px-1">X-API-Key</code>).
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={submit} className="flex flex-wrap items-end gap-3">
            <div className="space-y-1.5">
              <Label>Label</Label>
              <Input
                placeholder="e.g. External integration"
                value={label}
                onChange={(e) => setLabel(e.target.value)}
                className="w-72"
              />
            </div>
            <Button type="submit" disabled={busy || !label.trim()} className="gap-1.5">
              <Plus className="h-4 w-4" /> {busy ? "Creating…" : "Create key"}
            </Button>
          </form>

          {revealed && (
            <div className="mt-4 rounded-md border border-green-500/50 bg-green-500/10 p-3">
              <p className="flex items-center justify-between gap-2 text-sm">
                <span className="font-medium">New API key (shown once)</span>
                <Button variant="outline" size="sm" onClick={() => copy(revealed)} className="gap-1">
                  <Copy className="h-3.5 w-3.5" /> Copy
                </Button>
              </p>
              <code className="mt-1 block break-all rounded bg-background p-2 text-xs">{revealed}</code>
            </div>
          )}
          {notice && <p className="mt-2 text-xs text-muted-foreground">{notice}</p>}
          {error && <p className="mt-2 text-xs text-destructive">{error}</p>}

          <div className="mt-4">
            <a
              href="/api/docs/"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 text-sm text-primary hover:underline"
            >
              <ExternalLink className="h-3.5 w-3.5" /> Open API documentation (Swagger)
            </a>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Active Keys</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-2"><Skeleton className="h-10 w-full" /><Skeleton className="h-10 w-full" /></div>
          ) : keys.length === 0 ? (
            <p className="text-sm text-muted-foreground">No API keys yet.</p>
          ) : (
            <ul className="space-y-2">
              {keys.map((k) => (
                <li key={k.id} className="flex items-center justify-between gap-3 rounded-md border p-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium">{k.label}</p>
                      <Badge variant="secondary" className="font-mono">…{k.keyHint}</Badge>
                    </div>
                    <p className="mt-0.5 text-xs text-muted-foreground">
                      Created {new Date(k.createdAt + (k.createdAt.includes("Z") ? "" : "Z")).toLocaleDateString()}
                      {k.lastUsedAt ? ` · last used ${new Date(k.lastUsedAt).toLocaleDateString()}` : " · never used"}
                      {k.expiresAt ? ` · expires ${new Date(k.expiresAt).toLocaleDateString()}` : " · no expiry"}
                    </p>
                  </div>
                  <Button variant="ghost" size="sm" onClick={() => handleRevoke(k.id, k.label)} title="Revoke">
                    <X className="h-4 w-4" />
                  </Button>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
