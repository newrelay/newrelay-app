<script setup>
import { TooltipProvider } from 'reka-ui';

defineProps({
  delayDuration: {
    type: Number,
    default: 200,
  },
});
</script>

<template>
  <TooltipProvider :delay-duration="delayDuration">
    <slot />
  </TooltipProvider>
</template>
