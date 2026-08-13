import { useState, useMemo, useEffect, type ReactNode } from "react";
import { Send, Trash2, RefreshCw, FileText, Eye, Download } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";

import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
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
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { useFbrSandboxEnabled } from "@/context/config-context";
import {
  useUninvoicedParties,
  useInvoicePreview,
  useListInvoices,
  useInvoiceDetail,
  useGenerateInvoice,
  usePostInvoice,
  useDeleteInvoice,
  type InvoiceListItem,
  type InvoiceDetail,
} from "@/hooks/use-fbr-invoicing";
import { downloadInvoicePdf, amountInWords } from "@/lib/invoice-pdf";

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
  const [viewingId, setViewingId] = useState<number | null>(null);

  const { data: parties } = useUninvoicedParties();
  const { data: preview, isLoading: previewLoading, isFetching: previewFetching } = useInvoicePreview(partyId);
  const { data: invoices } = useListInvoices();
  const { data: viewing, isLoading: viewingLoading } = useInvoiceDetail(viewingId);

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

  // One detail query drives both the View dialog and the PDF download. When
  // a download is requested we re-point the detail query at that id; once the
  // items arrive the effect below builds the PDF.
  const [downloadTarget, setDownloadTarget] = useState<number | null>(null);
  useEffect(() => {
    if (downloadTarget != null && viewing && viewing.id === downloadTarget && !viewingLoading) {
      downloadInvoicePdf(viewing);
      setDownloadTarget(null);
    }
  }, [downloadTarget, viewing, viewingLoading]);

  const handleDownloadPdf = (invoiceId: number) => {
    setViewingId(invoiceId);
    setDownloadTarget(invoiceId);
  };

  const handleView = (invoiceId: number) => setViewingId(invoiceId);

  return (
    <Layout>
      <div className="flex flex-col gap-6">
        {/* Page header — matches the rest of the app (eyebrow + 1.75rem title
            on a hairline rule) rather than the old text-xl treatment. */}
        <header className="border-b pb-5">
          <p className="eyebrow">Billing &amp; invoicing</p>
          <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">Invoicing</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Generate a digital invoice per party from un-invoiced fabric deliveries, then post it to FBR.
          </p>
        </header>

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

        {/* Generate invoice card (same treatment as the app's other list cards) */}
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h2 className="text-sm font-semibold text-foreground">Generate Invoice</h2>
            <span className="eyebrow">{fbrSandbox ? "FBR sandbox" : "FBR production"}</span>
          </div>
          <CardContent className="space-y-4 p-5">
            <p className="text-sm text-muted-foreground">
              Pick a party with un-invoiced Fabric Delivery transactions. Net weights are summed per yarn
              type/count; enter a per-KG rate for each line to compute value, 18% sales tax, and total.
            </p>
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

        {/* Invoice list (same treatment as the app's other list cards) */}
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h2 className="text-sm font-semibold text-foreground">Invoices</h2>
            <span className="eyebrow">Draft · Posted</span>
          </div>
          <CardContent className="p-0">
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
                          <div className="flex justify-end">
                            <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" title="View" onClick={() => handleView(inv.id)}>
                              <Eye className="h-4 w-4" />
                            </Button>
                            <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" title="Download PDF" onClick={() => handleDownloadPdf(inv.id)}>
                              <Download className="h-4 w-4" />
                            </Button>
                          </div>
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
      {/* View invoice detail — mirrors the FBR "SALES TAX INVOICE" PDF layout */}
      <Dialog open={viewingId != null} onOpenChange={(o) => { if (!o) { setViewingId(null); setDownloadTarget(null); } }}>
        <DialogContent className="sm:max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader className="sr-only">
            <DialogTitle>Invoice #{viewing?.id ?? ""}</DialogTitle>
            <DialogDescription>
              {viewing?.status === "posted"
                ? `Reported to FBR · ${viewing.fbrInvoiceNumber ?? "no FBR number"}`
                : "Draft invoice — not yet posted to FBR."}
            </DialogDescription>
          </DialogHeader>
          {viewingLoading && !viewing ? (
            <div className="space-y-2"><Skeleton className="h-4 w-full" /><Skeleton className="h-4 w-full" /></div>
          ) : viewing ? (
            <InvoiceView inv={viewing} onDownload={() => downloadInvoicePdf(viewing)} />
          ) : null}
        </DialogContent>
      </Dialog>
    </Layout>
  );
}

// ─── Invoice view (mirrors the FBR "SALES TAX INVOICE" PDF) ────────────────
// A small label/value row used inside the boxed detail sections.
function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-2 py-0.5 text-[13px] leading-snug">
      <span className="w-28 shrink-0 text-muted-foreground">{label}</span>
      <span className="font-medium">{value}</span>
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="rounded-md border border-foreground/20">
      <div className="border-b border-foreground/20 bg-muted px-3 py-1.5 text-xs font-bold uppercase tracking-wide">
        {title}
      </div>
      <div className="px-3 py-2">{children}</div>
    </div>
  );
}

