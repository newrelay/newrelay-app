<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import { RELAY_FILTER_CLASS } from 'dashboard/components-next/relay/chrome/constants';

defineProps({
  buttonText: {
    type: String,
    default: '',
  },
  trailingIcon: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: '',
  },
  textClass: {
    type: String,
    default: RELAY_FILTER_CLASS,
  },
});
</script>

<template>
  <Button
    ghost
    slate
    sm
    class="relative"
    :class="textClass"
    no-animation
    :icon="icon"
    :trailing-icon="trailingIcon"
  >
    <span class="min-w-0 truncate">{{ buttonText }}</span>
    <slot name="dropdown" />
  </Button>
</template>
