import { useState, useMemo, useEffect, type ReactNode } from "react";
import { Send, Trash2, RefreshCw, FileText, Eye, Download, Plus, Banknote, CalendarPlus } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";

import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Spinner } from "@/components/ui/spinner";
import { Skeleton } from "@/components/ui/skeleton";
import { SortableHead as SortHead } from "@/components/sortable-head";
import { useSort } from "@/hooks/use-sort";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { MultiSelect } from "@/components/ui/multi-select";
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
  DialogFooter,
} from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { useCurrentUserDisplayName } from "@/hooks/use-current-user";
import { useFbrSandboxEnabled } from "@/context/config-context";
import {
  useUninvoicedParties,
  useInvoicePreview,
  useListInvoices,
  useInvoiceDetail,
  useGenerateInvoice,
  usePostInvoice,
  useDeleteInvoice,
  useCreatePayment,
  useDeletePayment,
  useReceivables,
  useAllowBackdatedInvoices,
  useCreateBackdatedInvoice,
  useListPartiesForInvoicing,
  type InvoiceListItem,
  type InvoiceDetail,
  type InvoicePayment,
} from "@/hooks/use-fbr-invoicing";
import { useListYarnTypeMaster, useListYarnCountMaster } from "@workspace/api-client-react";
import { downloadInvoicePdf, amountInWords } from "@/lib/invoice-pdf";

const SALES_TAX_PERCENT = 18;

