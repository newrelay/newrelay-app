<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';

defineProps({
  label: {
    type: String,
    required: true,
  },
  tooltip: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    required: true,
  },
  icon: {
    type: String,
    default: 'i-lucide-target',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div class="flex-1 flex items-start gap-4">
    <div
      class="size-14 rounded-full bg-primary/10 flex items-center justify-center shrink-0"
    >
      <span :class="icon" class="size-6 text-primary" />
    </div>
    <div class="flex flex-col gap-1.5">
      <div
        class="text-[14px] text-muted-foreground font-medium flex items-center gap-1.5"
      >
        {{ label }}
        <RelayTooltip :content="tooltip" side="right">
          <span class="i-lucide-info size-3.5 opacity-60" />
        </RelayTooltip>
      </div>
      <div
        v-if="isLoading"
        class="w-16 h-8 rounded-md bg-muted animate-pulse mt-1"
      />
      <div
        v-else
        class="text-[28px] font-semibold tracking-tight leading-none mt-1 text-foreground"
      >
        {{ value }}
      </div>
    </div>
  </div>
</template>
