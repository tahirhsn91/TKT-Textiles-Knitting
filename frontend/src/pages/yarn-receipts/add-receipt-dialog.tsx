import { useEffect, useRef, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { format } from "date-fns";
import { Plus, Trash2 } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";

import {
  useListPartyMaster,
  useListYarnCountMaster,
  useListYarnBrandMaster,
} from "@workspace/api-client-react";
import {
  useCreateYarnReceipt,
  useUpdateYarnReceipt,
  useGetYarnReceipt,
} from "@/hooks/use-yarn-receipts";

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
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Table, TableBody, TableCell, TableRow } from "@/components/ui/table";
import { Spinner } from "@/components/ui/spinner";
import { useToast } from "@/hooks/use-toast";

const LS_ENTERED_BY = "yarn-receipt-entered-by";

const headerSchema = z.object({
  receiptDate: z.date({ required_error: "Receipt date is required" }),
  partyId: z.number({ required_error: "Party is required" }),
  enteredBy: z.string().min(1, "Enter your name"),
});
type HeaderValues = z.infer<typeof headerSchema>;

interface LineRow {
  key: number;
  yarnCountId: string;
  yarnBrandId: string;
  quantity: string;
  netWeight: string;
}

let lineKeySeq = 0;

function defaultHeaderValues(enteredBy: string, defaultDate: Date = new Date()): HeaderValues {
  return {
    receiptDate: defaultDate,
    partyId: undefined as unknown as number,
    enteredBy,
  };
}

