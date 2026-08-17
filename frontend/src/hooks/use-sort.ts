import { useCallback, useMemo, useRef, useState } from "react";

export type SortDir = "asc" | "desc";

export type SortState<K extends string = string> = {
  key: K | null;
  dir: SortDir;
};

/** Extracts the comparable value for one column from one row. */
export type SortAccessors<T, K extends string = string> = Record<
  K,
  (row: T) => unknown
>;

function isEmpty(v: unknown): boolean {
  return v === null || v === undefined || v === "";
}

/**
 * Type-aware comparison for grid cells.
 *
 * The app's previous sort compared everything with a plain `localeCompare` on
 * strings, which orders "10" before "9". Numerics are compared as numbers, and
 * the string path passes `numeric: true` so mixed labels used throughout the
 * masters — "M#2" vs "M#10", "Count 20/1" vs "Count 100/1" — order the way an
 * operator reads them rather than character by character.
 *
 * ISO dates (YYYY-MM-DD) need no special case: lexicographic order is already
 * chronological, which is why the transactions grid's date column was correct
 * despite the string comparison.
 */
export function compareValues(a: unknown, b: unknown): number {
  if (typeof a === "number" && typeof b === "number") return a - b;
  if (typeof a === "boolean" && typeof b === "boolean") return Number(a) - Number(b);
  if (a instanceof Date && b instanceof Date) return a.getTime() - b.getTime();

  const as = String(a);
  const bs = String(b);
  // Number() already ignores surrounding whitespace, so trim once up-front
  // rather than re-checking the raw strings on every comparison.
  const aTrim = as.trim();
  const bTrim = bs.trim();
  if (aTrim !== "" && bTrim !== "") {
    const an = Number(aTrim);
    const bn = Number(bTrim);
    if (!Number.isNaN(an) && !Number.isNaN(bn)) return an - bn;
  }

  return as.localeCompare(bs, undefined, { numeric: true, sensitivity: "base" });
}

/**
 * Client-side grid sorting.
 *
 * Safe to do client-side here because no list endpoint in this app paginates —
 * every grid already holds its full result set. If server-side paging is ever
 * added, sorting has to move to the query or it will only order the visible
 * page, which looks like it works and quietly isn't.
 */
export function useSort<T, K extends string = string>(
  rows: T[] | undefined,
  accessors: SortAccessors<T, K>,
  initial: SortState<K> = { key: null, dir: "asc" },
) {
  const [sort, setSort] = useState<SortState<K>>(initial);

  // Accessor maps are recreated by callers as inline literals every render
  // (e.g. `useSort(rows, { partyName: (r) => r.partyName })`), so the maps
  // themselves are cheap to replace. Keeping the latest one in a ref means
  // `toggleSort` keeps a single stable identity for the lifetime of the hook
  // (no fresh handler per render), and the sorted memo below always reads the
  // latest accessors even though it only re-runs when rows or sort change.
  const accessorsRef = useRef(accessors);
  accessorsRef.current = accessors;

  // Typed as `string` rather than `K` on purpose. SortableHead's onSort is
  // `(key: string) => void` so that it stays a drop-in replacement for the
  // SortHead components the report pages already had; a `(key: K) => void`
  // handler is not assignable to that. Unknown keys are ignored instead of
  // being trusted, so a typo in a sortKey leaves the grid unsorted rather
  // than throwing.
  const toggleSort = useCallback((key: string) => {
    if (!(key in accessorsRef.current)) return;
    const k = key as K;
    setSort((prev) =>
      prev.key === k
        ? { key: k, dir: prev.dir === "asc" ? "desc" : "asc" }
        : { key: k, dir: "asc" },
    );
  }, []);

  const sorted = useMemo(() => {
    const list = rows ?? [];
    const key = sort.key;
    if (!key) return list;

    const accessor = accessorsRef.current[key];
    if (!accessor) return list;

    // Array.prototype.sort is stable per spec, so rows that tie keep the
    // order the server sent — which is what makes repeated toggling feel
    // predictable rather than shuffling equal rows around.
    return [...list].sort((ra, rb) => {
      const a = accessor(ra);
      const b = accessor(rb);

      // Blanks sort last in BOTH directions. Flipping them to the top on
      // descending buries the rows the user actually wants to look at.
      const aEmpty = isEmpty(a);
      const bEmpty = isEmpty(b);
      if (aEmpty || bEmpty) {
        if (aEmpty && bEmpty) return 0;
        return aEmpty ? 1 : -1;
      }

      return sort.dir === "asc" ? compareValues(a, b) : compareValues(b, a);
    });
  }, [rows, sort]);

  return { sorted, sort, toggleSort, setSort };
}
