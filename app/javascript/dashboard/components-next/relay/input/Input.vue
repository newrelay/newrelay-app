<script setup>
import { cn } from '../utils/cn';

const props = defineProps({
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  id: { type: String, default: undefined },
  className: { type: String, default: '' },
});

const model = defineModel({ type: [String, Number], default: '' });
</script>

<template>
  <input
    :id="id"
    v-model="model"
    data-slot="input"
    :type="type"
    :placeholder="placeholder"
    :disabled="disabled"
    :class="
      cn(
        'flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm text-foreground shadow-xs transition-colors',
        'placeholder:text-muted-foreground',
        'focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring',
        'disabled:cursor-not-allowed disabled:opacity-50',
        props.className
      )
    "
  />
</template>
