export const DROPDOWN_MENU_CONTENT_CLASS =
  'anim-pop bg-popover text-popover-foreground z-50 min-w-[8rem] overflow-hidden rounded-md border border-border p-1 shadow-md';

export const DROPDOWN_MENU_ITEM_BASE_CLASS =
  'relative flex w-full cursor-default items-center gap-2 rounded-sm border-0 px-2 py-1.5 text-sm outline-none select-none data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:size-4 [&_svg]:shrink-0';

export const DROPDOWN_MENU_ITEM_CLASS =
  'text-foreground focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground';

export const DROPDOWN_MENU_ITEM_DESTRUCTIVE_CLASS =
  'text-destructive focus:text-destructive hover:text-destructive focus:bg-destructive/10 hover:bg-destructive/10 data-[highlighted]:bg-destructive/10 data-[highlighted]:text-destructive';

export const DROPDOWN_MENU_LABEL_CLASS = 'px-2 py-1.5 text-sm font-semibold';

export const DROPDOWN_MENU_SEPARATOR_CLASS = 'bg-border -mx-1 my-1 h-px';

/** Searchable dropdown header — matches ChatList conversation search (h-8). */
export const DROPDOWN_MENU_SEARCH_HEADER_CLASS = 'border-b border-border p-2';

export const DROPDOWN_MENU_SEARCH_WRAPPER_CLASS =
  'relative flex w-full items-center';

export const DROPDOWN_MENU_SEARCH_ICON_CLASS =
  'i-lucide-search pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground';

export const DROPDOWN_MENU_SEARCH_INPUT_CLASS =
  'reset-base no-margin box-border h-8 w-full rounded-md border border-border/80 bg-muted/30 pl-8 pr-3 text-[13px] text-foreground placeholder:text-muted-foreground/70 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';

/** Searchable dropdown inside modals — clamp to trigger width and available panel height. */
export const DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS =
  'z-[250] flex max-h-[var(--reka-dropdown-menu-content-available-height)] w-[var(--reka-dropdown-menu-trigger-width)] max-w-[var(--reka-dropdown-menu-trigger-width)] flex-col overflow-hidden p-0';

export const DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS =
  'min-h-0 flex-1 overflow-y-auto p-1';

export const DROPDOWN_MENU_MODAL_CONTENT_CLASS =
  'z-[250] max-h-[var(--reka-dropdown-menu-content-available-height)] w-[var(--reka-dropdown-menu-trigger-width)] max-w-[var(--reka-dropdown-menu-trigger-width)] overflow-y-auto p-1';

export const isDestructiveDropdownAction = action =>
  ['delete', 'block'].includes(action);

export const isDestructiveDropdownItem = item =>
  Boolean(item?.destructive) || isDestructiveDropdownAction(item?.action);

export const getDropdownItemInteractionClass = item =>
  isDestructiveDropdownItem(item)
    ? DROPDOWN_MENU_ITEM_DESTRUCTIVE_CLASS
    : DROPDOWN_MENU_ITEM_CLASS;
