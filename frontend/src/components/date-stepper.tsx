/**
 * Date picker with left/right arrows to step a day at a time.
 *
 * Used in the Daily Operations KPI strips (Daily Production, Yarn Receipt,
 * Daily Delivery) so the user can page back and forth between dates instead of
 * opening the calendar every time. Wraps the shared DateInput.
 */
import { ChevronLeft, ChevronRight } from "lucide-react";
import { addDays, subDays, format } from "date-fns";
import { DateInput } from "@/components/ui/date-input";
import { Button } from "@/components/ui/button";

function toIso(d: Date) {
  return format(d, "yyyy-MM-dd");
}

export function DateStepper({
  value,
  onChange,
  max,
}: {
  /** Selected date as YYYY-MM-DD. */
  value: string;
  onChange: (date: string) => void;
  /** Maximum selectable date (YYYY-MM-DD); the next arrow is disabled at it. */
  max?: string;
}) {
  const canGoNext = !max || value < max;
  const go = (dir: -1 | 1) => {
    const base = value ? new Date(value + "T00:00:00") : new Date();
    const next = dir === -1 ? subDays(base, 1) : addDays(base, 1);
    onChange(toIso(next));
  };

  return (
    <div className="flex w-full items-center gap-1.5">
      <Button
        type="button"
        variant="outline"
        size="icon"
        className="h-9 w-9 shrink-0"
        aria-label="Previous day"
        title="Previous day"
        onClick={() => go(-1)}
      >
        <ChevronLeft className="h-4 w-4" />
      </Button>
      <DateInput
        className="h-9 min-w-0 flex-1"
        value={value}
        max={max}
        onChange={(e) => onChange(e.target.value || value)}
      />
      <Button
        type="button"
        variant="outline"
        size="icon"
        className="h-9 w-9 shrink-0"
        aria-label="Next day"
        title="Next day"
        onClick={() => go(1)}
        disabled={!canGoNext}
      >
        <ChevronRight className="h-4 w-4" />
      </Button>
    </div>
  );
}
