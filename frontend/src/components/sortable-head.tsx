import { ChevronUp, ChevronDown, ChevronsUpDown } from "lucide-react";
import { TableHead } from "@/components/ui/table";
import type { SortDir } from "@/hooks/use-sort";

/**
 * Sortable column header.
 *
 * The prop shape deliberately matches the local `SortHead` components that
 * already existed in the two report pages, so those were a drop-in swap. The
 * drag props are carried for the transactions grid, which supports
 * drag-to-reorder columns alongside sorting.
 *
 * The clickable target is a real <button> rather than a click handler on the
 * <th>: the previous implementations were mouse-only, so no column could be
 * sorted from the keyboard. `aria-sort` on the cell reports current state to
 * screen readers.
 */
export function SortableHead({
  label,
  sortKey,
  sort,
  onSort,
  right,
  className,
  draggable,
  onDragStart,
  onDragOver,
  onDrop,
  onDragEnd,
  isDragging,
}: {
  label: string;
  sortKey: string;
  sort: { key: string | null; dir: SortDir };
  onSort: (key: string) => void;
  right?: boolean;
  className?: string;
  draggable?: boolean;
  onDragStart?: (e: React.DragEvent<HTMLTableCellElement>) => void;
  onDragOver?: (e: React.DragEvent<HTMLTableCellElement>) => void;
  onDrop?: (e: React.DragEvent<HTMLTableCellElement>) => void;
  onDragEnd?: () => void;
  isDragging?: boolean;
}) {
  const active = sort.key === sortKey;

  return (
    <TableHead
      aria-sort={active ? (sort.dir === "asc" ? "ascending" : "descending") : "none"}
      className={[
        "select-none whitespace-nowrap transition-opacity",
        right ? "text-right" : "",
        draggable ? "cursor-grab" : "",
        isDragging ? "opacity-30" : "",
        className ?? "",
      ].filter(Boolean).join(" ")}
      draggable={draggable}
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDrop={onDrop}
      onDragEnd={onDragEnd}
    >
      <button
        type="button"
        onClick={() => onSort(sortKey)}
        className={[
          "inline-flex items-center gap-1 rounded-sm text-inherit",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          right ? "w-full justify-end" : "",
        ].filter(Boolean).join(" ")}
      >
        {label}
        {active ? (
          sort.dir === "asc"
            ? <ChevronUp className="h-3 w-3 shrink-0" />
            : <ChevronDown className="h-3 w-3 shrink-0" />
        ) : (
          <ChevronsUpDown className="h-3 w-3 shrink-0 opacity-35" />
        )}
      </button>
    </TableHead>
  );
}
