/** Sidebar directory-tree — single vertical spine, flat column alignment. */

export const TREE_LEVEL = {
  SECTION: 1,
  /** Conversations — 14px / 500 */
  MAIN_BRANCH: 2,
  /** Items under Conversations (incl. Teams row) — 14px / 400 */
  CHILD_BRANCH: 3,
  /** Items under Teams / Channels / Labels — 13px / 400 */
  SUB_LEAF: 4,
};

/** Section tree — spine is drawn per-row (not border-l) so the last item can terminate cleanly. */
export const SIDEBAR_TREE_LIST =
  'relative m-0 flex min-w-0 list-none flex-col ltr:ml-5 rtl:mr-5';

/** Nested branch rows share the parent spine column. */
export const SIDEBAR_TREE_LIST_NESTED =
  'relative m-0 flex min-w-0 list-none flex-col';

/** Dot-only sub-lists (Teams / Channels / Labels children). */
export const SIDEBAR_TREE_LIST_DOTS =
  'relative m-0 flex min-w-0 list-none flex-col before:pointer-events-none before:absolute before:inset-y-0 before:z-[1] before:bg-sidebar ltr:before:-left-1 ltr:before:w-2 rtl:before:-right-1 rtl:before:w-2';

export const SIDEBAR_TREE_DOT_ROW = 'relative z-[2] min-w-0';

export const SIDEBAR_TREE_INDENT = 'pl-3';

export const SIDEBAR_TREE_ROW = 'relative min-w-0 min-h-8';
export const SIDEBAR_TREE_ROW_COMPACT = 'relative min-w-0 min-h-7';

/** Hide the shared spine beside open dot sub-menus (Teams / Channels / Labels). */
export const SIDEBAR_TREE_OPEN_BRANCH_MASK =
  'before:pointer-events-none before:absolute before:top-7 before:bottom-0 before:z-[1] before:bg-sidebar ltr:before:-left-1 ltr:before:w-2 rtl:before:-right-1 rtl:before:w-2';

export const treeRowClass = (
  level,
  { dotOnly = false, compact = false } = {}
) => {
  const useCompact =
    dotOnly || compact || level === TREE_LEVEL.SUB_LEAF;
  const base = useCompact ? SIDEBAR_TREE_ROW_COMPACT : SIDEBAR_TREE_ROW;

  return dotOnly ? `${base} ${SIDEBAR_TREE_DOT_ROW}` : base;
};

export const treeBranchItemClass = ({ isOpen = false, depth = 1 } = {}) => {
  if (isOpen && depth >= 2) return SIDEBAR_TREE_OPEN_BRANCH_MASK;
  return '';
};

export const sectionHeaderClasses = active => [
  'relative flex w-full min-w-0 items-center gap-3 rounded-md p-2 py-2 text-left text-sm capitalize outline-none transition-colors',
  active
    ? 'font-medium text-sidebar-primary before:absolute before:inset-y-1.5 before:w-[3px] before:bg-sidebar-primary ltr:before:-left-2 ltr:before:rounded-r-md rtl:before:-right-2 rtl:before:rounded-l-md'
    : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground',
];

/** Depth 1 collapsible — Conversations: 14px, weight 500 */
export const mainBranchClasses = active => [
  'flex w-full min-w-0 items-center gap-2 h-8 rounded-md px-2 text-[14px] font-medium capitalize outline-none transition-colors',
  active
    ? 'text-sidebar-primary'
    : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground',
];

/** Depth 2 under Conversations — 14px, weight 400 */
export const childBranchClasses = (active, { compact = false } = {}) => [
  `flex w-full min-w-0 items-center gap-2 ${compact ? 'h-7' : 'h-8'} rounded-md px-2 text-[14px] font-normal capitalize outline-none transition-colors`,
  active
    ? 'text-sidebar-primary'
    : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground',
];

/** Depth 3 under Teams / Channels / Labels — 13px, weight 400 */
export const subLeafClasses = active => [
  'flex h-7 min-w-0 w-full items-center gap-2 rounded-md px-2 text-[13px] font-normal capitalize outline-none transition-colors',
  active
    ? 'text-sidebar-primary'
    : 'text-sidebar-foreground/75 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground',
];

export const treeItemWrapperClass = level => {
  if (level === TREE_LEVEL.SUB_LEAF) return 'group/leaf relative min-w-0';
  return 'group/menu-sub-item relative min-w-0';
};

export const treeButtonClasses = (level, active, { compact = false } = {}) => {
  switch (level) {
    case TREE_LEVEL.MAIN_BRANCH:
      return mainBranchClasses(active);
    case TREE_LEVEL.SUB_LEAF:
      return subLeafClasses(active);
    default:
      return childBranchClasses(active, { compact });
  }
};

/** Deepest rows under Teams / Channels / Labels — dot only, no tree lines. */
export const isDotOnlyDepth = depth => depth >= 3;

export const treeButtonLevel = ({ depth, isLeaf, collapsible }) => {
  if (depth >= 3 || isLeaf) return TREE_LEVEL.SUB_LEAF;
  if (depth === 1 && collapsible) return TREE_LEVEL.MAIN_BRANCH;
  return TREE_LEVEL.CHILD_BRANCH;
};

/** Whether this branch row should continue the spine to the next sibling. */
export const shouldConnectBranchDown = ({
  isLast,
  isOpen = false,
  depth = 1,
}) => {
  if (isLast) return false;
  if (depth >= 2 && isOpen) return false;
  return true;
};

/** Collapsible rows under Conversations (Teams / Channels / Labels) use compact height. */
export const isCompactChildBranch = ({ depth, collapsible }) =>
  depth >= 2 && collapsible;
