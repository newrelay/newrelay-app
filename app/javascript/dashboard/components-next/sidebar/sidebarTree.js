/** Sidebar directory-tree — aligned with Design-System-NR AppSidebar.vue */

export const TREE_LEVEL = {
  SECTION: 1,
  /** Conversations — 14px / 500 */
  MAIN_BRANCH: 2,
  /** Items under Conversations (incl. Teams row) — 14px / 400 */
  CHILD_BRANCH: 3,
  /** Items under Teams / Channels / Labels — 13px / 400 */
  SUB_LEAF: 4,
};

/** Level-1 sub-menu under a section group (Inbox, Conversations). */
export const SIDEBAR_TREE_LIST =
  'relative m-0 flex min-w-0 list-none flex-col gap-0.5 py-0.5 ltr:ml-4 rtl:mr-4';

/** Nested list under Conversations. */
export const SIDEBAR_TREE_LIST_NESTED =
  'relative m-0 flex min-w-0 list-none flex-col gap-0.5 py-1';

/** Dot-only list under Teams / Channels / Labels. */
export const SIDEBAR_TREE_LIST_DOTS =
  'relative m-0 flex min-w-0 list-none flex-col gap-0.5 py-1';

export const SIDEBAR_TREE_INDENT = 'pl-3';

export const SIDEBAR_TREE_ROW = 'relative min-w-0 min-h-8';
export const SIDEBAR_TREE_ROW_COMPACT = 'relative min-w-0 min-h-7';

export const SIDEBAR_TREE_COLLAPSE_GRID =
  'grid transition-[grid-template-rows] duration-200 ease-out';

export const treeRowClass = (
  level,
  { dotOnly = false, compact = false } = {}
) => {
  const useCompact = dotOnly || compact || level === TREE_LEVEL.SUB_LEAF;
  const base = useCompact ? SIDEBAR_TREE_ROW_COMPACT : SIDEBAR_TREE_ROW;

  return dotOnly ? `${base} relative z-[2]` : base;
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

export const isDotOnlyDepth = depth => depth >= 3;

export const treeButtonLevel = ({ depth, isLeaf, collapsible }) => {
  if (depth >= 3 || isLeaf) return TREE_LEVEL.SUB_LEAF;
  if (depth === 1 && collapsible) return TREE_LEVEL.MAIN_BRANCH;
  return TREE_LEVEL.CHILD_BRANCH;
};

export const isCompactChildBranch = ({ depth, collapsible }) =>
  depth >= 2 && collapsible;

/** Elbow height: depth 1 → h-4, depth 2+ → h-[14px] */
export const getTreeElbowSize = depth => (depth <= 1 ? 'md' : 'sm');

/**
 * Spine variant matching Design-System-NR:
 * - none: last closed item (no line below elbow)
 * - extend: -bottom-[2px] connector to next sibling
 * - fixed-36: Conversations open (stops before nested children)
 * - fixed-7: Teams/Channels/Labels open (stops before dot children)
 */
export const getTreeSpineVariant = ({
  isLast,
  isOpen = false,
  depth = 1,
  collapsible = false,
  hasDotChildren = false,
}) => {
  if (collapsible) {
    if (isLast && !isOpen) return 'none';
    if (isOpen && depth === 1) return 'fixed-36';
    if (isOpen && depth >= 2 && hasDotChildren) return 'fixed-7';
    if (!isLast) return 'extend';
    return 'none';
  }

  if (isLast) return 'none';
  return 'extend';
};
