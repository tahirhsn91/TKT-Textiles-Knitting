import { useState } from "react";
import { Plus, Pencil, RotateCcw, Wrench, Eye, Trash2 } from "lucide-react";
import { format } from "date-fns";
import { useQueryClient } from "@tanstack/react-query";

import {
  useGetMachineMaintenanceList,
  useSetMachineMaintenanceStatus,
  type MachineMaintenanceRow,
} from "@/hooks/use-machine-maintenance";
import { MachineMaintenanceDialog } from "./add-machine-maintenance-dialog";
import { MachineMaintenanceAnalytics } from "./analytics-tab";
import { useIsMobile } from "@/hooks/use-mobile";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { DateStepper } from "@/components/date-stepper";
import { Badge } from "@/components/ui/badge";
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

const COLUMN_COUNT = 6;
const PAGE_SIZE = 50;

type StatusFilter = "submitted" | "cancelled";

function todayIso() {
  return format(new Date(), "yyyy-MM-dd");
}

export default function MachineMaintenanceList() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isMobile = useIsMobile();

  const [date, setDate] = useState(todayIso());
  const [status, setStatus] = useState<StatusFilter>("submitted");
  const [page, setPage] = useState(1);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [viewingId, setViewingId] = useState<number | null>(null);
  const [editMachineId, setEditMachineId] = useState<number | undefined>(undefined);
  const [pendingCancel, setPendingCancel] = useState<MachineMaintenanceRow | null>(null);

  const { data, isLoading } = useGetMachineMaintenanceList(date, status, page);
  const setStatusMut = useSetMachineMaintenanceStatus();

  const rows = data?.rows ?? [];
  const total = data?.total ?? 0;
  const totalPages = Math.max(Math.ceil(total / PAGE_SIZE), 1);
  const dateLabel = format(new Date(date + "T00:00:00"), "d MMM yyyy");
  const monthLabel = format(new Date(date + "T00:00:00"), "MMM yyyy");

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ["/api/maintenance/machine"] });
  };

  const openAdd = () => {
    setEditingId(null);
    setViewingId(null);
    setDialogOpen(true);
  };

  const openEdit = (id: number, machineId?: number) => {
    setViewingId(null);
    setEditingId(id);
    setEditMachineId(machineId);
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
      setEditMachineId(undefined);
    }
  };

  const doCancel = (r: MachineMaintenanceRow) => {
    setStatusMut.mutate(
      { id: r.id, status: "cancelled", updatedBy: r.createdBy },
      {
        onSuccess: () => {
          invalidate();
          toast({ title: "Record cancelled", description: "It stays listed under Cancelled and can be restored." });
          setPendingCancel(null);
        },
        onError: (err) => {
          toast({ title: "Failed to cancel", description: err instanceof Error ? err.message : undefined, variant: "destructive" });
          setPendingCancel(null);
        },
      },
    );
  };

  const doRestore = (r: MachineMaintenanceRow) => {
    setStatusMut.mutate(
      { id: r.id, status: "submitted", updatedBy: r.createdBy },
      {
        onSuccess: () => {
          invalidate();
          toast({ title: "Record restored" });
        },
        onError: (err) => {
          toast({ title: "Failed to restore", description: err instanceof Error ? err.message : undefined, variant: "destructive" });
        },
      },
    );
  };

  return (
    <Layout>
      <div className="flex flex-col gap-6">
        <header className="flex items-start justify-between gap-4 border-b pb-5">
          <div>
            <p className="eyebrow">Maintenance</p>
            <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">
              Machine maintenance
            </h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Machine maintenance history for <span className="num">{dateLabel}</span>.
            </p>
          </div>
          <Button onClick={openAdd} className="shrink-0">
            <Plus className="mr-2 h-4 w-4" />
            Add new
          </Button>
        </header>

        {/* Filter + totals — one strip: date, status, day total cost, month-to-date. */}
        <Card className="overflow-hidden">
          <div className="grid grid-cols-1 divide-y divide-border sm:grid-cols-[220px_1fr_1fr_1fr] sm:divide-x sm:divide-y-0">
            <div className="flex flex-col justify-center gap-2 px-5 py-4">
              <label className="eyebrow">Date</label>
              <DateStepper
                value={date}
                max={todayIso()}
                onChange={(d) => { setDate(d); setPage(1); }}
              />
            </div>
            <div className="flex flex-col justify-center gap-2 px-5 py-4">
              <label className="eyebrow">Status</label>
              <div className="inline-flex w-fit rounded-md border border-border bg-muted/40 p-0.5">
                {(["submitted", "cancelled"] as StatusFilter[]).map((s) => (
                  <button
                    key={s}
                    type="button"
                    onClick={() => { setStatus(s); setPage(1); }}
                    className={
                      "rounded px-3 py-1.5 text-xs font-medium transition-colors " +
                      (status === s
                        ? "selvedge bg-background text-foreground shadow-sm"
                        : "text-muted-foreground hover:text-foreground")
                    }
                  >
                    {s === "submitted" ? "Active" : "Cancelled"}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-muted">
                <Wrench className="h-5 w-5 text-muted-foreground" />
              </div>
              <div className="min-w-0">
                <p className="eyebrow">Day total cost</p>
                <p className="num mt-1 text-xl font-semibold leading-none text-foreground sm:text-2xl">
                  {Number(data?.dayTotalCost ?? 0).toFixed(2)}
                </p>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  <span className="num">{total}</span> active maintenance record{total === 1 ? "" : "s"} · {dateLabel}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-muted">
                <Wrench className="h-5 w-5 text-muted-foreground" />
              </div>
              <div className="min-w-0">
                <p className="eyebrow">Month to date</p>
                <p className="num mt-1 text-xl font-semibold leading-none text-foreground sm:text-2xl">
                  {Number(data?.monthToDateCost ?? 0).toFixed(2)}
                </p>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  total maintenance cost · {monthLabel}
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* Records / Analytics — same date, two views of the records */}
        <Tabs defaultValue="records">
          <TabsList>
            <TabsTrigger value="records">Records</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
          </TabsList>
          <TabsContent value="records" className="mt-4">
        {/* List */}
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h2 className="text-sm font-semibold text-foreground">
              {status === "submitted" ? "Active maintenance records" : "Cancelled maintenance records"}
            </h2>
            <span className="eyebrow">
              <span className="num">{total}</span> record{total === 1 ? "" : "s"}
            </span>
          </div>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead className="eyebrow h-11 px-5">Machine</TableHead>
                  <TableHead className="eyebrow h-11">Maintenance work</TableHead>
                  <TableHead className="eyebrow h-11 hidden sm:table-cell">Cost</TableHead>
                  <TableHead className="eyebrow h-11 hidden md:table-cell">Vendor</TableHead>
                  <TableHead className="eyebrow h-11 hidden md:table-cell">Entered by</TableHead>
                  <TableHead className="sticky right-0 bg-background eyebrow h-11 px-1.5 text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: COLUMN_COUNT }).map((_, j) => (
                        <TableCell key={j} className="px-5"><Skeleton className="h-5 w-20" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={COLUMN_COUNT} className="py-10 text-center text-muted-foreground">
                      No {status === "submitted" ? "active" : "cancelled"} machine maintenance for {dateLabel} yet.
                      {status === "submitted" ? " Add one to get started." : ""}
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((r) => {
                    const cancelled = r.status === "cancelled";
                    const rowBg = cancelled ? "bg-muted/30 hover:bg-muted/30" : undefined;
                    return (
                    <TableRow
                      key={r.id}
                      className={`${rowBg ?? ""} ${isMobile ? "cursor-pointer" : ""}`.trim() || undefined}
                      onClick={isMobile ? () => (cancelled ? openView(r.id) : openEdit(r.id, r.machineId)) : undefined}
                    >
                      <TableCell className="whitespace-nowrap px-5">
                        <span className="inline-flex items-center gap-2 font-medium">
                          <Wrench className="h-3.5 w-3.5 text-muted-foreground" />
                          {r.machineNumber ?? `Machine ${r.machineId}`}
                          {cancelled && (
                            <Badge variant="outline" className="border-border text-muted-foreground">Cancelled</Badge>
                          )}
                        </span>
                      </TableCell>
                      <TableCell className="max-w-[16rem] whitespace-pre-wrap text-sm">{r.maintenanceWork}</TableCell>
                      <TableCell className="num hidden sm:table-cell">
                        {r.cost != null ? Number(r.cost).toFixed(2) : "-"}
                      </TableCell>
                      <TableCell className="hidden md:table-cell">{r.vendor ?? "-"}</TableCell>
                      <TableCell className="hidden text-xs text-muted-foreground md:table-cell">{r.createdBy}</TableCell>
                      <TableCell className="sticky right-0 bg-background px-1.5 text-right">
                        <div className="flex items-center justify-end gap-0.5" onClick={(e) => e.stopPropagation()}>
                          {cancelled ? (
                            <>
                              <Button
                                type="button"
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                                aria-label={`View record ${r.id}`}
                                onClick={() => openView(r.id)}
                              >
                                <Eye className="h-4 w-4" />
                              </Button>
                              <Button
                                type="button"
                                variant="ghost"
                                size="sm"
                                className="h-8 text-muted-foreground hover:text-emerald-700"
                                onClick={() => doRestore(r)}
                              >
                                <RotateCcw className="mr-1.5 h-3.5 w-3.5" />
                                Restore
                              </Button>
                            </>
                          ) : (
                            <>
                              <Button
                                type="button"
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                                aria-label={`Edit record ${r.id}`}
                                onClick={() => openEdit(r.id, r.machineId)}
                              >
                                <Pencil className="h-4 w-4" />
                              </Button>
                              <Button
                                type="button"
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
                                aria-label={`Cancel record ${r.id}`}
                                onClick={() => setPendingCancel(r)}
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
            </Table>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between gap-2 border-t px-5 py-3">
                <span className="text-xs text-muted-foreground">
                  Page <span className="num">{page}</span> of <span className="num">{totalPages}</span> · <span className="num">{total}</span> records
                </span>
                <div className="flex items-center gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    disabled={page <= 1}
                    onClick={() => setPage((p) => Math.max(p - 1, 1))}
                  >
                    Previous
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    disabled={page >= totalPages}
                    onClick={() => setPage((p) => Math.min(p + 1, totalPages))}
                  >
                    Next
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
          </TabsContent>
          <TabsContent value="analytics" className="mt-4">
            <MachineMaintenanceAnalytics
              rows={rows}
              monthSeries={data?.monthSeries ?? []}
              isLoading={isLoading}
              dateLabel={dateLabel}
            />
          </TabsContent>
        </Tabs>
      </div>

      <MachineMaintenanceDialog
        open={dialogOpen}
        onOpenChange={handleDialogOpenChange}
        recordId={editingId ?? viewingId}
        defaultDate={date ? new Date(date + "T00:00:00") : undefined}
        defaultMachineId={editMachineId}
        maxDate={new Date(todayIso() + "T00:00:00")}
        readOnly={viewingId != null}
      />

      <AlertDialog
        open={pendingCancel !== null}
        onOpenChange={(o) => { if (!o && !setStatusMut.isPending) setPendingCancel(null); }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Cancel this maintenance record?</AlertDialogTitle>
            <AlertDialogDescription>
              {pendingCancel && (
                <>
                  <span className="font-medium text-foreground">
                    {pendingCancel.machineNumber ?? `Machine ${pendingCancel.machineId}`}
                  </span>{" "}
                  — {pendingCancel.maintenanceWork}
                  <br /><br />
                  Cancelling soft-deletes the record: it will move to the Cancelled tab and can be restored anytime.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={setStatusMut.isPending}>Keep</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => { e.preventDefault(); if (pendingCancel) doCancel(pendingCancel); }}
              disabled={setStatusMut.isPending}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {setStatusMut.isPending && <Spinner className="mr-2" />}
              Cancel record
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  );
}
