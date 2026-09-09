<script setup>
import { computed } from 'vue';
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';

const props = defineProps({
  modelValue: { type: String, default: '' },
  options: { type: Array, default: () => [] },
  placeholder: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);

const selectedLabel = computed(() => {
  const match = props.options.find(option => option.value === props.modelValue);
  return match?.label || props.placeholder;
});
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <button
        type="button"
        class="inline-flex items-center justify-end gap-1 h-9 text-sm text-end border-0 bg-transparent cursor-pointer focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 rounded-md px-1"
        :class="[
          modelValue ? 'text-foreground' : 'text-muted-foreground',
          { 'animate-shake': hasError },
        ]"
      >
        <span class="truncate">{{ selectedLabel }}</span>
        <span
          class="i-lucide-chevron-down size-4 shrink-0 text-muted-foreground"
        />
      </button>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent align="end" class="min-w-[10rem]">
      <RelayDropdownMenuItem
        v-for="opt in options"
        :key="opt.value"
        class="cursor-pointer"
        @click="emit('update:modelValue', opt.value)"
      >
        {{ opt.label }}
      </RelayDropdownMenuItem>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