function money(n: number): string {
  return n.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/** Payment state for a listed invoice (derived from the detail fields). */
function paymentState(inv: { status: string; paid: boolean; overdue: boolean; outstanding: number; dueDate: string | null; origin?: string }) {
  if (inv.status !== "posted") return null;
  return {
    label: inv.paid ? (inv.outstanding < 0 ? "Overpaid" : "Paid") : inv.overdue ? "Overdue" : "Pending",
    overdue: inv.overdue,
    paid: inv.paid,
    outstanding: inv.outstanding,
    dueDate: inv.dueDate,
    origin: inv.origin,
  };
}

/** Due-status label for an invoice; null for drafts (no due state). */
function dueStatusOf(inv: { status: string; paid?: boolean; outstanding?: number; overdue?: boolean }): string | null {
  if (inv.status !== "posted") return null;
  const outstanding = inv.outstanding ?? parseFloat((inv as { grandTotal?: string }).grandTotal ?? "0");
  if (inv.paid && (outstanding ?? 0) < 0) return "overpaid";
  if (inv.paid) return "paid";
  if (inv.overdue) return "overdue";
  return "pending";
}

export default function InvoicingPage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const fbrSandbox = useFbrSandboxEnabled();

  const [partyId, setPartyId] = useState<number | null>(null);
  const enteredBy = useCurrentUserDisplayName();
  const [rates, setRates] = useState<Record<string, string>>({});
  const [pendingDelete, setPendingDelete] = useState<InvoiceListItem | null>(null);
  const [viewingId, setViewingId] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<"invoices" | "receivables">("invoices");

  // Invoice table filters: multi-select Party, Status, and Due Status, each
  // defaulting to show everything (empty selection = no restriction).
  const [partySel, setPartySel] = useState<string[]>([]);
  const [statusSel, setStatusSel] = useState<string[]>(["draft", "posted"]);
  const [dueSel, setDueSel] = useState<string[]>(["pending", "overdue"]);

  // Payment dialog state
  const [payFor, setPayFor] = useState<InvoiceListItem | null>(null);
  const [payAmount, setPayAmount] = useState("");
  const [payTax, setPayTax] = useState("");
  const [payDate, setPayDate] = useState("");
  const [payMethod, setPayMethod] = useState("Bank Transfer");
  const [payRef, setPayRef] = useState("");
  const [payNotes, setPayNotes] = useState("");
  const [deletePayment, setDeletePayment] = useState<{ inv: InvoiceListItem | InvoiceDetail; payment: InvoicePayment } | null>(null);

  // Backdated dialog state
  const [backdatedOpen, setBackdatedOpen] = useState(false);
  const { data: allowBackdated } = useAllowBackdatedInvoices();

  const { data: parties } = useUninvoicedParties();
  const { data: preview, isLoading: previewLoading, isFetching: previewFetching } = useInvoicePreview(partyId);
  const { data: invoices } = useListInvoices();
  const { data: viewing, isLoading: viewingLoading } = useInvoiceDetail(viewingId);
  const { data: receivables } = useReceivables();
  const { data: allParties } = useListPartiesForInvoicing();

  const generate = useGenerateInvoice();
  const post = usePostInvoice();
  const remove = useDeleteInvoice();
  const addPayment = useCreatePayment();
  const removePayment = useDeletePayment();
  const createBackdated = useCreateBackdatedInvoice();

  // Distinct parties present in the invoices, for the Party filter.
  const invoiceParties = useMemo(() => {
    const map = new Map<number, string>();
    for (const inv of invoices ?? []) {
      if (inv.partyId != null && inv.partyName) map.set(inv.partyId, inv.partyName);
    }
    return Array.from(map.entries())
      .map(([id, name]) => ({ id, name }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [invoices]);

  // Filter by party, status, and due status (multi-select; empty = all).
  const filteredInvoices = useMemo(() => {
    const partySet = new Set(partySel);
    const statusSet = new Set(statusSel);
    const dueSet = new Set(dueSel);
    return (invoices ?? []).filter((inv) => {
      if (partySel.length > 0 && (inv.partyId == null || !partySet.has(String(inv.partyId)))) return false;
      if (statusSel.length > 0 && !statusSet.has(inv.status)) return false;
      if (dueSel.length > 0) {
        const ds = dueStatusOf(inv);
        if (ds === null || !dueSet.has(ds)) return false;
      }
      return true;
    });
  }, [invoices, partySel, statusSel, dueSel]);

  // Grand total of the filtered invoices (sum of Grand Total column).
  const filteredGrandTotal = useMemo(
    () => (filteredInvoices ?? []).reduce((s, inv) => s + (parseFloat(inv.grandTotal) || 0), 0),
    [filteredInvoices],
  );

  // Client-side sorting (all list endpoints here return the full set).
  // Default: newest invoice first.
  const { sorted: sortedInvoices, sort: sortState, toggleSort } = useSort<
    InvoiceListItem,
    "id" | "invoiceDate" | "partyName" | "companyName" | "grandTotal" | "status" | "fbrInvoiceNumber"
  >(
    filteredInvoices,
    {
      id: (inv) => inv.id,
      invoiceDate: (inv) => inv.invoiceDate,
      partyName: (inv) => inv.partyName ?? "",
      companyName: (inv) => inv.companyName ?? "",
      grandTotal: (inv) => parseFloat(inv.grandTotal) || 0,
      status: (inv) => inv.status,
      fbrInvoiceNumber: (inv) => inv.fbrInvoiceNumber ?? "",
    },
    { key: "invoiceDate", dir: "desc" },
  );
  const handleSortInvoice = (key: string) => toggleSort(key);

  // Reset per-party state when the selected party changes.
  const selectParty = (v: string) => {
    setPartyId(Number(v));
    setRates({});
  };

  // Rows computed from preview groups + entered rates.
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
      onSuccess: (d) => {
        const unregistered = d.invoice.origin === "local";
        toast({
          title: unregistered ? "Invoice marked posted (unregistered party)" : "Invoice posted to FBR",
          description: unregistered ? "Not sent to FBR — party is unregistered." : d.invoice.fbrInvoiceNumber ?? undefined,
        });
      },
      onError: (e) =>
        toast({
          title: "Posting failed",
          description: (e as { message?: string })?.message ?? "Check the response",
          variant: "destructive",
        }),
    });
  };

  // Open the Record Payment dialog pre-filled for an invoice.
  const openPayment = (inv: InvoiceListItem) => {
    setPayFor(inv);
    setPayAmount("");
    setPayTax("0");
    setPayDate(new Date().toISOString().slice(0, 10));
    setPayMethod("Bank Transfer");
    setPayRef("");
    setPayNotes("");
  };

  const submitPayment = () => {
    if (!payFor) return;
    const amount = parseFloat(payAmount);
    const tax = parseFloat(payTax) || 0;
    if (!Number.isFinite(amount) || amount <= 0) {
      toast({ title: "Enter a valid amount", variant: "destructive" });
      return;
    }
    addPayment.mutate(
      {
        id: payFor.id,
        body: {
          amount,
          taxDeduction: Math.max(0, Math.min(tax, amount)),
          paymentDate: payDate || new Date().toISOString().slice(0, 10),
          method: payMethod,
          reference: payRef || null,
          notes: payNotes || null,
        },
      },
      {
        onSuccess: () => {
          toast({ title: "Payment recorded" });
          setPayFor(null);
        },
        onError: (e) => toast({ title: "Could not record payment", description: e?.message, variant: "destructive" }),
      },
    );
  };

  const confirmDeletePayment = () => {
    if (!deletePayment) return;
    removePayment.mutate(
      { id: deletePayment.inv.id, paymentId: deletePayment.payment.id },
      {
        onSuccess: () => {
          toast({ title: "Payment deleted" });
          setDeletePayment(null);
        },
        onError: (e) => toast({ title: "Could not delete payment", description: e?.message, variant: "destructive" }),
      },
    );
  };

  // One detail query drives both the View dialog and the PDF download.
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
        <header className="border-b pb-5">
          <p className="eyebrow">Billing &amp; invoicing</p>
          <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">Invoicing</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Generate a digital invoice per party from un-invoiced fabric deliveries, post it, and track payments.
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

        {/* Tabs: Invoices + Receivables (issue #189) */}
        <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as "invoices" | "receivables")}>
          <div className="flex items-center justify-between gap-2 flex-wrap">
            <TabsList>
              <TabsTrigger value="invoices">Invoices</TabsTrigger>
              <TabsTrigger value="receivables">Receivables</TabsTrigger>
            </TabsList>
            {activeTab === "receivables" && (
              <Button variant="outline" size="sm" className="gap-1.5" onClick={() => queryClient.invalidateQueries({ queryKey: ["/api/invoicing/receivables"] })}>
                <RefreshCw className="h-3.5 w-3.5" /> Refresh
              </Button>
            )}
          </div>

          <TabsContent value="invoices" className="space-y-4 mt-3">
            {/* Generate invoice card */}
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
                    <Input placeholder="Your name" value={enteredBy} disabled />
                  </div>
                </div>

                {/* Backdated invoice button (only when toggle enabled) */}
                {allowBackdated && (
                  <div className="flex justify-end">
                    <Button variant="outline" size="sm" className="gap-1.5" onClick={() => setBackdatedOpen(true)}>
                      <CalendarPlus className="h-4 w-4" /> Create Backdated Invoice
                    </Button>
                  </div>
                )}

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
            <Card className="overflow-hidden">
              <div className="flex flex-wrap items-center justify-between gap-x-4 gap-y-2 border-b px-5 py-3">
                <h2 className="text-sm font-semibold text-foreground">Invoices</h2>
                <div className="flex items-center gap-2 flex-wrap">
                  <label className="flex items-center gap-2 text-xs text-muted-foreground">
                    Party
                    <MultiSelect
                      options={invoiceParties.map((p) => ({ value: String(p.id), label: p.name }))}
                      selected={partySel}
                      onChange={setPartySel}
                      placeholder="All"
                      className="w-44"
                    />
                  </label>
                  <label className="flex items-center gap-2 text-xs text-muted-foreground">
                    Status
                    <MultiSelect
                      options={[
                        { value: "draft", label: "Draft" },
                        { value: "posted", label: "Posted" },
                      ]}
                      selected={statusSel}
                      onChange={setStatusSel}
                      placeholder="All"
                      className="w-32"
                    />
                  </label>
                  <label className="flex items-center gap-2 text-xs text-muted-foreground">
                    Due Status
                    <MultiSelect
                      options={[
                        { value: "pending", label: "Pending" },
                        { value: "overdue", label: "Overdue" },
                        { value: "paid", label: "Paid" },
                        { value: "overpaid", label: "Overpaid" },
                      ]}
                      selected={dueSel}
                      onChange={setDueSel}
                      placeholder="All"
                      className="w-36"
                    />
                  </label>
                  <span className="eyebrow">Draft · Posted</span>
                </div>
              </div>
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <SortHead label="#" sortKey="id" sort={sortState} onSort={handleSortInvoice} />
                      <SortHead label="Invoice Date" sortKey="invoiceDate" sort={sortState} onSort={handleSortInvoice} />
                      <SortHead label="Party" sortKey="partyName" sort={sortState} onSort={handleSortInvoice} />
                      <SortHead label="Company" sortKey="companyName" sort={sortState} onSort={handleSortInvoice} />
                      <SortHead label="Grand Total" sortKey="grandTotal" sort={sortState} onSort={handleSortInvoice} right />
                      <SortHead label="Status" sortKey="status" sort={sortState} onSort={handleSortInvoice} />
                      <SortHead label="FBR No." sortKey="fbrInvoiceNumber" sort={sortState} onSort={handleSortInvoice} />
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {sortedInvoices.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={8} className="py-8 text-center text-muted-foreground">
                          {partySel.length > 0 || statusSel.length > 0 || dueSel.length > 0 ? "No invoices match the selected filters." : "No invoices yet."}
                        </TableCell>
                      </TableRow>
                    ) : (
                      sortedInvoices.map((inv) => (
                        <TableRow key={inv.id}>
                          <TableCell className="font-medium">#{inv.id}</TableCell>
                          <TableCell>{format(new Date(inv.invoiceDate), "dd MMM yyyy")}</TableCell>
                          <TableCell>{inv.partyName}</TableCell>
                          <TableCell>{inv.companyName}</TableCell>
                          <TableCell className="text-right tabular-nums">{money(parseFloat(inv.grandTotal))}</TableCell>
                          <TableCell>
                            <div className="flex flex-col gap-1">
                              <span
                                className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                                  inv.status === "posted"
                                    ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300"
                                    : "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300"
                                }`}
                              >
                                {inv.status}
                              </span>
                              <PaymentBadge inv={inv} />
                            </div>
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
                              <div className="flex justify-end gap-1">
                                <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" title="View" onClick={() => handleView(inv.id)}>
                                  <Eye className="h-4 w-4" />
                                </Button>
                                <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" title="Download PDF" onClick={() => handleDownloadPdf(inv.id)}>
                                  <Download className="h-4 w-4" />
                                </Button>
                                <Button variant="outline" size="sm" className="gap-1.5" onClick={() => openPayment(inv)} disabled={addPayment.isPending}>
                                  <Banknote className="h-4 w-4" /> Record Payment
                                </Button>
                              </div>
                            )}
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                    {sortedInvoices.length > 0 && (
                      <TableRow className="bg-muted/50 font-semibold">
                        <TableCell colSpan={4} className="whitespace-nowrap">
                          Grand Total ({sortedInvoices.length} invoice{sortedInvoices.length === 1 ? "" : "s"})
                        </TableCell>
                        <TableCell className="text-right tabular-nums text-foreground">{money(filteredGrandTotal)}</TableCell>
                        <TableCell colSpan={3} />
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Receivables tab */}
          <TabsContent value="receivables" className="mt-3 space-y-4">
            <ReceivablesView data={receivables} loading={!receivables} />
          </TabsContent>
        </Tabs>
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

      {/* Record Payment dialog */}
      <Dialog open={payFor != null} onOpenChange={(o) => {
        if (!o) setPayFor(null);
      }}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Record Payment — Invoice #{payFor?.id}</DialogTitle>
            <DialogDescription>Record a payment received against this invoice. Amount is gross; tax deduction is withholding tax (net = amount − tax).</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="rounded-md border border-border bg-muted/30 px-3 py-2 text-sm">
              <span className="text-muted-foreground">Grand total </span>
              <span className="font-semibold">{payFor ? money(parseFloat(payFor.grandTotal)) : ""}</span>
              <span className="mx-2 text-muted-foreground">·</span>
              <span className="text-muted-foreground">Outstanding </span>
              <span className="font-semibold">{payFor ? money(payFor.outstanding ?? parseFloat(payFor.grandTotal)) : ""}</span>
            </div>
            <div className="space-y-1.5">
              <Label>Amount (gross)</Label>
              <Input type="number" min="0" step="0.01" value={payAmount} onChange={(e) => setPayAmount(e.target.value)} placeholder="0.00" />
            </div>
            <div className="space-y-1.5">
              <Label>Tax Deduction (WHT)</Label>
              <Input type="number" min="0" step="0.01" value={payTax} onChange={(e) => setPayTax(e.target.value)} placeholder="0.00" />
            </div>
            <div className="space-y-1.5">
              <Label>Payment Date</Label>
              <Input type="date" value={payDate} onChange={(e) => setPayDate(e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label>Method</Label>
              <Select value={payMethod} onValueChange={setPayMethod}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {["Bank Transfer", "Cash", "Cheque", "Other"].map((m) => (
                    <SelectItem key={m} value={m}>{m}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Reference</Label>
              <Input value={payRef} onChange={(e) => setPayRef(e.target.value)} placeholder="Cheque no. / bank ref" />
            </div>
            <div className="space-y-1.5">
              <Label>Notes</Label>
              <Textarea rows={2} value={payNotes} onChange={(e) => setPayNotes(e.target.value)} />
            </div>
            {(parseFloat(payAmount) > 0) && (
              <p className="text-xs text-muted-foreground">
                Net applied: <span className="font-semibold">{money((parseFloat(payAmount) || 0) - (parseFloat(payTax) || 0))}</span>
              </p>
            )}
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setPayFor(null)}>Cancel</Button>
            <Button type="button" onClick={submitPayment} disabled={addPayment.isPending} className="gap-2">
              {addPayment.isPending ? <Spinner className="h-4 w-4" /> : <Banknote className="h-4 w-4" />}
              Record Payment
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete payment confirm */}
      <AlertDialog open={deletePayment != null} onOpenChange={(o) => !o && setDeletePayment(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete payment?</AlertDialogTitle>
            <AlertDialogDescription>
              This removes the payment of {deletePayment ? money(parseFloat(deletePayment.payment.amount)) : ""} from invoice #{deletePayment?.inv.id}. The outstanding balance updates automatically.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction className="bg-destructive text-destructive-foreground hover:bg-destructive/90" onClick={confirmDeletePayment}>
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* View invoice detail */}
      <Dialog open={viewingId != null} onOpenChange={(o) => { if (!o) { setViewingId(null); setDownloadTarget(null); } }}>
        <DialogContent className="sm:max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader className="sr-only">
            <DialogTitle>Invoice #{viewing?.id ?? ""}</DialogTitle>
            <DialogDescription>
              {viewing?.status === "posted"
                ? `Reported · ${viewing.fbrInvoiceNumber ?? (viewing.origin === "local" ? "unregistered (not sent to FBR)" : "no FBR number")}`
                : "Draft invoice — not yet posted."}
            </DialogDescription>
          </DialogHeader>
          {viewingLoading && !viewing ? (
            <div className="space-y-2"><Skeleton className="h-4 w-full" /><Skeleton className="h-4 w-full" /></div>
          ) : viewing ? (
            <InvoiceView
              inv={viewing}
              onDownload={() => downloadInvoicePdf(viewing)}
              onAddPayment={() => openPayment(viewing)}
              onDeletePayment={(p) => setDeletePayment({ inv: viewing, payment: p })}
            />
          ) : null}
        </DialogContent>
      </Dialog>

      {/* Backdated invoice dialog */}
      <BackdatedInvoiceDialog
        open={backdatedOpen}
        onOpenChange={setBackdatedOpen}
        parties={allParties ?? []}
        createdBy={enteredBy || "system"}
        onCreate={(body) =>
          createBackdated.mutate(body, {
            onSuccess: () => { toast({ title: "Backdated invoice created" }); setBackdatedOpen(false); },
            onError: (e) => toast({ title: "Could not create backdated invoice", description: (e as { message?: string })?.message, variant: "destructive" }),
          })
        }
        pending={createBackdated.isPending}
      />
    </Layout>
  );
}

// ─── Payment badge for the list ───────────────────────────────────────────
function PaymentBadge({ inv }: { inv: InvoiceListItem }) {
  const st = paymentState({ status: inv.status, paid: !!inv.paid, overdue: !!inv.overdue, outstanding: inv.outstanding ?? parseFloat(inv.grandTotal), dueDate: inv.dueDate ?? null, origin: inv.origin });
  if (!st) return null;
  const cls =
    st.label === "Paid"
      ? st.overdue
        ? "bg-amber-100 text-amber-700 dark:bg-amber-950/50 dark:text-amber-300"
        : "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300"
      : st.overdue
        ? "bg-red-100 text-red-700 dark:bg-red-950/50 dark:text-red-300"
        : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300";
  const title = st.dueDate ? `Due ${st.dueDate}${st.overdue ? " · overdue" : ""} · Outstanding ${money(st.outstanding)}` : `Outstanding ${money(st.outstanding)}`;
  return (
    <span title={title} className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${cls}`}>
      {st.label}
    </span>
  );
}

