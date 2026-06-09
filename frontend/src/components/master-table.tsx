import { useState } from "react";
import { Plus, Pencil, Trash2, Check, X } from "lucide-react";
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

  const emptyAdd = () => Object.fromEntries(fields.map((f) => [f.key, ""]));

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
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{title}</h2>
          {description && <p className="text-muted-foreground text-sm mt-0.5">{description}</p>}
        </div>
        <Button
          size="sm"
          onClick={() => { setShowAddRow(true); setAddValues(emptyAdd()); setEditingId(null); }}
          disabled={showAddRow}
        >
          <Plus className="mr-2 h-4 w-4" />
          Add New
        </Button>
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              {fields.map((f) => (
                <TableHead key={f.key}>{f.label}</TableHead>
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
                    <Button size="icon" variant="ghost" className="h-8 w-8 text-green-600 hover:text-green-700" onClick={handleAdd} disabled={saving}>
                      <Check className="h-4 w-4" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => { setShowAddRow(false); setAddValues({}); }}>
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
                <TableCell colSpan={fields.length + 1} className="text-center py-10 text-muted-foreground">
                  No entries yet. Click "Add New" to get started.
                </TableCell>
              </TableRow>
            )}

            {/* Data rows */}
            {rows?.map((row) => (
              <TableRow key={row.id}>
                {fields.map((f, i) => (
                  <TableCell key={f.key}>
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
                      <Button size="icon" variant="ghost" className="h-8 w-8 text-green-600 hover:text-green-700" onClick={handleSaveEdit} disabled={saving}>
                        <Check className="h-4 w-4" />
                      </Button>
                      <Button size="icon" variant="ghost" className="h-8 w-8" onClick={cancelEdit}>
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ) : (
                    <div className="flex justify-end gap-1">
                      <Button size="icon" variant="ghost" className="h-8 w-8 text-muted-foreground hover:text-foreground" onClick={() => startEdit(row)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button size="icon" variant="ghost" className="h-8 w-8 text-muted-foreground hover:text-destructive">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Delete this entry?</AlertDialogTitle>
                            <AlertDialogDescription>
                              This will permanently remove this record. It cannot be deleted if it is currently used in a transaction.
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
    </div>
  );
}
