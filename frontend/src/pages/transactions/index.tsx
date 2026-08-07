import { useState, useMemo, useEffect } from "react";
import { Link, useLocation } from "wouter";
import { Plus, Edit, Trash2, X } from "lucide-react";
import { SortableHead } from "@/components/sortable-head";
import { compareValues } from "@/hooks/use-sort";
import {
  useListTransactions,
  useDeleteTransaction,
  getListTransactionsQueryKey,
  useListTransactionTypeMaster,
  useListPartyMaster,
  useListLocationMaster,
  useListJobMaster,
  useListYarnBrandMaster,
  useListFabricTypeMaster,
} from "@workspace/api-client-react";
import { useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { DateInput } from "@/components/ui/date-input";
import { Label } from "@/components/ui/label";
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
import { Skeleton } from "@/components/ui/skeleton";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { TransactionAnalytics } from "./analytics-tab";
import { useToast } from "@/hooks/use-toast";
import { Layout } from "@/components/layout";
import { useIsMobile } from "@/hooks/use-mobile";

// ─── Column definitions ───────────────────────────────────────────────────────

type ColKey = "docNumber" | "transactionType" | "date" | "party" | "location" | "reference";

const ALL_COLUMNS: { key: ColKey; label: string }[] = [
  { key: "docNumber",        label: "Doc Number" },
  { key: "transactionType",  label: "Transaction Type" },
  { key: "date",             label: "Date" },
  { key: "party",            label: "Party" },
  { key: "location",         label: "Location" },
  { key: "reference",        label: "Reference" },
];
const ALL_COL_KEYS = ALL_COLUMNS.map((c) => c.key);
const LS_COL_ORDER = "tx-col-order";
const LS_FILTERS = "tx-filters";

// ─── Filters ──────────────────────────────────────────────────────────────────

const EMPTY_FILTERS = {
  transactionTypeId: "",
  partyId: "",
  dateFrom: "",
  dateTo: "",
  jobId: [] as string[],
  yarnBrandId: [] as string[],
  docNumber: "",
  reference: "",
};

// Persist the active filters to localStorage so they survive navigating to the
// New/Edit transaction screens (and back), and full page reloads. Mirrors the
// existing column-order persistence (LS_COL_ORDER) in this screen.
function loadFilters(): typeof EMPTY_FILTERS {
  try {
    const saved = localStorage.getItem(LS_FILTERS);
    if (!saved) return EMPTY_FILTERS;
    const parsed = JSON.parse(saved) as Partial<typeof EMPTY_FILTERS>;
    if (!parsed || typeof parsed !== "object") return EMPTY_FILTERS;
    // Coerce each field to its expected type so corrupt/stale storage can't
    // put a non-string or non-array into the filter state.
    return {
      transactionTypeId: typeof parsed.transactionTypeId === "string" ? parsed.transactionTypeId : "",
      partyId: typeof parsed.partyId === "string" ? parsed.partyId : "",
      dateFrom: typeof parsed.dateFrom === "string" ? parsed.dateFrom : "",
      dateTo: typeof parsed.dateTo === "string" ? parsed.dateTo : "",
      jobId: Array.isArray(parsed.jobId) ? parsed.jobId.map(String) : [],
      yarnBrandId: Array.isArray(parsed.yarnBrandId) ? parsed.yarnBrandId.map(String) : [],
      docNumber: typeof parsed.docNumber === "string" ? parsed.docNumber : "",
      reference: typeof parsed.reference === "string" ? parsed.reference : "",
    };
  } catch {
    return EMPTY_FILTERS;
  }
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function TransactionList() {
  const { data: transactions, isLoading } = useListTransactions();
  const { data: transactionTypeMaster } = useListTransactionTypeMaster();
  const { data: partyMaster } = useListPartyMaster();
  const { data: locationMaster } = useListLocationMaster();
  const { data: jobMaster } = useListJobMaster();
  const { data: yarnBrandMaster } = useListYarnBrandMaster();
  const { data: fabricTypeMaster } = useListFabricTypeMaster();
  const deleteTransaction = useDeleteTransaction();
  const queryClient = useQueryClient();
  const { toast } = useToast();
  const isMobile = useIsMobile();
  const [, setLocation] = useLocation();

  // Filters are hydrated from localStorage so the active filter set survives
  // navigating away to New/Edit (which unmounts this screen) and coming back.
  const [filters, setFilters] = useState(loadFilters);
  const [sort, setSort] = useState<{ key: ColKey; dir: "asc" | "desc" }>({ key: "date", dir: "desc" });
  // Filters collapse behind a toggle on phones (the 8-field wall is a lot of
  // scroll for a screen whose primary use is scanning entries).
  const [filtersOpen, setFiltersOpen] = useState(!isMobile);

  // ── Column order (drag-and-drop, persisted) ────────────────────────────────
  const [colOrder, setColOrder] = useState<ColKey[]>(() => {
    try {
      const saved = localStorage.getItem(LS_COL_ORDER);
      if (saved) {
        const arr = JSON.parse(saved) as string[];
        if (Array.isArray(arr)) {
          const valid = arr.filter((k) => ALL_COL_KEYS.includes(k as ColKey)) as ColKey[];
          const missing = ALL_COL_KEYS.filter((k) => !valid.includes(k));
          return [...valid, ...missing];
        }
      }
    } catch {}
    return ALL_COL_KEYS;
  });
  const [dragCol, setDragCol] = useState<ColKey | null>(null);

  useEffect(() => {
    localStorage.setItem(LS_COL_ORDER, JSON.stringify(colOrder));
  }, [colOrder]);

  // Persist filters on every change so they're restored when the user returns
  // from the New/Edit screens or after a reload.
  useEffect(() => {
    localStorage.setItem(LS_FILTERS, JSON.stringify(filters));
  }, [filters]);

  // ── Helpers ────────────────────────────────────────────────────────────────
  const setFilter = (key: keyof typeof EMPTY_FILTERS, value: string | string[]) =>
    setFilters((f) => ({ ...f, [key]: value }));

  const lookupName = (list: { id: number; name: string }[] | undefined, id: number | null | undefined) =>
    id != null ? (list?.find((x) => x.id === id)?.name ?? String(id)) : "-";

  // Jobs filtered by selected party
  const filteredJobOptions = useMemo(
    () =>
      (jobMaster ?? [])
        .filter((j) => !filters.partyId || j.partyId === Number(filters.partyId))
        .map((j) => ({ value: String(j.id), label: j.name })),
    [jobMaster, filters.partyId]
  );

  const hasFilters =
    filters.transactionTypeId !== "" ||
    filters.partyId !== "" ||
    filters.dateFrom !== "" ||
    filters.dateTo !== "" ||
    filters.jobId.length > 0 ||
    filters.yarnBrandId.length > 0 ||
    filters.docNumber !== "" ||
    filters.reference !== "";

  // ── Filtered + sorted rows ─────────────────────────────────────────────────
  const filtered = useMemo(() => {
    if (!transactions) return [];
    return transactions.filter((t) => {
      if (filters.transactionTypeId && String(t.transactionTypeId) !== filters.transactionTypeId) return false;
      if (filters.partyId && String(t.partyId) !== filters.partyId) return false;
      if (filters.dateFrom && t.date < filters.dateFrom) return false;
      if (filters.dateTo && t.date > filters.dateTo) return false;
      if (filters.jobId.length > 0 && !filters.jobId.includes(String(t.jobId ?? ""))) return false;
      if (filters.yarnBrandId.length > 0) {
        const brandIds = t.yarnBrandIds ?? [];
        if (!filters.yarnBrandId.some((id) => brandIds.includes(Number(id)))) return false;
      }
      if (filters.docNumber) {
        if (!(t.docNumber ?? "").toLowerCase().includes(filters.docNumber.toLowerCase())) return false;
      }
      if (filters.reference) {
        if (!(t.reference ?? "").toLowerCase().includes(filters.reference.toLowerCase())) return false;
      }
      return true;
    });
  }, [transactions, filters]);

  const sorted = useMemo(() => {
    const arr = [...filtered];
    arr.sort((a, b) => {
      let av = "", bv = "";
      switch (sort.key) {
        case "docNumber":         av = a.docNumber ?? "";                              bv = b.docNumber ?? "";                              break;
        case "date":              av = a.date ?? "";                                   bv = b.date ?? "";                                   break;
        case "transactionType":   av = lookupName(transactionTypeMaster, a.transactionTypeId); bv = lookupName(transactionTypeMaster, b.transactionTypeId); break;
        case "party":             av = lookupName(partyMaster, a.partyId);             bv = lookupName(partyMaster, b.partyId);             break;
        case "location":          av = lookupName(locationMaster, a.locationId);       bv = lookupName(locationMaster, b.locationId);       break;
        case "reference":         av = (a as { reference?: string | null }).reference ?? ""; bv = (b as { reference?: string | null }).reference ?? ""; break;
      }
      // compareValues instead of a bare localeCompare: the previous version
      // ordered "10" before "9", so any numeric-ish column (doc numbers,
      // machine codes like M#2 vs M#10) sorted character by character rather
      // than by value. Dates were unaffected because they are ISO.
      return sort.dir === "asc" ? compareValues(av, bv) : compareValues(bv, av);
    });
    return arr;
  }, [filtered, sort, transactionTypeMaster, partyMaster, locationMaster]);

  // ── Sort handlers ──────────────────────────────────────────────────────────
  function handleSort(key: ColKey) {
    setSort((prev) =>
      prev.key === key ? { key, dir: prev.dir === "asc" ? "desc" : "asc" } : { key, dir: "asc" }
    );
  }

  // SortIcon and the hand-rolled <TableHead> it lived in were replaced by the
  // shared SortableHead, which also makes these columns keyboard-sortable.

  // ── Drag handlers ──────────────────────────────────────────────────────────
  function handleDragStart(_e: React.DragEvent, key: ColKey) { setDragCol(key); }
  function handleDragOver(e: React.DragEvent, key: ColKey) {
    e.preventDefault();
    if (!dragCol || dragCol === key) return;
    setColOrder((prev) => {
      const next = [...prev];
      const from = next.indexOf(dragCol);
      const to   = next.indexOf(key);
      if (from === -1 || to === -1) return prev;
      next.splice(from, 1);
      next.splice(to, 0, dragCol);
      return next;
    });
  }
  function handleDragEnd() { setDragCol(null); }

  // ── Ordered column list ────────────────────────────────────────────────────
  const orderedCols = colOrder.map((k) => ALL_COLUMNS.find((c) => c.key === k)!).filter(Boolean);

  // ── Delete handler ─────────────────────────────────────────────────────────
  const handleDelete = (id: number) => {
    deleteTransaction.mutate(
      { id },
      {
        onSuccess: () => {
          toast({ title: "Transaction deleted successfully" });
          queryClient.invalidateQueries({ queryKey: getListTransactionsQueryKey() });
        },
        onError: () => {
          toast({ title: "Failed to delete transaction", variant: "destructive" });
        },
      }
    );
  };

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <Layout>
      <div className="flex flex-col gap-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Transactions</h1>
            <p className="text-muted-foreground mt-1">Manage factory transactions and production entries.</p>
          </div>
          <Link href="/transactions/new">
            <Button className="w-full sm:w-auto">
              <Plus className="mr-2 h-4 w-4" />
              New Transaction
            </Button>
          </Link>
        </div>

        {/* Filter Bar — collapsible on mobile (P4). The toggle is hidden on
            sm+ where the full grid always shows. */}
        <div className="rounded-md border bg-card p-4">
          <div className="flex items-center justify-between sm:hidden">
            <button
              type="button"
              className="flex h-11 flex-1 items-center justify-between rounded-md border border-input bg-background px-3 text-sm font-medium text-foreground"
              onClick={() => setFiltersOpen((o) => !o)}
              aria-expanded={filtersOpen}
            >
              Filters
              <span className="text-muted-foreground">{filtersOpen ? "Hide" : "Show"}</span>
            </button>
          </div>
          <div className={`space-y-3 ${filtersOpen ? "mt-3 block" : "hidden"} sm:mt-0 sm:block`}>
          {/* Row 1 */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Transaction Type</Label>
              <Select
                value={filters.transactionTypeId || "all"}
                onValueChange={(v) => setFilter("transactionTypeId", v === "all" ? "" : v)}
              >
                <SelectTrigger className="h-11 sm:h-9">
                  <SelectValue placeholder="All" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  {transactionTypeMaster?.map((t) => (
                    <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Party</Label>
              <Select
                value={filters.partyId || "all"}
                onValueChange={(v) => {
                  setFilters((f) => ({ ...f, partyId: v === "all" ? "" : v, jobId: [] }));
                }}
              >
                <SelectTrigger className="h-11 sm:h-9">
                  <SelectValue placeholder="All" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  {partyMaster?.map((p) => (
                    <SelectItem key={p.id} value={String(p.id)}>{p.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Date From</Label>
              <DateInput
                className="h-11 sm:h-9"
                value={filters.dateFrom}
                onChange={(e) => setFilter("dateFrom", e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Date To</Label>
              <DateInput
                className="h-11 sm:h-9"
                value={filters.dateTo}
                onChange={(e) => setFilter("dateTo", e.target.value)}
              />
            </div>
          </div>

          {/* Row 2 */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Job Type</Label>
              <MultiSelect
                options={filteredJobOptions}
                selected={filters.jobId}
                onChange={(v) => setFilter("jobId", v)}
                placeholder="All"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Yarn Brand</Label>
              <MultiSelect
                options={(yarnBrandMaster ?? []).map((b) => ({ value: String(b.id), label: b.name }))}
                selected={filters.yarnBrandId}
                onChange={(v) => setFilter("yarnBrandId", v)}
                placeholder="All"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Document Number</Label>
              <Input
                className="h-11 sm:h-9"
                placeholder="Search doc number…"
                value={filters.docNumber}
                onChange={(e) => setFilter("docNumber", e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Reference</Label>
              <div className="flex gap-2">
                <Input
                  className="h-11 flex-1 sm:h-9"
                  placeholder="Search reference…"
                  value={filters.reference}
                  onChange={(e) => setFilter("reference", e.target.value)}
                />
                {hasFilters && (
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-11 w-11 shrink-0 text-muted-foreground hover:text-foreground sm:h-9 sm:w-9"
                    onClick={() => setFilters(EMPTY_FILTERS)}
                    title="Clear filters"
                  >
                    <X className="h-4 w-4" />
                  </Button>
                )}
              </div>
            </div>
          </div>

          {hasFilters && (
            <p className="text-xs text-muted-foreground">
              Showing {filtered.length} of {transactions?.length ?? 0} transactions
            </p>
          )}
          </div>
        </div>

        {/* Table + analytics — tabs. The table is wrapped in its own border
            card; the analytics tab aggregates client-side from the same
            filtered rows so charts always match the active filters. */}
        <Tabs defaultValue="entries">
          <TabsList>
            <TabsTrigger value="entries">Entries</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
          </TabsList>
          <TabsContent value="entries" className="mt-4">
        {/* Table — single scroll container: the Table component already wraps
            itself in overflow-auto, so an outer overflow-auto would create a
            second scrollport that clips the sticky Actions column (P1). */}
        <div className="rounded-md border bg-card overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                {orderedCols.map((c) => (
                  <SortableHead
                    key={c.key}
                    label={c.label}
                    sortKey={c.key}
                    sort={sort}
                    onSort={(k) => handleSort(k as ColKey)}
                    draggable
                    isDragging={dragCol === c.key}
                    onDragStart={(e) => handleDragStart(e, c.key)}
                    onDragOver={(e) => handleDragOver(e, c.key)}
                    onDrop={(e) => e.preventDefault()}
                    onDragEnd={handleDragEnd}
                  />
                ))}
                <TableHead className="sticky right-0 z-10 bg-background px-1.5 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {orderedCols.map((c) => (
                      <TableCell key={c.key}><Skeleton className="h-5 w-24" /></TableCell>
                    ))}
                    <TableCell><Skeleton className="h-8 w-16 ml-auto" /></TableCell>
                  </TableRow>
                ))
              ) : sorted.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={orderedCols.length + 1} className="text-center py-10 text-muted-foreground">
                    {hasFilters ? "No transactions match the selected filters." : "No transactions found. Create one to get started."}
                  </TableCell>
                </TableRow>
              ) : (
                sorted.map((t) => {
                  const ref = (t as { reference?: string | null }).reference;
                  return (
                    // Whole-row tap opens edit on mobile (P3) — the action
                    // cell stops propagation so its buttons still work.
                    <TableRow
                      key={t.id}
                      className={isMobile ? "cursor-pointer" : undefined}
                      onClick={isMobile ? () => setLocation(`/transactions/${t.id}/edit`) : undefined}
                    >
                      {orderedCols.map((c) => {
                        switch (c.key) {
                          case "docNumber":       return <TableCell key={c.key} className="font-medium whitespace-nowrap">{t.docNumber}</TableCell>;
                          case "transactionType": return <TableCell key={c.key} className="whitespace-nowrap">{lookupName(transactionTypeMaster, t.transactionTypeId)}</TableCell>;
                          case "date":            return <TableCell key={c.key} className="whitespace-nowrap">{new Date(t.date + "T00:00:00").toLocaleDateString()}</TableCell>;
                          case "party":           return <TableCell key={c.key} className="whitespace-nowrap">{lookupName(partyMaster, t.partyId)}</TableCell>;
                          case "location":        return <TableCell key={c.key} className="whitespace-nowrap">{lookupName(locationMaster, t.locationId)}</TableCell>;
                          case "reference":       return <TableCell key={c.key} className="whitespace-nowrap text-muted-foreground">{ref ?? "-"}</TableCell>;
                          default:                return <TableCell key={c.key} />;
                        }
                      })}
                      <TableCell className="sticky right-0 z-10 bg-background px-1.5 text-right">
                        <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                          <Link href={`/transactions/${t.id}/edit`}>
                            <Button variant="ghost" size="icon" className="h-11 w-11 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8">
                              <Edit className="h-4 w-4" />
                              <span className="sr-only">Edit</span>
                            </Button>
                          </Link>

                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-11 w-11 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8">
                                <Trash2 className="h-4 w-4" />
                                <span className="sr-only">Delete</span>
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Delete Transaction?</AlertDialogTitle>
                                <AlertDialogDescription>
                                  <span className="font-medium text-foreground">
                                    {t.docNumber} · {lookupName(transactionTypeMaster, t.transactionTypeId)}
                                  </span>
                                  {" — "}
                                  {lookupName(partyMaster, t.partyId)}
                                  {ref ? ` · ${ref}` : ""}
                                  {" on "}
                                  {new Date(t.date + "T00:00:00").toLocaleDateString()}
                                  {". This cannot be undone."}
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancel</AlertDialogCancel>
                                <AlertDialogAction
                                  onClick={() => handleDelete(t.id)}
                                  className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                                >
                                  Delete
                                </AlertDialogAction>
                              </AlertDialogFooter>
                            </AlertDialogContent>
                          </AlertDialog>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </div>
          </TabsContent>
          <TabsContent value="analytics" className="mt-4">
            <TransactionAnalytics
              rows={filtered}
              isLoading={isLoading}
              countLabel={`${filtered.length} of ${transactions?.length ?? 0} transactions`}
              transactionTypeMaster={transactionTypeMaster}
              partyMaster={partyMaster}
              locationMaster={locationMaster}
              fabricTypeMaster={fabricTypeMaster}
              jobMaster={jobMaster}
            />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}
