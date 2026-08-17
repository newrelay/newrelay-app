export const DROPDOWN_MENU_CONTENT_CLASS =
  'anim-pop bg-popover text-popover-foreground z-50 min-w-[8rem] overflow-hidden rounded-md border border-border p-1 shadow-md';

export const DROPDOWN_MENU_ITEM_BASE_CLASS =
  'relative flex w-full cursor-pointer items-center gap-2 rounded-sm border-0 px-2 py-1.5 text-sm outline-none select-none data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:size-4 [&_svg]:shrink-0';

export const DROPDOWN_MENU_ITEM_CLASS =
  'text-popover-foreground focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground';

export const DROPDOWN_MENU_ITEM_DESTRUCTIVE_CLASS =
  'text-destructive focus:text-destructive hover:text-destructive focus:bg-destructive/10 hover:bg-destructive/10 data-[highlighted]:bg-destructive/10 data-[highlighted]:text-destructive';

export const DROPDOWN_MENU_LABEL_CLASS = 'px-2 py-1.5 text-sm font-semibold';

export const DROPDOWN_MENU_SEPARATOR_CLASS = 'bg-border -mx-1 my-1 h-px';

export const isDestructiveDropdownAction = action =>
  ['delete', 'block'].includes(action);

export const isDestructiveDropdownItem = item =>
  Boolean(item?.destructive) || isDestructiveDropdownAction(item?.action);

export const getDropdownItemInteractionClass = item =>
  isDestructiveDropdownItem(item)
    ? DROPDOWN_MENU_ITEM_DESTRUCTIVE_CLASS
    : DROPDOWN_MENU_ITEM_CLASS;
