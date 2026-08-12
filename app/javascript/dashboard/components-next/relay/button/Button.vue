<script setup>
import { computed, useAttrs } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: value =>
      [
        'default',
        'destructive',
        'outline',
        'secondary',
        'ghost',
        'link',
      ].includes(value),
  },
  size: {
    type: String,
    default: 'default',
    validator: value => ['default', 'sm', 'lg', 'icon'].includes(value),
  },
  as: { type: String, default: 'button' },
  disabled: { type: Boolean, default: false },
  type: { type: String, default: 'button' },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();

// Exact shadcn/ui button classes from new-ui
const base =
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0';

const variants = {
  default: 'bg-primary text-primary-foreground shadow-xs hover:bg-primary/90',
  destructive:
    'bg-destructive text-destructive-foreground shadow-xs hover:bg-destructive/90',
  outline:
    'border border-input bg-background shadow-xs hover:bg-accent hover:text-accent-foreground hover:border-transparent',
  secondary:
    'bg-secondary text-secondary-foreground shadow-xs hover:bg-secondary/80',
  ghost: 'hover:bg-accent hover:text-accent-foreground',
  link: 'text-primary underline-offset-4 hover:underline',
};

const sizes = {
  default: 'h-9 px-4 py-2',
  sm: 'h-8 rounded-md px-3 text-xs',
  lg: 'h-10 rounded-md px-6',
  icon: 'size-9',
};

const classes = computed(() =>
  cn(base, variants[props.variant], sizes[props.size], attrs.class)
);
</script>

<template>
  <component
    :is="as"
    v-bind="{ ...attrs, class: undefined }"
    :type="as === 'button' ? type : undefined"
    :disabled="as === 'button' ? disabled : undefined"
    :class="classes"
  >
    <slot />
  </component>
</template>
