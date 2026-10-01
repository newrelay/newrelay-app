<script setup>
import { cn } from '../utils/cn';

defineProps({
  variant: {
    type: String,
    default: 'pill',
    validator: value => ['pill', 'underline'].includes(value),
  },
});
</script>

<template>
  <div
    role="tablist"
    :class="
      cn(
        variant === 'underline'
          ? 'flex h-auto items-center gap-6 border-b border-border/40 bg-transparent p-0'
          : 'inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground'
      )
    "
  >
    <slot />
  </div>
</template>
