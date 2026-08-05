import { useEffect, useRef, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { format } from "date-fns";
import { useQueryClient, useQuery } from "@tanstack/react-query";

import { useListPartyMaster, useListYarnTypeMaster } from "@workspace/api-client-react";
import {
  useCreateDailyDelivery,
  useUpdateDailyDelivery,
  useGetDailyDelivery,
} from "@/hooks/use-daily-deliveries";

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
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
import { Spinner } from "@/components/ui/spinner";
import { useToast } from "@/hooks/use-toast";

const LS_ENTERED_BY = "daily-delivery-entered-by";

const deliverySchema = z.object({
  challanNo: z.string().min(1, "Challan # is required"),
  deliveryDate: z.date({ required_error: "Delivery date is required" }),
  partyId: z.number({ required_error: "Party is required" }),
  yarnTypeId: z.number({ required_error: "Yarn type is required" }),
  sl: z.string().optional(),
  gsm: z.string().optional(),
  quantity: z.string().min(1, "Quantity is required"),
  netWeight: z.string().min(1, "Net weight is required"),
  enteredBy: z.string().min(1, "Enter your name"),
});
type DeliveryValues = z.infer<typeof deliverySchema>;

function defaultValues(enteredBy: string, defaultDate: Date = new Date()): DeliveryValues {
  return {
    challanNo: "",
    deliveryDate: defaultDate,
    partyId: undefined as unknown as number,
    yarnTypeId: undefined as unknown as number,
    sl: "",
    gsm: "",
    quantity: "",
    netWeight: "",
    enteredBy,
  };
}

export function DailyDeliveryDialog({
  open,
  onOpenChange,
  deliveryId = null,
  defaultDate,
  maxDate,
  readOnly = false,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  deliveryId?: number | null;
  defaultDate?: Date;
  maxDate?: Date;
  readOnly?: boolean;
}) {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const isEdit = deliveryId != null;

  const { data: partyMaster } = useListPartyMaster();
  const { data: yarnTypeMaster } = useListYarnTypeMaster();

  const createDelivery = useCreateDailyDelivery();
  const updateDelivery = useUpdateDailyDelivery();

  const deliveryQuery = useGetDailyDelivery(deliveryId ?? null, {
    query: { enabled: open && isEdit },
  });
  const delivery = deliveryQuery.data;

  const savedEnteredBy = (() => {
    try { return localStorage.getItem(LS_ENTERED_BY) ?? ""; } catch { return ""; }
  })();

  const form = useForm<DeliveryValues>({
    resolver: zodResolver(deliverySchema),
    defaultValues: defaultValues(savedEnteredBy, defaultDate),
  });

  const [pendingAction, setPendingAction] = useState<"save" | "saveAndAdd" | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  const prefilledFor = useRef<number | null | undefined>(undefined);

  // Next challan suggestion (D-<n>), like the other daily screens.
  const { data: suggestions } = useQuery<{ nextChallanNo: string }>({
    queryKey: ["/api/daily-deliveries/suggestions"],
    queryFn: () =>
      fetch("/api/daily-deliveries/suggestions").then((r) => r.json()) as Promise<{ nextChallanNo: string }>,
  });

  useEffect(() => {
    if (!open) {
      prefilledFor.current = undefined;
      return;
    }

    if (!isEdit) {
      if (prefilledFor.current === null) return;
      prefilledFor.current = null;
      form.reset(defaultValues(savedEnteredBy, defaultDate));
      if (suggestions?.nextChallanNo) {
        form.setValue("challanNo", suggestions.nextChallanNo);
      }
      setPendingAction(null);
      return;
    }

    if (!delivery || delivery.id !== deliveryId) return;
    if (prefilledFor.current === deliveryId) return;
    prefilledFor.current = deliveryId;

    form.reset({
      challanNo: delivery.challanNo,
      deliveryDate: new Date(`${delivery.deliveryDate}T00:00:00`),
      partyId: delivery.partyId,
      yarnTypeId: delivery.yarnTypeId,
      sl: delivery.sl ?? "",
      gsm: delivery.gsm != null ? String(delivery.gsm) : "",
      quantity: String(delivery.quantity),
      netWeight: delivery.netWeight,
      enteredBy: savedEnteredBy || delivery.createdBy,
    });
    setPendingAction(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isEdit, deliveryId, delivery, defaultDate, suggestions]);

  const isBusy = createDelivery.isPending || updateDelivery.isPending;
  const isLoadingDelivery = isEdit && deliveryQuery.isLoading;

  const doSave = async (keepOpen: boolean) => {
    if (isBusy) return;
    const valid = await form.trigger();
    if (!valid) return;

    const values = form.getValues();

    // Rolls and net weight must be positive — a zero/negative delivery is a
    // half-finished row (same rule as the production and receipt popups).
    const qty = Number(values.quantity);
    const wt = Number(values.netWeight);
    if (!(qty > 0) || !(wt > 0)) {
      setFormError("Quantity (rolls) and net weight must both be greater than zero");
      return;
    }

    try { localStorage.setItem(LS_ENTERED_BY, values.enteredBy); } catch {}

    setPendingAction(keepOpen ? "saveAndAdd" : "save");

    const payload = {
      challanNo: values.challanNo,
      deliveryDate: format(values.deliveryDate, "yyyy-MM-dd"),
      partyId: values.partyId,
      yarnTypeId: values.yarnTypeId,
      sl: values.sl?.trim() ? values.sl.trim() : null,
      gsm: values.gsm?.trim() ? parseInt(values.gsm, 10) : null,
      quantity: parseInt(values.quantity, 10),
      netWeight: values.netWeight,
      createdBy: values.enteredBy,
    };

    const handleError = (verb: string) => (err: unknown) => {
      setPendingAction(null);
      toast({
        title: `Failed to ${verb} delivery`,
        description: err instanceof Error ? err.message : undefined,
        variant: "destructive",
      });
    };

    if (deliveryId != null) {
      updateDelivery.mutate(
        { id: deliveryId, data: { ...payload, updatedBy: values.enteredBy } },
        {
          onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["/api/daily-deliveries"] });
            queryClient.invalidateQueries({ queryKey: [`/api/daily-deliveries/${deliveryId}`] });
            setPendingAction(null);
            toast({ title: "Delivery updated" });
            onOpenChange(false);
          },
          onError: handleError("update"),
        },
      );
      return;
    }

    createDelivery.mutate(
      { data: payload },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/daily-deliveries"] });
          setPendingAction(null);

          if (keepOpen) {
            // Chained entry: same party/yarn type/date, cleared fields and
            // the next challan suggestion (D-<n> advances).
            queryClient.invalidateQueries({ queryKey: ["/api/daily-deliveries/suggestions"] });
            queryClient
              .fetchQuery({ queryKey: ["/api/daily-deliveries/suggestions"], queryFn: () => fetch("/api/daily-deliveries/suggestions").then((r) => r.json()) as Promise<{ nextChallanNo: string }> })
              .then((s) => {
                if (s?.nextChallanNo) form.setValue("challanNo", s.nextChallanNo);
              })
              .catch(() => {});
            form.setValue("sl", "");
            form.setValue("gsm", "");
            form.setValue("quantity", "");
            form.setValue("netWeight", "");
            toast({ title: "Saved", description: "Delivery recorded. Ready for the next one." });
          } else {
            toast({ title: "Delivery saved" });
            onOpenChange(false);
          }
        },
        onError: handleError("save"),
      },
    );
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !isBusy && onOpenChange(o)}>
      <DialogContent className="grid max-h-[92dvh] max-w-xl grid-rows-[auto_minmax(0,1fr)_auto] gap-0 p-0">
        <DialogHeader className="px-4 pb-3 pr-12 pt-5 text-left sm:px-6 sm:pr-12 sm:pt-6">
          <DialogTitle>
            {readOnly ? "View Daily Delivery" : isEdit ? "Edit Daily Delivery" : "Add Daily Delivery"}
          </DialogTitle>
          <DialogDescription>
            {readOnly
              ? "This delivery has been booked into a Fabric Delivery transaction and is locked. Viewing only — it can't be changed."
              : isEdit
                ? "Amend the delivery details."
                : "Record the delivery: party, challan #, SL/GSM, rolls and net weight."}
          </DialogDescription>
        </DialogHeader>

        <div className="min-h-0 overflow-y-auto overscroll-contain px-4 pb-5 sm:px-6">
          {isLoadingDelivery && (
            <div className="flex items-center gap-2 py-8 text-sm text-muted-foreground">
              <Spinner />
              Loading delivery…
            </div>
          )}

          <Form {...form}>
            <div className="space-y-4 pt-5">
              <p className="eyebrow">Delivery details</p>
              {formError && (
                <p className="mt-1 text-sm font-medium text-destructive">{formError}</p>
              )}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="challanNo"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Challan # *</FormLabel>
                      <FormControl>
                        <Input placeholder="D-1" className="h-11 sm:h-9" disabled={readOnly} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="deliveryDate"
                  render={({ field }) => (
                    <FormItem className="flex flex-col">
                      <FormLabel>Date *</FormLabel>
                      <FormControl>
                        <DateInput
                          className="h-11 sm:h-9"
                          value={field.value ? format(field.value, "yyyy-MM-dd") : ""}
                          max={maxDate ? format(maxDate, "yyyy-MM-dd") : undefined}
                          disabled={readOnly}
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
                  name="partyId"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-2">
                      <FormLabel>Party *</FormLabel>
                      <FormControl>
                        <select
                          className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                          value={field.value?.toString() ?? ""}
                          disabled={readOnly}
                          onChange={(e) =>
                            field.onChange(e.target.value ? parseInt(e.target.value) : undefined)
                          }
                        >
                          <option value="" disabled>Select party</option>
                          {partyMaster?.map((p) => (
                            <option key={p.id} value={p.id.toString()}>{p.name}</option>
                          ))}
                        </select>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="yarnTypeId"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-2">
                      <FormLabel>Yarn Type *</FormLabel>
                      <FormControl>
                        <select
                          className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                          value={field.value?.toString() ?? ""}
                          disabled={readOnly}
                          onChange={(e) =>
                            field.onChange(e.target.value ? parseInt(e.target.value) : undefined)
                          }
                        >
                          <option value="" disabled>Select yarn type</option>
                          {yarnTypeMaster?.map((t) => (
                            <option key={t.id} value={t.id.toString()}>{t.name}</option>
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
                        <Input placeholder="Optional" className="h-11 sm:h-9" disabled={readOnly} {...field} />
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
                          min="0"
                          step="1"
                          inputMode="numeric"
                          placeholder="Optional"
                          className="h-11 sm:h-9"
                          disabled={readOnly}
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="quantity"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Quantity (rolls) *</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min="1"
                          step="1"
                          inputMode="numeric"
                          placeholder="Rolls"
                          className="h-9 num"
                          disabled={readOnly}
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="netWeight"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Net Weight (kg) *</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min="0"
                          step="any"
                          inputMode="decimal"
                          placeholder="kg"
                          className="h-9 num"
                          disabled={readOnly}
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="enteredBy"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-2">
                      <FormLabel>{isEdit ? "Updated By *" : "Entered By *"}</FormLabel>
                      <FormControl>
                        <Input placeholder="Your name" className="h-11 sm:h-9" disabled={readOnly} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </div>
          </Form>
        </div>

        <DialogFooter className="gap-2 border-t bg-background px-4 py-4 sm:px-6">
          {readOnly ? (
            <Button
              type="button"
              variant="outline"
              className="w-full sm:w-auto"
              onClick={() => onOpenChange(false)}
            >
              Close
            </Button>
          ) : (
            <>
              <Button
                type="button"
                variant="outline"
                className="w-full sm:w-auto"
                onClick={() => onOpenChange(false)}
                disabled={isBusy}
              >
                Cancel
              </Button>
              {!isEdit && (
                <Button
                  type="button"
                  variant="secondary"
                  className="w-full sm:w-auto"
                  onClick={() => doSave(true)}
                  disabled={isBusy}
                >
                  {pendingAction === "saveAndAdd" && <Spinner className="mr-2" />}
                  Save & Add More
                </Button>
              )}
              <Button
                type="button"
                variant="signal"
                className="w-full sm:w-auto"
                onClick={() => doSave(false)}
                disabled={isBusy || isLoadingDelivery}
              >
                {pendingAction === "save" && <Spinner className="mr-2" />}
                Save
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
