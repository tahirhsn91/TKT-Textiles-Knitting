/**
 * Date stepper extended with "previous / next date with unconciled data"
 * buttons (issue #120).
 *
 * Wraps the shared `DateStepper` and adds two double-chevron buttons that jump
 * to the nearest date (strictly before / after the selected date) holding at
 * least one unreconciled row (`reconciled=false`, `status<>'cancelled'`).
 * Each button is disabled while the nav targets are loading, and disabled for
 * its direction when no such date exists. Used on the three daily operations
 * screens (Daily Production, Yarn Receipt, Daily Delivery).
 */
import { ChevronsLeft, ChevronsRight } from "lucide-react";
import { DateStepper } from "@/components/date-stepper";
import { Button } from "@/components/ui/button";
import {
  useUnreconciledNav,
  type UnreconciledOperation,
} from "@/hooks/use-unreconciled-nav";

export function UnreconciledDateStepper({
  operation,
  value,
  max,
  onChange,
}: {
  operation: UnreconciledOperation;
  /** Selected date as YYYY-MM-DD. */
  value: string;
  /** Maximum selectable date (YYYY-MM-DD); the next arrow is disabled at it. */
  max?: string;
  onChange: (date: string) => void;
}) {
  const { data, isFetching } = useUnreconciledNav(operation, value);

  // Both buttons are disabled while the nav targets load (Q6); once loaded,
  // each is disabled when its direction has no unreconciled date (null target).
  const prevDisabled = isFetching || !data?.prev;
  const nextDisabled = isFetching || !data?.next;

  return (
    <div className="flex w-full flex-col gap-1.5">
      <DateStepper value={value} max={max} onChange={onChange} />
      <div className="flex items-center gap-1.5 border-t pt-1.5">
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="h-7 w-7 shrink-0"
          aria-label="Previous date with unconciled data"
          title="Previous date with unconciled data"
          onClick={() => data?.prev && onChange(data.prev)}
          disabled={prevDisabled}
        >
          <ChevronsLeft className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="h-7 w-7 shrink-0"
          aria-label="Next date with unconciled data"
          title="Next date with unconciled data"
          onClick={() => data?.next && onChange(data.next)}
          disabled={nextDisabled}
        >
          <ChevronsRight className="h-4 w-4" />
        </Button>
        <span className="min-w-0 flex-1 truncate text-xs text-muted-foreground">
          Unconciled dates
        </span>
      </div>
    </div>
  );
}
