import { useState, useMemo, useEffect } from "react";
import { Link } from "wouter";
import { Plus, Edit, Trash2, X, ChevronUp, ChevronDown, ChevronsUpDown } from "lucide-react";
import {
  useListTransactions,
  useDeleteTransaction,
  getListTransactionsQueryKey,
  useListTransactionTypeMaster,
  useListPartyMaster,
  useListLocationMaster,
  useListJobMaster,
  useListYarnBrandMaster,
} from "@workspace/api-client-react";
import { useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
import { useToast } from "@/hooks/use-toast";
import { Layout } from "@/components/layout";

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

// ─── Component ────────────────────────────────────────────────────────────────

export default function TransactionList() {
  const { data: transactions, isLoading } = useListTransactions();
  const { data: transactionTypeMaster } = useListTransactionTypeMaster();
  const { data: partyMaster } = useListPartyMaster();
  const { data: locationMaster } = useListLocationMaster();
  const { data: jobMaster } = useListJobMaster();
  const { data: yarnBrandMaster } = useListYarnBrandMaster();
  const deleteTransaction = useDeleteTransaction();
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const [filters, setFilters] = useState(EMPTY_FILTERS);
  const [sort, setSort] = useState<{ key: ColKey; dir: "asc" | "desc" }>({ key: "date", dir: "desc" });

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
      return sort.dir === "asc" ? av.localeCompare(bv) : bv.localeCompare(av);
    });
    return arr;
  }, [filtered, sort, transactionTypeMaster, partyMaster, locationMaster]);

  // ── Sort handlers ──────────────────────────────────────────────────────────
  function handleSort(key: ColKey) {
    setSort((prev) =>
      prev.key === key ? { key, dir: prev.dir === "asc" ? "desc" : "asc" } : { key, dir: "asc" }
    );
  }

  function SortIcon({ col }: { col: ColKey }) {
    if (sort.key !== col) return <ChevronsUpDown className="inline h-3 w-3 opacity-35 ml-1" />;
    return sort.dir === "asc"
      ? <ChevronUp className="inline h-3 w-3 ml-1" />
      : <ChevronDown className="inline h-3 w-3 ml-1" />;
  }

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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Transactions</h1>
            <p className="text-muted-foreground mt-1">Manage factory transactions and production entries.</p>
          </div>
          <Link href="/transactions/new">
            <Button>
              <Plus className="mr-2 h-4 w-4" />
              New Transaction
            </Button>
          </Link>
        </div>

        {/* Filter Bar */}
        <div className="rounded-md border bg-card p-4 space-y-3">
          {/* Row 1 */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Transaction Type</Label>
              <Select
                value={filters.transactionTypeId || "all"}
                onValueChange={(v) => setFilter("transactionTypeId", v === "all" ? "" : v)}
              >
                <SelectTrigger className="h-9">
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
                <SelectTrigger className="h-9">
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
              <Input
                type="date"
                className="h-9"
                value={filters.dateFrom}
                onChange={(e) => setFilter("dateFrom", e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Date To</Label>
              <Input
                type="date"
                className="h-9"
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
                className="h-9"
                placeholder="Search doc number…"
                value={filters.docNumber}
                onChange={(e) => setFilter("docNumber", e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Reference</Label>
              <div className="flex gap-2">
                <Input
                  className="h-9 flex-1"
                  placeholder="Search reference…"
                  value={filters.reference}
                  onChange={(e) => setFilter("reference", e.target.value)}
                />
                {hasFilters && (
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-9 w-9 shrink-0 text-muted-foreground hover:text-foreground"
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

        {/* Table */}
        <div className="rounded-md border bg-card overflow-auto">
          <Table>
            <TableHeader>
              <TableRow>
                {orderedCols.map((c) => (
                  <TableHead
                    key={c.key}
                    className={`select-none whitespace-nowrap cursor-grab transition-opacity${dragCol === c.key ? " opacity-30" : ""}`}
                    draggable
                    onClick={() => handleSort(c.key)}
                    onDragStart={(e) => handleDragStart(e, c.key)}
                    onDragOver={(e) => handleDragOver(e, c.key)}
                    onDrop={(e) => e.preventDefault()}
                    onDragEnd={handleDragEnd}
                  >
                    {c.label}<SortIcon col={c.key} />
                  </TableHead>
                ))}
                <TableHead className="text-right">Actions</TableHead>
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
                    <TableRow key={t.id}>
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
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Link href={`/transactions/${t.id}/edit`}>
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground hover:text-foreground">
                              <Edit className="h-4 w-4" />
                              <span className="sr-only">Edit</span>
                            </Button>
                          </Link>

                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground hover:text-destructive">
                                <Trash2 className="h-4 w-4" />
                                <span className="sr-only">Delete</span>
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Delete Transaction?</AlertDialogTitle>
                                <AlertDialogDescription>
                                  This action cannot be undone. This will permanently delete transaction {t.docNumber}.
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
      </div>
    </Layout>
  );
}
