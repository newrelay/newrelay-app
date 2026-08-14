<script setup>
import { computed, ref } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';
import SidebarTreeChrome from './SidebarTreeChrome.vue';
import { useSidebarContext } from './provider';
import { useEventListener } from '@vueuse/core';
import {
  SIDEBAR_TREE_INDENT,
  SIDEBAR_TREE_LIST_DOTS,
  treeBranchItemClass,
  treeButtonLevel,
  treeRowClass,
  shouldConnectBranchDown,
} from './sidebarTree';

const props = defineProps({
  isExpanded: { type: Boolean, default: false },
  label: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
  depth: { type: Number, default: 1 },
  isLast: { type: Boolean, default: false },
});

const { isAllowed } = useSidebarContext();
const scrollableContainer = ref(null);

const accessibleItems = computed(() =>
  props.children.filter(child => child.to && isAllowed(child.to))
);

const hasAccessibleItems = computed(() => accessibleItems.value.length > 0);

const isScrollable = computed(() => accessibleItems.value.length > 7);

const scrollEnd = ref(false);

useEventListener(scrollableContainer, 'scroll', () => {
  const { scrollHeight, scrollTop, clientHeight } = scrollableContainer.value;
  scrollEnd.value = scrollHeight - scrollTop === clientHeight;
});

const buttonLevel = computed(() =>
  treeButtonLevel({ depth: props.depth, isLeaf: false, collapsible: false })
);

const rowClass = computed(() => treeRowClass(buttonLevel.value));

const connectRowDown = computed(() =>
  shouldConnectBranchDown({
    isLast: props.isLast,
    isOpen: props.isExpanded,
    depth: props.depth,
  })
);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    v-if="hasAccessibleItems"
    :class="[
      'group/menu-sub-item relative min-w-0',
      treeBranchItemClass({ isOpen: isExpanded, depth }),
    ]"
  >
    <div :class="rowClass">
      <SidebarTreeChrome mode="branch" :connect-down="connectRowDown" />
      <div :class="SIDEBAR_TREE_INDENT">
        <SidebarGroupSeparator
          v-show="isExpanded"
          :label="label"
          :icon="icon"
        />
      </div>
    </div>
    <ul
      v-show="isExpanded"
      ref="scrollableContainer"
      :class="[
        SIDEBAR_TREE_LIST_DOTS,
        'relative min-w-0',
        isScrollable &&
          'max-h-[calc(14rem+16px)] overflow-y-scroll no-scrollbar',
      ]"
    >
      <SidebarGroupLeaf
        v-for="(child, index) in accessibleItems"
        v-bind="child"
        :key="child.name"
        :active="activeChild?.name === child.name"
        :depth="depth + 1"
        :is-last="index === accessibleItems.length - 1"
      />
    </ul>
  </li>
</template>
