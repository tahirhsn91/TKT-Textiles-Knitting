import { useState } from "react";
import { useLocation } from "wouter";
import {
  ChevronDown,
  KeyRound,
  LogOut,
  Settings,
  User as UserIcon,
  ShieldCheck,
  Loader2,
  Menu,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/context/auth-context";
import { useChangePassword } from "@/hooks/use-rbac";
import { useToast } from "@/hooks/use-toast";
import { TenantSwitcher } from "@/components/TenantSwitcher";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";

/**
 * Top bar shown across the whole app. Left: hamburger (mobile). Right:
 * account dropdown (user + role, Users & Roles, Change Password, Sign out).
 * Uses the same height as the sidebar header so the top region is consistent.
 */
export function TopBar({ onMenuClick }: { onMenuClick?: () => void }) {
  const { session, can, logout } = useAuth();
  const [, setLocation] = useLocation();
  const [pwOpen, setPwOpen] = useState(false);

  const signOut = () => {
    logout();
    setLocation("/login");
  };

  return (
    <header
      className={cn(
        "sticky top-0 z-30 flex h-14 shrink-0 items-center justify-between gap-2 border-b border-sidebar-border bg-sidebar px-3 text-sidebar-foreground print:hidden",
        // Push below the fixed dev banner in dev builds.
        import.meta.env.DEV && "top-7"
      )}
    >
      {/* Left: hamburger (mobile). */}
      <div className="flex min-w-0 items-center gap-1">
        {onMenuClick && (
          <button
            onClick={onMenuClick}
            className="flex h-8 w-8 items-center justify-center rounded-md text-sidebar-foreground/70 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground md:hidden"
            aria-label="Open navigation menu"
          >
            <Menu className="h-5 w-5" />
          </button>
        )}
      </div>

      {/* Right: tenant switcher (super-admin only) + account dropdown aligned to the top-right corner. */}
      <div className="flex flex-1 items-center justify-end gap-2">
        {/* Tenant Switcher - Super Admin Only */}
        <TenantSwitcher isSuperAdmin={session?.role?.name === 'super-admin'} />
        
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button
              className="flex h-8 items-center gap-2 rounded-md px-2 text-sm font-medium text-sidebar-foreground/80 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              aria-label="Account menu"
            >
              <span className="flex h-6 w-6 items-center justify-center rounded-full bg-sidebar-accent text-sidebar-accent-foreground">
                <UserIcon className="h-3.5 w-3.5" />
              </span>
              <span className="hidden max-w-[10rem] truncate sm:block">
                {session?.user.displayName ?? session?.user.username ?? "Account"}
              </span>
              <ChevronDown className="h-4 w-4 opacity-60" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-60">
            <DropdownMenuLabel className="font-normal">
              <p className="truncate text-sm font-semibold">{session?.user.displayName ?? "—"}</p>
              <p className="flex items-center gap-1 text-xs text-muted-foreground">
                <ShieldCheck className="h-3 w-3" /> {session?.role.name ?? ""}
              </p>
            </DropdownMenuLabel>

            {can("users") && (
              <>
                <DropdownMenuSeparator />
                <DropdownMenuItem onSelect={() => setLocation("/settings")}>
                  <Settings className="mr-2 h-4 w-4" />
                  Users &amp; Roles
                </DropdownMenuItem>
              </>
            )}

            {session?.role?.name === 'super-admin' && (
              <>
                <DropdownMenuSeparator />
                <DropdownMenuItem onSelect={() => setLocation("/admin/tenants")}>
                  <ShieldCheck className="mr-2 h-4 w-4" />
                  Tenant Administration
                </DropdownMenuItem>
              </>
            )}

            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={() => setPwOpen(true)}>
              <KeyRound className="mr-2 h-4 w-4" />
              Change Password
            </DropdownMenuItem>

            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={signOut} className="text-destructive focus:text-destructive">
              <LogOut className="mr-2 h-4 w-4" />
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {pwOpen && <ChangePasswordDialog open={pwOpen} onClose={() => setPwOpen(false)} />}
    </header>
  );
}

function ChangePasswordDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { toast } = useToast();
  const changePassword = useChangePassword();
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const submit = () => {
    if (!currentPassword) {
      setError("Current password is required.");
      return;
    }
    if (newPassword.length < 6) {
      setError("New password must be at least 6 characters.");
      return;
    }
    if (newPassword === currentPassword) {
      setError("New password must be different from the current password.");
      return;
    }
    if (newPassword !== confirmPassword) {
      setError("New password and confirm password do not match.");
      return;
    }
    setError(null);
    changePassword.mutate(
      { currentPassword, newPassword },
      {
        onSuccess: () => {
          toast({ title: "Password changed" });
          setCurrentPassword("");
          setNewPassword("");
          setConfirmPassword("");
          onClose();
        },
        onError: (e) => {
          setError((e as { message?: string })?.message ?? "Could not change password");
        },
      },
    );
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Change password</DialogTitle>
          <DialogDescription>
            Enter your current password and a new one (6+ characters). Your session stays signed in.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label>Current password</Label>
            <Input
              type="password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              autoFocus
            />
          </div>
          <div className="space-y-1.5">
            <Label>New password</Label>
            <Input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="6+ characters"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Confirm password</Label>
            <Input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Re-enter your new password"
            />
          </div>
          {error && (
            <p className="rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">
              {error}
            </p>
          )}
        </div>
        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={submit} disabled={changePassword.isPending} className="gap-2">
            {changePassword.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <KeyRound className="h-4 w-4" />}
            Change password
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
