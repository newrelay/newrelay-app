<script setup>
import { cn } from '../utils/cn';
</script>

<template>
  <div
    role="tablist"
    :class="
      cn(
        'inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground'
      )
    "
  >
    <slot />
  </div>
</template>
