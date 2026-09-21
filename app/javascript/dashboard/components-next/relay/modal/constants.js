/** Modal/dialog backdrop — NewRelay `backdrop-blur-sm` (4px) + `bg-background/80`. */
export const RELAY_MODAL_OVERLAY_BLUR_CLASS = 'backdrop-blur-sm';

export const RELAY_DIALOG_OVERLAY_CLASS = [
  'fixed inset-0 z-[200] bg-background/80',
  RELAY_MODAL_OVERLAY_BLUR_CLASS,
  'data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
].join(' ');

/** Native `<dialog>` `::backdrop` — same fill/blur as `RELAY_DIALOG_OVERLAY_CLASS`. */
export const RELAY_NATIVE_DIALOG_BACKDROP_CLASS = 'backdrop:bg-transparent';

/** Modal header — title + description with a light bottom rule. */
export const RELAY_MODAL_HEADER_CLASS =
  'flex shrink-0 items-start justify-between border-b border-border/40 px-6 pt-6 pb-4';

/** Wide / undivided header (Add Bot): extra padding + light divider. */
export const RELAY_MODAL_HEADER_PLAIN_CLASS =
  'flex shrink-0 items-start justify-between border-b border-border/40 px-8 py-6';

export const RELAY_MODAL_TITLE_CLASS =
  'block text-lg font-semibold tracking-tight text-foreground';

export const RELAY_MODAL_DESCRIPTION_CLASS =
  'mb-0 mt-0.5 block pr-6 text-[14px] font-normal leading-normal text-muted-foreground';

export const RELAY_MODAL_BODY_CLASS = 'flex-1 overflow-y-auto px-6 pb-6 pt-4';

/** Flush form body — header already padded; fields start below the divider. */
export const RELAY_MODAL_FORM_BODY_CLASS = 'space-y-5 px-6 pb-2';

export const RELAY_MODAL_FORM_FOOTER_CLASS =
  'relative z-0 flex shrink-0 justify-end gap-3 border-t border-border/40 bg-background px-6 py-5';

/** Overrides RelayInput's default `h-9` (cn does not tailwind-merge). */
export const RELAY_MODAL_INPUT_CLASS = '!h-10 px-4';

/** Icon close — shadcn ghost size-8, no resting fill (hover:bg-accent only). */
export const RELAY_MODAL_CLOSE_BUTTON_CLASS =
  'reset-base inline-flex size-8 shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-md p-0 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0';
