export const CALENDAR_CONTENT_CLASS =
  'anim-pop bg-popover text-popover-foreground z-50 w-auto overflow-hidden rounded-md border border-border p-4 shadow-md';

export const CALENDAR_HEADER_CLASS =
  'mb-4 flex items-center justify-between px-2';

export const CALENDAR_MONTH_LABEL_CLASS =
  'text-sm font-semibold text-foreground';

export const CALENDAR_NAV_BUTTON_CLASS =
  'inline-flex size-7 items-center justify-center rounded-md border border-border text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50';

export const CALENDAR_WEEKDAY_GRID_CLASS =
  'mb-2 grid grid-cols-7 text-center text-[10px] font-semibold text-muted-foreground';

export const CALENDAR_DAY_GRID_CLASS = 'grid grid-cols-7 gap-y-2 text-sm';

export const CALENDAR_CELL_CLASS =
  'relative flex h-9 items-center justify-center';

export const CALENDAR_DAY_BUTTON_BASE_CLASS =
  'relative z-10 flex size-8 items-center justify-center rounded-full text-[13px] transition-colors';

export const CALENDAR_DAY_DEFAULT_CLASS = 'text-foreground hover:bg-muted/80';

export const CALENDAR_DAY_OUTSIDE_CLASS =
  'pointer-events-none text-muted-foreground/30';

export const CALENDAR_DAY_SELECTED_CLASS =
  'bg-primary font-semibold text-primary-foreground shadow-sm';

export const CALENDAR_DAY_TODAY_CLASS = 'font-semibold ring-1 ring-primary/40';

export const CALENDAR_RANGE_BG_CLASS =
  'absolute inset-y-0 w-full bg-primary/10';

export const CALENDAR_RANGE_START_BG_CLASS =
  'absolute inset-y-0 right-0 w-[85%] rounded-l-full bg-primary/10';

export const CALENDAR_RANGE_END_BG_CLASS =
  'absolute inset-y-0 left-0 w-[85%] rounded-r-full bg-primary/10';

export const CALENDAR_FOOTER_CLASS =
  'mt-4 flex items-center justify-between border-t border-border pt-3';

export const CALENDAR_FOOTER_ACTION_CLASS =
  'text-xs font-medium text-primary hover:text-primary/80';

export const TIME_PICKER_CONTENT_CLASS =
  'anim-pop bg-popover text-popover-foreground z-50 max-h-[280px] w-48 overflow-y-auto overflow-x-hidden rounded-md border border-border p-1 shadow-md';

export const TIME_PICKER_ITEM_CLASS =
  'relative flex w-full cursor-pointer items-center rounded-sm px-2 py-1.5 text-sm outline-none select-none hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground';

export const TIME_PICKER_ITEM_SELECTED_CLASS =
  'bg-primary/10 font-medium text-primary hover:bg-primary/10 hover:text-primary focus:bg-primary/10 focus:text-primary';

export const DATE_PICKER_TRIGGER_CLASS =
  'flex h-9 w-full items-center justify-between rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm transition-colors hover:bg-muted/50 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';
