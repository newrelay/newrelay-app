<script setup>
import { cn } from '../utils/cn';

defineProps({
  htmlFor: { type: String, default: undefined },
});
</script>

<template>
  <label
    :for="htmlFor"
    :class="
      cn(
        'text-sm font-medium leading-none text-foreground',
        'peer-disabled:cursor-not-allowed peer-disabled:opacity-70'
      )
    "
  >
    <slot />
  </label>
</template>
