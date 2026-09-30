<script setup>
import { computed, inject } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  value: { type: String, required: true },
  disabled: { type: Boolean, default: false },
  variant: {
    type: String,
    default: 'pill',
    validator: value => ['pill', 'underline'].includes(value),
  },
});

const activeValue = inject('relayTabsValue');
const setValue = inject('relayTabsSetValue');

const isActive = computed(() => activeValue?.value === props.value);
</script>

<template>
  <button
    type="button"
    role="tab"
    :aria-selected="isActive"
    :disabled="disabled"
    :class="
      cn(
        props.variant === 'underline'
          ? [
              'relative -mb-px inline-flex shrink-0 items-center rounded-none bg-transparent px-1 pb-3 pt-2 text-left text-sm font-normal text-muted-foreground shadow-none transition-colors hover:text-foreground',
              isActive ? 'font-medium text-foreground' : '',
            ]
          : [
              'inline-flex items-center justify-center gap-1.5 whitespace-nowrap rounded-md px-3 py-1 text-sm font-medium transition-all',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring ring-offset-background',
              'disabled:pointer-events-none disabled:opacity-50',
              isActive
                ? 'bg-background text-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground',
            ]
      )
    "
    @click="setValue?.(value)"
  >
    <slot />
    <span
      v-if="variant === 'underline' && isActive"
      class="absolute inset-x-0 bottom-0 h-px bg-primary"
      aria-hidden="true"
    />
  </button>
</template>