// ─── Receivables view ─────────────────────────────────────────────────────
function ReceivablesView({ data, loading }: { data: import("@/hooks/use-fbr-invoicing").ReceivablesData | undefined; loading: boolean }) {
  const totals = useMemo(() => {
    if (!data) return { totalInvoiced: 0, totalPaid: 0, outstanding: 0, totalWht: 0, current: 0, b1_30: 0, b31_60: 0, b60: 0 };
    return data.parties.reduce(
      (a, p) => ({
        totalInvoiced: a.totalInvoiced + p.totalInvoiced,
        totalPaid: a.totalPaid + p.totalPaid,
        outstanding: a.outstanding + p.outstanding,
        totalWht: a.totalWht + p.totalTaxDeduction,
        current: a.current + p.aging.current,
        b1_30: a.b1_30 + p.aging.b1_30,
        b31_60: a.b31_60 + p.aging.b31_60,
        b60: a.b60 + p.aging.b60,
      }),
      { totalInvoiced: 0, totalPaid: 0, outstanding: 0, totalWht: 0, current: 0, b1_30: 0, b31_60: 0, b60: 0 },
    );
  }, [data]);

  return (
    <Card className="overflow-hidden">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
        <h2 className="text-sm font-semibold text-foreground">Receivables (as of {data?.today ?? "…"})</h2>
        <span className="eyebrow">Outstanding {loading ? "" : money(totals.outstanding)}</span>
      </div>
      <CardContent className="p-0">
        {loading ? (
          <div className="space-y-2 p-5"><Skeleton className="h-8 w-full" /><Skeleton className="h-8 w-full" /></div>
        ) : !data || data.parties.length === 0 ? (
          <p className="py-10 text-center text-muted-foreground">No outstanding invoices (all paid or none yet).</p>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Party</TableHead>
                  <TableHead className="text-right">Total Invoiced</TableHead>
                  <TableHead className="text-right">Total Paid</TableHead>
                  <TableHead className="text-right">Outstanding</TableHead>
                  <TableHead className="text-right">WHT</TableHead>
                  <TableHead className="text-right">Current</TableHead>
                  <TableHead className="text-right">1–30</TableHead>
                  <TableHead className="text-right">31–60</TableHead>
                  <TableHead className="text-right">60+</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.parties.map((p) => (
                  <TableRow key={p.partyId}>
                    <TableCell className="font-medium">{p.partyName}</TableCell>
                    <TableCell className="text-right tabular-nums">{money(p.totalInvoiced)}</TableCell>
                    <TableCell className="text-right tabular-nums">{money(p.totalPaid)}</TableCell>
                    <TableCell className={`text-right tabular-nums font-semibold ${p.outstanding < 0 ? "text-emerald-700" : p.outstanding > 0 ? "text-red-600" : ""}`}>{money(p.outstanding)}</TableCell>
                    <TableCell className="text-right tabular-nums text-muted-foreground">{money(p.totalTaxDeduction)}</TableCell>
                    <TableCell className="text-right tabular-nums">{money(p.aging.current)}</TableCell>
                    <TableCell className="text-right tabular-nums">{money(p.aging.b1_30)}</TableCell>
                    <TableCell className="text-right tabular-nums">{money(p.aging.b31_60)}</TableCell>
                    <TableCell className={`text-right tabular-nums ${p.aging.b60 > 0 ? "text-red-700 font-semibold" : ""}`}>{money(p.aging.b60)}</TableCell>
                  </TableRow>
                ))}
                <TableRow className="bg-muted/50 font-semibold">
                  <TableCell>Total</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.totalInvoiced)}</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.totalPaid)}</TableCell>
                  <TableCell className={`text-right tabular-nums ${totals.outstanding < 0 ? "text-emerald-700" : totals.outstanding > 0 ? "text-red-600" : ""}`}>{money(totals.outstanding)}</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.totalWht)}</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.current)}</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.b1_30)}</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.b31_60)}</TableCell>
                  <TableCell className="text-right tabular-nums">{money(totals.b60)}</TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ─── Backdated invoice dialog ─────────────────────────────────────────────
