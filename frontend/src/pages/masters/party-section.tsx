import { useState, useMemo } from "react";
import { Plus, Pencil, Trash2, Search } from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import {
  useListPartyMasterCrud,
  useCreatePartyMaster,
  useUpdatePartyMaster,
  useDeletePartyMaster,
  getListPartyMasterCrudQueryKey,
  getListPartyMasterQueryKey,
} from "@workspace/api-client-react";
import { useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";

/** Official FBR province names (mirrors backend constant). */
const FBR_PROVINCES = ["Punjab", "Sindh", "KPK", "Balochistan", "Islamabad"] as const;

/** The live API returns more than the generated LookupItem, so parties carry the
 *  FBR buyer fields too (ntnCnic, province, address, registrationType). */
interface PartyRow {
  id: number;
  name: string;
  code: string;
  wastePercent?: string | null;
  ntnCnic?: string | null;
  province?: string | null;
  address?: string | null;
  registrationType?: string | null;
}

const partySchema = z.object({
  name: z.string().min(1, "Name is required"),
  code: z.string().min(1, "Code is required"),
  wastePercent: z.string().optional(),
  ntnCnic: z.string().optional(),
  province: z.string().optional(),
  address: z.string().optional(),
  registrationType: z.string().optional(),
});
type PartyFormValues = z.infer<typeof partySchema>;

function emptyForm(): PartyFormValues {
  return { name: "", code: "", wastePercent: "", ntnCnic: "", province: "", address: "", registrationType: "Unregistered" };
}

function toForm(p: PartyRow): PartyFormValues {
  return {
    name: p.name,
    code: p.code,
    wastePercent: p.wastePercent ?? "",
    ntnCnic: p.ntnCnic ?? "",
    province: p.province ?? "",
    address: p.address ?? "",
    registrationType: p.registrationType ?? "Unregistered",
  };
}

export function PartySection() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<PartyRow | null>(null);
  const [pendingDelete, setPendingDelete] = useState<PartyRow | null>(null);
  const [search, setSearch] = useState("");

  const { data, isLoading } = useListPartyMasterCrud();
  const create = useCreatePartyMaster();
  const update = useUpdatePartyMaster();
  const remove = useDeletePartyMaster();

  const done = () => {
    void queryClient.invalidateQueries({ queryKey: getListPartyMasterCrudQueryKey() });
    void queryClient.invalidateQueries({ queryKey: getListPartyMasterQueryKey() });
    void queryClient.refetchQueries({ queryKey: getListPartyMasterQueryKey(), type: "all" });
  };

  const parties = (data ?? []) as unknown as PartyRow[];

  const form = useForm<PartyFormValues>({
    resolver: zodResolver(partySchema),
    defaultValues: emptyForm(),
  });

  const openCreate = () => {
    setEditing(null);
    form.reset(emptyForm());
    setDialogOpen(true);
  };
  const openEdit = (p: PartyRow) => {
    setEditing(p);
    form.reset(toForm(p));
    setDialogOpen(true);
  };

  const onSubmit = (values: PartyFormValues) => {
    const body = {
      name: values.name,
      code: values.code,
      wastePercent: values.wastePercent || undefined,
      ntnCnic: values.ntnCnic || null,
      province: values.province || null,
      address: values.address || null,
      registrationType: values.registrationType || "Unregistered",
    };
    const action = editing
      ? new Promise<void>((res, rej) =>
          update.mutate({ id: editing.id, data: body as never }, { onSuccess: () => { done(); res(); }, onError: rej }),
        )
      : new Promise<void>((res, rej) =>
          create.mutate({ data: body as never }, { onSuccess: () => { done(); res(); }, onError: rej }),
        );
    action
      .then(() => {
        toast({ title: editing ? "Party updated" : "Party added" });
        setDialogOpen(false);
      })
      .catch((e) => {
        toast({ title: "Could not save party", description: e?.message ?? "Something went wrong", variant: "destructive" });
      });
  };

  const removeWithConfirm = () => {
    if (!pendingDelete) return;
    remove.mutate({ id: pendingDelete.id }, {
      onSuccess: () => { done(); toast({ title: "Party deleted" }); setPendingDelete(null); },
      onError: (e) => {
        toast({
          title: "Failed to delete. It may be in use.",
          description: (e as { data?: { error?: string } })?.data?.error !== "Internal server error" ? (e as { data?: { error?: string } })?.data?.error : undefined,
          variant: "destructive",
        });
      },
    });
  };

  const trimmedSearch = search.trim().toLowerCase();
  const filtered = useMemo(
    () =>
      parties.filter((p) =>
        !trimmedSearch
          ? true
          : [p.name, p.code, p.ntnCnic, p.province, p.address].some((v) => (v ?? "").toLowerCase().includes(trimmedSearch)),
      ),
    [parties, trimmedSearch],
  );

  return (
    <>
      <div className="flex flex-col gap-5">
        {/* Header + Add, same stack as the other master screens. */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between sm:gap-6">
          <div>
            <h2 className="text-lg font-semibold leading-none text-foreground">Parties</h2>
            <p className="mt-2 max-w-prose text-sm text-muted-foreground sm:max-w-md">
              Business parties (customers, suppliers, contractors). The FBR buyer fields (NTN/CNIC, province,
              address, registration type) are used on digital invoices.
            </p>
          </div>
          <Button className="w-full shrink-0 sm:w-auto" onClick={openCreate}>
            <Plus className="mr-2 h-4 w-4" />
            Add new
          </Button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search parties…"
            className="h-9 pl-9"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h3 className="text-sm font-semibold text-foreground">All parties</h3>
            {!isLoading && parties && (
              <span className="eyebrow">
                <span className="num">
                  {trimmedSearch ? `${filtered.length} of ${parties.length} record${parties.length === 1 ? "" : "s"}` : `${parties.length} record${parties.length === 1 ? "" : "s"}`}
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
                    <TableHead>Code</TableHead>
                    <TableHead>Waste%</TableHead>
                    <TableHead>NTN/CNIC</TableHead>
                    <TableHead>Province</TableHead>
                    <TableHead>Address</TableHead>
                    <TableHead>Reg. Type</TableHead>
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
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-full" /></TableCell>
                        <TableCell><Skeleton className="h-5 w-16 ml-auto" /></TableCell>
                      </TableRow>
                    ))
                  ) : filtered.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="py-10 text-center text-muted-foreground">
                        {trimmedSearch ? `No parties match "${search.trim()}".` : "No parties recorded yet. Add the first one to get started."}
                      </TableCell>
                    </TableRow>
                  ) : (
                    filtered.map((p) => (
                      <TableRow key={p.id}>
                        <TableCell className="font-medium">{p.name}</TableCell>
                        <TableCell>{p.code}</TableCell>
                        <TableCell>{p.wastePercent ?? "—"}</TableCell>
                        <TableCell>{p.ntnCnic ?? "—"}</TableCell>
                        <TableCell>{p.province ?? "—"}</TableCell>
                        <TableCell className="max-w-[200px] truncate">{p.address ?? "—"}</TableCell>
                        <TableCell>
                          {p.registrationType ? (
                            <span
                              className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                                p.registrationType === "Registered"
                                  ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300"
                                  : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"
                              }`}
                            >
                              {p.registrationType}
                            </span>
                          ) : (
                            "—"
                          )}
                        </TableCell>
                        <TableCell className="sticky right-0 bg-background text-right">
                          <div className="flex justify-end gap-1">
                            <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" onClick={() => openEdit(p)} title="Edit">
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8" onClick={() => setPendingDelete(p)} title="Delete">
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

      {/* Add / edit dialog — contains all old + new party fields. */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit Party" : "Add Party"}</DialogTitle>
            <DialogDescription>Business party details. The FBR fields are used on digital invoices.</DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={form.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Name</FormLabel>
                      <FormControl><Input placeholder="e.g. Sunrise Textiles" {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="code"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Code</FormLabel>
                      <FormControl><Input placeholder="e.g. SUN" {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              <FormField
                control={form.control}
                name="wastePercent"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Waste %</FormLabel>
                    <FormControl><Input type="number" step="0.01" placeholder="1.00" {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="rounded-md border border-border p-3 space-y-4">
                <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">FBR Buyer Info</p>
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
                <div className="grid gap-4 sm:grid-cols-2">
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
                    name="registrationType"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Registration Type</FormLabel>
                        <FormControl>
                          <Select value={field.value || "Unregistered"} onValueChange={field.onChange}>
                            <SelectTrigger><SelectValue placeholder="Select type" /></SelectTrigger>
                            <SelectContent>
                              <SelectItem value="Registered">Registered</SelectItem>
                              <SelectItem value="Unregistered">Unregistered</SelectItem>
                            </SelectContent>
                          </Select>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
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
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
                <Button type="submit" disabled={create.isPending || update.isPending}>
                  {editing ? "Save Changes" : "Add Party"}
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
            <AlertDialogTitle>Delete party?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently remove <span className="font-semibold">{pendingDelete?.name}</span>. It can't be
              deleted if a transaction already uses it.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction className="bg-destructive text-destructive-foreground hover:bg-destructive/90" onClick={removeWithConfirm}>
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
