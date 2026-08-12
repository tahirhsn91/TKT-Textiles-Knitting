import { useState, useMemo } from "react";
import { Plus, Pencil, Trash2, Star, Search } from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
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

export function CompanyInfoSection() {
  const { toast } = useToast();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<CompanyInfo | null>(null);
  const [pendingDelete, setPendingDelete] = useState<CompanyInfo | null>(null);
  const [search, setSearch] = useState("");

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

  const trimmedSearch = search.trim().toLowerCase();
  const filtered = useMemo(
    () =>
      (companies ?? []).filter((c) =>
        !trimmedSearch
          ? true
          : [c.name, c.ntnCnic, c.province, c.address].some((v) =>
              (v ?? "").toLowerCase().includes(trimmedSearch),
            ),
      ),
    [companies, trimmedSearch],
  );

  // Matches MasterTable's header + section-head + search layout so the
  // Company Info tab reads like every other master-data screen.
  return (
    <>
      <div className="flex flex-col gap-5">
        {/* Title + description + action — same stack as MasterTable. */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between sm:gap-6">
          <div>
            <h2 className="text-lg font-semibold leading-none text-foreground">Company Info</h2>
            <p className="mt-2 max-w-prose text-sm text-muted-foreground sm:max-w-md">
              Seller details used on FBR digital invoices. Multiple companies can be added, but exactly one must
              be set as default — invoice generation uses the default company.
            </p>
          </div>
          <Button className="w-full shrink-0 sm:w-auto" onClick={openCreate}>
            <Plus className="mr-2 h-4 w-4" />
            Add new
          </Button>
        </div>

        {/* Search — same as the other master tables. */}
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search companies…"
            className="h-9 pl-9"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {/* Card with a hairline section head + record count — same framing as
            MasterTable's "All {title}" header. */}
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h3 className="text-sm font-semibold text-foreground">All companies</h3>
            {!isLoading && companies && (
              <span className="eyebrow">
                <span className="num">
                  {trimmedSearch ? `${filtered.length} of ${companies.length} record${companies.length === 1 ? "" : "s"}` : `${companies.length} record${companies.length === 1 ? "" : "s"}`}
                </span>
              </span>
            )}
          </div>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>NTN/CNIC</TableHead>
                    <TableHead>Province</TableHead>
                    <TableHead>Address</TableHead>
                    <TableHead>Default</TableHead>
                    <TableHead className="sticky right-0 w-28 bg-background text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {isLoading ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <TableRow key={i}>
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-16 ml-auto" /></TableCell>
                      </TableRow>
                    ))
                  ) : filtered.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="py-10 text-center text-muted-foreground">
                        {trimmedSearch
                          ? `No companies match "${search.trim()}".`
                          : "No companies recorded yet. Add the first one to get started."}
                      </TableCell>
                    </TableRow>
                  ) : (
                    filtered.map((c) => (
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
                        <TableCell className="sticky right-0 bg-background text-right">
                          <div className="flex justify-end gap-1">
                            <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" onClick={() => openEdit(c)} title="Edit">
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-9 w-9 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
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
            </div>
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
    </>
  );
}
