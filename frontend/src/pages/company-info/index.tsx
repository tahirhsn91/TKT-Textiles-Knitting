import { useState } from "react";
import { Plus, Pencil, Trash2, Star } from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";

import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
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
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
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
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";
import {
  useListCompanyInfo,
  useCreateCompanyInfo,
  useUpdateCompanyInfo,
  useSetDefaultCompany,
  useDeleteCompanyInfo,
  type CompanyInfo,
} from "@/hooks/use-fbr-invoicing";

/** Official FBR province names (mirrors backend constant). */
const FBR_PROVINCES = ["Punjab", "Sindh", "KPK", "Balochistan", "Islamabad"] as const;

const companySchema = z.object({
  name: z.string().min(1, "Company name is required"),
  ntnCnic: z.string().min(1, "NTN/CNIC is required"),
  province: z.string().min(1, "Province is required"),
  address: z.string().min(1, "Address is required"),
  fbrSandboxToken: z.string().optional(),
  fbrProductionToken: z.string().optional(),
});
type CompanyFormValues = z.infer<typeof companySchema>;

function emptyForm(): CompanyFormValues {
  return { name: "", ntnCnic: "", province: "", address: "", fbrSandboxToken: "", fbrProductionToken: "" };
}

function toForm(c: CompanyInfo): CompanyFormValues {
  return {
    name: c.name,
    ntnCnic: c.ntnCnic,
    province: c.province,
    address: c.address,
    fbrSandboxToken: c.fbrSandboxToken ?? "",
    fbrProductionToken: c.fbrProductionToken ?? "",
  };
}

export default function CompanyInfoPage() {
  const { toast } = useToast();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<CompanyInfo | null>(null);
  const [pendingDelete, setPendingDelete] = useState<CompanyInfo | null>(null);

  const { data: companies, isLoading } = useListCompanyInfo();
  const createCompany = useCreateCompanyInfo();
  const updateCompany = useUpdateCompanyInfo();
  const setDefault = useSetDefaultCompany();
  const deleteCompany = useDeleteCompanyInfo();

  const form = useForm<CompanyFormValues>({
    resolver: zodResolver(companySchema),
    defaultValues: emptyForm(),
  });

  const openCreate = () => {
    setEditing(null);
    form.reset(emptyForm());
    setDialogOpen(true);
  };
  const openEdit = (c: CompanyInfo) => {
    setEditing(c);
    form.reset(toForm(c));
    setDialogOpen(true);
  };

  const onSubmit = (values: CompanyFormValues) => {
    const body = {
      name: values.name,
      ntnCnic: values.ntnCnic,
      province: values.province,
      address: values.address,
      fbrSandboxToken: values.fbrSandboxToken || null,
      fbrProductionToken: values.fbrProductionToken || null,
    };
    const action = editing
      ? updateCompany.mutateAsync({ id: editing.id, body })
      : createCompany.mutateAsync(body);
    action
      .then(() => {
        toast({ title: editing ? "Company updated" : "Company created" });
        setDialogOpen(false);
      })
      .catch((e) => {
        toast({ title: "Could not save company", description: e?.message ?? "Something went wrong", variant: "destructive" });
      });
  };

  const head = (
    <>
      <CardHeader>
        <CardTitle>Company Info</CardTitle>
        <CardDescription>
          Seller details used on FBR digital invoices. Multiple companies can be added, but exactly one must be
          set as default — invoice generation uses the default company.
        </CardDescription>
      </CardHeader>
      <div className="flex justify-end px-6 pb-2">
        <Button onClick={openCreate} className="gap-2">
          <Plus className="h-4 w-4" /> Add Company
        </Button>
      </div>
    </>
  );

  return (
    <Layout>
      <div className="space-y-4">
        <Card className="border-sidebar-border">
          {head}
          <CardContent className="px-0">
            {isLoading ? (
              <div className="space-y-2 px-6">
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>NTN/CNIC</TableHead>
                    <TableHead>Province</TableHead>
                    <TableHead>Address</TableHead>
                    <TableHead>Default</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(companies ?? []).length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center text-muted-foreground py-8">
                        No companies yet. Add one to start invoicing.
                      </TableCell>
                    </TableRow>
                  ) : (
                    (companies ?? []).map((c) => (
                      <TableRow key={c.id}>
                        <TableCell className="font-medium">{c.name}</TableCell>
                        <TableCell>{c.ntnCnic}</TableCell>
                        <TableCell>{c.province}</TableCell>
                        <TableCell className="max-w-[220px] truncate">{c.address}</TableCell>
                        <TableCell>
                          {c.isDefault ? (
                            <span className="inline-flex items-center gap-1.5 text-sm font-medium text-foreground">
                              <Star className="h-4 w-4 fill-amber-400 text-amber-400" /> Default
                            </span>
                          ) : (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="gap-1.5 text-muted-foreground"
                              onClick={() =>
                                setDefault.mutate(c.id, {
                                  onSuccess: () => toast({ title: `${c.name} set as default` }),
                                  onError: (e) => toast({ title: "Could not set default", description: e?.message, variant: "destructive" }),
                                })
                              }
                            >
                              <Star className="h-4 w-4" /> Set default
                            </Button>
                          )}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-1">
                            <Button variant="ghost" size="icon" onClick={() => openEdit(c)} title="Edit">
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="text-destructive hover:text-destructive"
                              onClick={() => setPendingDelete(c)}
                              title={c.isDefault ? "Cannot delete the default company" : "Delete"}
                              disabled={c.isDefault}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Create / edit dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit Company" : "Add Company"}</DialogTitle>
            <DialogDescription>
              Seller details used on FBR digital invoices.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Business Name</FormLabel>
                    <FormControl><Input placeholder="e.g. TKT Textiles (Pvt) Ltd" {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="ntnCnic"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>NTN / CNIC</FormLabel>
                    <FormControl><Input placeholder="7-digit NTN or 13-digit CNIC" {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="province"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Province</FormLabel>
                    <FormControl>
                      <Select value={field.value || undefined} onValueChange={field.onChange}>
                        <SelectTrigger><SelectValue placeholder="Select province" /></SelectTrigger>
                        <SelectContent>
                          {FBR_PROVINCES.map((p) => (
                            <SelectItem key={p} value={p}>{p}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="address"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Address</FormLabel>
                    <FormControl><Textarea rows={2} placeholder="Business address" {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="rounded-md border border-border p-3 space-y-4">
                <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">FBR API Tokens</p>
                <FormField
                  control={form.control}
                  name="fbrSandboxToken"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Sandbox Token</FormLabel>
                      <FormControl><Input placeholder="FBR sandbox security token" {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="fbrProductionToken"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Production Token</FormLabel>
                      <FormControl><Input placeholder="FBR production security token" {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
                <Button type="submit" disabled={createCompany.isPending || updateCompany.isPending}>
                  {editing ? "Save Changes" : "Add Company"}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Delete confirm */}
      <AlertDialog open={pendingDelete != null} onOpenChange={(o) => !o && setPendingDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete company?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently remove <span className="font-semibold">{pendingDelete?.name}</span>. This cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={() =>
                pendingDelete &&
                deleteCompany.mutate(pendingDelete.id, {
                  onSuccess: () => toast({ title: "Company deleted" }),
                  onError: (e) => toast({ title: "Could not delete", description: e?.message, variant: "destructive" }),
                })
              }
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  );
}
