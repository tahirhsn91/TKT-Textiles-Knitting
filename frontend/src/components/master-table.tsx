import { useMemo, useState } from "react";
import { Plus, Pencil, Trash2, Check, X } from "lucide-react";
import { useSort } from "@/hooks/use-sort";
import { SortableHead } from "@/components/sortable-head";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
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
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";

export type FieldOption = { value: string; label: string };

export type Field = {
  key: string;
  label: string;
  placeholder?: string;
  type?: string;
  step?: string;
  options?: FieldOption[];
  displayKey?: string;
  defaultValue?: string;
};

type Row = { id: number; [key: string]: string | number | null | undefined };

type Props = {
  title: string;
  description?: string;
  fields: Field[];
  rows: Row[] | undefined;
  isLoading: boolean;
  onAdd: (data: Record<string, string>) => Promise<void>;
  onUpdate: (id: number, data: Record<string, string>) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
};

function FieldInput({
  field,
  value,
  onChange,
  autoFocus,
  onEnter,
  onEscape,
}: {
  field: Field;
  value: string;
  onChange: (v: string) => void;
  autoFocus?: boolean;
  onEnter?: () => void;
  onEscape?: () => void;
}) {
  if (field.type === "select" && field.options) {
    return (
      <Select value={value || "__none__"} onValueChange={(v) => onChange(v === "__none__" ? "" : v)}>
        <SelectTrigger className="h-8 text-sm">
          <SelectValue placeholder={field.placeholder || `Select ${field.label}`} />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="__none__">— None —</SelectItem>
          {field.options.map((o) => (
            <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>
    );
  }
  if (field.type === "checkbox") {
    return (
      <input
        type="checkbox"
        className="h-4 w-4 accent-primary"
        checked={value === "true"}
        onChange={(e) => onChange(String(e.target.checked))}
        autoFocus={autoFocus}
      />
    );
  }
  return (
    <Input
      className="h-8 text-sm"
      type={field.type || "text"}
      step={field.step}
      placeholder={field.placeholder || field.label}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onKeyDown={(e) => {
        if (e.key === "Enter" && onEnter) onEnter();
        if (e.key === "Escape" && onEscape) onEscape();
      }}
      autoFocus={autoFocus}
    />
  );
}

function displayValue(field: Field, row: Row): string {
  const raw = field.displayKey ? row[field.displayKey] : row[field.key];
  if (field.type === "select" && field.options) {
    const match = field.options.find((o) => o.value === String(row[field.key] ?? ""));
    return match ? match.label : (raw != null ? String(raw) : "—");
  }
  if (field.type === "checkbox") {
    return String(row[field.key]) === "true" ? "Yes" : "No";
  }
  return raw != null ? String(raw) : "";
}

export function MasterTable({
  title,
  description,
  fields,
  rows,
  isLoading,
  onAdd,
  onUpdate,
  onDelete,
}: Props) {
  const { toast } = useToast();
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editValues, setEditValues] = useState<Record<string, string>>({});
  const [addValues, setAddValues] = useState<Record<string, string>>({});
  const [showAddRow, setShowAddRow] = useState(false);
  const [saving, setSaving] = useState(false);

  // Sort on the value the cell actually renders, not the raw field. A select
  // column stores an id but shows a label, so sorting the raw value would
  // order parties by primary key while the user reads names.
  const accessors = useMemo(
    () => Object.fromEntries(fields.map((f) => [f.key, (row: Row) => displayValue(f, row)])),
    [fields],
  );
  const { sorted: sortedRows, sort, toggleSort } = useSort(rows, accessors);

  const emptyAdd = () => Object.fromEntries(fields.map((f) => [f.key, f.defaultValue ?? ""]));

  const startEdit = (row: Row) => {
    setEditingId(row.id as number);
    setEditValues(Object.fromEntries(fields.map((f) => [f.key, String(row[f.key] ?? "")])));
  };

  const cancelEdit = () => { setEditingId(null); setEditValues({}); };

  const handleSaveEdit = async () => {
    if (!editingId) return;
    setSaving(true);
    try {
      await onUpdate(editingId, editValues);
      toast({ title: `${title} updated` });
      setEditingId(null);
    } catch {
      toast({ title: "Failed to update", variant: "destructive" });
    } finally {
      setSaving(false);
    }
  };

  const handleAdd = async () => {
    setSaving(true);
    try {
      await onAdd(addValues);
      toast({ title: `${title} added` });
      setShowAddRow(false);
      setAddValues({});
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to add";
      toast({ title: msg, variant: "destructive" });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await onDelete(id);
      toast({ title: `${title} deleted` });
    } catch {
      toast({ title: "Failed to delete. It may be in use.", variant: "destructive" });
    }
  };

  return (
    <div className="flex flex-col gap-5">
      {/* Stacks on a phone so neither the description nor the action gets
          squeezed; the action goes full-width for a proper touch target. */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between sm:gap-6">
        <div>
          <h2 className="text-lg font-semibold leading-none text-foreground">{title}</h2>
          {description && (
            <p className="mt-2 max-w-prose text-sm text-muted-foreground">{description}</p>
          )}
        </div>
        <Button
          className="w-full shrink-0 sm:w-auto"
          onClick={() => { setShowAddRow(true); setAddValues(emptyAdd()); setEditingId(null); }}
          disabled={showAddRow}
        >
          <Plus className="mr-2 h-4 w-4" />
          Add new
        </Button>
      </div>

      {/* Card with a hairline section head, matching the production grid. The
          record count sits where that grid puts its date — the one piece of
          context worth carrying in a header. */}
      <Card className="overflow-hidden">
        <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b px-5 py-3.5">
          <h3 className="text-sm font-semibold text-foreground">All {title.toLowerCase()}</h3>
          {!isLoading && rows && (
            <span className="eyebrow">
              <span className="num">{rows.length}</span> record{rows.length === 1 ? "" : "s"}
            </span>
          )}
        </div>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              {fields.map((f) => (
                <SortableHead
                  key={f.key}
                  label={f.label}
                  sortKey={f.key}
                  sort={sort}
                  onSort={toggleSort}
                />
              ))}
              <TableHead className="w-24 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {/* Add row */}
            {showAddRow && (
              <TableRow className="bg-muted/30">
                {fields.map((f, i) => (
                  <TableCell key={f.key}>
                    <FieldInput
                      field={f}
                      value={addValues[f.key] || ""}
                      onChange={(v) => setAddValues((prev) => ({ ...prev, [f.key]: v }))}
                      autoFocus={i === 0}
                      onEnter={handleAdd}
                      onEscape={() => { setShowAddRow(false); setAddValues({}); }}
                    />
                  </TableCell>
                ))}
                <TableCell className="text-right">
                  <div className="flex justify-end gap-1">
                    {/* Solid Graphite primary, not green. Green is not in the
                        Mass Balance palette, and Signal is reserved for the
                        one primary action per screen (Add new). */}
                    <Button size="icon" className="h-9 w-9 sm:h-8 sm:w-8" aria-label="Save new entry" onClick={handleAdd} disabled={saving}>
                      <Check className="h-4 w-4" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-9 w-9 sm:h-8 sm:w-8" aria-label="Discard new entry" onClick={() => { setShowAddRow(false); setAddValues({}); }}>
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            )}

            {/* Loading */}
            {isLoading && Array.from({ length: 3 }).map((_, i) => (
              <TableRow key={i}>
                {fields.map((f) => <TableCell key={f.key}><Skeleton className="h-5 w-full" /></TableCell>)}
                <TableCell><Skeleton className="h-5 w-16 ml-auto" /></TableCell>
              </TableRow>
            ))}

            {/* Empty */}
            {!isLoading && !showAddRow && (!rows || rows.length === 0) && (
              <TableRow>
                {/* An empty screen is an invitation, not a dead end — and it
                    names the control by the label actually on the button. */}
                <TableCell colSpan={fields.length + 1} className="py-10 text-center text-muted-foreground">
                  No {title.toLowerCase()} recorded yet. Add the first one to get started.
                </TableCell>
              </TableRow>
            )}

            {/* Data rows */}
            {sortedRows.map((row) => (
              <TableRow key={row.id}>
                {fields.map((f, i) => (
                  // Figures get the tabular mono face so columns of numbers
                  // line up digit-for-digit, as they already do on the
                  // production and report grids.
                  <TableCell key={f.key} className={f.type === "number" ? "num" : undefined}>
                    {editingId === row.id ? (
                      <FieldInput
                        field={f}
                        value={editValues[f.key] || ""}
                        onChange={(v) => setEditValues((prev) => ({ ...prev, [f.key]: v }))}
                        autoFocus={i === 0}
                        onEnter={handleSaveEdit}
                        onEscape={cancelEdit}
                      />
                    ) : (
                      displayValue(f, row)
                    )}
                  </TableCell>
                ))}
                <TableCell className="text-right">
                  {editingId === row.id ? (
                    <div className="flex justify-end gap-1">
                      <Button size="icon" className="h-9 w-9 sm:h-8 sm:w-8" aria-label="Save changes" onClick={handleSaveEdit} disabled={saving}>
                        <Check className="h-4 w-4" />
                      </Button>
                      <Button size="icon" variant="ghost" className="h-9 w-9 sm:h-8 sm:w-8" aria-label="Cancel editing" onClick={cancelEdit}>
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ) : (
                    <div className="flex justify-end gap-1">
                      <Button size="icon" variant="ghost" className="h-9 w-9 text-muted-foreground hover:text-foreground sm:h-8 sm:w-8" aria-label={`Edit ${displayValue(fields[0], row)}`} onClick={() => startEdit(row)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button size="icon" variant="ghost" className="h-9 w-9 text-muted-foreground hover:text-destructive sm:h-8 sm:w-8" aria-label={`Delete ${displayValue(fields[0], row)}`}>
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            {/* Names the record instead of asking about "this
                                entry" — the user may have several rows open in
                                their head. */}
                            <AlertDialogTitle>Delete {displayValue(fields[0], row) || "this entry"}?</AlertDialogTitle>
                            <AlertDialogDescription>
                              This permanently removes the record. It can't be deleted if a transaction already uses it.
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancel</AlertDialogCancel>
                            <AlertDialogAction
                              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                              onClick={() => handleDelete(row.id as number)}
                            >
                              Delete
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
