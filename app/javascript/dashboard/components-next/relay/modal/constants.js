/** Modal/dialog backdrop — 8px blur (not Tailwind `backdrop-blur-sm`, which is 4px). */
export const RELAY_MODAL_OVERLAY_BLUR_CLASS = 'backdrop-blur-[8px]';

export const RELAY_DIALOG_OVERLAY_CLASS = [
  'fixed inset-0 z-[200] bg-background/80',
  RELAY_MODAL_OVERLAY_BLUR_CLASS,
  'data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
  'data-relay-overlay',
].join(' ');

/** Modal header — title, description, bottom divider; form body starts below. */
export const RELAY_MODAL_HEADER_CLASS =
  'flex shrink-0 items-center justify-between border-b border-border/80 p-6';

export const RELAY_MODAL_TITLE_CLASS =
  'text-[18px] font-[600] tracking-tight text-foreground';

export const RELAY_MODAL_DESCRIPTION_CLASS =
  'mb-0 mt-1 text-[14px] font-normal leading-normal text-muted-foreground';

export const RELAY_MODAL_BODY_CLASS = 'flex-1 overflow-y-auto p-6';
