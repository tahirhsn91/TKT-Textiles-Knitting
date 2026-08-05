import { NUM_DECIMALS } from "@/lib/format";
import { useEffect, useRef, useState, useCallback, useMemo } from "react";
import { useLocation, useParams } from "wouter";
import { useForm, useFieldArray, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Plus, Trash2, ArrowLeft, Lock, Loader2 } from "lucide-react";
import { useUnreconciledProduction } from "@/hooks/use-daily-production";
import { useUnreconciledYarnReceipts } from "@/hooks/use-yarn-receipts";
import { useUnreconciledDailyDeliveries } from "@/hooks/use-daily-deliveries";
import { useQueryClient, useQuery } from "@tanstack/react-query";
import { format } from "date-fns";

import {
  useListTransactionTypeMaster,
  useListJobMaster,
  useListPartyMaster,
  useListMachineMaster,
  useListLocationMaster,
  useListYarnTypeMaster,
  useListYarnCountMaster,
  useListYarnBrandMaster,
  useListUomMaster,
  useListFabricTypeMaster,
  useListEmployeeMaster,
  useGetTransaction,
  useCreateTransaction,
  useUpdateTransaction,
  getGetTransactionQueryKey,
  getListTransactionsQueryKey
} from "@workspace/api-client-react";

import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { DateInput } from "@/components/ui/date-input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";


const nullableInt = z.preprocess(
  (v) => (v === "" || v === null || v === undefined ? null : Number(v)),
  z.number().int().nullable()
);

const detailSchema = z.object({
  id: z.number().optional(),
  machineId: z.number().nullable(),
  employeeId: z.number().nullable(),
  yarnTypeId: z.number().nullable(),
  yarnCountId: z.number().nullable(),
  yarnBrandId: z.number().nullable(),
  uomId: z.number().nullable(),
  quantity: z.string().nullable(),
  netWt: z.string().nullable(),
});

const formSchema = z.object({
  transactionTypeId: z.number({ required_error: "Transaction Type is required" }),
  date: z.date({ required_error: "Date is required" }),
  docNumber: z.string().min(1, "Document Number is required"),
  jobId: z.number().nullable(),
  partyId: z.number().nullable(),
  locationId: z.number().nullable(),
  reference: z.string().nullable(),
  fabricTypeId: z.number().nullable(),
  sl: z.string().nullable(),
  gsm: nullableInt,
  details: z.array(detailSchema),
});

type FormValues = z.infer<typeof formSchema>;

const emptyDetail = (): z.infer<typeof detailSchema> => ({
  machineId: null,
  employeeId: null,
  yarnTypeId: null,
  yarnCountId: null,
  yarnBrandId: null,
  uomId: null,
  quantity: "1",
  netWt: null,
});

