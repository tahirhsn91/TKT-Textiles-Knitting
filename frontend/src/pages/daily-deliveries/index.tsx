import { NUM_DECIMALS } from "@/lib/format";
import { useState } from "react";
import { Plus, Pencil, Trash2, Lock, Eye, Truck } from "lucide-react";
import { format } from "date-fns";
import { useQueryClient } from "@tanstack/react-query";

import {
  useGetDailyDeliveriesSummary,
  useDeleteDailyDelivery,
  type DailyDeliveryRow,
} from "@/hooks/use-daily-deliveries";
import { DailyDeliveryDialog } from "./add-delivery-dialog";
import { DailyDeliveryAnalytics } from "./analytics-tab";
import { useSort } from "@/hooks/use-sort";
import { SortableHead } from "@/components/sortable-head";
import { useIsMobile } from "@/hooks/use-mobile";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
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
import { useToast } from "@/hooks/use-toast";

const COLUMN_COUNT = 7;

function todayIso() {
  return format(new Date(), "yyyy-MM-dd");
}

export default function DailyDeliveryList() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isMobile = useIsMobile();

  const [date, setDate] = useState(todayIso());
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [viewingId, setViewingId] = useState<number | null>(null);
  const [pendingDelete, setPendingDelete] = useState<DailyDeliveryRow | null>(null);

  const { data, isLoading, isFetching } = useGetDailyDeliveriesSummary(date);
  const deleteDelivery = useDeleteDailyDelivery();

  const { sorted: rows, sort, toggleSort } = useSort(data?.rows, {
    challanNo: (r) => r.challanNo,
    partyName: (r) => r.partyName,
    yarnTypeName: (r) => r.yarnTypeName,
    sl: (r) => r.sl,
    gsm: (r) => r.gsm,
    quantity: (r) => r.quantity,
    netWeight: (r) => parseFloat(r.netWeight),
  });

  const dayQty = rows.reduce((s, r) => s + (r.quantity || 0), 0);
  const dayKg = rows.reduce((s, r) => s + (parseFloat(r.netWeight) || 0), 0);
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
    deleteDelivery.mutate(
      { id: pendingDelete.id },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/daily-deliveries"] });
          toast({ title: "Delivery deleted" });
          setPendingDelete(null);
        },
        onError: (err) => {
          toast({
            title: "Failed to delete delivery",
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
              Daily deliveries
            </h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Fabric deliveries out on <span className="num">{dateLabel}</span>, one row per delivery.
            </p>
          </div>
          <Button onClick={openAdd} className="shrink-0">
            <Plus className="mr-2 h-4 w-4" />
            Add new
          </Button>
        </header>

        {/* Filter + totals — one strip, same shape as the other daily screens. */}
        <Card className="overflow-hidden">
          <div className="grid grid-cols-1 divide-y divide-border sm:grid-cols-[220px_1fr_1fr] sm:divide-x sm:divide-y-0">
            <div className="flex flex-col justify-center gap-2 px-5 py-4">
              <label className="eyebrow">Delivery date</label>
              <Input
                type="date"
                className="h-9"
                value={date}
                max={todayIso()}
                onChange={(e) => setDate(e.target.value || todayIso())}
              />
            </div>
            <div className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-muted">
                <Truck className="h-5 w-5 text-muted-foreground" />
              </div>
              <div className="min-w-0">
                <p className="eyebrow">Day total</p>
                <p className="num mt-1 text-xl font-semibold leading-none text-foreground sm:text-2xl">
                  {dayKg.toFixed(NUM_DECIMALS)}
                  <span className="ml-1.5 text-sm font-medium text-muted-foreground">kg</span>
                </p>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  <span className="num">{dayQty}</span> roll{dayQty === 1 ? "" : "s"} · <span className="num">{rows.length}</span> delivery{rows.length === 1 ? "" : "s"}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-muted">
                <Truck className="h-5 w-5 text-muted-foreground" />
              </div>
              <div className="min-w-0">
                <p className="eyebrow">Month to date</p>
                <p className="num mt-1 text-xl font-semibold leading-none text-foreground sm:text-2xl">
                  {mtdKg.toFixed(NUM_DECIMALS)}
                  <span className="ml-1.5 text-sm font-medium text-muted-foreground">kg</span>
                </p>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  <span className="num">{mtdQty}</span> roll{mtdQty === 1 ? "" : "s"} · {monthLabel}
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* Entries / Analytics — same date, two views of the same deliveries */}
        <Tabs defaultValue="entries">
          <TabsList>
            <TabsTrigger value="entries">Entries</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
          </TabsList>
          <TabsContent value="entries" className="mt-4">
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h2 className="text-sm font-semibold text-foreground">Daily deliveries</h2>
            <span className="eyebrow">{dateLabel}</span>
          </div>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <SortableHead className="eyebrow h-11 px-5" label="Challan #" sortKey="challanNo" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Party" sortKey="partyName" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Yarn Type" sortKey="yarnTypeName" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11 hidden sm:table-cell" label="SL" sortKey="sl" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11 hidden sm:table-cell" label="GSM" sortKey="gsm" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Rolls" sortKey="quantity" sort={sort} onSort={toggleSort} right />
                  <SortableHead className="eyebrow h-11" label="Net weight" sortKey="netWeight" sort={sort} onSort={toggleSort} right />
                  <TableHead className="sticky right-0 bg-background eyebrow h-11 px-2 text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 4 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: COLUMN_COUNT + 1 }).map((_, j) => (
                        <TableCell key={j} className="px-5"><Skeleton className="h-5 w-20" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={COLUMN_COUNT + 1} className="text-center py-10 text-muted-foreground">
                      No deliveries for {dateLabel} yet. Add one to get started.
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((r) => {
                    const stickyBg = r.reconciled ? "bg-yellow-100 dark:bg-yellow-950/40" : "bg-background";
                    return (
                    // Booked deliveries are tinted yellow and locked — same
                    // convention as reconciled production / yarn receipts.
                    <TableRow
                      key={r.id}
                      className={`${r.reconciled ? "bg-yellow-100 hover:bg-yellow-100 dark:bg-yellow-950/40 dark:hover:bg-yellow-950/40" : ""} ${isMobile ? "cursor-pointer" : ""}`.trim() || undefined}
                      // Whole-row tap opens the delivery on mobile.
                      onClick={isMobile ? () => (r.reconciled ? openView(r.id) : openEdit(r.id)) : undefined}
                    >
                      <TableCell className="whitespace-nowrap px-5 font-medium text-muted-foreground">
                        {r.challanNo}
                      </TableCell>
                      <TableCell className="whitespace-nowrap font-medium">
                        <span className="inline-flex items-center gap-2">
                          {r.partyName ?? "-"}
                          {r.reconciled && (
                            <span className="inline-flex items-center gap-1 rounded-sm border border-yellow-300 bg-yellow-50 px-1.5 py-0.5 text-[0.6875rem] font-medium uppercase tracking-wide text-yellow-900 dark:border-yellow-800 dark:bg-yellow-950 dark:text-yellow-200">
                              <Lock className="h-3 w-3" />
                              Reconciled
                            </span>
                          )}
                        </span>
                      </TableCell>
                      <TableCell className="whitespace-nowrap">{r.yarnTypeName ?? "-"}</TableCell>
                      <TableCell className="num hidden sm:table-cell">{r.sl ?? "-"}</TableCell>
                      <TableCell className="num hidden sm:table-cell">{r.gsm ?? "-"}</TableCell>
                      <TableCell className="num text-right">{r.quantity}</TableCell>
                      <TableCell className="num text-right font-medium">
                        {Number(r.netWeight).toFixed(NUM_DECIMALS)}
                      </TableCell>
                      <TableCell className={`sticky right-0 ${stickyBg} px-2 text-right`}>
                        <div className="flex items-center justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                        {r.reconciled ? (
                          <>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-11 w-11 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                              aria-label={`View delivery ${r.challanNo}`}
                              onClick={() => openView(r.id)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <span
                              className="inline-flex items-center gap-1.5 pr-1 text-xs text-muted-foreground"
                              title={
                                r.reconciledTransactionId
                                  ? `Booked into transaction #${r.reconciledTransactionId}. This delivery can't be changed once consumed.`
                                  : "Booked into a Fabric Delivery transaction. This delivery can't be changed once consumed."
                              }
                            >
                              <Lock className="h-3.5 w-3.5" />
                              Locked
                            </span>
                          </>
                        ) : (
                          <>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-11 w-11 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                              aria-label={`Edit delivery ${r.challanNo}`}
                              onClick={() => openEdit(r.id)}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-11 w-11 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
                              aria-label={`Delete delivery ${r.challanNo}`}
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
                    <TableCell colSpan={isMobile ? 4 : 6} className="px-5 text-right text-sm text-muted-foreground">
                      Grand total
                    </TableCell>
                    <TableCell className="selvedge-top py-4 text-right">
                      <span className="num text-lg font-semibold text-foreground">{dayKg.toFixed(NUM_DECIMALS)}</span>
                    </TableCell>
                    <TableCell className="sticky right-0 bg-background px-2" />
                  </TableRow>
                </tfoot>
              )}
            </Table>
          </CardContent>
        </Card>
          </TabsContent>
          <TabsContent value="analytics" className="mt-4">
            <DailyDeliveryAnalytics
              rows={rows}
              monthSeries={data?.monthSeries ?? []}
              isLoading={isLoading}
              dateLabel={dateLabel}
            />
          </TabsContent>
        </Tabs>

        {isFetching && !isLoading && (
          <p className="text-xs text-muted-foreground -mt-4">Refreshing…</p>
        )}
      </div>

      <DailyDeliveryDialog
        open={dialogOpen}
        onOpenChange={handleDialogOpenChange}
        deliveryId={editingId ?? viewingId}
        readOnly={viewingId != null}
        defaultDate={date ? new Date(date + "T00:00:00") : undefined}
        maxDate={new Date(todayIso() + "T00:00:00")}
      />

      <AlertDialog
        open={pendingDelete !== null}
        onOpenChange={(o) => { if (!o && !deleteDelivery.isPending) setPendingDelete(null); }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this delivery?</AlertDialogTitle>
            <AlertDialogDescription>
              {pendingDelete && (
                <>
                  <span className="font-medium text-foreground">
                    {pendingDelete.challanNo} · {pendingDelete.partyName ?? "Party"}
                  </span>
                  {" — "}
                  <span className="num">{pendingDelete.quantity}</span> roll
                  {pendingDelete.quantity === 1 ? "" : "s"} totalling{" "}
                  <span className="num">{Number(pendingDelete.netWeight).toFixed(NUM_DECIMALS)}</span>.
                  <br />
                  <br />
                  This permanently removes the delivery. It cannot be undone.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteDelivery.isPending}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => { e.preventDefault(); confirmDelete(); }}
              disabled={deleteDelivery.isPending}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteDelivery.isPending && <Spinner className="mr-2" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  );
}
