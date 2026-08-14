import { useEffect, useRef, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { format } from "date-fns";
import { useQueryClient } from "@tanstack/react-query";

import {
  useCreateFactoryMaintenance,
  useUpdateFactoryMaintenance,
  useGetFactoryMaintenance,
} from "@/hooks/use-factory-maintenance";

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
import { useCurrentUserDisplayName } from "@/hooks/use-current-user";

// Fixed category options (issue #109). "Other" is the default selection and is
// a member of the list; stored as a plain string so a future change to this
// list never orphans history.
export const FACTORY_CATEGORIES = [
  "Electrical",
  "Plumbing",
  "Civil",
  "Compressor",
  "HVAC",
  "Safety",
  "Housekeeping",
  "Painting",
  "Other",
];

const factorySchema = z.object({
  maintenanceDate: z.date({ required_error: "Date is required" }),
  category: z.string().min(1, "Category is required"),
  maintenanceWork: z.string().min(1, "Maintenance work is required"),
  enteredBy: z.string().min(1, "Enter your name"),
});
type FactoryValues = z.infer<typeof factorySchema>;

function defaultValues(enteredBy: string, defaultDate: Date = new Date()): FactoryValues {
  return {
    maintenanceDate: defaultDate,
    category: "Other",
    maintenanceWork: "",
    enteredBy,
  };
}

export function FactoryMaintenanceDialog({
  open,
  onOpenChange,
  recordId = null,
  defaultDate,
  maxDate,
  readOnly = false,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  recordId?: number | null;
  defaultDate?: Date;
  maxDate?: Date;
  readOnly?: boolean;
}) {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const isEdit = recordId != null;

  const createRecord = useCreateFactoryMaintenance();
  const updateRecord = useUpdateFactoryMaintenance();

  const recordQuery = useGetFactoryMaintenance(recordId ?? null, {
    query: { enabled: open && isEdit },
  });
  const record = recordQuery.data;

  // "Entered By" is always the logged-in user; the field is read-only.
  const enteredByName = useCurrentUserDisplayName();

  const form = useForm<FactoryValues>({
    resolver: zodResolver(factorySchema),
    defaultValues: defaultValues(enteredByName, defaultDate),
  });

  const [pendingAction, setPendingAction] = useState<"save" | "saveAndAdd" | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  const prefilledFor = useRef<number | null | undefined>(undefined);

  useEffect(() => {
    if (!open) {
      prefilledFor.current = undefined;
      return;
    }

    if (!isEdit) {
      if (prefilledFor.current === null) return;
      prefilledFor.current = null;
      form.reset(defaultValues(enteredByName, defaultDate));
      setPendingAction(null);
      setFormError(null);
      return;
    }

    if (!record || record.id !== recordId) return;
    if (prefilledFor.current === recordId) return;
    prefilledFor.current = recordId;

    form.reset({
      maintenanceDate: new Date(`${record.maintenanceDate}T00:00:00`),
      category: record.category || "Other",
      maintenanceWork: record.maintenanceWork,
      enteredBy: enteredByName,
    });
    setPendingAction(null);
    setFormError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isEdit, recordId, record, defaultDate, maxDate]);

  const isBusy = createRecord.isPending || updateRecord.isPending;
  const isLoadingRecord = isEdit && recordQuery.isLoading;

  const doSave = async (keepOpen: boolean) => {
    if (isBusy) return;
    const valid = await form.trigger();
    if (!valid) return;

    const values = form.getValues();

    setPendingAction(keepOpen ? "saveAndAdd" : "save");

    const payload = {
      maintenanceDate: format(values.maintenanceDate, "yyyy-MM-dd"),
      category: values.category.trim() || "Other",
      maintenanceWork: values.maintenanceWork.trim(),
      createdBy: values.enteredBy,
    };

    const handleError = (verb: string) => (err: unknown) => {
      setPendingAction(null);
      toast({
        title: `Failed to ${verb} factory maintenance`,
        description: err instanceof Error ? err.message : undefined,
        variant: "destructive",
      });
    };

    if (recordId != null) {
      updateRecord.mutate(
        { id: recordId, data: { ...payload, updatedBy: values.enteredBy } },
        {
          onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["/api/maintenance/factory"] });
            queryClient.invalidateQueries({ queryKey: [`/api/maintenance/factory/${recordId}`] });
            setPendingAction(null);
            toast({ title: "Factory maintenance updated" });
            onOpenChange(false);
          },
          onError: handleError("update"),
        },
      );
      return;
    }

    createRecord.mutate(
      { data: payload },
      {
        onSuccess: () => {
          queryClient.invalidateQueries({ queryKey: ["/api/maintenance/factory"] });
          setPendingAction(null);
          if (keepOpen) {
            form.setValue("maintenanceWork", "");
            toast({ title: "Saved", description: "Recorded. Ready for the next job." });
          } else {
            toast({ title: "Factory maintenance saved" });
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
            {readOnly ? "View Factory Maintenance" : isEdit ? "Edit Factory Maintenance" : "Add Factory Maintenance"}
          </DialogTitle>
          <DialogDescription>
            {readOnly
              ? "This record is cancelled. Viewing only — it can't be changed unless restored."
              : isEdit
                ? "Amend the factory maintenance job details."
                : "Record a factory maintenance job: category and work performed."}
          </DialogDescription>
        </DialogHeader>

        <div className="min-h-0 overflow-y-auto overscroll-contain px-4 pb-5 sm:px-6">
          {isLoadingRecord && (
            <div className="flex items-center gap-2 py-8 text-sm text-muted-foreground">
              <Spinner />
              Loading record…
            </div>
          )}

          <Form {...form}>
            <div className="space-y-4 pt-5">
              <p className="eyebrow">Maintenance details</p>
              {formError && <p className="text-sm font-medium text-destructive">{formError}</p>}

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="maintenanceDate"
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
                  name="category"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Category *</FormLabel>
                      <FormControl>
                        <select
                          className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 sm:h-9"
                          value={field.value}
                          disabled={readOnly}
                          onChange={(e) => field.onChange(e.target.value)}
                        >
                          {FACTORY_CATEGORIES.map((c) => (
                            <option key={c} value={c}>{c}</option>
                          ))}
                        </select>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="maintenanceWork"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-2">
                      <FormLabel>Maintenance Work *</FormLabel>
                      <FormControl>
                        <textarea
                          rows={3}
                          className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                          placeholder="Describe the maintenance work performed"
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
                        <Input placeholder="Your name" className="h-11 sm:h-9" disabled {...field} />
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
            <Button type="button" variant="outline" className="w-full sm:w-auto" onClick={() => onOpenChange(false)}>
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
                disabled={isBusy || isLoadingRecord}
              >
                {(pendingAction === "save" || isLoadingRecord) && <Spinner className="mr-2" />}
                Save
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
