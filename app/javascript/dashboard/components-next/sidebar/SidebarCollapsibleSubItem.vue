<script setup>
import { computed, ref, watch } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarSubGroup from './SidebarSubGroup.vue';
import { useSidebarContext } from './provider';

const props = defineProps({
  label: { type: String, required: true },
  children: { type: Array, default: () => [] },
  activeChild: { type: Object, default: undefined },
  isParentExpanded: { type: Boolean, default: false },
  defaultOpen: { type: Boolean, default: true },
});

const { isAllowed } = useSidebarContext();
const isOpen = ref(props.defaultOpen);

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
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li v-if="hasAccessibleChildren" class="group/menu-sub-item relative min-w-0">
    <button
      type="button"
      class="flex h-8 w-full min-w-0 items-center gap-2 rounded-md px-2 text-sm transition-colors"
      :class="
        isOpen || containsActiveChild
          ? 'font-medium text-sidebar-primary'
          : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground'
      "
      :aria-expanded="isOpen"
      @click="toggle"
    >
      <span class="min-w-0 flex-1 truncate text-left">{{ label }}</span>
      <span
        class="i-lucide-chevron-right size-3.5 shrink-0 text-muted-foreground transition-transform duration-200"
        :class="{ 'rotate-90': isOpen }"
      />
    </button>

    <div
      class="grid transition-[grid-template-rows] duration-200 ease-out"
      :class="isOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'"
    >
      <div class="overflow-hidden">
        <ul
          class="ml-2 flex min-w-0 list-none flex-col gap-0.5 border-l border-sidebar-border py-1 ltr:pl-3 rtl:pr-3"
        >
          <template v-for="child in children" :key="child.name">
            <SidebarCollapsibleSubItem
              v-if="child.collapsible && child.children"
              :label="child.label"
              :children="child.children"
              :active-child="activeChild"
              :is-parent-expanded="isParentExpanded && isOpen"
              :default-open="child.defaultOpen !== false"
            />
            <SidebarSubGroup
              v-else-if="child.children"
              :label="child.label"
              :icon="child.icon"
              :children="child.children"
              :is-expanded="isParentExpanded && isOpen"
              :active-child="activeChild"
            />
            <SidebarGroupLeaf
              v-else-if="isAllowed(child.to)"
              v-bind="child"
              :active="activeChild?.name === child.name"
            />
          </template>
        </ul>
      </div>
    </div>
  </li>
</template>
