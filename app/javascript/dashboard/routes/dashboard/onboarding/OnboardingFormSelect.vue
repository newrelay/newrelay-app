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
        class="w-full h-11 px-3.5 rounded-xl border border-border/90 bg-card text-[14px] shadow-2xs outline-none flex items-center justify-between transition-all hover:bg-muted/30 focus-visible:border-primary/70 focus-visible:ring-2 focus-visible:ring-primary/20"
        :class="[
          modelValue ? 'text-foreground font-normal' : 'text-muted-foreground',
          { 'animate-shake': hasError },
        ]"
      >
        <span class="truncate">{{ selectedLabel }}</span>
        <span
          class="i-lucide-chevron-down size-4 shrink-0 text-muted-foreground ml-2"
        />
      </button>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent align="end" class="w-72 max-h-60 overflow-y-auto">
      <RelayDropdownMenuItem
        v-for="opt in options"
        :key="opt.value"
        class="cursor-pointer justify-between"
        @click="emit('update:modelValue', opt.value)"
      >
        <span class="truncate">{{ opt.label }}</span>
        <span
          v-if="opt.value === modelValue"
          class="i-lucide-check size-3.5 text-primary shrink-0"
        />
      </RelayDropdownMenuItem>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
