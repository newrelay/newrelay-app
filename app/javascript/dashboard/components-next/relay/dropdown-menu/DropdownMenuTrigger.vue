<script setup>
import { DropdownMenuTrigger } from 'reka-ui';
import { cn } from '../utils/cn';

defineProps({
  asChild: { type: Boolean, default: false },
});
</script>

<template>
  <DropdownMenuTrigger :as-child="asChild" :class="cn($attrs.class)">
    <slot />
  </DropdownMenuTrigger>
</template>
