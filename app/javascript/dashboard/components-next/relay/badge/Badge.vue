<script setup>
import { computed } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: value =>
      ['default', 'secondary', 'destructive', 'outline'].includes(value),
  },
});

const base =
  'inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium transition-colors focus:outline-none focus:ring-1 focus:ring-ring';

const variants = {
  default: 'border-transparent bg-primary text-primary-foreground',
  secondary: 'border-transparent bg-secondary text-secondary-foreground',
  destructive: 'border-transparent bg-destructive text-destructive-foreground',
  outline: 'text-foreground',
};

const classes = computed(() => cn(base, variants[props.variant]));
</script>

<template>
  <span :class="classes">
    <slot />
  </span>
</template>