function InvoiceView({ inv, onDownload }: { inv: InvoiceDetail; onDownload: () => void }) {
  const invDate = (() => {
    try {
      return format(new Date(inv.invoiceDate + "T00:00:00"), "dd-MMM-yyyy").toUpperCase();
    } catch {
      return inv.invoiceDate;
    }
  })();
  const custAddr = [inv.partyAddress, inv.partyProvince].filter(Boolean).join(", ");
  const words = amountInWords(inv.grandTotal);

  return (
    <div className="space-y-4 text-foreground">
      {/* Header: company (left) + SALES TAX INVOICE badge (right) */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h2 className="text-lg font-bold uppercase leading-tight">{inv.companyName ?? "TKT TEXTILES"}</h2>
          {inv.companyAddress && (
            <p className="mt-0.5 max-w-xs text-xs text-muted-foreground">{inv.companyAddress}</p>
          )}
        </div>
        <div className="rounded bg-foreground px-4 py-2 text-sm font-bold uppercase tracking-wide text-background">
          Sales Tax Invoice
        </div>
      </div>

      {/* Supplier + Transaction */}
      <div className="grid gap-3 sm:grid-cols-2">
        <Section title="Supplier Details">
          <Field label="Name:" value={(inv.companyName ?? "—").toUpperCase()} />
          <Field label="NTN / CNIC:" value={inv.companyNtnCnic ?? "—"} />
          <Field label="Address:" value={inv.companyAddress ?? "—"} />
        </Section>
        <Section title="Transaction Details">
          <Field label="Transaction No.:" value={String(inv.id).padStart(8, "0")} />
          <Field label="Transaction Date:" value={invDate} />
          <Field label="Transaction Type:" value={inv.items[0]?.saleType ?? "Goods at standard rate (default)"} />
          <Field label="FBR Invoice No.:" value={inv.fbrInvoiceNumber ?? "—"} />
          <Field label="Site Name:" value="Head Office" />
          <Field label="Store Name:" value="Store 01" />
        </Section>
      </div>

      {/* Customer */}
      <div className="grid gap-3 sm:grid-cols-2">
        <Section title="Customer Details">
          <Field label="Name:" value={(inv.partyName ?? "—").toUpperCase()} />
          <Field label="NTN:" value={inv.partyNtnCnic ?? "—"} />
          <Field label="Address:" value={custAddr || "—"} />
        </Section>
      </div>

      {/* Line-item table */}
      <div className="overflow-x-auto rounded-md border border-foreground/20">
        <table className="w-full border-collapse text-[13px]">
          <thead>
            <tr className="bg-muted text-left [&>th]:border-r [&>th]:border-foreground/20 [&>th]:px-2 [&>th]:py-2 [&>th]:align-middle [&>th]:font-bold last:[&>th]:border-r-0">
              <th className="w-10 text-center">S. #</th>
              <th>Description</th>
              <th className="w-14">UOM</th>
              <th className="text-right">Quantity</th>
              <th className="text-right">Price</th>
              <th className="text-right">Taxes Exclusive Value</th>
              <th className="text-center">Tax Rate</th>
              <th className="text-right">Tax Amount</th>
              <th className="text-right">Taxes Inclusive Value</th>
            </tr>
          </thead>
          <tbody>
            {inv.items.map((it, idx) => (
              <tr
                key={it.id}
                className="border-t border-foreground/20 [&>td]:border-r [&>td]:border-foreground/20 [&>td]:px-2 [&>td]:py-2 [&>td]:align-middle last:[&>td]:border-r-0"
              >
                <td className="text-center tabular-nums">{idx + 1}</td>
                <td>
                  {(it.hsCode ? `${it.hsCode} - ` : "") + (it.yarnTypeName ?? "—")}
                  {it.yarnCountName ? ` (${it.yarnCountName})` : ""}
                </td>
                <td>{it.uoM ?? "KG"}</td>
                <td className="text-right tabular-nums">{money(parseFloat(it.quantity))}</td>
                <td className="text-right tabular-nums">{money(parseFloat(it.ratePerKg))}</td>
                <td className="text-right tabular-nums">{money(parseFloat(it.valueExcludingTax))}</td>
                <td className="text-center tabular-nums">18%</td>
                <td className="text-right tabular-nums">{money(parseFloat(it.taxAmount))}</td>
                <td className="text-right tabular-nums">{money(parseFloat(it.totalValue))}</td>
              </tr>
            ))}
            {/* Amount-in-words row carrying the column totals */}
            <tr className="border-t border-foreground/20 font-bold [&>td]:px-2 [&>td]:py-2 [&>td]:align-middle">
              <td colSpan={5}>{words}</td>
              <td className="border-l border-foreground/20 text-right tabular-nums">{money(parseFloat(inv.totalValue))}</td>
              <td className="border-l border-foreground/20" />
              <td className="border-l border-foreground/20 text-right tabular-nums">{money(parseFloat(inv.totalTax))}</td>
              <td className="border-l border-foreground/20 text-right tabular-nums">{money(parseFloat(inv.grandTotal))}</td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* Totals summary box (right) */}
      <div className="flex justify-end">
        <div className="w-full max-w-sm overflow-hidden rounded-md border border-foreground/20 text-sm">
          <div className="flex justify-between border-b border-foreground/20 px-3 py-2">
            <span>Total Taxes Exclusive Value</span>
            <span className="font-semibold tabular-nums">{money(parseFloat(inv.totalValue))}</span>
          </div>
          <div className="flex justify-between border-b border-foreground/20 px-3 py-2">
            <span>Total Tax Amount @ 18%</span>
            <span className="font-semibold tabular-nums">{money(parseFloat(inv.totalTax))}</span>
          </div>
          <div className="flex justify-between px-3 py-2 font-bold">
            <span>Total Taxes Inclusive Value</span>
            <span className="tabular-nums">{money(parseFloat(inv.grandTotal))}</span>
          </div>
        </div>
      </div>

      {/* Footer note + download */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border pt-3">
        <p className="text-xs text-muted-foreground">
          This is a computer generated document. No signature is required.
        </p>
        {inv.status === "posted" && (
          <Button variant="outline" className="gap-2" onClick={onDownload}>
            <Download className="h-4 w-4" /> Download PDF
          </Button>
        )}
      </div>
    </div>
  );
}
