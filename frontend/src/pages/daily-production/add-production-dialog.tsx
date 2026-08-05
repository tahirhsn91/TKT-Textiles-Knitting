import { NUM_DECIMALS } from "@/lib/format";
import { useEffect, useRef, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { format } from "date-fns";
import { Plus, Trash2 } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";

import {
  useListMachineMaster,
  useListPartyMaster,
  useListEmployeeMaster,
  useListDepartmentMaster,
} from "@workspace/api-client-react";
import {
  useCreateDailyProduction,
  useUpdateDailyProduction,
  useGetDailyProduction,
  type Shift,
} from "@/hooks/use-daily-production";

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
import { Table, TableBody, TableCell, TableRow } from "@/components/ui/table";
import { Spinner } from "@/components/ui/spinner";
import { useToast } from "@/hooks/use-toast";
import { useIsMobile } from "@/hooks/use-mobile";

const LS_ENTERED_BY = "daily-production-entered-by";

const headerSchema = z.object({
  productionDate: z.date({ required_error: "Production date is required" }),
  machineId: z.number({ required_error: "Machine is required" }),
  employeeId: z.number({ required_error: "Employee is required" }),
  partyId: z.number({ required_error: "Party is required" }),
  shift: z.enum(["Morning", "Night"], { required_error: "Shift is required" }),
  enteredBy: z.string().min(1, "Enter your name"),
});
type HeaderValues = z.infer<typeof headerSchema>;

interface RollRow {
  key: number;
  weight: string;
}

let rollKeySeq = 0;

function defaultHeaderValues(enteredBy: string, defaultDate: Date = new Date()): HeaderValues {
  return {
    productionDate: defaultDate,
    machineId: undefined as unknown as number,
    employeeId: undefined as unknown as number,
    partyId: undefined as unknown as number,
    shift: undefined as unknown as Shift,
    enteredBy,
  };
}

/**
 * Handles both creating a new production entry and editing an existing one.
 * Pass `entryId` to edit; leave it null/undefined to create. In edit mode the
 * footer drops "Save & Add" — that action exists to chain *new* entries and
 * has no meaning once you are amending a specific record.
 */
export function ProductionEntryDialog({
  open,
  onOpenChange,
  entryId = null,
  readOnly = false,
  defaultDate,
  maxDate,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  entryId?: number | null;
  readOnly?: boolean;
  /** Date prefilled for a new entry — the page passes its selected date. */
  defaultDate?: Date;
  /** Latest selectable date in the picker (the page blocks today onwards). */
  maxDate?: Date;
}) {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isMobile = useIsMobile();

  const isEdit = entryId != null;

  const { data: machineMaster } = useListMachineMaster();
  const { data: partyMaster } = useListPartyMaster();
  const { data: employeeMaster } = useListEmployeeMaster();
  const { data: departments } = useListDepartmentMaster();

  // Only employees belonging to the Production department appear here — the
  // dropdown feeds a knitting production form, so employees from other
  // departments (e.g. Administration) would be noise. Matched by department
  // code (0002) rather than name or a hardcoded id, so it keeps working even
  // if the department name changes.
  const productionDepartmentId = departments?.find(
    (d) => d.code === "0002",
  )?.id;
  const productionEmployees = employeeMaster?.filter(
    (op) =>
      (op as { active?: boolean }).active !== false &&
      op.departmentId != null &&
      op.departmentId === productionDepartmentId,
  );
  const createEntry = useCreateDailyProduction();
  const updateEntry = useUpdateDailyProduction();

  const entryQuery = useGetDailyProduction(entryId ?? 0, {
    query: { enabled: open && isEdit },
  });
  const entry = entryQuery.data;

  const savedEnteredBy = (() => {
    try { return localStorage.getItem(LS_ENTERED_BY) ?? ""; } catch { return ""; }
  })();

  const form = useForm<HeaderValues>({
    resolver: zodResolver(headerSchema),
    defaultValues: defaultHeaderValues(savedEnteredBy, defaultDate),
  });

  const [rolls, setRolls] = useState<RollRow[]>([]);
  const [rollInput, setRollInput] = useState("");
  const [rollError, setRollError] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<"save" | "saveAndAdd" | null>(null);

  const rollInputRef = useRef<HTMLInputElement>(null);

  // Tracks which record the form currently holds, so a background refetch of
  // the entry can't clobber edits the user has already typed. `undefined`
  // means "not yet populated for this opening of the dialog".
  const prefilledFor = useRef<number | null | undefined>(undefined);

  // Fresh state every time the modal is opened — regardless of how the
  // previous session ended (Save, Cancel, Escape, overlay click). In edit
  // mode the reset has to wait for the record to arrive.
  useEffect(() => {
    if (!open) {
      prefilledFor.current = undefined;
      return;
    }

    if (!isEdit) {
      if (prefilledFor.current === null) return;
      prefilledFor.current = null;
      form.reset(defaultHeaderValues(savedEnteredBy, defaultDate));
      setRolls([]);
      setRollInput("");
      setRollError(null);
      setPendingAction(null);
      return;
    }

    if (!entry || entry.id !== entryId) return;
    if (prefilledFor.current === entryId) return;
    prefilledFor.current = entryId;

    form.reset({
      productionDate: new Date(`${entry.productionDate}T00:00:00`),
      machineId: entry.machineId,
      employeeId: entry.employeeId,
      partyId: entry.partyId,
      shift: entry.shift,
      enteredBy: savedEnteredBy || entry.createdBy,
    });
    setRolls(entry.rolls.map((r) => ({ key: ++rollKeySeq, weight: r.rollWeight })));
    setRollInput("");
    setRollError(null);
    setPendingAction(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isEdit, entryId, entry, defaultDate]);

  const handleAddRoll = useCallback(() => {
    const trimmed = rollInput.trim();
    const value = Number(trimmed);
    if (!trimmed || isNaN(value) || value <= 0) {
      setRollError("Enter a roll weight greater than zero");
      return;
    }
    setRolls((prev) => [...prev, { key: ++rollKeySeq, weight: trimmed }]);
    setRollInput("");
    setRollError(null);
    requestAnimationFrame(() => rollInputRef.current?.focus());
  }, [rollInput]);

  const handleRollKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleAddRoll();
    }
  };

  const handleRemoveRoll = (key: number) => {
    setRolls((prev) => prev.filter((r) => r.key !== key));
  };

  const totalWeight = rolls.reduce((s, r) => s + (parseFloat(r.weight) || 0), 0);

  const isBusy = createEntry.isPending || updateEntry.isPending;
  const isLoadingEntry = isEdit && entryQuery.isLoading;

  const doSave = async (keepOpen: boolean) => {
    if (isBusy) return; // guard against double-click / double-Enter submissions

    const valid = await form.trigger();
    if (!valid) return;

    if (rolls.length === 0) {
      setRollError("At least one yarn roll entry is required");
      return;
    }

    // A list of rolls could still sum to zero (e.g. all weights entered as
    // 0.00 before the per-roll guard tightened) — the total must be positive
    // too, or the production entry is meaningless.
    if (!(totalWeight > 0)) {
      setRollError("Total weight must be greater than zero");
      return;
    }

    const values = form.getValues();
    try { localStorage.setItem(LS_ENTERED_BY, values.enteredBy); } catch {}

    setPendingAction(keepOpen ? "saveAndAdd" : "save");

    const payload = {
      productionDate: format(values.productionDate, "yyyy-MM-dd"),
      machineId: values.machineId,
      employeeId: values.employeeId,
      partyId: values.partyId,
      shift: values.shift,
      remarks: null,
      rolls: rolls.map((r) => ({ rollWeight: r.weight })),
    };

    const handleError = (verb: string) => (err: unknown) => {
      setPendingAction(null);
      toast({
        title: `Failed to ${verb} production entry`,
        description: err instanceof Error ? err.message : undefined,
        variant: "destructive",
      });
    };

    // Checked as `entryId != null` rather than via `isEdit` so TypeScript
    // narrows the id to a number for the mutation payload.
    if (entryId != null) {
      // PUT replaces the rolls wholesale, so roll_number stays a contiguous
      // 1..N sequence after an edit.
      updateEntry.mutate(
        { id: entryId, data: { ...payload, updatedBy: values.enteredBy } },
        {
          onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["/api/daily-production"] });
            queryClient.invalidateQueries({ queryKey: [`/api/daily-production/${entryId}`] });
            setPendingAction(null);
            toast({ title: "Production entry updated" });
            onOpenChange(false);
          },
          onError: handleError("update"),
        },
      );
      return;
    }

    createEntry.mutate(
      { data: { ...payload, createdBy: values.enteredBy } },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/daily-production"] });
          setPendingAction(null);

          if (keepOpen) {
            toast({ title: "Saved", description: `${rolls.length} roll(s) recorded. Ready for the next entry.` });
            setRolls([]);
            setRollInput("");
            setRollError(null);
            requestAnimationFrame(() => rollInputRef.current?.focus());
          } else {
            toast({ title: "Production entry saved successfully" });
            onOpenChange(false);
          }
        },
        onError: handleError("save"),
      },
    );
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !isBusy && onOpenChange(o)}>
      {/* The dialog is a three-row grid — header / scrolling body / footer —
          capped at 92dvh. `minmax(0,1fr)` on the middle row is what actually
          lets it shrink: without it the row takes its content height, the
          dialog grows past the viewport, and because DialogContent is
          centred with translate(-50%,-50%) the overflow is clipped off both
          edges with nothing to scroll. dvh rather than vh so mobile browser
          chrome doesn't eat the footer. */}
      <DialogContent className="grid max-h-[92dvh] max-w-2xl grid-rows-[auto_minmax(0,1fr)_auto] gap-0 p-0">
        <DialogHeader className="px-4 pb-3 pr-12 pt-5 text-left sm:px-6 sm:pr-12 sm:pt-6">
          <DialogTitle>
            {readOnly
              ? "View Daily Production"
              : isEdit
                ? "Edit Daily Production"
                : "Add Daily Production"}
          </DialogTitle>
          <DialogDescription>
            {readOnly
              ? "This entry has been reconciled into a Fabric Production transaction and is locked. Viewing only — it can't be changed."
              : isEdit
                ? "Amend the machine run details or the recorded yarn roll weights."
                : "Enter the machine run details, then record each yarn roll weight below."}
          </DialogDescription>
        </DialogHeader>

        {/* Single scroll container for the whole body. Nothing inside scrolls
            independently — nested scroll areas on a touch screen trap the
            gesture and are the reason the roll list felt unscrollable. */}
        <div className="min-h-0 overflow-y-auto overscroll-contain px-4 pb-5 sm:px-6">
          {isLoadingEntry && (
            <div className="flex items-center gap-2 py-8 text-sm text-muted-foreground">
              <Spinner />
              Loading entry…
            </div>
          )}

          {/* Running tally. This is the number the floor actually watches while
              tagging rolls, so it leads the dialog and stays pinned while the
              form scrolls under it. selvedge-top is the existing signature for
              "this leads the card" — same treatment as the grand total on the
              production grid — rather than a new accessory. */}
          <div className="sticky top-0 z-20 -mx-4 border-b bg-background px-4 pb-4 pt-4 sm:-mx-6 sm:px-6">
            <div className="selvedge-top grid grid-cols-2 divide-x divide-border pt-4">
              <div className="pr-4">
                <p className="eyebrow">Rolls entered</p>
                <p className="num mt-1.5 text-3xl font-semibold leading-none text-foreground sm:text-4xl">
                  {rolls.length}
                </p>
              </div>
              <div className="pl-4">
                <p className="eyebrow">Total weight</p>
                <p className="num mt-1.5 text-3xl font-semibold leading-none text-foreground sm:text-4xl">
                  {totalWeight.toFixed(NUM_DECIMALS)}
                </p>
              </div>
            </div>
          </div>

        <Form {...form}>
          <div className="space-y-4 pt-5">
            <p className="eyebrow">Production details</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="productionDate"
                render={({ field }) => (
                  <FormItem className="flex flex-col">
                    <FormLabel>Production Date *</FormLabel>
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
                name="shift"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Shift *</FormLabel>
                    <FormControl>
                      <select
                        className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                        value={field.value ?? ""}
                        disabled={readOnly}
                        onChange={(e) => field.onChange(e.target.value || undefined)}
                      >
                        <option value="" disabled>Select shift</option>
                        <option value="Morning">Morning</option>
                        <option value="Night">Night</option>
                      </select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="machineId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Machine Number *</FormLabel>
                    <FormControl>
                      <select
                        className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                        value={field.value?.toString() ?? ""}
                        disabled={readOnly}
                        onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : undefined)}
                      >
                        <option value="" disabled>Select machine</option>
                        {machineMaster?.map((m) => (
                          <option key={m.id} value={m.id.toString()}>{m.name}</option>
                        ))}
                      </select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="employeeId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Employee *</FormLabel>
                    <FormControl>
                      <select
                        className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                        value={field.value?.toString() ?? ""}
                        disabled={readOnly}
                        onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : undefined)}
                      >
                        <option value="" disabled>Select employee</option>
                        {productionEmployees?.map((op) => (
                          <option key={op.id} value={op.id.toString()}>{op.name}</option>
                        ))}
                      </select>
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
                    <FormLabel>Party *</FormLabel>
                    <FormControl>
                      <select
                        className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                        value={field.value?.toString() ?? ""}
                        disabled={readOnly}
                        onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : undefined)}
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
                      <Input placeholder="Your name" className="h-11 sm:h-9" disabled={readOnly} {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <div className="border-t pt-4">
              <p className="eyebrow">Yarn roll entries</p>
              {!readOnly && (
                <div className="mt-2 flex items-end gap-2">
                <div className="flex-1">
                  <label className="text-sm font-medium mb-1.5 block">Roll weight</label>
                  <Input
                    ref={rollInputRef}
                    type="number"
                    step="any"
                    min="0"
                    disabled={readOnly}
                    // Brings up the numeric keypad with a decimal key on iOS
                    // and Android instead of the full alphabetic keyboard.
                    inputMode="decimal"
                    placeholder={isMobile ? "Weight" : "Enter weight and press Enter"}
                    className="num h-11 sm:h-9"
                    value={rollInput}
                    onChange={(e) => { setRollInput(e.target.value); setRollError(null); }}
                    onKeyDown={handleRollKeyDown}
                    // Autofocusing on a phone throws the keyboard up over the
                    // form the moment the dialog opens, hiding the fields the
                    // employee has to fill in first.
                    autoFocus={!isMobile}
                  />
                </div>
                <Button type="button" className="h-11 shrink-0 sm:h-9" onClick={handleAddRoll}>
                  <Plus className="mr-2 h-4 w-4" />
                  Add
                </Button>
                </div>
              )}
              {rollError && <p className="text-sm font-medium text-destructive mt-1.5">{rollError}</p>}

              <div className="mt-3 rounded-md border">
                <Table>
                  <TableBody>
                    {rolls.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={3} className="text-center text-muted-foreground py-6">
                          No rolls entered yet
                        </TableCell>
                      </TableRow>
                    ) : (
                      rolls.map((r, i) => (
                        // A roll over 30 kg is out of the ordinary for this
                        // line — tint the row red so the floor can see at a
                        // glance which rolls deserve a second look.
                        <TableRow
                          key={r.key}
                          className={parseFloat(r.weight) > 30 ? "bg-red-300 dark:bg-red-900/80" : undefined}
                        >
                          <TableCell className="w-14 py-1.5">
                            {/* A roll tag: this really is the sequence a physical
                                roll gets tagged with on the floor, not a
                                decorative index. */}
                            <span className="num inline-flex h-6 min-w-6 items-center justify-center rounded-sm border border-border bg-muted px-1.5 text-xs text-muted-foreground">
                              {i + 1}
                            </span>
                          </TableCell>
                          <TableCell className="num py-1.5">{Number(r.weight).toFixed(NUM_DECIMALS)}</TableCell>
                          <TableCell className="w-12 py-1.5 text-right">
                            {!readOnly && (
                              <Button
                                type="button"
                                variant="ghost"
                                size="icon"
                                className="h-11 w-11 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8"
                                aria-label={`Remove roll ${i + 1}`}
                                onClick={() => handleRemoveRoll(r.key)}
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
            </div>
          </div>
        </Form>
        </div>

        {/* Pinned outside the scroll area so Save stays reachable on a short
            mobile viewport. DialogFooter's base only sets sm:space-x-2, which
            leaves stacked mobile buttons flush against each other — hence the
            explicit gap. */}
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
                  Save & Add
                </Button>
              )}
              <Button
                type="button"
                variant="signal"
                className="w-full sm:w-auto"
                onClick={() => doSave(false)}
                disabled={isBusy || isLoadingEntry}
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
