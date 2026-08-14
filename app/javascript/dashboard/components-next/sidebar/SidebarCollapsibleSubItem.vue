<script setup>
import { computed, ref, watch } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarSubGroup from './SidebarSubGroup.vue';
import SidebarTreeChrome from './SidebarTreeChrome.vue';
import SidebarCollapsibleSubItem from './SidebarCollapsibleSubItem.vue';
import {
  SIDEBAR_TREE_INDENT,
  SIDEBAR_TREE_LIST_DOTS,
  SIDEBAR_TREE_LIST_NESTED,
  treeBranchItemClass,
  treeButtonClasses,
  treeButtonLevel,
  treeItemWrapperClass,
  treeRowClass,
  shouldConnectBranchDown,
  isCompactChildBranch,
} from './sidebarTree';
import { useSidebarContext } from './provider';

const props = defineProps({
  label: { type: String, required: true },
  children: { type: Array, default: () => [] },
  activeChild: { type: Object, default: undefined },
  isParentExpanded: { type: Boolean, default: false },
  defaultOpen: { type: Boolean, default: false },
  depth: { type: Number, default: 1 },
  isLast: { type: Boolean, default: false },
});

const { isAllowed } = useSidebarContext();
const isOpen = ref(props.defaultOpen);

const buttonLevel = computed(() =>
  treeButtonLevel({ depth: props.depth, isLeaf: false, collapsible: true })
);

const rowClass = computed(() =>
  treeRowClass(buttonLevel.value, {
    compact: isCompactChildBranch({
      depth: props.depth,
      collapsible: true,
    }),
  })
);

const buttonClasses = computed(() =>
  treeButtonClasses(buttonLevel.value, isHighlighted.value, {
    compact: isCompactChildBranch({
      depth: props.depth,
      collapsible: true,
    }),
  })
);

const connectRowDown = computed(() =>
  shouldConnectBranchDown({
    isLast: props.isLast,
    isOpen: isOpen.value,
    depth: props.depth,
  })
);

const itemClass = computed(() =>
  [
    treeItemWrapperClass(buttonLevel.value),
    treeBranchItemClass({ isOpen: isOpen.value, depth: props.depth }),
  ].join(' ')
);

const nestedListClass = computed(() =>
  props.depth >= 2 ? SIDEBAR_TREE_LIST_DOTS : SIDEBAR_TREE_LIST_NESTED
);

const accessibleChildren = computed(() =>
  props.children.filter(child => {
    if (child.children?.length) {
      return child.children.some(sub => sub.to && isAllowed(sub.to));
    }
    return child.to && isAllowed(child.to);
  })
);

const hasAccessibleChildren = computed(
  () => accessibleChildren.value.length > 0
);

const containsActiveChild = computed(() => {
  if (!props.activeChild) return false;
  const walk = items =>
    items.some(child => {
      if (child.name === props.activeChild.name) return true;
      if (child.children?.length) return walk(child.children);
      return false;
    });
  return walk(props.children);
});

watch(
  containsActiveChild,
  active => {
    if (active) isOpen.value = true;
  },
  { immediate: true }
);

const toggle = () => {
  isOpen.value = !isOpen.value;
};

const isHighlighted = computed(() => isOpen.value || containsActiveChild.value);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li v-if="hasAccessibleChildren" :class="itemClass">
    <div :class="rowClass">
      <SidebarTreeChrome mode="branch" :connect-down="connectRowDown" />
      <div :class="SIDEBAR_TREE_INDENT">
        <button
          type="button"
          :class="buttonClasses"
          :aria-expanded="isOpen"
          @click="toggle"
        >
          <span class="min-w-0 flex-1 truncate text-left">{{ label }}</span>
          <span
            class="i-lucide-chevron-right ml-auto size-3.5 shrink-0 text-muted-foreground transition-transform duration-200"
            :class="{ 'rotate-90': isOpen }"
          />
        </button>
      </div>
    </div>

    <ul v-if="isOpen" :class="nestedListClass">
      <template
        v-for="(child, index) in accessibleChildren"
        :key="child.name"
      >
        <SidebarCollapsibleSubItem
          v-if="child.collapsible && child.children && depth < 2"
          :label="child.label"
          :children="child.children"
          :active-child="activeChild"
          :is-parent-expanded="isParentExpanded && isOpen"
          :default-open="child.defaultOpen === true"
          :depth="depth + 1"
          :is-last="index === accessibleChildren.length - 1"
        />
        <SidebarSubGroup
          v-else-if="child.children && depth < 2"
          :label="child.label"
          :icon="child.icon"
          :children="child.children"
          :is-expanded="isParentExpanded && isOpen"
          :active-child="activeChild"
          :depth="depth + 1"
          :is-last="index === accessibleChildren.length - 1"
        />
        <SidebarGroupLeaf
          v-else-if="isAllowed(child.to)"
          v-bind="child"
          :active="activeChild?.name === child.name"
          :depth="depth + 1"
          :is-last="index === accessibleChildren.length - 1"
        />
      </template>
    </ul>
  </li>
</template>
