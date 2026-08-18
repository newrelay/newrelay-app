/** Shared form field styling — see relay/DESIGN.md “Modals / forms”. */
export const RELAY_FORM_FIELD_CLASS = 'flex flex-col gap-1.5';

export const RELAY_FORM_LABEL_CLASS =
  'text-[13.5px] font-medium leading-normal text-foreground';

export const RELAY_FORM_CHECKBOX_ROW_CLASS = 'flex items-center gap-3';

export const RELAY_FORM_INPUT_CLASS =
  'text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';

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
