import { useState, useMemo } from "react";
import { Link } from "wouter";
import { Plus, Edit, Trash2, X } from "lucide-react";
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

const EMPTY_FILTERS = {
  transactionTypeId: "",
  partyId: "",
  dateFrom: "",
  dateTo: "",
  jobId: [] as string[],
  yarnBrandId: [] as string[],
};

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

  const setFilter = (key: keyof typeof EMPTY_FILTERS, value: string | string[]) =>
    setFilters((f) => ({ ...f, [key]: value }));

  // Jobs filtered by selected party (all jobs when no party chosen)
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
    filters.yarnBrandId.length > 0;

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
      return true;
    });
  }, [transactions, filters]);

  const lookupName = (list: { id: number; name: string }[] | undefined, id: number | null | undefined) =>
    id != null ? (list?.find((x) => x.id === id)?.name ?? String(id)) : "-";

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
              <div className="flex gap-2">
                <Input
                  type="date"
                  className="h-9 flex-1"
                  value={filters.dateTo}
                  onChange={(e) => setFilter("dateTo", e.target.value)}
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

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="flex flex-col gap-1.5">
              <Label className="text-xs text-muted-foreground">Job Type</Label>
              <MultiSelect
                options={filteredJobOptions}
                selected={filters.jobId}
                onChange={(v) => setFilter("jobId", v)}
                placeholder={filters.partyId ? "All" : "All"}
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
          </div>

          {hasFilters && (
            <p className="text-xs text-muted-foreground">
              Showing {filtered.length} of {transactions?.length ?? 0} transactions
            </p>
          )}
        </div>

        <div className="rounded-md border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Doc Number</TableHead>
                <TableHead>Transaction Type</TableHead>
                <TableHead>Date</TableHead>
                <TableHead>Party</TableHead>
                <TableHead>Location</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    <TableCell><Skeleton className="h-5 w-24" /></TableCell>
                    <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                    <TableCell><Skeleton className="h-5 w-24" /></TableCell>
                    <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                    <TableCell><Skeleton className="h-5 w-20" /></TableCell>
                    <TableCell><Skeleton className="h-8 w-16 ml-auto" /></TableCell>
                  </TableRow>
                ))
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-10 text-muted-foreground">
                    {hasFilters ? "No transactions match the selected filters." : "No transactions found. Create one to get started."}
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((t) => (
                  <TableRow key={t.id}>
                    <TableCell className="font-medium">{t.docNumber}</TableCell>
                    <TableCell>{lookupName(transactionTypeMaster, t.transactionTypeId)}</TableCell>
                    <TableCell>{new Date(t.date + "T00:00:00").toLocaleDateString()}</TableCell>
                    <TableCell>{lookupName(partyMaster, t.partyId)}</TableCell>
                    <TableCell>{lookupName(locationMaster, t.locationId)}</TableCell>
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
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>
    </Layout>
  );
}
