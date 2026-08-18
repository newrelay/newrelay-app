<script setup>
import { cn } from 'dashboard/components-next/relay/utils/cn';
import { DROPDOWN_MENU_CONTENT_CLASS } from 'dashboard/components-next/relay/dropdown-menu/constants';

defineProps({
  strong: {
    type: Boolean,
    default: false,
  },
  contentClass: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="absolute">
    <ul
      :class="
        cn(
          DROPDOWN_MENU_CONTENT_CLASS,
          'list-none reset-base m-0 flex flex-col gap-0.5 p-1',
          strong && 'border-border',
          contentClass
        )
      "
    >
      <slot />
    </ul>
  </div>
</template>
