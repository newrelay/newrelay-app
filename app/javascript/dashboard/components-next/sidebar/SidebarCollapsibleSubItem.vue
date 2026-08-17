<script setup>
import { computed, ref, watch } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarSubGroup from './SidebarSubGroup.vue';
import SidebarTreeChrome from './SidebarTreeChrome.vue';
import SidebarCollapsibleSubItem from './SidebarCollapsibleSubItem.vue';
import {
  SIDEBAR_TREE_COLLAPSE_GRID,
  SIDEBAR_TREE_INDENT,
  SIDEBAR_TREE_LIST_DOTS,
  SIDEBAR_TREE_LIST_NESTED,
  treeButtonClasses,
  treeButtonLevel,
  treeItemWrapperClass,
  treeRowClass,
  getTreeElbowSize,
  getTreeSpineVariant,
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

const hasDotChildren = computed(() => props.depth >= 2);

const rowClass = computed(() =>
  treeRowClass(buttonLevel.value, {
    compact: isCompactChildBranch({
      depth: props.depth,
      collapsible: true,
    }),
  })
);

const spineVariant = computed(() =>
  getTreeSpineVariant({
    isLast: props.isLast,
    isOpen: isOpen.value,
    depth: props.depth,
    collapsible: true,
    hasDotChildren: hasDotChildren.value,
  })
);

const elbowSize = computed(() => getTreeElbowSize(props.depth));

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

const isHighlighted = computed(() => isOpen.value || containsActiveChild.value);

const buttonClasses = computed(() =>
  treeButtonClasses(buttonLevel.value, isHighlighted.value, {
    compact: isCompactChildBranch({
      depth: props.depth,
      collapsible: true,
    }),
  })
);

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
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li v-if="hasAccessibleChildren" :class="treeItemWrapperClass(buttonLevel)">
    <SidebarTreeChrome mode="branch" :spine="spineVariant" :elbow="elbowSize" />
    <div :class="rowClass">
      <div :class="SIDEBAR_TREE_INDENT">
        <button
          type="button"
          :class="buttonClasses"
          :aria-expanded="isOpen"
          @click="toggle"
        >
          <span class="min-w-0 flex-1 truncate text-left">{{ label }}</span>
          <span
            class="i-lucide-chevron-right ml-auto size-3.5 shrink-0 transition-transform duration-200"
            :class="[
              isHighlighted ? 'text-sidebar-primary' : 'text-muted-foreground',
              { 'rotate-90': isOpen },
            ]"
          />
        </button>
      </div>
    </div>

    <div
      :class="[
        SIDEBAR_TREE_COLLAPSE_GRID,
        isOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]',
      ]"
    >
      <div :class="isOpen ? 'overflow-visible' : 'overflow-hidden'">
        <ul :class="nestedListClass">
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
      </div>
    </div>
  </li>
</template>
