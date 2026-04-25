import * as React from "react";
import { Check, ChevronDown, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";

export interface MultiSelectOption {
  value: string;
  label: string;
}

interface MultiSelectProps {
  options: MultiSelectOption[];
  selected: string[];
  onChange: (values: string[]) => void;
  placeholder?: string;
  className?: string;
}

export function MultiSelect({
  options,
  selected,
  onChange,
  placeholder = "All",
  className,
}: MultiSelectProps) {
  const [open, setOpen] = React.useState(false);

  const allSelected = selected.length === 0;

  function toggle(value: string) {
    if (selected.includes(value)) {
      onChange(selected.filter((v) => v !== value));
    } else {
      onChange([...selected, value]);
    }
  }

  function clearAll() {
    onChange([]);
  }

  const label = React.useMemo(() => {
    if (selected.length === 0) return placeholder;
    if (selected.length === 1) {
      return options.find((o) => o.value === selected[0])?.label ?? selected[0];
    }
    return `${selected.length} selected`;
  }, [selected, options, placeholder]);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn(
            "h-8 w-full justify-between text-sm font-normal px-2",
            allSelected ? "text-muted-foreground" : "text-foreground",
            className
          )}
        >
          <span className="truncate">{label}</span>
          <div className="flex items-center shrink-0 ml-1 gap-0.5">
            {selected.length > 0 && (
              <span
                role="button"
                tabIndex={0}
                className="rounded-sm hover:bg-muted p-0.5"
                onClick={(e) => { e.stopPropagation(); clearAll(); }}
                onKeyDown={(e) => { if (e.key === "Enter") { e.stopPropagation(); clearAll(); }}}
              >
                <X className="h-3 w-3 text-muted-foreground" />
              </span>
            )}
            <ChevronDown className="h-3.5 w-3.5 text-muted-foreground" />
          </div>
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[220px] p-0" align="start">
        <div className="max-h-60 overflow-y-auto py-1">
          <div
            className="flex items-center gap-2 px-3 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm mx-1"
            onClick={clearAll}
          >
            <Check className={cn("h-3.5 w-3.5", allSelected ? "opacity-100" : "opacity-0")} />
            <span>All</span>
          </div>
          {options.map((option) => {
            const checked = selected.includes(option.value);
            return (
              <div
                key={option.value}
                className="flex items-center gap-2 px-3 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm mx-1"
                onClick={() => toggle(option.value)}
              >
                <Checkbox
                  checked={checked}
                  onCheckedChange={() => toggle(option.value)}
                  className="pointer-events-none"
                />
                <span className="truncate">{option.label}</span>
              </div>
            );
          })}
        </div>
      </PopoverContent>
    </Popover>
  );
}
