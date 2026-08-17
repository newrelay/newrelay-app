<script setup>
import { computed } from 'vue';
import { DropdownMenuItem } from 'reka-ui';
import { cn } from '../utils/cn';
import {
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  getDropdownItemInteractionClass,
} from './constants';
const props = defineProps({
  destructive: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
});

const interactionClass = computed(() =>
  getDropdownItemInteractionClass(
    props.destructive ? { destructive: true } : {}
  )
);
</script>

<template>
  <DropdownMenuItem
    :disabled="disabled"
    :class="cn(DROPDOWN_MENU_ITEM_BASE_CLASS, interactionClass, $attrs.class)"
  >
    <slot />
  </DropdownMenuItem>
</template>