export function YarnReceiptDialog({
  open,
  onOpenChange,
  receiptId = null,
  defaultDate,
  maxDate,
  readOnly = false,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  receiptId?: number | null;
  defaultDate?: Date;
  maxDate?: Date;
  readOnly?: boolean;
}) {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const isEdit = receiptId != null;

  const { data: partyMaster } = useListPartyMaster();
  const { data: yarnCountMaster } = useListYarnCountMaster();
  const { data: yarnBrandMaster } = useListYarnBrandMaster();

  const createReceipt = useCreateYarnReceipt();
  const updateReceipt = useUpdateYarnReceipt();

  const receiptQuery = useGetYarnReceipt(receiptId ?? null, {
    query: { enabled: open && isEdit },
  });
  const receipt = receiptQuery.data;

  const savedEnteredBy = (() => {
    try { return localStorage.getItem(LS_ENTERED_BY) ?? ""; } catch { return ""; }
  })();

  const form = useForm<HeaderValues>({
    resolver: zodResolver(headerSchema),
    defaultValues: defaultHeaderValues(savedEnteredBy, defaultDate),
  });

  const [lines, setLines] = useState<LineRow[]>([]);
  const [lineError, setLineError] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<"save" | null>(null);

  const prefilledFor = useRef<number | null | undefined>(undefined);

  // Fresh state every open. Create resets immediately; edit waits for the
  // record to arrive (same pattern as the production dialog).
  useEffect(() => {
    if (!open) {
      prefilledFor.current = undefined;
      return;
    }

    if (!isEdit) {
      if (prefilledFor.current === null) return;
      prefilledFor.current = null;
      form.reset(defaultHeaderValues(savedEnteredBy, defaultDate));
      setLines([]);
      setLineError(null);
      setPendingAction(null);
      return;
    }

    if (!receipt || receipt.id !== receiptId) return;
    if (prefilledFor.current === receiptId) return;
    prefilledFor.current = receiptId;

    form.reset({
      receiptDate: new Date(`${receipt.receiptDate}T00:00:00`),
      partyId: receipt.partyId,
      enteredBy: savedEnteredBy || receipt.createdBy,
    });
    setLines(
      receipt.lines.map((l) => ({
        key: ++lineKeySeq,
        yarnCountId: String(l.yarnCountId),
        yarnBrandId: String(l.yarnBrandId),
        quantity: String(l.quantity),
        netWeight: l.netWeight,
      })),
    );
    setLineError(null);
    setPendingAction(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isEdit, receiptId, receipt, defaultDate]);

  const handleAddLine = useCallback(() => {
    setLines((prev) => [
      ...prev,
      {
        key: ++lineKeySeq,
        yarnCountId: "",
        yarnBrandId: "",
        quantity: "",
        netWeight: "",
      },
    ]);
    setLineError(null);
  }, []);

  const handleRemoveLine = (key: number) => {
    setLines((prev) => prev.filter((l) => l.key !== key));
  };

  const updateLine = (key: number, patch: Partial<LineRow>) => {
    setLines((prev) => prev.map((l) => (l.key === key ? { ...l, ...patch } : l)));
  };

  const totalQty = lines.reduce((s, l) => s + (parseInt(l.quantity, 10) || 0), 0);
  const totalNetWeight = lines.reduce((s, l) => s + (parseFloat(l.netWeight) || 0), 0);

  const isBusy = createReceipt.isPending || updateReceipt.isPending;
  const isLoadingReceipt = isEdit && receiptQuery.isLoading;

  const doSave = async () => {
    if (isBusy) return;
    const valid = await form.trigger();
    if (!valid) return;

    if (lines.length === 0) {
      setLineError("Add at least one yarn line");
      return;
    }
    for (const l of lines) {
      if (!l.yarnCountId || !l.yarnBrandId) {
        setLineError("Every line needs a yarn count and yarn brand");
        return;
      }
      const qty = parseInt(l.quantity, 10);
      const wt = parseFloat(l.netWeight);
      if (!l.quantity || isNaN(qty) || qty <= 0) {
        setLineError("Every line needs a whole-bag quantity greater than zero");
        return;
      }
      if (!l.netWeight || isNaN(wt) || wt <= 0) {
        setLineError("Every line needs a net weight greater than zero");
        return;
      }
    }
    setLineError(null);

    const values = form.getValues();
    try { localStorage.setItem(LS_ENTERED_BY, values.enteredBy); } catch {}

    setPendingAction("save");

    const payload = {
      receiptDate: format(values.receiptDate, "yyyy-MM-dd"),
      partyId: values.partyId,
      createdBy: values.enteredBy,
      lines: lines.map((l) => ({
        yarnCountId: parseInt(l.yarnCountId, 10),
        yarnBrandId: parseInt(l.yarnBrandId, 10),
        quantity: parseInt(l.quantity, 10),
        netWeight: l.netWeight,
      })),
    };

    const handleError = (verb: string) => (err: unknown) => {
      setPendingAction(null);
      toast({
        title: `Failed to ${verb} yarn receipt`,
        description: err instanceof Error ? err.message : undefined,
        variant: "destructive",
      });
    };

    if (receiptId != null) {
      updateReceipt.mutate(
        { id: receiptId, data: { ...payload, updatedBy: values.enteredBy } },
        {
          onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["/api/yarn-receipts"] });
            queryClient.invalidateQueries({ queryKey: [`/api/yarn-receipts/${receiptId}`] });
            setPendingAction(null);
            toast({ title: "Yarn receipt updated" });
            onOpenChange(false);
          },
          onError: handleError("update"),
        },
      );
      return;
    }

    createReceipt.mutate(
      { data: payload },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/yarn-receipts"] });
          setPendingAction(null);
          toast({ title: "Yarn receipt saved" });
          onOpenChange(false);
        },
        onError: handleError("save"),
      },
    );
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !isBusy && onOpenChange(o)}>
      <DialogContent className="grid max-h-[92dvh] max-w-2xl grid-rows-[auto_minmax(0,1fr)_auto] gap-0 p-0">
        <DialogHeader className="px-4 pb-3 pr-12 pt-5 text-left sm:px-6 sm:pr-12 sm:pt-6">
          <DialogTitle>
            {readOnly ? "View Yarn Receipt" : isEdit ? "Edit Yarn Receipt" : "Add Yarn Receipt"}
          </DialogTitle>
          <DialogDescription>
            {readOnly
              ? "This receipt has been booked into a Yarn Receipt transaction and is locked. Viewing only — it can't be changed."
              : isEdit
                ? "Amend the receipt details or the yarn lots received."
                : "Enter the receipt header, then add each yarn lot (count, bags, net weight)."}
          </DialogDescription>
        </DialogHeader>

        <div className="min-h-0 overflow-y-auto overscroll-contain px-4 pb-5 sm:px-6">
          {isLoadingReceipt && (
            <div className="flex items-center gap-2 py-8 text-sm text-muted-foreground">
              <Spinner />
              Loading receipt…
            </div>
          )}

          <div className="sticky top-0 z-20 -mx-4 border-b bg-background px-4 pb-4 pt-4 sm:-mx-6 sm:px-6">
            <div className="selvedge-top grid grid-cols-2 divide-x divide-border pt-4">
              <div className="pr-4">
                <p className="eyebrow">Bags received</p>
                <p className="num mt-1.5 text-3xl font-semibold leading-none text-foreground sm:text-4xl">
                  {totalQty}
                </p>
              </div>
              <div className="pl-4">
                <p className="eyebrow">Net weight</p>
                <p className="num mt-1.5 text-3xl font-semibold leading-none text-foreground sm:text-4xl">
                  {totalNetWeight.toFixed(3)}
                </p>
              </div>
            </div>
          </div>

          <Form {...form}>
            <div className="space-y-4 pt-5">
              <p className="eyebrow">Receipt details</p>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <FormField
                  control={form.control}
                  name="receiptDate"
                  render={({ field }) => (
                    <FormItem className="flex flex-col">
                      <FormLabel>Date *</FormLabel>
                      <FormControl>
                        <Input
                          type="date"
                          className="h-9"
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
                          className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
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
                  name="enteredBy"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>{isEdit ? "Updated By *" : "Entered By *"}</FormLabel>
                      <FormControl>
                        <Input placeholder="Your name" disabled={readOnly} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="border-t pt-4">
                <p className="eyebrow">Yarn lots</p>
                <div className="mt-2 rounded-md border">
                  <Table>
                    <TableBody>
                      {lines.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={5} className="text-center text-muted-foreground py-6">
                            No yarn lots added yet
                          </TableCell>
                        </TableRow>
                      ) : (
                        lines.map((l, i) => (
                          <TableRow key={l.key}>
                            <TableCell className="w-10 py-1.5">
                              <span className="num inline-flex h-6 min-w-6 items-center justify-center rounded-sm border border-border bg-muted px-1.5 text-xs text-muted-foreground">
                                {i + 1}
                              </span>
                            </TableCell>
                            <TableCell className="py-1.5">
                              <select
                                className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                                value={l.yarnCountId}
                                disabled={readOnly}
                                onChange={(e) => updateLine(l.key, { yarnCountId: e.target.value })}
                              >
                                <option value="" disabled>Count</option>
                                {yarnCountMaster?.map((c) => (
                                  <option key={c.id} value={c.id.toString()}>{c.count}</option>
                                ))}
                              </select>
                            </TableCell>
                            <TableCell className="py-1.5">
                              <select
                                className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                                value={l.yarnBrandId}
                                disabled={readOnly}
                                onChange={(e) => updateLine(l.key, { yarnBrandId: e.target.value })}
                              >
                                <option value="" disabled>Brand</option>
                                {yarnBrandMaster?.map((b) => (
                                  <option key={b.id} value={b.id.toString()}>{b.name}</option>
                                ))}
                              </select>
                            </TableCell>
                            <TableCell className="py-1.5">
                              <Input
                                type="number"
                                min="1"
                                step="1"
                                inputMode="numeric"
                                placeholder="Bags"
                                className="num h-9"
                                value={l.quantity}
                                disabled={readOnly}
                                onChange={(e) => updateLine(l.key, { quantity: e.target.value })}
                              />
                            </TableCell>
                            <TableCell className="py-1.5">
                              <Input
                                type="number"
                                min="0"
                                step="any"
                                inputMode="decimal"
                                placeholder="Net kg"
                                className="num h-9"
                                value={l.netWeight}
                                disabled={readOnly}
                                onChange={(e) => updateLine(l.key, { netWeight: e.target.value })}
                              />
                            </TableCell>
                            <TableCell className="w-10 py-1.5 text-right">
                              {!readOnly && (
                                <Button
                                  type="button"
                                  variant="ghost"
                                  size="icon"
                                  className="h-8 w-8 text-muted-foreground hover:text-destructive"
                                  aria-label={`Remove line ${i + 1}`}
                                  onClick={() => handleRemoveLine(l.key)}
                                >
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              )}
                            </TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </div>
                {lineError && <p className="text-sm font-medium text-destructive mt-1.5">{lineError}</p>}
                {!readOnly && (
                  <Button type="button" variant="outline" className="mt-2" onClick={handleAddLine}>
                    <Plus className="mr-2 h-4 w-4" />
                    Add line
                  </Button>
                )}
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
              <Button
                type="button"
                variant="signal"
                className="w-full sm:w-auto"
                onClick={doSave}
                disabled={isBusy || isLoadingReceipt}
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
