import { useEffect, useState } from "react";
import { Mail, UserPlus, X } from "lucide-react";
import { useInvitations, type Invitation } from "@/hooks/useInvitations";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

/**
 * InvitationsTab — issue #219 1.4 user invitation system.
 * Invite people to the active tenant by email + role, view pending invites,
 * and revoke them.
 */

function statusBadge(status: string) {
  switch (status) {
    case "pending":
      return <Badge className="bg-amber-500">Pending</Badge>;
    case "accepted":
      return <Badge className="bg-green-500">Accepted</Badge>;
    case "revoked":
      return <Badge variant="secondary">Revoked</Badge>;
    case "expired":
      return <Badge variant="secondary">Expired</Badge>;
    default:
      return <Badge>{status}</Badge>;
  }
}

export function InvitationsTab() {
  const { invitations, loading, error, list, create, revoke } = useInvitations();
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("Manager");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    void list().catch(() => undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setMsg(null);
    try {
      const inv = await create(email, role);
      setEmail("");
      setMsg(inv.token ? `Invite created. Token: ${inv.token}` : "Invite created");
    } catch {
      setMsg("Failed to create invitation");
    } finally {
      setBusy(false);
    }
  };

  const handleRevoke = async (token: string) => {
    try {
      await revoke(token);
    } catch {
      /* surface via list error on next load */
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <UserPlus className="h-4 w-4" /> Invite a Team Member
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={submit} className="flex flex-wrap items-end gap-3">
            <div className="space-y-1.5">
              <Label>Email</Label>
              <Input
                type="email"
                required
                placeholder="user@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-64"
              />
            </div>
            <div className="space-y-1.5">
              <Label>Role</Label>
              <Select value={role} onValueChange={setRole}>
                <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="Manager">Manager</SelectItem>
                  <SelectItem value="Supervisor">Supervisor</SelectItem>
                  <SelectItem value="Admin">Admin</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Button type="submit" disabled={busy} className="gap-1.5">
              <Mail className="h-4 w-4" /> {busy ? "Inviting…" : "Invite"}
            </Button>
          </form>
          {msg && <p className="mt-2 break-all text-xs text-muted-foreground">{msg}</p>}
          {error && <p className="mt-2 text-xs text-destructive">{error}</p>}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Invitations</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-2"><Skeleton className="h-10 w-full" /><Skeleton className="h-10 w-full" /></div>
          ) : invitations.length === 0 ? (
            <p className="text-sm text-muted-foreground">No invitations yet.</p>
          ) : (
            <ul className="space-y-2">
              {invitations.map((inv: Invitation) => (
                <li key={inv.id} className="flex items-center justify-between gap-3 rounded-md border p-3">
                  <div>
                    <p className="text-sm font-medium">{inv.email}</p>
                    <p className="font-mono text-xs text-muted-foreground">{inv.role}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    {statusBadge(inv.status)}
                    {inv.status === "pending" && inv.token && (
                      <Button variant="ghost" size="sm" onClick={() => handleRevoke(inv.token!)} title="Revoke">
                        <X className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
