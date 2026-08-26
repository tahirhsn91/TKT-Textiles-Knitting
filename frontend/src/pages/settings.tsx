import { useState } from "react";
import {
  Users as UsersIcon,
  ShieldCheck,
  Building2,
  UserPlus,
  KeyRound,
  Palette,
  Pencil,
  Check,
  X,
  Trash2,
} from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import { useAuth } from "@/context/auth-context";
import { Layout } from "@/components/layout";
import { CompanySettingsTab } from "@/pages/company-settings-tab";
import { InvitationsTab } from "@/pages/invitations-tab";
import { ApiKeysTab } from "@/pages/api-keys-tab";
import { BrandingTab } from "@/pages/branding-tab";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Spinner } from "@/components/ui/spinner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
  TooltipProvider,
} from "@/components/ui/tooltip";
import { useToast } from "@/hooks/use-toast";
import {
  useListRoles,
  useRolePermissions,
  useListUsers,
  useCreateUser,
  useUpdateUser,
  useResetPassword,
  useDeleteUser,
  useSavePermissions,
  type UserView,
  type RolePermissions,
} from "@/hooks/use-rbac";

interface EmployeeLookup {
  id: number;
  name: string;
  code?: string | null;
}

// The route/module keys admin can toggle (must match backend requirePermission
// moduleIds + the ProtectedRoute moduleId props).
const MODULE_LABELS: Array<[string, string]> = [
  ["dashboard", "Dashboard"],
  ["masters", "Master Data"],
  ["transactions", "Transactions"],
  ["dailyProduction", "Daily Production"],
  ["yarnReceipts", "Yarn Receipts"],
  ["dailyDeliveries", "Daily Deliveries"],
  ["payroll", "Payroll / Salary"],
  ["reports", "Reports"],
  ["maintenance", "Maintenance"],
  ["companyInfo", "Company Info"],
  ["invoicing", "Invoicing"],
  ["users", "Users & Permissions"],
];

