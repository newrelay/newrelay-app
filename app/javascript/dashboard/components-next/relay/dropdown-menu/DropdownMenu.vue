<script setup>
import { DropdownMenuRoot, useForwardPropsEmits } from 'reka-ui';

/* eslint-disable vue/no-unused-properties -- forwarded via useForwardPropsEmits */
const props = defineProps({
  defaultOpen: { type: Boolean, default: false },
  open: { type: Boolean, default: undefined },
  modal: { type: Boolean, default: false },
});
/* eslint-enable vue/no-unused-properties */

const emit = defineEmits(['update:open']);

const forwarded = useForwardPropsEmits(props, emit);
</script>

<template>
  <DropdownMenuRoot v-bind="forwarded" :modal="modal">
    <slot />
  </DropdownMenuRoot>
</template>