function BackdatedInvoiceDialog({
  open,
  onOpenChange,
  parties,
  createdBy,
  onCreate,
  pending,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  parties: { id: number; name: string }[];
  createdBy: string;
  onCreate: (body: import("@/hooks/use-fbr-invoicing").CreateBackdatedInvoiceBody) => void;
  pending: boolean;
}) {
  const { data: yarnTypes } = useListYarnTypeMaster();
  const { data: yarnCounts } = useListYarnCountMaster();

  const [form, setForm] = useState({
    id: "",
    partyId: "",
    invoiceDate: new Date().toISOString().slice(0, 10),
    fbrInvoiceNumber: "",
    items: [{ yarnTypeId: "", yarnCountId: "", quantity: "", ratePerKg: "" }],
  });

  const reset = () => {
    setForm({ id: "", partyId: "", invoiceDate: new Date().toISOString().slice(0, 10), fbrInvoiceNumber: "", items: [{ yarnTypeId: "", yarnCountId: "", quantity: "", ratePerKg: "" }] });
  };

  const setItem = (idx: number, field: string, value: string) => {
    setForm((f) => ({
      ...f,
      items: f.items.map((it, i) => (i === idx ? { ...it, [field]: value } : it)),
    }));
  };

  const addItem = () => setForm((f) => ({ ...f, items: [...f.items, { yarnTypeId: "", yarnCountId: "", quantity: "", ratePerKg: "" }] }));
  const removeItem = (idx: number) => setForm((f) => ({ ...f, items: f.items.filter((_, i) => i !== idx) }));

  const total = useMemo(() => {
    let value = 0;
    for (const it of form.items) {
      const q = parseFloat(it.quantity) || 0;
      const r = parseFloat(it.ratePerKg) || 0;
      value += q * r;
    }
    const tax = (value * SALES_TAX_PERCENT) / 100;
    return { value, tax, total: value + tax };
  }, [form.items]);

  const submit = () => {
    const id = parseInt(form.id, 10);
    const partyId = parseInt(form.partyId, 10);
    if (!Number.isInteger(id) || id <= 0) { alert("Enter a valid invoice ID"); return; }
    if (!Number.isInteger(partyId) || partyId <= 0) { alert("Select a party"); return; }
    const items = form.items
      .map((it) => ({
        yarnTypeId: parseInt(it.yarnTypeId, 10),
        yarnCountId: it.yarnCountId ? parseInt(it.yarnCountId, 10) : null,
        quantity: parseFloat(it.quantity) || 0,
        ratePerKg: parseFloat(it.ratePerKg) || 0,
      }))
      .filter((it) => Number.isInteger(it.yarnTypeId) && it.yarnTypeId > 0 && it.quantity > 0 && it.ratePerKg > 0);
    if (items.length === 0) { alert("Add at least one valid item (yarn type, quantity, rate)"); return; }
    onCreate({
      id,
      partyId,
      invoiceDate: form.invoiceDate,
      fbrInvoiceNumber: form.fbrInvoiceNumber || null,
      items,
    });
  };

  return (
    <Dialog open={open} onOpenChange={(o) => { if (!o) reset(); onOpenChange(o); }}>
      <DialogContent className="sm:max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create Backdated Invoice</DialogTitle>
          <DialogDescription>
            Record an invoice generated from another system. The entered ID must not already exist. Created as posted (not sent to FBR).
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Invoice ID (manual)</Label>
              <Input type="number" min="1" value={form.id} onChange={(e) => setForm({ ...form, id: e.target.value })} placeholder="e.g. 500" />
            </div>
            <div className="space-y-1.5">
              <Label>Invoice Date</Label>
              <Input type="date" value={form.invoiceDate} onChange={(e) => setForm({ ...form, invoiceDate: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Party</Label>
              <Select value={form.partyId || undefined} onValueChange={(v) => setForm({ ...form, partyId: v })}>
                <SelectTrigger className="w-full"><SelectValue placeholder="Select party" /></SelectTrigger>
                <SelectContent>
                  {parties.map((p) => <SelectItem key={p.id} value={String(p.id)}>{p.name}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>FBR Invoice No. (optional)</Label>
              <Input value={form.fbrInvoiceNumber} onChange={(e) => setForm({ ...form, fbrInvoiceNumber: e.target.value })} placeholder="From the old system" />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>Line Items</Label>
              <Button type="button" variant="outline" size="sm" onClick={addItem} className="gap-1"><Plus className="h-3.5 w-3.5" /> Add item</Button>
            </div>
            {form.items.map((it, idx) => (
              <div key={idx} className="grid grid-cols-2 gap-2 rounded-md border border-border p-3 sm:grid-cols-5">
                <div className="space-y-1">
                  <Label className="text-xs">Yarn Type</Label>
                  <Select value={it.yarnTypeId || undefined} onValueChange={(v) => setItem(idx, "yarnTypeId", v)}>
                    <SelectTrigger className="h-8 text-sm"><SelectValue placeholder="Type" /></SelectTrigger>
                    <SelectContent>
                      {(yarnTypes ?? []).map((y) => <SelectItem key={y.id} value={String(y.id)}>{y.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Count</Label>
                  <Select value={it.yarnCountId || undefined} onValueChange={(v) => setItem(idx, "yarnCountId", v)}>
                    <SelectTrigger className="h-8 text-sm"><SelectValue placeholder="Count" /></SelectTrigger>
                    <SelectContent>
                      {(yarnCounts ?? []).map((y) => <SelectItem key={y.id} value={String(y.id)}>{y.count}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Qty (kg)</Label>
                  <Input type="number" min="0" step="0.001" className="h-8 text-sm" value={it.quantity} onChange={(e) => setItem(idx, "quantity", e.target.value)} />
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Rate/kg</Label>
                  <Input type="number" min="0" step="0.01" className="h-8 text-sm" value={it.ratePerKg} onChange={(e) => setItem(idx, "ratePerKg", e.target.value)} />
                </div>
                <div className="flex items-end justify-end">
                  <Button type="button" variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => removeItem(idx)} title="Remove item">
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3 rounded-md border border-border bg-muted/30 px-3 py-2 text-sm">
            <span className="text-muted-foreground">Created by <span className="font-medium text-foreground">{createdBy}</span></span>
            <span className="space-x-3">
              <span>Value <span className="font-semibold">{money(total.value)}</span></span>
              <span>Tax <span className="font-semibold">{money(total.tax)}</span></span>
              <span>Grand Total <span className="font-semibold">{money(total.total)}</span></span>
            </span>
          </div>
        </div>
        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
          <Button type="button" onClick={submit} disabled={pending} className="gap-2">
            {pending ? <Spinner className="h-4 w-4" /> : <CalendarPlus className="h-4 w-4" />}
            Create Invoice
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ─── Invoice view (mirrors the FBR "SALES TAX INVOICE" PDF) ────────────────
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

function InvoiceView({
  inv,
  onDownload,
  onAddPayment,
  onDeletePayment,
}: {
  inv: InvoiceDetail;
  onDownload: () => void;
  onAddPayment: () => void;
  onDeletePayment: (p: InvoicePayment) => void;
}) {
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
          <Field label="FBR Invoice No.:" value={inv.fbrInvoiceNumber ?? (inv.origin === "local" ? "— (unregistered)" : "—")} />
          <Field label="Due Date:" value={inv.dueDate ?? "—"} />
          <Field label="Status:" value={inv.status} />
          <Field label="Site Name:" value="Head Office" />
          <Field label="Store Name:" value="Store 01" />
        </Section>
      </div>

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

      {/* Totals summary box */}
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
          <div className="flex justify-between border-b border-foreground/20 px-3 py-2 font-bold">
            <span>Grand Total</span>
            <span className="tabular-nums">{money(parseFloat(inv.grandTotal))}</span>
          </div>
          <div className="flex justify-between border-b border-foreground/20 px-3 py-2">
            <span>Paid</span>
            <span className="font-semibold tabular-nums text-emerald-700">{money(inv.paidAmount ?? 0)}</span>
          </div>
          <div className="flex justify-between border-b border-foreground/20 px-3 py-2">
            <span>Outstanding</span>
            <span className={`font-semibold tabular-nums ${(inv.outstanding ?? 0) > 0 ? "text-red-600" : "text-emerald-700"}`}>{money(inv.outstanding ?? parseFloat(inv.grandTotal))}</span>
          </div>
          {(inv.overpaid ?? 0) > 0 && (
            <div className="flex justify-between px-3 py-2 font-bold text-amber-700">
              <span>Overpaid</span>
              <span className="tabular-nums">{money(inv.overpaid ?? 0)}</span>
            </div>
          )}
          {(inv.totalTaxDeduction ?? 0) > 0 && (
            <div className="flex justify-between px-3 py-2">
              <span>WHT Deducted</span>
              <span className="font-semibold tabular-nums">{money(inv.totalTaxDeduction ?? 0)}</span>
            </div>
          )}
        </div>
      </div>

      {/* Payments section (issue #189) */}
      {inv.status === "posted" && (
        <Section title={`Payments (${(inv.payments ?? []).length})`}>
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs text-muted-foreground">Recorded payments against this invoice</span>
              <Button variant="outline" size="sm" className="gap-1.5" onClick={onAddPayment}>
                <Banknote className="h-3.5 w-3.5" /> Add Payment
              </Button>
            </div>
            {(inv.payments ?? []).length === 0 ? (
              <p className="text-sm text-muted-foreground">No payments recorded yet.</p>
            ) : (
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Date</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                      <TableHead className="text-right">WHT</TableHead>
                      <TableHead className="text-right">Net Applied</TableHead>
                      <TableHead>Method</TableHead>
                      <TableHead>Reference</TableHead>
                      <TableHead>By</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {(inv.payments ?? []).map((p) => (
                      <TableRow key={p.id}>
                        <TableCell>{format(new Date(p.paymentDate + "T00:00:00"), "dd MMM yyyy")}</TableCell>
                        <TableCell className="text-right tabular-nums">{money(parseFloat(p.amount))}</TableCell>
                        <TableCell className="text-right tabular-nums">{money(parseFloat(p.taxDeduction))}</TableCell>
                        <TableCell className="text-right tabular-nums font-medium">{money(parseFloat(p.amount) - parseFloat(p.taxDeduction))}</TableCell>
                        <TableCell>{p.method ?? "—"}</TableCell>
                        <TableCell>{p.reference ?? "—"}</TableCell>
                        <TableCell>{p.paidBy}</TableCell>
                        <TableCell className="text-right">
                          <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => onDeletePayment(p)} title="Delete payment">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </div>
        </Section>
      )}

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
