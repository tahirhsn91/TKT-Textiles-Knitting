import { NUM_DECIMALS } from "@/lib/format";
import { useState } from "react";
import { Plus, Pencil, Trash2, Package, Lock, Eye } from "lucide-react";
import { format } from "date-fns";
import { useQueryClient } from "@tanstack/react-query";

import {
  useGetYarnReceiptsSummary,
  useDeleteYarnReceipt,
  useYarnReceiptsAnalytics,
  type YarnReceiptSummaryRow,
} from "@/hooks/use-yarn-receipts";
import { YarnReceiptDialog } from "./add-receipt-dialog";
import { YarnReceiptAnalytics } from "./analytics-tab";
import { useSort } from "@/hooks/use-sort";
import { SortableHead } from "@/components/sortable-head";
import { useIsMobile } from "@/hooks/use-mobile";
import { useReconciledLock } from "@/context/config-context";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { UnreconciledDateStepper } from "@/components/unreconciled-date-stepper";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/ui/spinner";
import { Layout } from "@/components/layout";
import { PlausibilityListBanner } from "@/components/plausibility-warning";
import { AbnormalDataTab } from "@/components/abnormal-data-tab";
import { usePlausibilityList } from "@/hooks/use-plausibility-list";
import { useToast } from "@/hooks/use-toast";

const COLUMN_COUNT = 6;

function todayIso() {
  return format(new Date(), "yyyy-MM-dd");
}

