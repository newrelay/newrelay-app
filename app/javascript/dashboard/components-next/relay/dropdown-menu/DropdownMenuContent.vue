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
  collisionPadding: { type: Number, default: undefined },
  collisionBoundary: { type: [Object, null], default: undefined },
  portalTo: { type: [Object, String], default: undefined },
  disablePortal: { type: Boolean, default: false },
});
</script>

<template>
  <DropdownMenuPortal :to="portalTo" :disabled="disablePortal">
    <DropdownMenuContent
      :align="align"
      :side="side"
      :side-offset="sideOffset"
      :avoid-collisions="avoidCollisions"
      :collision-padding="collisionPadding"
      :collision-boundary="collisionBoundary"
      :class="cn(DROPDOWN_MENU_CONTENT_CLASS, $attrs.class)"
    >
      <slot />
    </DropdownMenuContent>
  </DropdownMenuPortal>
</template>
