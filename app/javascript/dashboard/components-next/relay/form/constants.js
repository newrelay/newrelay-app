/** Shared form field styling — see relay/DESIGN.md “Modals / forms”. */
export const RELAY_FORM_FIELD_CLASS = 'flex flex-col gap-1.5';

export const RELAY_FORM_LABEL_CLASS =
  'text-[13.5px] font-medium leading-normal text-foreground';

export const RELAY_FORM_CHECKBOX_ROW_CLASS = 'flex items-center gap-3';

/** Native radio — NewRelay `h-4 w-4 text-primary focus:ring-primary`. */
export const RELAY_RADIO_INPUT_CLASS =
  'size-4 shrink-0 cursor-pointer accent-primary text-primary focus:ring-1 focus:ring-primary';

export const RELAY_FORM_INPUT_CLASS =
  'text-[14px] shadow-sm rounded-md border-border/80 bg-background hover:bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';

/** Select/combobox trigger — same chrome as RelayInput, no gray hover fill. */
export const RELAY_FORM_SELECT_TRIGGER_CLASS = [
  'reset-base inline-flex h-9 w-full items-center justify-between gap-2 rounded-md border border-border/80 bg-background px-3 text-left text-[14px] font-normal text-foreground shadow-sm',
  'hover:bg-background hover:text-foreground hover:border-border/80',
  'focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30',
  'disabled:cursor-not-allowed disabled:opacity-50',
].join(' ');

export const RELAY_FORM_INPUT_FULL_CLASS = [
  'flex h-9 w-full border px-3 py-1 text-foreground transition-colors',
  'placeholder:text-muted-foreground',
  'disabled:cursor-not-allowed disabled:opacity-50',
  RELAY_FORM_INPUT_CLASS,
].join(' ');

export const RELAY_FORM_TEXTAREA_CLASS = [
  'flex min-h-[80px] w-full resize-y border px-3 py-2 text-foreground transition-colors',
  'placeholder:text-muted-foreground',
  'disabled:cursor-not-allowed disabled:opacity-50',
  RELAY_FORM_INPUT_CLASS,
].join(' ');

/** Borderless inline fields (e.g. compose modal “To:” row) — keep primary focus halo. */
export const RELAY_FORM_INLINE_INPUT_CLASS =
  'border-none bg-transparent shadow-none focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';

/** Apply {@link RELAY_FORM_INLINE_INPUT_CLASS} to nested `input` (TagInput). */
export const RELAY_FORM_INLINE_INPUT_WRAPPER_CLASS =
  '[&_input]:border-none [&_input]:bg-transparent [&_input]:text-[14px] [&_input]:shadow-none [&_input]:outline-none [&_input]:focus-visible:ring-1 [&_input]:focus-visible:ring-primary/30';
