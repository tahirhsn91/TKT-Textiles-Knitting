import { NUM_DECIMALS } from "@/lib/format";
import { useEffect, useRef, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { format } from "date-fns";
import { Plus, Trash2 } from "lucide-react";
import { useQueryClient, useQuery } from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

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
import { DateInput } from "@/components/ui/date-input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Spinner } from "@/components/ui/spinner";
import { useToast } from "@/hooks/use-toast";
import { useCurrentUserDisplayName } from "@/hooks/use-current-user";
import { PlausibilityWarnings } from "@/components/plausibility-warning";
import {
  validateDailyEntry,
  recordPlausibilityFeedback,
  warningsToFeedback,
  type PlausibilityWarning,
} from "@/lib/plausibility";

const headerSchema = z.object({
  docNumber: z.string().min(1, "Document number is required"),
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

function emptyLine(): LineRow {
  return { key: ++lineKeySeq, yarnCountId: "", yarnBrandId: "", quantity: "", netWeight: "" };
}

function defaultHeaderValues(enteredBy: string, defaultDate: Date = new Date()): HeaderValues {
  return {
    docNumber: "",
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

  // Next doc number suggestion (YR-<n>), like the transactions screen.
  const { data: suggestions } = useQuery<{ nextDocNumber: string }>({
    queryKey: ["/api/yarn-receipts/suggestions"],
    queryFn: () => customFetch<{ nextDocNumber: string }>("/api/yarn-receipts/suggestions", { method: "GET" }),
  });

  const receiptQuery = useGetYarnReceipt(receiptId ?? null, {
    query: { enabled: open && isEdit },
  });
  const receipt = receiptQuery.data;

  // "Entered By" is always the logged-in user; the field is read-only.
  const enteredByName = useCurrentUserDisplayName();

  const form = useForm<HeaderValues>({
    resolver: zodResolver(headerSchema),
    defaultValues: defaultHeaderValues(enteredByName, defaultDate),
  });

  const [lines, setLines] = useState<LineRow[]>([]);
  const [lineError, setLineError] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<"save" | "saveAndAdd" | null>(null);
  // Plausibility (warn-only): abnormal net weights / bag ratios require a
  // deliberate second confirmation before saving.
  const [plausWarnings, setPlausWarnings] = useState<PlausibilityWarning[]>([]);
  const [plausConfirmed, setPlausConfirmed] = useState(false);
  const [validating, setValidating] = useState(false);

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
      form.reset(defaultHeaderValues(enteredByName, defaultDate));
      // Auto-fill the next doc number on a fresh receipt.
      if (suggestions?.nextDocNumber) {
        form.setValue("docNumber", suggestions.nextDocNumber);
      }
      // A fresh receipt starts with one empty line — the common case is a
      // single yarn lot, so the dialog opens ready to fill rather than
      // showing an empty state the user has to click past.
      setLines([emptyLine()]);
      setLineError(null);
      setPendingAction(null);
      return;
    }

    if (!receipt || receipt.id !== receiptId) return;
    if (prefilledFor.current === receiptId) return;
    prefilledFor.current = receiptId;

    form.reset({
      docNumber: receipt.docNumber,
      receiptDate: new Date(`${receipt.receiptDate}T00:00:00`),
      partyId: receipt.partyId,
      enteredBy: enteredByName,
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
  }, [open, isEdit, receiptId, receipt, defaultDate, suggestions]);

  const handleAddLine = useCallback(() => {
    setLines((prev) => [...prev, emptyLine()]);
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

  // Editing any line invalidates a prior plausibility confirmation.
  useEffect(() => {
    setPlausConfirmed(false);
    setPlausWarnings([]);
  }, [lines]);

  const isBusy = createReceipt.isPending || updateReceipt.isPending;
  const isLoadingReceipt = isEdit && receiptQuery.isLoading;

  const doSave = async (keepOpen: boolean) => {
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
    // Totals must be positive too (same rule as production / deliveries).
    if (!(totalQty > 0) || !(totalNetWeight > 0)) {
      setLineError("Total bags and net weight must both be greater than zero");
      return;
    }
    setLineError(null);

    const values = form.getValues();

    // ── Plausibility gate (warn-only) ──────────────────────────────────────
    // Validate each line's net weight, bag count and derived weight-per-bag.
    // Collect all warnings across lines; first save surfaces them, a second
    // click confirms.
    if (!plausConfirmed) {
      setValidating(true);
      const all: PlausibilityWarning[] = [];
      for (const l of lines) {
        const w = await validateDailyEntry("receipt", {
          netWeight: parseFloat(l.netWeight),
          quantity: parseInt(l.quantity, 10),
        });
        all.push(...w);
      }
      setValidating(false);
      if (all.length > 0) {
        setPlausWarnings(all);
        setPlausConfirmed(true);
        return;
      }
    } else if (plausWarnings.length > 0) {
      void recordPlausibilityFeedback(
        warningsToFeedback("receipt", plausWarnings, "confirmed_anyway", values.enteredBy),
      );
    }

    setPendingAction(keepOpen ? "saveAndAdd" : "save");

    const payload = {
      docNumber: values.docNumber,
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

          if (keepOpen) {
            // Chained entry: same party/date, fresh lines and the next doc
            // number — refetch the suggestion so YR-<n> advances.
            queryClient.invalidateQueries({ queryKey: ["/api/yarn-receipts/suggestions"] });
            queryClient
              .fetchQuery({ queryKey: ["/api/yarn-receipts/suggestions"], queryFn: () => customFetch<{ nextDocNumber: string }>("/api/yarn-receipts/suggestions", { method: "GET" }) })
              .then((s) => {
                if (s?.nextDocNumber) form.setValue("docNumber", s.nextDocNumber);
              })
              .catch(() => {});
            setLines([emptyLine()]);
            setLineError(null);
            toast({ title: "Saved", description: `${lines.length} lot(s) recorded. Ready for the next receipt.` });
          } else {
            toast({ title: "Yarn receipt saved" });
            onOpenChange(false);
          }
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
                  {totalNetWeight.toFixed(NUM_DECIMALS)}
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
                  name="docNumber"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Document Number *</FormLabel>
                      <FormControl>
                        <Input
                          placeholder="YR-1"
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
                  name="receiptDate"
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
                  name="enteredBy"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>{isEdit ? "Updated By *" : "Entered By *"}</FormLabel>
                      <FormControl>
                        <Input placeholder="Your name" className="h-11 sm:h-9" disabled {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="partyId"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-3">
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
              </div>

              <div className="border-t pt-4">
                <p className="eyebrow">Yarn lots</p>

                {/* Mobile: one stacked card per lot — the wide table is
                    unscrollable inside the modal on a phone. Desktop keeps
                    the dense table (hidden sm:block). */}
                <div className="mt-3 space-y-3 sm:hidden">
                  {lines.length === 0 ? (
                    <p className="rounded-md border py-6 text-center text-sm text-muted-foreground">
                      No yarn lots added yet
                    </p>
                  ) : (
                    lines.map((l, i) => (
                      <div key={l.key} className="rounded-md border p-3">
                        <div className="flex items-center justify-between gap-2">
                          <span className="num inline-flex h-6 min-w-6 items-center justify-center rounded-sm border border-border bg-muted px-1.5 text-xs text-muted-foreground">
                            {i + 1}
                          </span>
                          {!readOnly && (
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-11 w-11 text-muted-foreground hover:text-destructive"
                              aria-label={`Remove line ${i + 1}`}
                              onClick={() => handleRemoveLine(l.key)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          )}
                        </div>
                        <div className="mt-2 grid grid-cols-2 gap-2">
                          <select
                            className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={l.yarnCountId}
                            disabled={readOnly}
                            onChange={(e) => updateLine(l.key, { yarnCountId: e.target.value })}
                          >
                            <option value="" disabled>Count</option>
                            {yarnCountMaster?.map((c) => (
                              <option key={c.id} value={c.id.toString()}>{c.count}</option>
                            ))}
                          </select>
                          <select
                            className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            value={l.yarnBrandId}
                            disabled={readOnly}
                            onChange={(e) => updateLine(l.key, { yarnBrandId: e.target.value })}
                          >
                            <option value="" disabled>Brand</option>
                            {yarnBrandMaster?.map((b) => (
                              <option key={b.id} value={b.id.toString()}>{b.name}</option>
                            ))}
                          </select>
                        </div>
                        <div className="mt-2 grid grid-cols-2 gap-2">
                          <div>
                            <label className="mb-1 block text-xs font-medium text-muted-foreground">Bags</label>
                            <Input
                              type="number"
                              min="1"
                              step="1"
                              inputMode="numeric"
                              placeholder="Bags"
                              className="num h-11"
                              value={l.quantity}
                              disabled={readOnly}
                              onChange={(e) => updateLine(l.key, { quantity: e.target.value })}
                            />
                          </div>
                          <div>
                            <label className="mb-1 block text-xs font-medium text-muted-foreground">Net kg</label>
                            <Input
                              type="number"
                              min="0"
                              step="any"
                              inputMode="decimal"
                              placeholder="Net kg"
                              className="num h-11"
                              value={l.netWeight}
                              disabled={readOnly}
                              onChange={(e) => updateLine(l.key, { netWeight: e.target.value })}
                            />
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>

                <div className="mt-2 hidden rounded-md border sm:block">
                  <Table>
                    <TableHeader>
                      <TableRow className="hover:bg-transparent">
                        <TableHead className="w-10" />
                        <TableHead className="w-[7.5rem] text-xs font-medium text-muted-foreground">Count</TableHead>
                        <TableHead className="w-[9rem] text-xs font-medium text-muted-foreground">Brand</TableHead>
                        <TableHead className="w-28 text-xs font-medium text-muted-foreground">Bags</TableHead>
                        <TableHead className="w-32 text-xs font-medium text-muted-foreground">Net kg</TableHead>
                        <TableHead className="w-10" />
                      </TableRow>
                    </TableHeader>
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
                            <TableCell className="w-[7.5rem] py-1.5">
                              <select
                                className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
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
                            <TableCell className="w-[9rem] py-1.5">
                              <select
                                className="h-11 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
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
                            <TableCell className="w-28 py-1.5">
                              <Input
                                type="number"
                                min="1"
                                step="1"
                                inputMode="numeric"
                                placeholder="Bags"
                                className="num h-11 sm:h-9"
                                value={l.quantity}
                                disabled={readOnly}
                                onChange={(e) => updateLine(l.key, { quantity: e.target.value })}
                              />
                            </TableCell>
                            <TableCell className="w-32 py-1.5">
                              <Input
                                type="number"
                                min="0"
                                step="any"
                                inputMode="decimal"
                                placeholder="Net kg"
                                className="num h-11 sm:h-9"
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
                                  className="h-11 w-11 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
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
                  <Button type="button" className="mt-2 h-11 shrink-0 sm:h-9" onClick={handleAddLine}>
                    <Plus className="mr-2 h-4 w-4" />
                    Add
                  </Button>
                )}
              </div>
            </div>
          </Form>
        </div>

        {!readOnly && plausWarnings.length > 0 && (
          <div className="border-t bg-background px-4 pt-3 sm:px-6">
            <PlausibilityWarnings warnings={plausWarnings} />
          </div>
        )}

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
                  disabled={isBusy || validating}
                >
                  {pendingAction === "saveAndAdd" && <Spinner className="mr-2" />}
                  {plausWarnings.length > 0 ? "Save anyway & Add More" : "Save & Add More"}
                </Button>
              )}
              <Button
                type="button"
                variant="signal"
                className="w-full sm:w-auto"
                onClick={() => doSave(false)}
                disabled={isBusy || isLoadingReceipt || validating}
              >
                {(pendingAction === "save" || validating) && <Spinner className="mr-2" />}
                {plausWarnings.length > 0 ? "Save anyway" : "Save"}
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
