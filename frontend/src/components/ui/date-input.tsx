import * as React from "react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";

/**
 * Date input that behaves readonly while keeping the native picker.
 *
 * A plain <input type="date"> only opens the picker from its small calendar
 * icon, and lets users type free-form dates. On the floor, dates are picked
 * from the calendar, so this component:
 *   - opens the native picker when ANY part of the field is tapped/clicked
 *     (via HTMLInputElement.showPicker(), falling back to focus on
 *     browsers without it — iOS Safari opens the picker natively anyway)
 *   - blocks keyboard editing, so the value only ever comes from the picker
 */
export const DateInput = React.forwardRef<
  HTMLInputElement,
  React.ComponentProps<"input">
>(({ className, onKeyDown, onClick, ...props }, ref) => {
  const innerRef = React.useRef<HTMLInputElement>(null);

  const setRefs = (el: HTMLInputElement | null) => {
    innerRef.current = el;
    if (typeof ref === "function") ref(el);
    else if (ref) ref.current = el;
  };

  return (
    <Input
      ref={setRefs}
      type="date"
      className={cn("cursor-pointer", className)}
      onKeyDown={(e) => {
        // Let focus navigation through; swallow anything that edits the value.
        if (e.key !== "Tab" && e.key !== "Escape") e.preventDefault();
        onKeyDown?.(e);
      }}
      onClick={(e) => {
        const el = innerRef.current;
        if (el) {
          if (typeof el.showPicker === "function") {
            try {
              el.showPicker();
            } catch {
              el.focus();
            }
          } else {
            el.focus();
          }
        }
        onClick?.(e);
      }}
      {...props}
    />
  );
});
DateInput.displayName = "DateInput";
