import { useEffect, useState } from "react";
import { useAuth } from "@/context/auth-context";
import { useAdmin } from "@/hooks/useAdmin";
import { Layout } from "@/components/layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Loader2, Plus, Eye, Edit2, Trash2 } from "lucide-react";

/**
 * Admin Tenants Page
 * Super-admin interface for managing all tenants
 * Features: Create, view, update, delete, and manage tenant admins
 */

export default function AdminTenantsPage() {
  const { session } = useAuth();
  const { tenants, loading, error, getTenants, createTenant, getTenantDetails, updateTenant, updateTenantStatus, deleteTenant } = useAdmin();
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [viewTenant, setViewTenant] = useState<any>(null);
  const [editingTenant, setEditingTenant] = useState<any>(null);
  const [deleteTenantTarget, setDeleteTenantTarget] = useState<any>(null);
  const [editForm, setEditForm] = useState({
    name: "",
    slug: "",
    industry: "",
    status: "active" as string,
  });
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    slug: "",
    industry: "",
    timezone: "Asia/Karachi",
    currency: "PKR",
    language: "ur",
  });

  // Check if user is super-admin
  const isSuperAdmin = session?.role?.name === "super-admin";

  useEffect(() => {
    if (isSuperAdmin) {
      getTenants();
    }
  }, [isSuperAdmin, getTenants]);

  const openView = async (tenant: any) => {
    setViewTenant(tenant);
    try {
      const detail = await getTenantDetails(tenant.id);
      setViewTenant((prev: any) => (prev && prev.id === tenant.id ? { ...prev, ...detail } : prev));
    } catch {
      /* fall back to list row data */
    }
  };

  const openEdit = (tenant: any) => {
    setEditingTenant(tenant);
    setEditForm({
      name: tenant.name ?? "",
      slug: tenant.slug ?? "",
      industry: tenant.industry ?? "",
      status: tenant.status ?? "active",
    });
    setActionError(null);
  };

  const handleEditSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingTenant) return;
    setBusy(true);
    setActionError(null);
    try {
      await updateTenant(editingTenant.id, {
        name: editForm.name,
        slug: editForm.slug,
        industry: editForm.industry,
      });
      await updateTenantStatus(editingTenant.id, editForm.status);
      setEditingTenant(null);
      await getTenants();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "Failed to update tenant");
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTenantTarget) return;
    setBusy(true);
    setActionError(null);
    try {
      await deleteTenant(deleteTenantTarget.id);
      setDeleteTenantTarget(null);
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "Failed to delete tenant");
    } finally {
      setBusy(false);
    }
  };


  if (!isSuperAdmin) {
    return (
      <Layout>
        <div className="flex h-screen items-center justify-center">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Access Denied</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">
                You must be a super-admin to access this page.
              </p>
            </CardContent>
          </Card>
        </div>
      </Layout>
    );
  }

  const handleCreateTenant = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await createTenant(formData);
      setShowCreateDialog(false);
      setFormData({
        name: "",
        slug: "",
        industry: "",
        timezone: "Asia/Karachi",
        currency: "PKR",
        language: "ur",
      });
      getTenants();
    } catch (err) {
      console.error("Error creating tenant:", err);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "active":
        return <Badge className="bg-green-500">Active</Badge>;
      case "suspended":
        return <Badge className="bg-yellow-500">Suspended</Badge>;
      case "inactive":
        return <Badge className="bg-gray-500">Inactive</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
  };

  return (
    <Layout>
      <div className="space-y-6 p-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Tenant Administration</h1>
            <p className="text-muted-foreground">
              Manage all tenants in the system
            </p>
          </div>
          <Button onClick={() => setShowCreateDialog(true)} className="gap-2">
            <Plus className="h-4 w-4" />
            Create Tenant
          </Button>
        </div>

        {/* Error Alert */}
        {error && (
          <Card className="border-destructive bg-destructive/5">
            <CardContent className="pt-6">
              <p className="text-sm text-destructive">{error}</p>
            </CardContent>
          </Card>
        )}

        {/* Tenants Table */}
        <Card>
          <CardHeader>
            <CardTitle>All Tenants</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : tenants.length === 0 ? (
              <div className="py-8 text-center">
                <p className="text-muted-foreground">No tenants found</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Slug</TableHead>
                      <TableHead>Industry</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Created</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {tenants.map((tenant) => (
                      <TableRow key={tenant.id}>
                        <TableCell className="font-medium">{tenant.name}</TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {tenant.slug}
                        </TableCell>
                        <TableCell className="text-sm">
                          {tenant.industry || "—"}
                        </TableCell>
                        <TableCell>{getStatusBadge(tenant.status)}</TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {new Date(tenant.created_at).toLocaleDateString()}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex items-center justify-end gap-2">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => openView(tenant)}
                              title="View tenant"
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => openEdit(tenant)}
                              title="Edit tenant"
                            >
                              <Edit2 className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-destructive"
                              onClick={() => { setActionError(null); setDeleteTenantTarget(tenant); }}
                              title="Delete tenant"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Create Tenant Dialog */}
      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Create New Tenant</DialogTitle>
            <DialogDescription>
              Add a new tenant to the system. All configurations will be auto-seeded.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleCreateTenant} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Company Name *</Label>
              <Input
                id="name"
                required
                placeholder="e.g., Sunrise Textiles"
                value={formData.name}
                onChange={(e) =>
                  setFormData({ ...formData, name: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="slug">Slug (URL-friendly) *</Label>
              <Input
                id="slug"
                required
                placeholder="e.g., sunrise-textiles"
                value={formData.slug}
                onChange={(e) =>
                  setFormData({ ...formData, slug: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="industry">Industry *</Label>
              <Input
                id="industry"
                required
                placeholder="e.g., Textile & Knitting"
                value={formData.industry}
                onChange={(e) =>
                  setFormData({ ...formData, industry: e.target.value })
                }
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="timezone">Timezone *</Label>
                <Select
                  value={formData.timezone}
                  onValueChange={(value) =>
                    setFormData({ ...formData, timezone: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Asia/Karachi">Asia/Karachi</SelectItem>
                    <SelectItem value="Asia/Dubai">Asia/Dubai</SelectItem>
                    <SelectItem value="UTC">UTC</SelectItem>
                    <SelectItem value="Europe/London">Europe/London</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="currency">Currency *</Label>
                <Select
                  value={formData.currency}
                  onValueChange={(value) =>
                    setFormData({ ...formData, currency: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="PKR">PKR</SelectItem>
                    <SelectItem value="USD">USD</SelectItem>
                    <SelectItem value="EUR">EUR</SelectItem>
                    <SelectItem value="AED">AED</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="language">Language *</Label>
              <Select
                value={formData.language}
                onValueChange={(value) =>
                  setFormData({ ...formData, language: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ur">Urdu</SelectItem>
                  <SelectItem value="en">English</SelectItem>
                  <SelectItem value="ar">Arabic</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setShowCreateDialog(false)}
              >
                Cancel
              </Button>
              <Button type="submit">Create Tenant</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
      {/* View Tenant Dialog */}
      <Dialog open={viewTenant != null} onOpenChange={(o) => !o && setViewTenant(null)}>
        <DialogContent className="sm:max-w-[460px]">
          <DialogHeader>
            <DialogTitle>Tenant Details</DialogTitle>
            <DialogDescription>View tenant information and configuration.</DialogDescription>
          </DialogHeader>
          {viewTenant && (
            <div className="space-y-3 text-sm">
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Name</span><span className="col-span-2 font-medium">{viewTenant.name}</span></div>
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Slug</span><span className="col-span-2 font-mono">{viewTenant.slug}</span></div>
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Industry</span><span className="col-span-2">{viewTenant.industry || "—"}</span></div>
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Country / TZ</span><span className="col-span-2">{viewTenant.country ?? "Pakistan"} • {viewTenant.timezone ?? "Asia/Karachi"}</span></div>
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Currency</span><span className="col-span-2">{viewTenant.currency ?? "PKR"}</span></div>
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Status</span><span className="col-span-2">{getStatusBadge(viewTenant.status ?? "unknown")}</span></div>
              <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Created</span><span className="col-span-2">{viewTenant.created_at ? new Date(viewTenant.created_at).toLocaleString() : viewTenant.createdAt ? new Date(viewTenant.createdAt).toLocaleString() : "—"}</span></div>
              {typeof viewTenant.userCount === "number" && (
                <div className="grid grid-cols-3 gap-1"><span className="text-muted-foreground">Users</span><span className="col-span-2">{viewTenant.userCount}</span></div>
              )}
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setViewTenant(null)}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Tenant Dialog */}
      <Dialog open={editingTenant != null} onOpenChange={(o) => !o && setEditingTenant(null)}>
        <DialogContent className="sm:max-w-[480px]">
          <DialogHeader>
            <DialogTitle>Edit Tenant</DialogTitle>
            <DialogDescription>Update tenant details and status.</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditSave} className="space-y-4">
            {actionError && <p className="text-sm text-destructive">{actionError}</p>}
            <div className="space-y-2">
              <Label htmlFor="edit-name">Company Name</Label>
              <Input id="edit-name" required value={editForm.name} onChange={(e) => setEditForm({ ...editForm, name: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-slug">Slug</Label>
              <Input id="edit-slug" required value={editForm.slug} onChange={(e) => setEditForm({ ...editForm, slug: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-industry">Industry</Label>
              <Input id="edit-industry" value={editForm.industry} onChange={(e) => setEditForm({ ...editForm, industry: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label>Status</Label>
              <Select value={editForm.status} onValueChange={(value) => setEditForm({ ...editForm, status: value })}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="suspended">Suspended</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setEditingTenant(null)}>Cancel</Button>
              <Button type="submit" disabled={busy}>{busy ? "Saving…" : "Save Changes"}</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Tenant Dialog */}
      <Dialog open={deleteTenantTarget != null} onOpenChange={(o) => !o && setDeleteTenantTarget(null)}>
        <DialogContent className="sm:max-w-[420px]">
          <DialogHeader>
            <DialogTitle>Delete Tenant</DialogTitle>
            <DialogDescription>
              This permanently deletes <strong>{deleteTenantTarget?.name}</strong> and all of its tenant-owned data. This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          {actionError && <p className="text-sm text-destructive">{actionError}</p>}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setDeleteTenantTarget(null)}>Cancel</Button>
            <Button type="button" variant="destructive" disabled={busy} onClick={handleDelete}>{busy ? "Deleting…" : "Delete Tenant"}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </Layout>
  );
}