export default function YarnReceiptList() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isMobile = useIsMobile();
  // When the "Reconciled lock" configuration (code 0001) is disabled, booked
  // receipts stay editable instead of being locked.
  const reconciledLockEnabled = useReconciledLock();

  const [date, setDate] = useState(todayIso());
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [viewingId, setViewingId] = useState<number | null>(null);
  const [pendingDelete, setPendingDelete] = useState<YarnReceiptSummaryRow | null>(null);

  const { data, isLoading, isFetching } = useGetYarnReceiptsSummary(date);

  // Plausibility check over this date's unreconciled receipts.
  const { data: plausibility } = usePlausibilityList("receipt", {
    dateFrom: date,
    dateTo: date,
  });
  const { data: analytics } = useYarnReceiptsAnalytics(date);
  const deleteReceipt = useDeleteYarnReceipt();

  const { sorted: rows, sort, toggleSort } = useSort(data?.rows, {
    docNumber: (r) => r.docNumber,
    partyName: (r) => r.partyName,
    lineCount: (r) => r.lineCount,
    totalQty: (r) => r.totalQty,
    totalNetWeight: (r) => parseFloat(r.totalNetWeight),
  });

  const dayQty = rows.reduce((s, r) => s + (r.totalQty || 0), 0);
  const dayKg = rows.reduce((s, r) => s + (parseFloat(r.totalNetWeight) || 0), 0);
  const mtdQty = data?.monthToDate?.totalQty ?? 0;
  const mtdKg = parseFloat(data?.monthToDate?.totalNetWeight ?? "0") || 0;
  const monthLabel = format(new Date(date + "T00:00:00"), "MMM yyyy");
  const dateLabel = format(new Date(date + "T00:00:00"), "d MMM yyyy");

  const openAdd = () => {
    setEditingId(null);
    setViewingId(null);
    setDialogOpen(true);
  };

  const openEdit = (id: number) => {
    setViewingId(null);
    setEditingId(id);
    setDialogOpen(true);
  };

  const openView = (id: number) => {
    setEditingId(null);
    setViewingId(id);
    setDialogOpen(true);
  };

  const handleDialogOpenChange = (o: boolean) => {
    setDialogOpen(o);
    if (!o) {
      setEditingId(null);
      setViewingId(null);
    }
  };

  const confirmDelete = () => {
    if (!pendingDelete) return;
    deleteReceipt.mutate(
      { id: pendingDelete.id },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/yarn-receipts"] });
          toast({ title: "Yarn receipt deleted" });
          setPendingDelete(null);
        },
        onError: (err) => {
          toast({
            title: "Failed to delete yarn receipt",
            description: err instanceof Error ? err.message : undefined,
            variant: "destructive",
          });
          setPendingDelete(null);
        },
      },
    );
  };

  return (
    <Layout>
      <div className="flex flex-col gap-6">
        <header className="flex items-start justify-between gap-4 border-b pb-5">
          <div>
            <p className="eyebrow">Knitting operations</p>
            <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">
              Yarn receipts
            </h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Yarn deliveries received on <span className="num">{dateLabel}</span>, one row per receipt.
            </p>
          </div>
          <Button onClick={openAdd} className="shrink-0">
            <Plus className="mr-2 h-4 w-4" />
            Add new
          </Button>
        </header>

        {/* Filter + totals — one strip, same shape as daily production. */}
        <Card className="overflow-hidden">
          <div className="grid grid-cols-1 divide-y divide-border sm:grid-cols-[300px_1fr_1fr] sm:divide-x sm:divide-y-0">
            <div className="flex flex-col justify-center gap-2 px-5 py-4">
              <label className="eyebrow">Receipt date</label>
              <UnreconciledDateStepper
                operation="receipt"
                value={date}
                max={todayIso()}
                onChange={(d) => setDate(d)}
              />
            </div>
            <div className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-muted">
                <Package className="h-5 w-5 text-muted-foreground" />
              </div>
              <div className="min-w-0">
                <p className="eyebrow">Day total</p>
                <p className="num mt-1 text-xl font-semibold leading-none text-foreground sm:text-2xl">
                  {dayKg.toFixed(NUM_DECIMALS)}
                  <span className="ml-1.5 text-sm font-medium text-muted-foreground">kg</span>
                </p>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  <span className="num">{dayQty}</span> bag{dayQty === 1 ? "" : "s"} · <span className="num">{rows.length}</span> receipt{rows.length === 1 ? "" : "s"}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-muted">
                <Package className="h-5 w-5 text-muted-foreground" />
              </div>
              <div className="min-w-0">
                <p className="eyebrow">Month to date</p>
                <p className="num mt-1 text-xl font-semibold leading-none text-foreground sm:text-2xl">
                  {mtdKg.toFixed(NUM_DECIMALS)}
                  <span className="ml-1.5 text-sm font-medium text-muted-foreground">kg</span>
                </p>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  <span className="num">{mtdQty}</span> bag{mtdQty === 1 ? "" : "s"} · {monthLabel}
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* Entries / Analytics — same date, two views of the same receipts */}
        <Tabs defaultValue="entries">
          <TabsList>
            <TabsTrigger value="entries">Entries</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
            <TabsTrigger value="abnormal">Abnormal</TabsTrigger>
          </TabsList>
          <TabsContent value="entries" className="mt-4 space-y-3">
        {plausibility && (
          <PlausibilityListBanner
            abnormalCount={plausibility.abnormalCount}
            totalChecked={plausibility.totalChecked}
            noun="receipts"
            combinationFindings={plausibility.combinationFindings}
          />
        )}
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h2 className="text-sm font-semibold text-foreground">Yarn receipts</h2>
            <span className="eyebrow">{dateLabel}</span>
          </div>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <SortableHead className="eyebrow h-11 px-5" label="Doc #" sortKey="docNumber" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Party" sortKey="partyName" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Lots" sortKey="lineCount" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Bags" sortKey="totalQty" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Net weight" sortKey="totalNetWeight" sort={sort} onSort={toggleSort} right />
                  <TableHead className="sticky right-0 bg-background eyebrow h-11 px-1.5 text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 4 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: COLUMN_COUNT }).map((_, j) => (
                        <TableCell key={j} className="px-5"><Skeleton className="h-5 w-20" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={COLUMN_COUNT} className="text-center py-10 text-muted-foreground">
                      No yarn receipts for {dateLabel} yet. Add one to get started.
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((r) => {
                    // When the Reconciled lock (code 0001) is enabled, a booked
                    // row is locked; when it's disabled it stays editable.
                    const locked = r.reconciled && reconciledLockEnabled;
                    const stickyBg = locked ? "bg-yellow-100 dark:bg-yellow-950/40" : "bg-background";
                    return (
                    // Receipts booked into a transaction are tinted yellow and
                    // locked — same convention as reconciled production rows.
                    <TableRow
                      key={r.id}
                      className={`${locked ? "bg-yellow-100 hover:bg-yellow-100 dark:bg-yellow-950/40 dark:hover:bg-yellow-950/40" : ""} ${isMobile ? "cursor-pointer" : ""}`.trim() || undefined}
                      // Whole-row tap opens the receipt on mobile.
                      onClick={isMobile ? () => (locked ? openView(r.id) : openEdit(r.id)) : undefined}
                    >
                      <TableCell className="whitespace-nowrap px-5 font-medium text-muted-foreground">
                        {r.docNumber}
                      </TableCell>
                      <TableCell className="whitespace-nowrap font-medium">
                        <span className="inline-flex items-center gap-2">
                          {r.partyName ?? "-"}
                          {locked && (
                            <span className="inline-flex items-center gap-1 rounded-sm border border-yellow-300 bg-yellow-50 px-1.5 py-0.5 text-[0.6875rem] font-medium uppercase tracking-wide text-yellow-900 dark:border-yellow-800 dark:bg-yellow-950 dark:text-yellow-200">
                              <Lock className="h-3 w-3" />
                              Reconciled
                            </span>
                          )}
                        </span>
                      </TableCell>
                      <TableCell className="num">{r.lineCount}</TableCell>
                      <TableCell className="num">{r.totalQty}</TableCell>
                      <TableCell className="num text-right font-medium">
                        {Number(r.totalNetWeight).toFixed(NUM_DECIMALS)}
                      </TableCell>
                      <TableCell className={`sticky right-0 ${stickyBg} px-1.5 text-right`}>
                        <div className="flex items-center justify-end gap-0.5" onClick={(e) => e.stopPropagation()}>
                        {locked ? (
                          <>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                              aria-label={`View receipt from ${r.partyName ?? "party"}`}
                              onClick={() => openView(r.id)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <span
                              className="inline-flex items-center gap-1.5 pr-1 text-xs text-muted-foreground"
                              title={
                                r.reconciledTransactionId
                                  ? `Booked into transaction #${r.reconciledTransactionId}. This receipt can't be changed once consumed.`
                                  : "Booked into a Yarn Receipt transaction. This receipt can't be changed once consumed."
                              }
                            >
                              <Lock className="h-3.5 w-3.5" />
                              <span className="hidden sm:inline">Locked</span>
                            </span>
                          </>
                        ) : (
                          <>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                              aria-label={`Edit receipt from ${r.partyName ?? "party"}`}
                              onClick={() => openEdit(r.id)}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-9 w-9 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
                              aria-label={`Delete receipt from ${r.partyName ?? "party"}`}
                              onClick={() => setPendingDelete(r)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </>
                        )}
                        </div>
                      </TableCell>
                    </TableRow>
                    );
                  })
                )}
              </TableBody>
              {rows.length > 0 && (
                <tfoot>
                  <TableRow className="hover:bg-transparent">
                    <TableCell colSpan={4} className="px-5 text-right text-sm text-muted-foreground">
                      Grand total
                    </TableCell>
                    <TableCell className="selvedge-top py-4 text-right">
                      <span className="num text-lg font-semibold text-foreground">{dayKg.toFixed(NUM_DECIMALS)}</span>
                    </TableCell>
                    <TableCell className="sticky right-0 bg-background px-1.5" />
                  </TableRow>
                </tfoot>
              )}
            </Table>
          </CardContent>
        </Card>
          </TabsContent>
          <TabsContent value="analytics" className="mt-4">
            <YarnReceiptAnalytics
              lines={analytics?.lines ?? []}
              monthSeries={analytics?.monthSeries ?? []}
              isLoading={isLoading}
              dateLabel={dateLabel}
            />
          </TabsContent>
          <TabsContent value="abnormal" className="mt-4">
            <AbnormalDataTab plausibility={plausibility} noun="receipt" onOpen={openEdit} />
          </TabsContent>
        </Tabs>

        {isFetching && !isLoading && (
          <p className="text-xs text-muted-foreground -mt-4">Refreshing…</p>
        )}
      </div>

      <YarnReceiptDialog
        open={dialogOpen}
        onOpenChange={handleDialogOpenChange}
        receiptId={editingId ?? viewingId}
        readOnly={viewingId != null}
        defaultDate={date ? new Date(date + "T00:00:00") : undefined}
        maxDate={new Date(todayIso() + "T00:00:00")}
      />

      <AlertDialog
        open={pendingDelete !== null}
        onOpenChange={(o) => { if (!o && !deleteReceipt.isPending) setPendingDelete(null); }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this yarn receipt?</AlertDialogTitle>
            <AlertDialogDescription>
              {pendingDelete && (
                <>
                  <span className="font-medium text-foreground">
                    {pendingDelete.partyName ?? "Party"}
                  </span>
                  {" — "}
                  <span className="num">{pendingDelete.totalQty}</span> bag
                  {pendingDelete.totalQty === 1 ? "" : "s"} totalling{" "}
                  <span className="num">{Number(pendingDelete.totalNetWeight).toFixed(NUM_DECIMALS)}</span>.
                  <br />
                  <br />
                  This permanently removes the receipt and all of its yarn lots. It cannot be undone.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteReceipt.isPending}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => { e.preventDefault(); confirmDelete(); }}
              disabled={deleteReceipt.isPending}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteReceipt.isPending && <Spinner className="mr-2" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  );
}
