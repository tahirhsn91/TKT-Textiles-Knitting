import { useState, useMemo } from "react";
import { Send, Trash2, RefreshCw, FileText, StickyNote } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";

import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Spinner } from "@/components/ui/spinner";
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
import { useFbrSandboxEnabled } from "@/context/config-context";
import {
  useUninvoicedParties,
  useInvoicePreview,
  useListInvoices,
  useGenerateInvoice,
  usePostInvoice,
  useDeleteInvoice,
  type InvoiceListItem,
} from "@/hooks/use-fbr-invoicing";

const SALES_TAX_PERCENT = 18;

function money(n: number): string {
  return n.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export default function InvoicingPage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const fbrSandbox = useFbrSandboxEnabled();

  const [partyId, setPartyId] = useState<number | null>(null);
  const [enteredBy, setEnteredBy] = useState("");
  const [rates, setRates] = useState<Record<string, string>>({});
  const [pendingDelete, setPendingDelete] = useState<InvoiceListItem | null>(null);

  const { data: parties } = useUninvoicedParties();
  const { data: preview, isLoading: previewLoading, isFetching: previewFetching } = useInvoicePreview(partyId);
  const { data: invoices } = useListInvoices();

  const generate = useGenerateInvoice();
  const post = usePostInvoice();
  const remove = useDeleteInvoice();

  // Reset per-party state when the selected party changes.
  const selectParty = (v: string) => {
    setPartyId(Number(v));
    setRates({});
  };

  // Rows computed from preview groups + entered rates. Each row's rate keys off
  // its group (yarnTypeId|yarnCountId) — the same key the backend uses.
  const rows = useMemo(() => {
    if (!preview) return [];
    return preview.groups.map((g) => {
      const key = `${g.yarnTypeId}|${g.yarnCountId ?? ""}`;
      const rate = parseFloat(rates[key] ?? "");
      const qty = parseFloat(g.quantity) || 0;
      const value = Number.isFinite(rate) ? qty * rate : 0;
      const tax = (value * SALES_TAX_PERCENT) / 100;
      return { group: g, key, rate: Number.isFinite(rate) ? rate : 0, value, tax, total: value + tax };
    });
  }, [preview, rates]);

  const totals = useMemo(
    () =>
      rows.reduce(
        (a, r) => ({ value: a.value + r.value, tax: a.tax + r.tax, total: a.total + r.total }),
        { value: 0, tax: 0, total: 0 },
      ),
    [rows],
  );

  const allRatesSet = rows.length > 0 && rows.every((r) => r.rate > 0);

  const handleGenerate = () => {
    if (!partyId || !allRatesSet) return;
    generate.mutate(
      {
        partyId,
        createdBy: enteredBy || "operator",
        items: rows.map((r) => ({
          yarnTypeId: r.group.yarnTypeId,
          yarnCountId: r.group.yarnCountId,
          quantity: parseFloat(r.group.quantity) || 0,
          ratePerKg: r.rate,
        })),
      },
      {
        onSuccess: () => {
          toast({ title: "Invoice generated" });
          setPartyId(null);
          setRates({});
        },
        onError: (e) => toast({ title: "Could not generate invoice", description: e?.message, variant: "destructive" }),
      },
    );
  };

  const handlePost = (inv: InvoiceListItem) => {
    post.mutate(inv.id, {
      onSuccess: (d) => toast({ title: "Invoice posted to FBR", description: d.invoice.fbrInvoiceNumber ?? undefined }),
      onError: (e) =>
        toast({
          title: "FBR rejected posting",
          description: (e as { message?: string })?.message ?? "Check the FBR response",
          variant: "destructive",
        }),
    });
  };

  return (
    <Layout>
      <div className="space-y-5">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Invoicing</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Generate a digital invoice per party from un-invoiced fabric deliveries, then post it to FBR.
          </p>
        </div>

        {/* Environment banner */}
        <div
          className={`flex items-center gap-2 rounded-md border px-3 py-2 text-sm ${
            fbrSandbox
              ? "border-amber-300 bg-amber-50 text-amber-800 dark:border-amber-800 dark:bg-amber-950/40 dark:text-amber-300"
              : "border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-300"
          }`}
        >
          <span className={`inline-block h-2 w-2 rounded-full ${fbrSandbox ? "bg-amber-500" : "bg-emerald-500"}`} />
          Posting to <span className="font-semibold">{fbrSandbox ? "FBR Sandbox" : "FBR Production"}</span> environment
          <span className="ml-auto text-xs opacity-70">(Configuration &mdash; FBR DI Sandbox)</span>
        </div>

        {/* Generate invoice card */}
        <Card className="border-sidebar-border">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base"><StickyNote className="h-4 w-4" /> Generate Invoice</CardTitle>
            <CardDescription>
              Pick a party with un-invoiced Fabric Delivery transactions. Net weights are summed per yarn
              type/count; enter a per-KG rate for each line to compute value, 18% sales tax, and total.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Party</Label>
                <Select value={partyId != null ? String(partyId) : undefined} onValueChange={selectParty}>
                  <SelectTrigger className="w-full"><SelectValue placeholder="Select party with un-invoiced deliveries" /></SelectTrigger>
                  <SelectContent>
                    {(parties ?? []).map((p) => (
                      <SelectItem key={p.partyId} value={String(p.partyId)}>
                        {p.partyName} ({p.transactionCount} tx, {p.totalNetWeight} kg)
                      </SelectItem>
                    ))}
                    {(parties ?? []).length === 0 && (
                      <div className="px-3 py-2 text-sm text-muted-foreground">No parties have un-invoiced deliveries</div>
                    )}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Entered by</Label>
                <Input placeholder="Your name" value={enteredBy} onChange={(e) => setEnteredBy(e.target.value)} />
              </div>
            </div>

            {partyId != null && (
              <div>
                {previewLoading || previewFetching ? (
                  <div className="space-y-2">
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                  </div>
                ) : preview && preview.groups.length === 0 ? (
                  <p className="rounded-md border border-border p-4 text-center text-sm text-muted-foreground">
                    No un-invoiced Fabric Delivery transactions for this party.
                  </p>
                ) : (
                  <div className="rounded-md border border-border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Yarn Type</TableHead>
                          <TableHead>Count</TableHead>
                          <TableHead>HS Code</TableHead>
                          <TableHead>UOM</TableHead>
                          <TableHead className="text-right">Net Wt (kg)</TableHead>
                          <TableHead className="text-right">Rate / kg</TableHead>
                          <TableHead className="text-right">Value</TableHead>
                          <TableHead className="text-right">Tax (18%)</TableHead>
                          <TableHead className="text-right">Total</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {rows.map((r) => (
                          <TableRow key={r.key}>
                            <TableCell className="font-medium">{r.group.yarnTypeName ?? "—"}</TableCell>
                            <TableCell>{r.group.yarnCountName ?? "—"}</TableCell>
                            <TableCell>{r.group.hsCode ?? "—"}</TableCell>
                            <TableCell>{r.group.uoM ?? "—"}</TableCell>
                            <TableCell className="text-right tabular-nums">{r.group.quantity}</TableCell>
                            <TableCell className="text-right">
                              <Input
                                type="number"
                                min="0"
                                step="0.01"
                                className="ml-auto h-8 w-28 text-right"
                                placeholder="Rate"
                                value={rates[r.key] ?? ""}
                                onChange={(e) => setRates((prev) => ({ ...prev, [r.key]: e.target.value }))}
                              />
                            </TableCell>
                            <TableCell className="text-right tabular-nums">{money(r.value)}</TableCell>
                            <TableCell className="text-right tabular-nums">{money(r.tax)}</TableCell>
                            <TableCell className="text-right tabular-nums">{money(r.total)}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border bg-muted/30 px-4 py-3">
                      <div className="text-sm">
                        <span className="text-muted-foreground">Total value </span>
                        <span className="font-semibold">{money(totals.value)}</span>
                        <span className="mx-2 text-muted-foreground">·</span>
                        <span className="text-muted-foreground">Tax </span>
                        <span className="font-semibold">{money(totals.tax)}</span>
                        <span className="mx-2 text-muted-foreground">·</span>
                        <span className="text-muted-foreground">Grand total </span>
                        <span className="font-semibold">{money(totals.total)}</span>
                      </div>
                      <Button onClick={handleGenerate} disabled={!allRatesSet || generate.isPending} className="gap-2">
                        {generate.isPending ? <Spinner className="h-4 w-4" /> : <FileText className="h-4 w-4" />}
                        Generate Invoice
                      </Button>
                    </div>
                    {!allRatesSet && rows.length > 0 && (
                      <p className="px-4 pb-3 text-xs text-muted-foreground">Enter a rate for every line to generate.</p>
                    )}
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Invoice list */}
        <Card className="border-sidebar-border">
          <CardHeader>
            <CardTitle className="text-base">Invoices</CardTitle>
            <CardDescription>Draft invoices can be posted or deleted; posted invoices are read-only.</CardDescription>
          </CardHeader>
          <CardContent className="px-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>#</TableHead>
                  <TableHead>Invoice Date</TableHead>
                  <TableHead>Party</TableHead>
                  <TableHead>Company</TableHead>
                  <TableHead className="text-right">Grand Total</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>FBR No.</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {(invoices ?? []).length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="py-8 text-center text-muted-foreground">No invoices yet.</TableCell>
                  </TableRow>
                ) : (
                  (invoices ?? []).map((inv) => (
                    <TableRow key={inv.id}>
                      <TableCell className="font-medium">#{inv.id}</TableCell>
                      <TableCell>{format(new Date(inv.invoiceDate), "dd MMM yyyy")}</TableCell>
                      <TableCell>{inv.partyName}</TableCell>
                      <TableCell>{inv.companyName}</TableCell>
                      <TableCell className="text-right tabular-nums">{money(parseFloat(inv.grandTotal))}</TableCell>
                      <TableCell>
                        <span
                          className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                            inv.status === "posted"
                              ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300"
                              : "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300"
                          }`}
                        >
                          {inv.status}
                        </span>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{inv.fbrInvoiceNumber ?? "—"}</TableCell>
                      <TableCell className="text-right">
                        {inv.status === "draft" ? (
                          <div className="flex justify-end gap-1">
                            <Button variant="outline" size="sm" className="gap-1.5" onClick={() => handlePost(inv)} disabled={post.isPending}>
                              <Send className="h-4 w-4" /> Post
                            </Button>
                            <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive" onClick={() => setPendingDelete(inv)} title="Delete">
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        ) : (
                          <span className="text-xs text-muted-foreground">Read-only</span>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      {/* Delete confirm (draft only) */}
      <AlertDialog open={pendingDelete != null} onOpenChange={(o) => !o && setPendingDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete draft invoice?</AlertDialogTitle>
            <AlertDialogDescription>
              Deleting invoice #{pendingDelete?.id} will un-invoice its fabric delivery transactions, making them
              available to generate a new invoice. Draft invoices can be deleted; posted invoices cannot.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={() =>
                pendingDelete &&
                remove.mutate(pendingDelete.id, {
                  onSuccess: () => toast({ title: "Invoice deleted" }),
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
