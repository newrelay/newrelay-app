<script setup>
import { DropdownMenuPortal, DropdownMenuContent } from 'reka-ui';
import { cn } from '../utils/cn';
import { DROPDOWN_MENU_CONTENT_CLASS } from './constants';

defineProps({
  align: {
    type: String,
    default: 'end',
    validator: value => ['start', 'center', 'end'].includes(value),
  },
  side: {
    type: String,
    default: 'bottom',
    validator: value => ['top', 'right', 'bottom', 'left'].includes(value),
  },
  sideOffset: { type: Number, default: 4 },
  avoidCollisions: { type: Boolean, default: true },
});
</script>

<template>
  <DropdownMenuPortal>
    <DropdownMenuContent
      :align="align"
      :side="side"
      :side-offset="sideOffset"
      :avoid-collisions="avoidCollisions"
      :class="cn(DROPDOWN_MENU_CONTENT_CLASS, $attrs.class)"
    >
      <slot />
    </DropdownMenuContent>
  </DropdownMenuPortal>
</template>
