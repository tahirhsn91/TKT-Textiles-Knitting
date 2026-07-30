import { useState } from "react";
import { Plus, Pencil, Trash2, Lock } from "lucide-react";
import { format } from "date-fns";
import { useQueryClient } from "@tanstack/react-query";

import {
  useGetDailyProductionSummary,
  useDeleteDailyProduction,
  type DailyProductionSummaryRow,
} from "@/hooks/use-daily-production";
import { useSort } from "@/hooks/use-sort";
import { SortableHead } from "@/components/sortable-head";
import { ProductionEntryDialog } from "./add-production-dialog";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
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

/** "Machine 4" repeated on every line of a grouped summary reads like a form,
 *  not a log — a mill ledger only writes the machine when it changes. Same
 *  convention as a paper daybook: a blank means "same as the line above." */
function useLedgerFade<T>(rows: T[], keyOf: (r: T) => unknown) {
  let prev: unknown;
  return rows.map((r) => {
    const k = keyOf(r);
    const repeat = k === prev;
    prev = k;
    return repeat;
  });
}

export default function DailyProductionList() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [date, setDate] = useState(todayIso());
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [pendingDelete, setPendingDelete] = useState<DailyProductionSummaryRow | null>(null);

  const { data, isLoading, isFetching } = useGetDailyProductionSummary(date);
  const deleteEntry = useDeleteDailyProduction();

  const { sorted: rows, sort, toggleSort } = useSort(data?.rows, {
    machineName: (r) => r.machineName,
    operatorName: (r) => r.operatorName,
    partyName: (r) => r.partyName,
    shift: (r) => r.shift,
    rollCount: (r) => r.rollCount,
    totalProduction: (r) => parseFloat(r.totalProduction),
  });

  // The ledger fade blanks a repeated machine name to mean "same as the line
  // above". That only reads correctly while rows are grouped by machine — the
  // API's default order, or an explicit machine sort. Under any other sort the
  // blanks would fall on unrelated rows and hide the machine entirely, so the
  // fade is switched off.
  const groupedByMachine = sort.key === null || sort.key === "machineName";
  const rawMachineRepeats = useLedgerFade(rows, (r) => r.machineId);
  const machineRepeats = groupedByMachine
    ? rawMachineRepeats
    : rawMachineRepeats.map(() => false);

  const grandTotal = rows.reduce((s, r) => s + (parseFloat(r.totalProduction) || 0), 0);
  const dateLabel = format(new Date(date + "T00:00:00"), "d MMM yyyy");

  const openAdd = () => {
    setEditingId(null);
    setDialogOpen(true);
  };

  const openEdit = (id: number) => {
    setEditingId(id);
    setDialogOpen(true);
  };

  // Clearing editingId on close matters: the dialog keys its prefill off
  // entryId, so leaving a stale id behind would reopen "Add" in edit mode.
  const handleDialogOpenChange = (o: boolean) => {
    setDialogOpen(o);
    if (!o) setEditingId(null);
  };

  const confirmDelete = () => {
    if (!pendingDelete) return;
    deleteEntry.mutate(
      { id: pendingDelete.id },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/daily-production"] });
          toast({ title: "Production entry deleted" });
          setPendingDelete(null);
        },
        onError: (err) => {
          toast({
            title: "Failed to delete production entry",
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
              Daily production
            </h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Yarn roll output for <span className="num">{dateLabel}</span>, one line per recorded entry.
            </p>
          </div>
          <Button onClick={openAdd} className="shrink-0">
            <Plus className="mr-2 h-4 w-4" />
            Add new
          </Button>
        </header>

        {/* Filter */}
        <div className="flex flex-col gap-1.5 max-w-[220px]">
          <label className="eyebrow">Production date</label>
          <Input
            type="date"
            className="h-9"
            value={date}
            onChange={(e) => setDate(e.target.value || todayIso())}
          />
        </div>

        {/* Entries */}
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
            <h2 className="text-sm font-semibold text-foreground">Production entries</h2>
            <span className="eyebrow">{dateLabel}</span>
          </div>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <SortableHead className="eyebrow h-11 px-5" label="Machine number" sortKey="machineName" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Operator" sortKey="operatorName" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Party" sortKey="partyName" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Shift" sortKey="shift" sort={sort} onSort={toggleSort} />
                  <SortableHead className="eyebrow h-11" label="Rolls" sortKey="rollCount" sort={sort} onSort={toggleSort} right />
                  <SortableHead className="eyebrow h-11" label="Total production" sortKey="totalProduction" sort={sort} onSort={toggleSort} right />
                  <TableHead className="eyebrow h-11 px-5 text-right">Action</TableHead>
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
                    <TableCell colSpan={COLUMN_COUNT} className="text-center py-10 text-muted-foreground">
                      Nothing recorded for {dateLabel} yet. Add an entry to get started.
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((r, i) => (
                    // Reconciled rows are tinted yellow. The dark variant is
                    // there because index.css ships a full dark-mode block —
                    // bg-yellow-100 alone would vanish against it. Light mode
                    // is exactly bg-yellow-100.
                    <TableRow
                      key={r.id}
                      className={r.reconciled ? "bg-yellow-100 hover:bg-yellow-100 dark:bg-yellow-950/40 dark:hover:bg-yellow-950/40" : undefined}
                    >
                      <TableCell className={`whitespace-nowrap px-5 font-medium ${machineRepeats[i] ? "text-muted-foreground/50" : ""}`}>
                        {machineRepeats[i] ? "—" : (r.machineName ?? "-")}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">{r.operatorName ?? "-"}</TableCell>
                      <TableCell className="whitespace-nowrap">{r.partyName ?? "-"}</TableCell>
                      <TableCell className="whitespace-nowrap text-muted-foreground">
                        <span className="inline-flex items-center gap-2">
                          {r.shift}
                          {/* Colour alone can't carry this: it fails for
                              colour-blind users and disappears in print. */}
                          {r.reconciled && (
                            <span className="inline-flex items-center gap-1 rounded-sm border border-yellow-300 bg-yellow-50 px-1.5 py-0.5 text-[0.6875rem] font-medium uppercase tracking-wide text-yellow-900 dark:border-yellow-800 dark:bg-yellow-950 dark:text-yellow-200">
                              <Lock className="h-3 w-3" />
                              Reconciled
                            </span>
                          )}
                        </span>
                      </TableCell>
                      <TableCell className="num text-right">{r.rollCount}</TableCell>
                      <TableCell className="num text-right font-medium">{Number(r.totalProduction).toFixed(3)}</TableCell>
                      <TableCell className="px-5 text-right">
                        <div className="flex items-center justify-end gap-1">
                          {r.reconciled ? (
                            // Disabled rather than hidden: a vanished control
                            // reads as a bug, whereas a disabled one with a
                            // reason explains itself. The API refuses these
                            // writes independently — this is only the signpost.
                            <span
                              className="inline-flex items-center gap-1.5 pr-1 text-xs text-muted-foreground"
                              title={
                                r.reconciledTransactionId
                                  ? `Reconciled into transaction #${r.reconciledTransactionId}. Production entries can't be changed once reconciled.`
                                  : "Reconciled into a Fabric Production transaction. Production entries can't be changed once reconciled."
                              }
                            >
                              <Lock className="h-3.5 w-3.5" />
                              Locked
                            </span>
                          ) : (
                            <>
                              <Button
                                type="button"
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8"
                                aria-label={`Edit entry for ${r.machineName ?? "machine"}, ${r.shift} shift`}
                                onClick={() => openEdit(r.id)}
                              >
                                <Pencil className="h-4 w-4" />
                              </Button>
                              <Button
                                type="button"
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
                                aria-label={`Delete entry for ${r.machineName ?? "machine"}, ${r.shift} shift`}
                                onClick={() => setPendingDelete(r)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
              {rows.length > 0 && (
                <tfoot>
                  <TableRow className="hover:bg-transparent">
                    <TableCell colSpan={5} className="px-5 text-right text-sm text-muted-foreground">
                      Grand total
                    </TableCell>
                    <TableCell className="selvedge-top py-4 text-right">
                      <span className="num text-lg font-semibold text-foreground">{grandTotal.toFixed(3)}</span>
                    </TableCell>
                    <TableCell className="px-5" />
                  </TableRow>
                </tfoot>
              )}
            </Table>
          </CardContent>
        </Card>

        {isFetching && !isLoading && (
          <p className="text-xs text-muted-foreground -mt-4">Refreshing…</p>
        )}
      </div>

      <ProductionEntryDialog
        open={dialogOpen}
        onOpenChange={handleDialogOpenChange}
        entryId={editingId}
      />

      {/* Deletion is irreversible and cascades to the entry's yarn rolls, so
          the confirmation names the specific record rather than asking a
          generic "are you sure". */}
      <AlertDialog
        open={pendingDelete !== null}
        onOpenChange={(o) => { if (!o && !deleteEntry.isPending) setPendingDelete(null); }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this production entry?</AlertDialogTitle>
            <AlertDialogDescription>
              {pendingDelete && (
                <>
                  <span className="font-medium text-foreground">
                    {pendingDelete.machineName ?? "Machine"} · {pendingDelete.shift} shift
                  </span>
                  {" — "}
                  {pendingDelete.operatorName ?? "operator"}, {pendingDelete.partyName ?? "party"},
                  {" "}
                  <span className="num">{pendingDelete.rollCount}</span> roll
                  {pendingDelete.rollCount === 1 ? "" : "s"} totalling{" "}
                  <span className="num">{Number(pendingDelete.totalProduction).toFixed(3)}</span>.
                  <br />
                  <br />
                  This permanently removes the entry and all of its yarn roll records. It cannot be undone.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteEntry.isPending}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => { e.preventDefault(); confirmDelete(); }}
              disabled={deleteEntry.isPending}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteEntry.isPending && <Spinner className="mr-2" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  );
}