export default function SettingsPage() {
  const { session } = useAuth();
  if (!session?.role.isAdmin) {
    // Should never render (route-gated), but stay safe.
    return (
      <Layout>
        <p className="py-8 text-center text-sm text-muted-foreground">Access denied</p>
      </Layout>
    );
  }
  return (
    <Layout>
      <div className="flex flex-col gap-6">
        <header className="border-b pb-5">
          <p className="eyebrow">Administration</p>
          <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">Users &amp; Roles</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Manage who can sign in, what role they hold, and which routes each role can open.
          </p>
        </header>

        <Tabs defaultValue="users">
          <TabsList>
            <TabsTrigger value="users" className="gap-1.5"><UsersIcon className="h-4 w-4" /> Users</TabsTrigger>
            <TabsTrigger value="permissions" className="gap-1.5"><ShieldCheck className="h-4 w-4" /> Permissions</TabsTrigger>
            <TabsTrigger value="company" className="gap-1.5"><Building2 className="h-4 w-4" /> Company</TabsTrigger>
            <TabsTrigger value="invitations" className="gap-1.5"><UserPlus className="h-4 w-4" /> Invitations</TabsTrigger>
            <TabsTrigger value="apikeys" className="gap-1.5"><KeyRound className="h-4 w-4" /> API Keys</TabsTrigger>
            <TabsTrigger value="branding" className="gap-1.5"><Palette className="h-4 w-4" /> Branding</TabsTrigger>
          </TabsList>
          <TabsContent value="users" className="mt-4"><UsersTab /></TabsContent>
          <TabsContent value="permissions" className="mt-4"><PermissionsTab /></TabsContent>
          <TabsContent value="company" className="mt-4"><CompanySettingsTab /></TabsContent>
          <TabsContent value="invitations" className="mt-4"><InvitationsTab /></TabsContent>
          <TabsContent value="apikeys" className="mt-4"><ApiKeysTab /></TabsContent>
          <TabsContent value="branding" className="mt-4"><BrandingTab /></TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}

// ─── Users tab ───────────────────────────────────────────────────────────────

function UsersTab() {
  const { session } = useAuth();
  const isAdmin = session?.role.isAdmin === true;
  const { data: users, isLoading } = useListUsers();
  const { data: roles } = useListRoles();
  const { data: employees } = useQuery<EmployeeLookup[]>({
    queryKey: ["employee-lookup"],
    queryFn: () => customFetch<EmployeeLookup[]>("/api/lookups/employee-master", { method: "GET" }),
    enabled: true,
  });
  const [createOpen, setCreateOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<UserView | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<UserView | null>(null);

  return (
    <TooltipProvider delayDuration={200}>
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">Users</h2>
        <Button size="sm" className="gap-1.5" onClick={() => setCreateOpen(true)}>
          <UserPlus className="h-4 w-4" /> Add user
        </Button>
      </div>
      <CardContent className="p-0">
        {isLoading ? (
          <div className="space-y-2 p-4"><Skeleton className="h-10 w-full" /><Skeleton className="h-10 w-full" /></div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Username</TableHead>
                <TableHead>Display name</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Employee</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {(users ?? []).length === 0 ? (
                <TableRow><TableCell colSpan={6} className="py-8 text-center text-muted-foreground">No users yet.</TableCell></TableRow>
              ) : (
                (users ?? []).map((u) => (
                  <TableRow key={u.id}>
                    <TableCell className="font-medium">{u.username}</TableCell>
                    <TableCell>{u.displayName}</TableCell>
                    <TableCell>
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${u.roleName === "Admin" ? "bg-violet-100 text-violet-700 dark:bg-violet-950/50 dark:text-violet-300" : "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300"}`}>
                        {u.roleName}
                      </span>
                    </TableCell>
                    <TableCell className="text-muted-foreground">{employees?.find((e) => e.id === u.employeeId)?.name ?? "—"}</TableCell>
                    <TableCell>
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${u.isActive ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300" : "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"}`}>
                        {u.isActive ? "Active" : "Inactive"}
                      </span>
                    </TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" className="gap-1" onClick={() => setEditTarget(u)}>
                        <Pencil className="h-4 w-4" /> Edit
                      </Button>
                      {isAdmin && u.roleName !== "Admin" && session?.user.id !== u.id ? (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="gap-1 text-destructive hover:text-destructive"
                          onClick={() => setDeleteTarget(u)}
                        >
                          <Trash2 className="h-4 w-4" /> Delete
                        </Button>
                      ) : (
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <span className="inline-flex cursor-not-allowed items-center gap-1 px-3 py-1.5 text-sm text-muted-foreground/50">
                              <Trash2 className="h-4 w-4" /> Delete
                            </span>
                          </TooltipTrigger>
                          <TooltipContent side="bottom" align="end">
                            {u.roleName === "Admin"
                              ? "Admin accounts cannot be deleted"
                              : "You cannot delete your own account"}
                          </TooltipContent>
                        </Tooltip>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        )}
      </CardContent>

      {createOpen && roles && (
        <CreateUserDialog
          roles={roles}
          employees={employees ?? []}
          onClose={() => setCreateOpen(false)}
        />
      )}
      {editTarget && roles && (
        <EditUserDialog
          user={editTarget}
          roles={roles}
          employees={employees ?? []}
          onClose={() => setEditTarget(null)}
        />
      )}
      {deleteTarget && (
        <DeleteUserDialog
          user={deleteTarget}
          onClose={() => setDeleteTarget(null)}
        />
      )}
    </Card>
    </TooltipProvider>
  );
}

function DeleteUserDialog({ user, onClose }: { user: UserView; onClose: () => void }) {
  const { toast } = useToast();
  const del = useDeleteUser();

  const confirm = () => {
    del.mutate(
      { id: user.id },
      {
        onSuccess: () => {
          toast({ title: "User deleted" });
          onClose();
        },
        onError: (e) => {
          toast({ title: "Could not delete user", description: (e as { message?: string })?.message, variant: "destructive" });
        },
      },
    );
  };

  return (
    <AlertDialog open onOpenChange={(o) => !o && onClose()}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete user — {user.username}?</AlertDialogTitle>
          <AlertDialogDescription>
            This permanently removes {user.displayName || user.username} and their ability to sign in. This action cannot be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={onClose}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            disabled={del.isPending}
            onClick={confirm}
          >
            <Trash2 className="h-4 w-4" /> Delete
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}

function CreateUserDialog({
  roles,
  employees,
  onClose,
}: {
  roles: { id: number; name: string; isAdmin: boolean }[];
  employees: EmployeeLookup[];
  onClose: () => void;
}) {
  const { toast } = useToast();
  const create = useCreateUser();
  const [username, setUsername] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [password, setPassword] = useState("");
  const [roleId, setRoleId] = useState<string>(String(roles[0]?.id ?? ""));
  const [employeeId, setEmployeeId] = useState<string>("__none__");
  const [error, setError] = useState<string | null>(null);

  const submit = () => {
    if (!username.trim() || !displayName.trim() || password.length < 6) {
      setError("Username, display name, and a password of 6+ characters are required.");
      return;
    }
    setError(null);
    create.mutate(
      {
        username: username.trim(),
        displayName: displayName.trim(),
        password,
        roleId: Number(roleId),
        employeeId: employeeId === "__none__" ? null : Number(employeeId),
        isActive: true,
      },
      {
        onSuccess: () => {
          toast({ title: "User created" });
          onClose();
        },
        onError: (e) => setError((e as { message?: string })?.message ?? "Could not create user"),
      },
    );
  };

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Add user</DialogTitle>
          <DialogDescription>Set the initial password — the user can change it later from inside.</DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Username</Label>
              <Input value={username} onChange={(e) => setUsername(e.target.value)} placeholder="operator1" autoFocus />
            </div>
            <div className="space-y-1.5">
              <Label>Display name</Label>
              <Input value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder="e.g. Ahmed Khan" />
            </div>
          </div>
          <div className="space-y-1.5">
            <Label>Password</Label>
            <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Initial password (6+ chars)" />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Role</Label>
              <Select value={roleId} onValueChange={setRoleId}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {roles.map((r) => (
                    <SelectItem key={r.id} value={String(r.id)}>{r.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Employee (optional)</Label>
              <Select value={employeeId} onValueChange={setEmployeeId}>
                <SelectTrigger className="w-full"><SelectValue placeholder="Not linked to an employee" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">— No employee —</SelectItem>
                  {employees.map((e) => (
                    <SelectItem key={e.id} value={String(e.id)}>{e.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          {error && <p className="rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">{error}</p>}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button onClick={submit} disabled={create.isPending} className="gap-2">
              {create.isPending ? <Spinner className="h-4 w-4" /> : <UserPlus className="h-4 w-4" />} Create user
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function EditUserDialog({
  user,
  roles,
  employees,
  onClose,
}: {
  user: UserView;
  roles: { id: number; name: string; isAdmin: boolean }[];
  employees: EmployeeLookup[];
  onClose: () => void;
}) {
  const { toast } = useToast();
  const update = useUpdateUser();
  const reset = useResetPassword();
  const [displayName, setDisplayName] = useState(user.displayName);
  const [roleId, setRoleId] = useState(String(user.roleId));
  const [employeeId, setEmployeeId] = useState(user.employeeId ? String(user.employeeId) : "__none__");
  const [isActive, setIsActive] = useState(user.isActive);
  const [resetOpen, setResetOpen] = useState(false);
  const [newPassword, setNewPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const save = () => {
    update.mutate(
      { id: user.id, body: { displayName, roleId: Number(roleId), employeeId: employeeId === "__none__" ? null : Number(employeeId), isActive } },
      {
        onSuccess: () => { toast({ title: "User updated" }); onClose(); },
        onError: (e) => setError((e as { message?: string })?.message ?? "Could not update user"),
      },
    );
  };

  const savePassword = () => {
    if (newPassword.length < 6) { setError("Password must be at least 6 characters."); return; }
    setError(null);
    reset.mutate(
      { id: user.id, password: newPassword },
      {
        onSuccess: () => { toast({ title: "Password reset" }); setResetOpen(false); setNewPassword(""); },
        onError: (e) => setError((e as { message?: string })?.message ?? "Could not reset password"),
      },
    );
  };

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Edit user — {user.username}</DialogTitle>
          <DialogDescription>Update details, role, employee link, or active status.</DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label>Display name</Label>
            <Input value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Role</Label>
              <Select value={roleId} onValueChange={setRoleId}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {roles.map((r) => (
                    <SelectItem key={r.id} value={String(r.id)}>{r.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Employee (optional)</Label>
              <Select value={employeeId} onValueChange={setEmployeeId}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">— No employee —</SelectItem>
                  {employees.map((e) => (
                    <SelectItem key={e.id} value={String(e.id)}>{e.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="flex items-center justify-between gap-3 rounded-md border border-border px-3 py-2">
            <span className="text-sm">Active account</span>
            <Button variant="ghost" size="sm" className={isActive ? "gap-1 text-emerald-600" : "gap-1 text-slate-500"} onClick={() => setIsActive((v) => !v)}>
              {isActive ? <><Check className="h-4 w-4" /> Active</> : <><X className="h-4 w-4" /> Inactive</>}
            </Button>
          </div>
          <div className="rounded-md border border-border">
            <button className="flex w-full items-center justify-between px-3 py-2 text-sm font-medium" onClick={() => setResetOpen((v) => !v)}>
              <span className="inline-flex items-center gap-1.5"><KeyRound className="h-4 w-4" /> Reset password</span>
              <span className="text-xs text-muted-foreground">{resetOpen ? "Hide" : "Show"}</span>
            </button>
            {resetOpen && (
              <div className="space-y-2 border-t border-border p-3">
                <Input type="password" placeholder="New password (6+ chars)" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
                <Button variant="outline" size="sm" onClick={savePassword} disabled={reset.isPending}>Set password</Button>
              </div>
            )}
          </div>
          {error && <p className="rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">{error}</p>}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button onClick={save} disabled={update.isPending} className="gap-2">
              {update.isPending ? <Spinner className="h-4 w-4" /> : <Check className="h-4 w-4" />} Save
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

// ─── Permissions tab ─────────────────────────────────────────────────────────

function PermissionsTab() {
  const { data: matrix, isLoading } = useRolePermissions();
  const save = useSavePermissions();
  const { toast } = useToast();
  const [drafts, setDrafts] = useState<Record<number, string[]>>({});
  const [savingId, setSavingId] = useState<number | null>(null);

  const rows = matrix ?? [];
  const editable = rows.filter((r) => !r.isAdmin);

  const toggle = (roleId: number, moduleId: string) => {
    setDrafts((prev) => {
      const base = matrix?.find((r) => r.roleId === roleId)?.permissions ?? [];
      const cur = prev[roleId] ?? base;
      const next = cur.includes(moduleId) ? cur.filter((m) => m !== moduleId) : [...cur, moduleId];
      return { ...prev, [roleId]: next };
    });
  };

  const saveRole = (role: RolePermissions) => {
    setSavingId(role.roleId);
    save.mutate(
      { roleId: role.roleId, permissions: drafts[role.roleId] ?? role.permissions },
      {
        onSuccess: () => {
          toast({ title: "Permissions saved" });
          setSavingId(null);
          setDrafts((prev) => { const n = { ...prev }; delete n[role.roleId]; return n; });
        },
        onError: (e) => {
          toast({ title: "Could not save", description: (e as { message?: string })?.message, variant: "destructive" });
          setSavingId(null);
        },
      },
    );
  };

  if (isLoading) {
    return <div className="h-24 animate-pulse rounded-lg bg-muted" />;
  }

  return (
    <div className="space-y-5">
      <p className="text-sm text-muted-foreground">
        Grant or restrict each route per role. The <span className="font-medium text-foreground">Admin</span> role always has full access and can’t be changed.
      </p>
      {editable.map((role) => {
        const current = drafts[role.roleId] ?? role.permissions;
        return (
          <Card key={role.roleId} className="overflow-hidden">
            <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
              <h3 className="text-sm font-semibold text-foreground">{role.role}</h3>
              <Button variant="outline" size="sm" className="gap-1.5" disabled={save.isPending} onClick={() => saveRole(role)}>
                {savingId === role.roleId ? <Spinner className="h-4 w-4" /> : <Check className="h-4 w-4" />} Save
              </Button>
            </div>
            <CardContent className="p-4">
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {MODULE_LABELS.map(([moduleId, label]) => {
                  const on = current.includes(moduleId);
                  return (
                    <label
                      key={moduleId}
                      className={`flex cursor-pointer items-center gap-2 rounded-md border px-3 py-2 text-sm transition-colors ${on ? "border-foreground/40 bg-foreground/[0.04]" : "border-border bg-muted/30"}`}
                    >
                      <input
                        type="checkbox"
                        className="h-4 w-4 accent-foreground"
                        checked={on}
                        onChange={() => toggle(role.roleId, moduleId)}
                      />
                      <span className="font-medium">{label}</span>
                    </label>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}
