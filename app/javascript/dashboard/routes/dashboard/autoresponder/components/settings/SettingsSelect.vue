<script setup>
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';

defineProps({
  modelValue: { type: String, default: '' },
  options: { type: Array, default: () => [] },
});

defineEmits(['update:modelValue']);
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <button
        type="button"
        class="w-full h-9 rounded-md border border-input bg-background px-3 text-[13px] shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 text-left flex items-center justify-between transition-colors hover:bg-muted/50 cursor-pointer text-foreground"
      >
        <span class="truncate">{{ modelValue }}</span>
        <span
          class="i-lucide-chevron-down size-4 text-muted-foreground shrink-0"
        />
      </button>
    </RelayDropdownMenuTrigger>
    <RelayDropdownMenuContent
      align="start"
      class="w-[--reka-dropdown-menu-trigger-width]"
    >
      <RelayDropdownMenuItem
        v-for="opt in options"
        :key="opt"
        class="flex items-center justify-between cursor-pointer"
        @click="$emit('update:modelValue', opt)"
      >
        <span>{{ opt }}</span>
        <span
          v-if="modelValue === opt"
          class="i-lucide-check size-3.5 text-primary"
        />
      </RelayDropdownMenuItem>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
