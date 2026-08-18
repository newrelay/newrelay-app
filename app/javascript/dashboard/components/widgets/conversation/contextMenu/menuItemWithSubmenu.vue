<script setup>
import { computed, ref, useTemplateRef } from 'vue';
import { useWindowSize, useElementBounding } from '@vueuse/core';

const props = defineProps({
  option: {
    type: Object,
    default: () => ({}),
  },
  subMenuAvailable: {
    type: Boolean,
    default: true,
  },
});

const ICON_MAP = {
  warning: 'i-lucide-triangle-alert',
  tag: 'i-lucide-tag',
  'person-add': 'i-lucide-user-plus',
  'people-team-add': 'i-lucide-users',
};

const menuRef = useTemplateRef('menuRef');
const isSubmenuOpen = ref(false);
const { width: windowWidth, height: windowHeight } = useWindowSize();
const { bottom, right } = useElementBounding(menuRef);

const iconClass = computed(
  () => ICON_MAP[props.option.icon] || 'i-lucide-circle'
);

const verticalPosition = computed(() => {
  const SUBMENU_HEIGHT = 240;
  const spaceBelow = windowHeight.value - bottom.value;
  return spaceBelow < SUBMENU_HEIGHT ? 'bottom-0' : 'top-0';
});

const horizontalPosition = computed(() => {
  const SUBMENU_WIDTH = 240;
  const spaceRight = windowWidth.value - right.value;
  return spaceRight < SUBMENU_WIDTH ? 'right-full' : 'left-full';
});

const submenuPosition = computed(() => [
  verticalPosition.value,
  horizontalPosition.value,
]);

const openSubmenu = () => {
  if (!props.subMenuAvailable) return;
  isSubmenuOpen.value = true;
};

const closeSubmenu = () => {
  isSubmenuOpen.value = false;
};
</script>

<template>
  <div
    ref="menuRef"
    class="relative w-full"
    :class="!subMenuAvailable ? 'opacity-50' : ''"
    @mouseenter="openSubmenu"
    @mouseleave="closeSubmenu"
  >
    <div
      class="flex w-full cursor-default items-center justify-between gap-2 rounded-sm px-2 py-1.5 text-sm text-foreground outline-none transition-colors"
      :class="
        subMenuAvailable && isSubmenuOpen
          ? 'bg-accent text-accent-foreground'
          : 'hover:bg-accent hover:text-accent-foreground'
      "
    >
      <div class="flex min-w-0 items-center gap-2">
        <span
          :class="iconClass"
          class="size-4 shrink-0 text-muted-foreground"
          aria-hidden="true"
        />
        <span class="truncate">{{ option.label }}</span>
      </div>
      <span
        class="i-lucide-chevron-right size-4 shrink-0 text-muted-foreground"
        aria-hidden="true"
      />
    </div>

    <div
      v-if="subMenuAvailable && isSubmenuOpen"
      class="absolute z-[100] min-w-[12rem] pl-1"
      :class="submenuPosition"
    >
      <div
        class="max-h-[15rem] overflow-y-auto overflow-x-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
      >
        <slot />
      </div>
    </div>
  </div>
</template>
