import { useEffect, useRef, useCallback } from "react";
import { useLocation, useParams } from "wouter";
import { useForm, useFieldArray } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Plus, Trash2, ArrowLeft } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
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
  useListMachineOperatorMaster,
  useGetTransaction,
  useCreateTransaction,
  useUpdateTransaction,
  getGetTransactionQueryKey,
  getListTransactionsQueryKey
} from "@workspace/api-client-react";

import { Layout } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { DatePicker } from "@/components/ui/date-picker";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ScrollArea, ScrollBar } from "@/components/ui/scroll-area";

const nullableInt = z.preprocess(
  (v) => (v === "" || v === null || v === undefined ? null : Number(v)),
  z.number().int().nullable()
);

const detailSchema = z.object({
  id: z.number().optional(),
  machineId: z.number().nullable(),
  machineOperatorId: z.number().nullable(),
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
  machineOperatorId: null,
  yarnTypeId: null,
  yarnCountId: null,
  yarnBrandId: null,
  uomId: null,
  quantity: null,
  netWt: null,
});

export default function TransactionForm() {
  const [, setLocation] = useLocation();
  const params = useParams();
  const id = params.id ? parseInt(params.id) : null;
  const isEditing = !!id;
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: transaction, isLoading: isLoadingTx } = useGetTransaction(id!, {
    query: { enabled: isEditing, queryKey: getGetTransactionQueryKey(id!) }
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
  const { data: machineOperatorMaster } = useListMachineOperatorMaster();

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

  const lookupsReady = !!(
    jobMaster && partyMaster && machineMaster && locationMaster &&
    yarnTypeMaster && yarnCountMaster && yarnBrandMaster && uomMaster &&
    fabricTypeMaster && machineOperatorMaster &&
    transactionTypeMaster
  );

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
              machineOperatorId: d.machineOperatorId ?? null,
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
            setLocation("/");
          },
          onError: () => {
            toast({ title: "Failed to update transaction", variant: "destructive" });
          }
        }
      );
    } else {
      createTx.mutate(
        { data: payload },
        {
          onSuccess: () => {
            toast({ title: "Transaction created successfully" });
            queryClient.invalidateQueries({ queryKey: getListTransactionsQueryKey() });
            setLocation("/");
          },
          onError: () => {
            toast({ title: "Failed to create transaction", variant: "destructive" });
          }
        }
      );
    }
  };

  const isPending = createTx.isPending || updateTx.isPending;

  const lineItemsRef = useRef<HTMLDivElement>(null);

  const handleAddRow = useCallback(() => {
    const details = form.getValues("details");
    const last = details[details.length - 1];
    const newRow = last
      ? { ...last, id: undefined, quantity: "0", netWt: "0" }
      : { ...emptyDetail(), quantity: "0", netWt: "0" };
    append(newRow);
    setTimeout(() => {
      const inputs = lineItemsRef.current?.querySelectorAll<HTMLInputElement>("[data-qty-input]");
      inputs?.[inputs.length - 1]?.focus();
      inputs?.[inputs.length - 1]?.select();
    }, 50);
  }, [form, append]);

  if (isEditing && isLoadingTx) {
    return <Layout><div className="p-8 text-center text-muted-foreground">Loading...</div></Layout>;
  }

  return (
    <Layout>
      <div className="flex flex-col gap-6 pb-20">
        <div className="flex items-center gap-4">
          <Button variant="outline" size="icon" onClick={() => setLocation("/")}>
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
                {/* Row 1: Transaction Type, Date, Doc Number, Job */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <FormField
                    control={form.control}
                    name="transactionTypeId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Transaction Type *</FormLabel>
                        <Select
                          key={field.value?.toString() || "unset"}
                          onValueChange={(val) => field.onChange(parseInt(val))}
                          value={field.value?.toString() || ""}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select transaction type" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {transactionTypeMaster?.map(t => (
                              <SelectItem key={`type-${t.id}`} value={t.id.toString()}>{t.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="date"
                    render={({ field }) => (
                      <FormItem className="flex flex-col pt-2">
                        <FormLabel className="mb-1.5">Date *</FormLabel>
                        <DatePicker date={field.value} setDate={field.onChange} />
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
                    name="jobId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Job</FormLabel>
                        <Select
                          key={field.value?.toString() || "none"}
                          onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                          value={field.value?.toString() || "none"}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select job" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            <SelectItem value="none">None</SelectItem>
                            {jobMaster?.map(j => (
                              <SelectItem key={`job-${j.id}`} value={j.id.toString()}>{j.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 2: Party, Location, Reference */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <FormField
                    control={form.control}
                    name="partyId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Party</FormLabel>
                        <Select
                          key={field.value?.toString() || "none"}
                          onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                          value={field.value?.toString() || "none"}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select party" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            <SelectItem value="none">None</SelectItem>
                            {partyMaster?.map(p => (
                              <SelectItem key={`party-${p.id}`} value={p.id.toString()}>{p.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
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
                        <Select
                          key={field.value?.toString() || "none"}
                          onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                          value={field.value?.toString() || "none"}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select location" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            <SelectItem value="none">None</SelectItem>
                            {locationMaster?.map(l => (
                              <SelectItem key={`loc-${l.id}`} value={l.id.toString()}>{l.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
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
                        <Select
                          key={field.value?.toString() || "none"}
                          onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                          value={field.value?.toString() || "none"}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select fabric type" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            <SelectItem value="none">None</SelectItem>
                            {fabricTypeMaster?.map(f => (
                              <SelectItem key={f.id} value={f.id.toString()}>{f.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
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
              <CardHeader className="pb-4 flex flex-row items-center justify-between">
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
              </CardHeader>
              <CardContent className="p-0">
                <ScrollArea className="w-full rounded-md">
                  <div className="min-w-[1200px] p-4 pt-0">
                    <div className="grid grid-cols-[2fr_2fr_2fr_2fr_2fr_2fr_1.5fr_1.5fr_auto] gap-2 mb-2 font-medium text-sm text-muted-foreground">
                      <div>Yarn Type</div>
                      <div>Yarn Count</div>
                      <div>Yarn Brand</div>
                      <div>UOM</div>
                      <div>Machine</div>
                      <div>Machine Operator</div>
                      <div>Qty</div>
                      <div>Net Wt</div>
                      <div className="w-10"></div>
                    </div>

                    <div className="space-y-2" ref={lineItemsRef}>
                      {fields.map((field, index) => (
                        <div key={field.id} className="grid grid-cols-[2fr_2fr_2fr_2fr_2fr_2fr_1.5fr_1.5fr_auto] gap-2 items-start">
                          <FormField
                            control={form.control}
                            name={`details.${index}.yarnTypeId`}
                            render={({ field }) => (
                              <FormItem>
                                <Select
                                  onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                                  value={field.value?.toString() || "none"}
                                >
                                  <FormControl>
                                    <SelectTrigger className="h-9">
                                      <SelectValue placeholder="Type" />
                                    </SelectTrigger>
                                  </FormControl>
                                  <SelectContent>
                                    <SelectItem value="none">None</SelectItem>
                                    {yarnTypeMaster?.map(y => (
                                      <SelectItem key={y.id} value={y.id.toString()}>{y.name}</SelectItem>
                                    ))}
                                  </SelectContent>
                                </Select>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.yarnCountId`}
                            render={({ field }) => (
                              <FormItem>
                                <Select
                                  onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                                  value={field.value?.toString() || "none"}
                                >
                                  <FormControl>
                                    <SelectTrigger className="h-9">
                                      <SelectValue placeholder="Count" />
                                    </SelectTrigger>
                                  </FormControl>
                                  <SelectContent>
                                    <SelectItem value="none">None</SelectItem>
                                    {yarnCountMaster?.map(y => (
                                      <SelectItem key={y.id} value={y.id.toString()}>{y.name}</SelectItem>
                                    ))}
                                  </SelectContent>
                                </Select>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.yarnBrandId`}
                            render={({ field }) => (
                              <FormItem>
                                <Select
                                  onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                                  value={field.value?.toString() || "none"}
                                >
                                  <FormControl>
                                    <SelectTrigger className="h-9">
                                      <SelectValue placeholder="Brand" />
                                    </SelectTrigger>
                                  </FormControl>
                                  <SelectContent>
                                    <SelectItem value="none">None</SelectItem>
                                    {yarnBrandMaster?.map(y => (
                                      <SelectItem key={y.id} value={y.id.toString()}>{y.name}</SelectItem>
                                    ))}
                                  </SelectContent>
                                </Select>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.uomId`}
                            render={({ field }) => (
                              <FormItem>
                                <Select
                                  onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                                  value={field.value?.toString() || "none"}
                                >
                                  <FormControl>
                                    <SelectTrigger className="h-9">
                                      <SelectValue placeholder="UOM" />
                                    </SelectTrigger>
                                  </FormControl>
                                  <SelectContent>
                                    <SelectItem value="none">None</SelectItem>
                                    {uomMaster?.map(u => (
                                      <SelectItem key={u.id} value={u.id.toString()}>{u.abbreviation}</SelectItem>
                                    ))}
                                  </SelectContent>
                                </Select>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.machineId`}
                            render={({ field }) => (
                              <FormItem>
                                <Select
                                  onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                                  value={field.value?.toString() || "none"}
                                >
                                  <FormControl>
                                    <SelectTrigger className="h-9">
                                      <SelectValue placeholder="Select machine" />
                                    </SelectTrigger>
                                  </FormControl>
                                  <SelectContent>
                                    <SelectItem value="none">None</SelectItem>
                                    {machineMaster?.map(m => (
                                      <SelectItem key={m.id} value={m.id.toString()}>
                                        {m.name}
                                      </SelectItem>
                                    ))}
                                  </SelectContent>
                                </Select>
                              </FormItem>
                            )}
                          />

                          <FormField
                            control={form.control}
                            name={`details.${index}.machineOperatorId`}
                            render={({ field }) => (
                              <FormItem>
                                <Select
                                  onValueChange={(val) => field.onChange(val === "none" ? null : parseInt(val))}
                                  value={field.value?.toString() || "none"}
                                >
                                  <FormControl>
                                    <SelectTrigger className="h-9">
                                      <SelectValue placeholder="Select operator" />
                                    </SelectTrigger>
                                  </FormControl>
                                  <SelectContent>
                                    <SelectItem value="none">None</SelectItem>
                                    {machineOperatorMaster?.map(op => (
                                      <SelectItem key={op.id} value={op.id.toString()}>
                                        {op.name}
                                      </SelectItem>
                                    ))}
                                  </SelectContent>
                                </Select>
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
                                    className="h-9"
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
                                    className="h-9"
                                    placeholder="Net Wt"
                                    {...field}
                                    value={field.value || ""}
                                  />
                                </FormControl>
                              </FormItem>
                            )}
                          />

                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="h-9 w-9 text-muted-foreground hover:text-destructive shrink-0"
                            onClick={() => remove(index)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  </div>
                  <ScrollBar orientation="horizontal" />
                </ScrollArea>
              </CardContent>
            </Card>

            <div className="flex justify-end gap-4 pt-4 border-t">
              <Button type="button" variant="outline" onClick={() => setLocation("/")}>
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? "Saving..." : isEditing ? "Save Changes" : "Create Transaction"}
              </Button>
            </div>
          </form>
        </Form>
      </div>
    </Layout>
  );
}