export default function TransactionForm() {
  const [, setLocation] = useLocation();
  const params = useParams();
  const id = params.id ? parseInt(params.id) : null;
  const isEditing = !!id;
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: transaction, isLoading: isLoadingTx, isError: isErrorTx } = useGetTransaction(id!, {
    query: { enabled: isEditing, queryKey: getGetTransactionQueryKey(id!) }
  });

  const { data: suggestions } = useQuery<{ nextDocNumber: string; lastReference: string | null }>({
    queryKey: ["transaction-suggestions"],
    queryFn: () => fetch(`${import.meta.env.BASE_URL}api/transactions/suggestions`).then((r) => r.json()),
    enabled: !isEditing,
    staleTime: 0,
  });

  const { data: transactionTypeMaster } = useListTransactionTypeMaster();
  const { data: jobMaster } = useListJobMaster();
  const { data: partyMaster } = useListPartyMaster();
  const { data: machineMaster } = useListMachineMaster();
  const { data: locationMaster } = useListLocationMaster();
  const { data: yarnTypeMaster } = useListYarnTypeMaster();
  const { data: yarnCountMaster } = useListYarnCountMaster();
  const { data: yarnBrandMaster } = useListYarnBrandMaster();
  const { data: uomMaster } = useListUomMaster();
  const { data: fabricTypeMaster } = useListFabricTypeMaster();
  const { data: employeeMaster } = useListEmployeeMaster();

  const createTx = useCreateTransaction();
  const updateTx = useUpdateTransaction();

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      transactionTypeId: undefined,
      date: new Date(),
      docNumber: "",
      jobId: null,
      partyId: null,
      locationId: null,
      reference: null,
      fabricTypeId: null,
      sl: null,
      gsm: null,
      details: [emptyDetail()],
    },
  });

  const { fields, append, remove } = useFieldArray({
    name: "details",
    control: form.control,
  });

  const watchedPartyId = form.watch("partyId");

  const watchedDetails = useWatch({ control: form.control, name: "details" });

  // ─── Fabric Production reconciliation ──────────────────────────────────────
  // Matched on the master's `code`, not its name or id: names are user-editable
  // in Master Data and ids differ per environment, so either would break the
  // moment someone renames the type or the app is deployed elsewhere.
  const watchedTypeId = form.watch("transactionTypeId");
  const watchedDate = form.watch("date");

  const isFabricProduction =
    transactionTypeMaster?.find((t) => t.id === watchedTypeId)?.code === "Fabric_Production";
  const isYarnReceipt =
    transactionTypeMaster?.find((t) => t.id === watchedTypeId)?.code === "Yarn_Receipt";
  const isFabricDelivery =
    transactionTypeMaster?.find((t) => t.id === watchedTypeId)?.code === "Fabric_Dispatch";

  const productionDateIso = watchedDate ? format(watchedDate, "yyyy-MM-dd") : "";

  const { data: unreconciled, isFetching: loadingProduction } = useUnreconciledProduction(
    isFabricProduction && !isEditing ? productionDateIso : "",
    isFabricProduction && !isEditing ? watchedPartyId : null,
  );

  // Ids claimed on save. Cleared whenever the date/party combination changes so
  // a transaction can never carry ids from a combination the user moved away from.
  const [reconcileIds, setReconcileIds] = useState<number[]>([]);
  const [reconcileReceiptIds, setReconcileReceiptIds] = useState<number[]>([]);
  const [reconcileDeliveryIds, setReconcileDeliveryIds] = useState<number[]>([]);

  // Auto-fill runs once per date+party pair. Without this guard every
  // background refetch would overwrite line items the user had already edited.
  const filledFor = useRef<string | null>(null);

  useEffect(() => {
    if (!isFabricProduction || isEditing) {
      filledFor.current = null;
      if (reconcileIds.length > 0) setReconcileIds([]);
      return;
    }

    const key = `${productionDateIso}|${watchedPartyId ?? ""}`;
    if (filledFor.current === key) return;
    if (!unreconciled || loadingProduction) return;

    filledFor.current = key;

    if (unreconciled.rows.length === 0) {
      setReconcileIds([]);
      return;
    }

    // One detail line per production entry: roll count becomes quantity and
    // total roll weight becomes net weight. Yarn type/count/brand and UoM are
    // left blank — daily production doesn't record them, and guessing would put
    // unverified values on a stock movement.
    form.setValue(
      "details",
      unreconciled.rows.map((p) => ({
        machineId: p.machineId,
        employeeId: p.employeeId,
        yarnTypeId: null,
        yarnCountId: null,
        yarnBrandId: null,
        uomId: null,
        quantity: String(p.rollCount),
        netWt: p.totalProduction,
      })),
      { shouldDirty: true },
    );
    setReconcileIds(unreconciled.rows.map((p) => p.id));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isFabricProduction, isEditing, productionDateIso, watchedPartyId, unreconciled, loadingProduction]);

  const { data: unreconciledReceipts, isFetching: loadingReceipts } = useUnreconciledYarnReceipts(
    isYarnReceipt && !isEditing ? productionDateIso : "",
    isYarnReceipt && !isEditing ? watchedPartyId : null,
  );

  const filledReceiptsFor = useRef<string | null>(null);

  // Same auto-fill guard as the production flow, for Yarn Receipt types:
  // one detail line per receipt line (yarn count, bags, net weight). The
  // receipt header ids are stashed for the save-time claim.
  useEffect(() => {
    if (!isYarnReceipt || isEditing) {
      filledReceiptsFor.current = null;
      if (reconcileReceiptIds.length > 0) setReconcileReceiptIds([]);
      return;
    }

    const key = `${productionDateIso}|${watchedPartyId ?? ""}`;
    if (filledReceiptsFor.current === key) return;
    if (!unreconciledReceipts || loadingReceipts) return;

    filledReceiptsFor.current = key;

    if (unreconciledReceipts.rows.length === 0) {
      setReconcileReceiptIds([]);
      return;
    }

    form.setValue(
      "details",
      unreconciledReceipts.rows.map((r) => ({
        machineId: null,
        employeeId: null,
        yarnTypeId: null,
        yarnCountId: r.yarnCountId,
        yarnBrandId: r.yarnBrandId,
        uomId: null,
        quantity: String(r.quantity),
        netWt: r.netWeight,
      })),
      { shouldDirty: true },
    );
    setReconcileReceiptIds(unreconciledReceipts.receiptIds);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isYarnReceipt, isEditing, productionDateIso, watchedPartyId, unreconciledReceipts, loadingReceipts]);

  const { data: unreconciledDeliveries, isFetching: loadingDeliveries } = useUnreconciledDailyDeliveries(
    isFabricDelivery && !isEditing ? productionDateIso : "",
    isFabricDelivery && !isEditing ? watchedPartyId : null,
  );

  const filledDeliveriesFor = useRef<string | null>(null);

  // Same auto-fill guard as the production/receipt flows, for Fabric Delivery
  // types: one detail line per delivery (quantity = rolls, netWt = kg). The
  // delivery ids are stashed for the save-time claim.
  useEffect(() => {
    if (!isFabricDelivery || isEditing) {
      filledDeliveriesFor.current = null;
      if (reconcileDeliveryIds.length > 0) setReconcileDeliveryIds([]);
      return;
    }

    const key = `${productionDateIso}|${watchedPartyId ?? ""}`;
    if (filledDeliveriesFor.current === key) return;
    if (!unreconciledDeliveries || loadingDeliveries) return;

    filledDeliveriesFor.current = key;

    if (unreconciledDeliveries.rows.length === 0) {
      setReconcileDeliveryIds([]);
      return;
    }

    form.setValue(
      "details",
      unreconciledDeliveries.rows.map((d) => ({
        machineId: null,
        employeeId: null,
        yarnTypeId: null,
        yarnCountId: null,
        yarnBrandId: null,
        uomId: null,
        quantity: String(d.quantity),
        netWt: d.netWeight,
      })),
      { shouldDirty: true },
    );
    setReconcileDeliveryIds(unreconciledDeliveries.rows.map((d) => d.id));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isFabricDelivery, isEditing, productionDateIso, watchedPartyId, unreconciledDeliveries, loadingDeliveries]);

  const runTotals = useMemo(() => {
    const result: number[] = [];
    let running = 0;
    let prevMachineId: number | null | undefined = undefined;
    let prevEmployeeId: number | null | undefined = undefined;
    for (let i = 0; i < (watchedDetails?.length ?? 0); i++) {
      const d = watchedDetails[i];
      const machineId = d?.machineId ?? null;
      const employeeId = d?.employeeId ?? null;
      const netWt = parseFloat(d?.netWt?.toString() ?? "0") || 0;
      if (i === 0 || machineId !== prevMachineId || employeeId !== prevEmployeeId) {
        running = netWt;
      } else {
        running += netWt;
      }
      result.push(running);
      prevMachineId = machineId;
      prevEmployeeId = employeeId;
    }
    return result;
  }, [watchedDetails]);

  const mcRunTotals = useMemo(() => {
    const result: number[] = [];
    let running = 0;
    let prevMachineId: number | null | undefined = undefined;
    for (let i = 0; i < (watchedDetails?.length ?? 0); i++) {
      const d = watchedDetails[i];
      const machineId = d?.machineId ?? null;
      const netWt = parseFloat(d?.netWt?.toString() ?? "0") || 0;
      if (i === 0 || machineId !== prevMachineId) {
        running = netWt;
      } else {
        running += netWt;
      }
      result.push(running);
      prevMachineId = machineId;
    }
    return result;
  }, [watchedDetails]);

  const filteredJobMaster = jobMaster?.filter((j) =>
    watchedPartyId == null ? true : j.partyId === watchedPartyId
  );

  useEffect(() => {
    const currentJobId = form.getValues("jobId");
    if (currentJobId == null) return;
    const jobStillValid = filteredJobMaster?.some((j) => j.id === currentJobId);
    if (!jobStillValid) {
      form.setValue("jobId", null);
    }
  }, [watchedPartyId]);

  const lookupsReady = !!(
    jobMaster && partyMaster && machineMaster && locationMaster &&
    yarnTypeMaster && yarnCountMaster && yarnBrandMaster && uomMaster &&
    fabricTypeMaster && employeeMaster &&
    transactionTypeMaster
  );

  useEffect(() => {
    if (!isEditing && suggestions) {
      form.setValue("docNumber", suggestions.nextDocNumber);
      if (suggestions.lastReference) {
        form.setValue("reference", suggestions.lastReference);
      }
    }
  }, [isEditing, suggestions]);

  useEffect(() => {
    if (transaction && isEditing && lookupsReady) {
      form.reset({
        transactionTypeId: transaction.transactionTypeId,
        date: new Date(transaction.date + "T00:00:00"),
        docNumber: transaction.docNumber,
        jobId: transaction.jobId ?? null,
        partyId: transaction.partyId ?? null,
        locationId: transaction.locationId ?? null,
        reference: (transaction as { reference?: string | null }).reference ?? null,
        fabricTypeId: transaction.fabricTypeId ?? null,
        sl: transaction.sl ?? null,
        gsm: transaction.gsm ?? null,
        details: transaction.details.length > 0
          ? transaction.details.map(d => ({
              id: d.id,
              machineId: d.machineId ?? null,
              employeeId: d.employeeId ?? null,
              yarnTypeId: d.yarnTypeId ?? null,
              yarnCountId: d.yarnCountId ?? null,
              yarnBrandId: d.yarnBrandId ?? null,
              uomId: d.uomId ?? null,
              quantity: d.quantity ?? null,
              netWt: d.netWt ?? null,
            }))
          : [emptyDetail()],
      });
    }
  }, [transaction, isEditing, lookupsReady, form]);

  const onSubmit = (values: FormValues) => {
    // P7: block save when any line has a non-positive quantity or net weight.
    // Blank is allowed ("None" rows), but a typed zero/negative is a typo the
    // floor should catch before it hits the books.
    const badLines: number[] = [];
    values.details.forEach((d, i) => {
      const qty = d.quantity;
      const wt = d.netWt;
      if (qty !== null && qty !== undefined && qty !== "" && !(Number(qty) > 0)) badLines.push(i);
      if (wt !== null && wt !== undefined && wt !== "" && !(Number(wt) > 0)) badLines.push(i);
    });
    if (badLines.length > 0) {
      const shown = [...new Set(badLines)].slice(0, 3);
      setLineError(
        `Line ${shown.map((i) => i + 1).join(", ")}${badLines.length > 3 ? "…" : ""} ${badLines.length === 1 ? "has" : "have"} a quantity or net weight that must be greater than zero.`,
      );
      return;
    }
    setLineError(null);

    const payload = {
      ...values,
      date: format(values.date, "yyyy-MM-dd"),
      details: values.details.map((d) => ({
        ...d,
        quantity: d.quantity === "" ? null : d.quantity,
        netWt: d.netWt === "" ? null : d.netWt,
      })),
    };

    if (isEditing) {
      updateTx.mutate(
        { id: id!, data: payload },
        {
          onSuccess: () => {
            toast({ title: "Transaction updated successfully" });
            queryClient.invalidateQueries({ queryKey: getListTransactionsQueryKey() });
            queryClient.invalidateQueries({ queryKey: getGetTransactionQueryKey(id!) });
            setLocation("/transactions");
          },
          onError: () => {
            toast({ title: "Failed to update transaction", variant: "destructive" });
          }
        }
      );
    } else {
      // reconcileProductionIds isn't part of CreateTransactionBody — that type
      // is generated from the OpenAPI spec and must not be hand-edited, so the
      // field is attached here and read separately on the server. Re-run the
      // API codegen and this cast can go.
      const createPayload = {
        ...payload,
        ...(reconcileIds.length > 0 ? { reconcileProductionIds: reconcileIds } : {}),
        ...(reconcileReceiptIds.length > 0 ? { reconcileReceiptIds } : {}),
        ...(reconcileDeliveryIds.length > 0 ? { reconcileDeliveryIds } : {}),
      } as typeof payload;

      createTx.mutate(
        { data: createPayload },
        {
          onSuccess: () => {
            toast({
              title: "Transaction created",
              description: reconcileIds.length > 0
                ? `${reconcileIds.length} production ${reconcileIds.length === 1 ? "entry" : "entries"} reconciled and locked.`
                : reconcileReceiptIds.length > 0
                  ? `${reconcileReceiptIds.length} yarn receipt${reconcileReceiptIds.length === 1 ? "" : "s"} consumed and locked.`
                  : reconcileDeliveryIds.length > 0
                    ? `${reconcileDeliveryIds.length} delivery${reconcileDeliveryIds.length === 1 ? "" : "ies"} consumed and locked.`
                    : undefined,
            });
            queryClient.invalidateQueries({ queryKey: getListTransactionsQueryKey() });
            queryClient.invalidateQueries({ queryKey: ["/api/daily-production"] });
            queryClient.invalidateQueries({ queryKey: ["/api/yarn-receipts"] });
            queryClient.invalidateQueries({ queryKey: ["/api/daily-deliveries"] });
            setLocation("/transactions");
          },
          onError: (err) => {
            // A 409 means someone else reconciled this production first. That
            // needs the real reason, not a generic failure toast.
            const status = (err as { status?: number })?.status;
            const detail = (err as { data?: { error?: string } })?.data?.error;
            toast({
              title: status === 409
                ? (isYarnReceipt ? "Receipts already booked" : isFabricDelivery ? "Deliveries already booked" : "Production already reconciled")
                : "Failed to create transaction",
              description: detail,
              variant: "destructive",
            });
          }
        }
      );
    }
  };

  const isPending = createTx.isPending || updateTx.isPending;

  // At least one line must remain — the last row can't be deleted (P9 follow-up).
  const canRemoveRow = fields.length > 1;

  // P7: per-form line validation message, cleared on the next submit.
  const [lineError, setLineError] = useState<string | null>(null);
  useEffect(() => {
    if (lineError) setLineError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [watchedDetails]);

  const lineItemsRef = useRef<HTMLDivElement>(null);

  const handleAddRow = useCallback(() => {
    const details = form.getValues("details");
    const last = details[details.length - 1];
    // Copy the dropdown selections from the last row — adding a line for the
    // same machine/employee/yarn is the common case, so the new row starts
    // pre-filled instead of empty. Only the id and numeric entries reset.
    const newRow = last
      ? {
          id: undefined,
          machineId: last.machineId ?? null,
          employeeId: last.employeeId ?? null,
          yarnTypeId: last.yarnTypeId ?? null,
          yarnCountId: last.yarnCountId ?? null,
          yarnBrandId: last.yarnBrandId ?? null,
          uomId: last.uomId ?? null,
          quantity: "0",
          netWt: "0",
        }
      : { ...emptyDetail(), quantity: "0", netWt: "0" };
    append(newRow);
    setTimeout(() => {
      const inputs = lineItemsRef.current?.querySelectorAll<HTMLInputElement>("[data-qty-input]");
      inputs?.[inputs.length - 1]?.focus();
      inputs?.[inputs.length - 1]?.select();
    }, 50);
  }, [form, append]);

  // The edit gate previously handled only isLoading — a failed fetch left the
  // user on an endless "Loading..." (issue #2). Error and 404 get their own
  // message with a back action instead.
  if (isEditing && isErrorTx) {
    return (
      <Layout>
        <div className="flex flex-col items-center gap-3 p-8 text-center">
          <p className="text-destructive">Couldn't load this transaction.</p>
          <Button variant="outline" onClick={() => setLocation("/transactions")}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to transactions
          </Button>
        </div>
      </Layout>
    );
  }

  if (isEditing && isLoadingTx) {
    return <Layout><div className="p-8 text-center text-muted-foreground">Loading...</div></Layout>;
  }

  return (
    <Layout>
      <div className="flex flex-col gap-6 pb-20">
        <div className="flex items-center gap-4">
          <Button variant="outline" size="icon" onClick={() => setLocation("/transactions")}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {isEditing ? `Edit Transaction: ${transaction?.docNumber}` : "New Transaction"}
            </h1>
            <p className="text-muted-foreground mt-1">
              Enter the master details and line items below.
            </p>
          </div>
        </div>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">

            {/* Header Card */}
            <Card>
              <CardHeader className="pb-4">
                <CardTitle className="text-lg">Header Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Row 1: Transaction Type, Date, Doc Number, Party */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <FormField
                    control={form.control}
                    name="transactionTypeId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Transaction Type *</FormLabel>
                        <FormControl>
                          <select
                            className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={field.value?.toString() ?? ""}
                            onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : undefined)}
                          >
                            <option value="" disabled>Select transaction type</option>
                            {transactionTypeMaster?.map(t => (
                              <option key={`type-${t.id}`} value={t.id.toString()}>{t.name}</option>
                            ))}
                          </select>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="date"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Date *</FormLabel>
                        <FormControl>
                          <DateInput
                            className="h-9"
                            value={field.value ? format(field.value, "yyyy-MM-dd") : ""}
                            onChange={(e) =>
                              field.onChange(
                                e.target.value ? new Date(e.target.value + "T00:00:00") : undefined,
                              )
                            }
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="docNumber"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Document Number *</FormLabel>
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="partyId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Party</FormLabel>
                        <FormControl>
                          <select
                            className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={field.value?.toString() ?? "none"}
                            onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                          >
                            <option value="none">None</option>
                            {partyMaster?.map(p => (
                              <option key={`party-${p.id}`} value={p.id.toString()}>{p.name}</option>
                            ))}
                          </select>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 2: Job, Location, Reference */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <FormField
                    control={form.control}
                    name="jobId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Job Type</FormLabel>
                        <FormControl>
                          <select
                            className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={field.value?.toString() ?? "none"}
                            onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                          >
                            <option value="none">None</option>
                            {filteredJobMaster?.map(j => (
                              <option key={`job-${j.id}`} value={j.id.toString()}>{j.name}</option>
                            ))}
                          </select>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="locationId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Location</FormLabel>
                        <FormControl>
                          <select
                            className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={field.value?.toString() ?? "none"}
                            onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                          >
                            <option value="none">None</option>
                            {locationMaster?.map(l => (
                              <option key={`loc-${l.id}`} value={l.id.toString()}>{l.name}</option>
                            ))}
                          </select>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="reference"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Reference</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="Reference (optional)"
                            {...field}
                            value={field.value ?? ""}
                            onChange={(e) => field.onChange(e.target.value === "" ? null : e.target.value)}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 3: Fabric Type, SL, GSM */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <FormField
                    control={form.control}
                    name="fabricTypeId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Fabric Type</FormLabel>
                        <FormControl>
                          <select
                            className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={field.value?.toString() ?? "none"}
                            onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                          >
                            <option value="none">None</option>
                            {fabricTypeMaster?.map(f => (
                              <option key={f.id} value={f.id.toString()}>{f.name}</option>
                            ))}
                          </select>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="sl"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>SL</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="SL"
                            {...field}
                            value={field.value ?? ""}
                            onChange={(e) => field.onChange(e.target.value === "" ? null : e.target.value)}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="gsm"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>GSM</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            placeholder="GSM"
                            {...field}
                            value={field.value ?? ""}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
              </CardContent>
            </Card>

            {/* Line Items Card */}
            <Card>
              <CardHeader className="pb-4">
                <div className="flex flex-row items-center justify-between">
                  <CardTitle className="text-lg">Line Items</CardTitle>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={handleAddRow}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Add Row
                  </Button>
                </div>
                {/* Fabric Production reconciliation status. Stated plainly
                    because saving here permanently freezes the production
                    entries — the user should know that before pressing Save,
                    not discover it on the production screen afterwards. */}
                {isFabricProduction && !isEditing && (
                  <div className="mt-2 rounded-md border border-yellow-300 bg-yellow-100 px-3 py-2 text-sm text-yellow-900 dark:border-yellow-800 dark:bg-yellow-950/40 dark:text-yellow-200">
                    {loadingProduction ? (
                      <span className="inline-flex items-center gap-2">
                        <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        Loading daily production for this date and party…
                      </span>
                    ) : !watchedPartyId ? (
                      "Choose a party to load that day's production."
                    ) : reconcileIds.length > 0 ? (
                      <span className="inline-flex items-center gap-2">
                        <Lock className="h-3.5 w-3.5 shrink-0" />
                        <span>
                          Loaded <span className="num font-medium">{reconcileIds.length}</span>{" "}
                          production {reconcileIds.length === 1 ? "entry" : "entries"} into the lines
                          below. Saving locks {reconcileIds.length === 1 ? "it" : "them"} permanently
                          — {reconcileIds.length === 1 ? "it" : "they"} can't be edited or deleted on
                          the Daily Production screen afterwards.
                        </span>
                      </span>
                    ) : (
                      "No unreconciled production for this date and party. Anything recorded has already been booked into another transaction."
                    )}
                  </div>
                )}

                {/* Yarn Receipt reconciliation status — same honest warning
                    as production: saving consumes (locks) these receipts. */}
                {isYarnReceipt && !isEditing && (
                  <div className="mt-2 rounded-md border border-yellow-300 bg-yellow-100 px-3 py-2 text-sm text-yellow-900 dark:border-yellow-800 dark:bg-yellow-950/40 dark:text-yellow-200">
                    {loadingReceipts ? (
                      <span className="inline-flex items-center gap-2">
                        <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        Loading yarn receipts for this date and party…
                      </span>
                    ) : !watchedPartyId ? (
                      "Choose a party to load that day's yarn receipts."
                    ) : reconcileReceiptIds.length > 0 ? (
                      <span className="inline-flex items-center gap-2">
                        <Lock className="h-3.5 w-3.5 shrink-0" />
                        <span>
                          Loaded <span className="num font-medium">{reconcileReceiptIds.length}</span>{" "}
                          yarn receipt{reconcileReceiptIds.length === 1 ? "" : "s"} into the lines
                          below. Saving consumes {reconcileReceiptIds.length === 1 ? "it" : "them"} permanently
                          — {reconcileReceiptIds.length === 1 ? "it" : "they"} can't be booked into another
                          transaction afterwards.
                        </span>
                      </span>
                    ) : (
                      "No unreconciled yarn receipts for this date and party. Anything recorded has already been booked into another transaction."
                    )}
                  </div>
                )}

                {/* Fabric Delivery status — same honest warning as the others:
                    saving consumes (locks) these deliveries. */}
                {isFabricDelivery && !isEditing && (
                  <div className="mt-2 rounded-md border border-yellow-300 bg-yellow-100 px-3 py-2 text-sm text-yellow-900 dark:border-yellow-800 dark:bg-yellow-950/40 dark:text-yellow-200">
                    {loadingDeliveries ? (
                      <span className="inline-flex items-center gap-2">
                        <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        Loading daily deliveries for this date and party…
                      </span>
                    ) : !watchedPartyId ? (
                      "Choose a party to load that day's deliveries."
                    ) : reconcileDeliveryIds.length > 0 ? (
                      <span className="inline-flex items-center gap-2">
                        <Lock className="h-3.5 w-3.5 shrink-0" />
                        <span>
                          Loaded <span className="num font-medium">{reconcileDeliveryIds.length}</span>{" "}
                          delivery{reconcileDeliveryIds.length === 1 ? "" : "ies"} into the lines
                          below. Saving consumes {reconcileDeliveryIds.length === 1 ? "it" : "them"} permanently
                          — {reconcileDeliveryIds.length === 1 ? "it" : "they"} can't be booked into another
                          transaction afterwards.
                        </span>
                      </span>
                    ) : (
                      "No unreconciled daily deliveries for this date and party. Anything recorded has already been booked into another transaction."
                    )}
                  </div>
                )}

                <div className="text-sm font-bold text-foreground mt-1">
                  Total_Net Wt.:&nbsp;
                  {(watchedDetails?.reduce((s, d) => s + (parseFloat(d?.netWt?.toString() ?? "0") || 0), 0) ?? 0).toFixed(NUM_DECIMALS)}
                </div>
              </CardHeader>
              <CardContent className="p-0">
                {/* Mobile: one stacked card per line — the 11-column
                    spreadsheet is unusable on a phone. Desktop (sm+) keeps
                    the frozen-header grid below. */}
                <div className="space-y-3 p-4 sm:hidden">
                  {fields.length === 0 && (
                    <p className="rounded-md border py-6 text-center text-sm text-muted-foreground">
                      No line items yet. Add a row to get started.
                    </p>
                  )}
                  {fields.map((field, index) => (
                    <div key={field.id} className="rounded-md border p-3">
                      <div className="flex items-center justify-between">
                        <span className="num inline-flex h-6 min-w-6 items-center justify-center rounded-sm border border-border bg-muted px-1.5 text-xs text-muted-foreground">
                          {index + 1}
                        </span>
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="h-11 w-11 text-muted-foreground hover:text-destructive disabled:opacity-40"
                          onClick={() => remove(index)}
                          disabled={!canRemoveRow}
                          aria-label={canRemoveRow ? `Remove line ${index + 1}` : "Cannot remove the last line"}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>

                      <div className="mt-2 grid grid-cols-2 gap-2">
                        <FormField
                          control={form.control}
                          name={`details.${index}.yarnTypeId`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Yarn Type</label>
                              <FormControl>
                                <select
                                  className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                                  value={field.value?.toString() ?? "none"}
                                  onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                >
                                  <option value="none">None</option>
                                  {yarnTypeMaster?.map(y => (
                                    <option key={y.id} value={y.id.toString()}>{y.name}</option>
                                  ))}
                                </select>
                              </FormControl>
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`details.${index}.yarnCountId`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Yarn Count</label>
                              <FormControl>
                                <select
                                  className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                                  value={field.value?.toString() ?? "none"}
                                  onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                >
                                  <option value="none">None</option>
                                  {yarnCountMaster?.map(y => (
                                    <option key={y.id} value={y.id.toString()}>
                                      {y.name === y.count ? y.name : `${y.name} (${y.count})`}
                                    </option>
                                  ))}
                                </select>
                              </FormControl>
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`details.${index}.yarnBrandId`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Yarn Brand</label>
                              <FormControl>
                                <select
                                  className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                                  value={field.value?.toString() ?? "none"}
                                  onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                >
                                  <option value="none">None</option>
                                  {yarnBrandMaster?.map(y => (
                                    <option key={y.id} value={y.id.toString()}>{y.name}</option>
                                  ))}
                                </select>
                              </FormControl>
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`details.${index}.uomId`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">UOM</label>
                              <FormControl>
                                <select
                                  className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                                  value={field.value?.toString() ?? "none"}
                                  onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                >
                                  <option value="none">None</option>
                                  {uomMaster?.map(u => (
                                    <option key={u.id} value={u.id.toString()}>{u.abbreviation}</option>
                                  ))}
                                </select>
                              </FormControl>
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`details.${index}.machineId`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Machine</label>
                              <FormControl>
                                <select
                                  className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                                  value={field.value?.toString() ?? "none"}
                                  onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                >
                                  <option value="none">None</option>
                                  {machineMaster?.map(m => (
                                    <option key={m.id} value={m.id.toString()}>{m.name}</option>
                                  ))}
                                </select>
                              </FormControl>
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`details.${index}.employeeId`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Machine Employee</label>
                              <FormControl>
                                <select
                                  className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                                  value={field.value?.toString() ?? "none"}
                                  onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                >
                                  <option value="none">None</option>
                                  {employeeMaster
                                    ?.filter(op => (op as { active?: boolean }).active !== false || op.id === field.value)
                                    .map(op => (
                                      <option key={op.id} value={op.id.toString()}>{op.name}</option>
                                    ))}
                                </select>
                              </FormControl>
                            </FormItem>
                          )}
                        />
                      </div>

                      <div className="mt-2 grid grid-cols-2 gap-2">
                        <FormField
                          control={form.control}
                          name={`details.${index}.quantity`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Qty</label>
                              <FormControl>
                                <Input
                                  type="number"
                                  step="any"
                                  inputMode="decimal"
                                  className="num h-11"
                                  placeholder="Qty"
                                  {...field}
                                  value={field.value ?? ""}
                                />
                              </FormControl>
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name={`details.${index}.netWt`}
                          render={({ field }) => (
                            <FormItem>
                              <label className="mb-1 block text-xs font-medium text-muted-foreground">Net Wt</label>
                              <FormControl>
                                <Input
                                  type="number"
                                  step="any"
                                  inputMode="decimal"
                                  className="num h-11"
                                  placeholder="Net Wt"
                                  {...field}
                                  value={field.value || ""}
                                />
                              </FormControl>
                            </FormItem>
                          )}
                        />
                      </div>

                      <div className="mt-2 grid grid-cols-2 gap-2">
                        <div className="rounded-md border border-input bg-muted px-3 py-2.5">
                          <p className="text-xs text-muted-foreground">Run total</p>
                          <p className="num text-sm font-medium">{(runTotals[index] ?? 0).toFixed(NUM_DECIMALS)}</p>
                        </div>
                        <div className="rounded-md border border-input bg-muted px-3 py-2.5">
                          <p className="text-xs text-muted-foreground">M/c run total</p>
                          <p className="num text-sm font-medium">{(mcRunTotals[index] ?? 0).toFixed(NUM_DECIMALS)}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                  <Button
                    type="button"
                    variant="outline"
                    className="w-full"
                    onClick={handleAddRow}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Add Row
                  </Button>
                </div>

                {/* Desktop spreadsheet — hidden on mobile. No min-width and no
                    horizontal scroll: the grid fits the card. The two running
                    totals share one stacked column so the selects keep usable
                    width (11 columns were forcing a 1560px scroll). */}
                <div className="hidden sm:block">
                  <div className="px-4 pt-4 pb-2 border-b bg-card">
                    <div className="grid grid-cols-[2fr_2fr_2fr_2fr_2fr_2fr_1fr_1fr_1.5fr_auto] gap-2 font-medium text-sm text-muted-foreground">
                        <div>Yarn Type</div>
                        <div>Yarn Count</div>
                        <div>Yarn Brand</div>
                        <div>UOM</div>
                        <div>Machine</div>
                        <div>Machine Employee</div>
                        <div>Qty</div>
                        <div>Net Wt</div>
                        <div>Run totals</div>
                        <div className="pl-2 text-right">Action</div>
                      </div>
                    </div>

                    {/* Rows flow at natural height — no inner scrollport. The
                        page scrolls as a whole, so there's no scroll-within-
                        scroll trap for mouse wheel or touch. */}
                    <div className="px-4 py-2">
                    <div className="space-y-2" ref={lineItemsRef}>
                      {fields.map((field, index) => (
                        <div key={field.id} className="grid grid-cols-[2fr_2fr_2fr_2fr_2fr_2fr_1fr_1fr_1.5fr_auto] gap-2 items-start">
                          <FormField
                            control={form.control}
                            name={`details.${index}.yarnTypeId`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <select
                                    className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                                    value={field.value?.toString() ?? "none"}
                                    onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                  >
                                    <option value="none">None</option>
                                    {yarnTypeMaster?.map(y => (
                                      <option key={y.id} value={y.id.toString()}>{y.name}</option>
                                    ))}
                                  </select>
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.yarnCountId`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <select
                                    className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                                    value={field.value?.toString() ?? "none"}
                                    onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                  >
                                    <option value="none">None</option>
                                    {yarnCountMaster?.map(y => (
                                      <option key={y.id} value={y.id.toString()}>
                                        {y.name === y.count ? y.name : `${y.name} (${y.count})`}
                                      </option>
                                    ))}
                                  </select>
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.yarnBrandId`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <select
                                    className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                                    value={field.value?.toString() ?? "none"}
                                    onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                  >
                                    <option value="none">None</option>
                                    {yarnBrandMaster?.map(y => (
                                      <option key={y.id} value={y.id.toString()}>{y.name}</option>
                                    ))}
                                  </select>
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.uomId`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <select
                                    className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                                    value={field.value?.toString() ?? "none"}
                                    onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                  >
                                    <option value="none">None</option>
                                    {uomMaster?.map(u => (
                                      <option key={u.id} value={u.id.toString()}>{u.abbreviation}</option>
                                    ))}
                                  </select>
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.machineId`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <select
                                    className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                                    value={field.value?.toString() ?? "none"}
                                    onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                  >
                                    <option value="none">None</option>
                                    {machineMaster?.map(m => (
                                      <option key={m.id} value={m.id.toString()}>
                                        {m.name}
                                      </option>
                                    ))}
                                  </select>
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.employeeId`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <select
                                    className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                                    value={field.value?.toString() ?? "none"}
                                    onChange={(e) => field.onChange(e.target.value === "none" ? null : parseInt(e.target.value))}
                                  >
                                    <option value="none">None</option>
                                    {employeeMaster
                                      ?.filter(op => (op as { active?: boolean }).active !== false || op.id === field.value)
                                      .map(op => (
                                        <option key={op.id} value={op.id.toString()}>
                                          {op.name}
                                        </option>
                                      ))}
                                  </select>
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.quantity`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <Input
                                    type="number"
                                    step="any"
                                    inputMode="decimal"
                                    className="num h-11 sm:h-9"
                                    placeholder="Qty"
                                    data-qty-input="true"
                                    {...field}
                                    value={field.value ?? ""}
                                    onFocus={(e) => e.target.select()}
                                  />
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.netWt`}
                            render={({ field }) => (
                              <FormItem>
                                <FormControl>
                                  <Input
                                    type="number"
                                    step="any"
                                    inputMode="decimal"
                                    className="num h-11 sm:h-9"
                                    placeholder="Net Wt"
                                    {...field}
                                    value={field.value || ""}
                                  />
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          {/* One cell, two lines — the header shows a single
                              "Run totals" column, so the row must too. Two
                              separate cells here is what pushed the delete
                              icon onto its own row. */}
                          <div className="flex h-12 flex-col justify-center gap-0.5 rounded-md border border-input bg-muted px-3 text-sm sm:h-11">
                            <div className="flex w-full items-baseline justify-between gap-2">
                              <span className="text-muted-foreground">Run</span>
                              <span className="num font-medium">{(runTotals[index] ?? 0).toFixed(NUM_DECIMALS)}</span>
                            </div>
                            <div className="flex w-full items-baseline justify-between gap-2">
                              <span className="text-muted-foreground">M/c</span>
                              <span className="num font-medium">{(mcRunTotals[index] ?? 0).toFixed(NUM_DECIMALS)}</span>
                            </div>
                          </div>

                          <div className="pl-2">
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-11 w-11 text-muted-foreground hover:text-destructive disabled:opacity-40 shrink-0 sm:h-8 sm:w-8"
                              onClick={() => remove(index)}
                              disabled={!canRemoveRow}
                              aria-label={canRemoveRow ? `Remove line ${index + 1}` : "Cannot remove the last line"}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                    </div>
                  </div>
              </CardContent>
            </Card>

            {/* P8: sticky action bar — Save stays reachable on a phone even
                with the header + line cards scrolled past. */}
            <div className="sticky bottom-0 z-10 -mx-1 border-t bg-background/95 px-1 py-3 backdrop-blur supports-[backdrop-filter]:bg-background/80">
              {lineError && (
                <p className="mb-2 text-sm font-medium text-destructive">{lineError}</p>
              )}
              <div className="flex justify-end gap-4">
                <Button type="button" variant="outline" onClick={() => setLocation("/transactions")}>
                  Cancel
                </Button>
                <Button type="submit" disabled={isPending}>
                  {isPending ? "Saving..." : isEditing ? "Save Changes" : "Create Transaction"}
                </Button>
              </div>
            </div>
          </form>
        </Form>
      </div>
    </Layout>
  );
}
