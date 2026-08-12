<script setup>
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
    default: 'i-lucide-message-square',
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
      class="size-11 rounded-full bg-primary/10 flex items-center justify-center shrink-0"
    >
      <span :class="icon" class="size-5 text-primary" />
    </div>
    <div class="flex flex-col gap-1.5">
      <div
        class="text-[14px] text-muted-foreground font-medium flex items-center gap-1.5"
      >
        {{ label }}
        <span
          v-tooltip.right="tooltip"
          class="i-lucide-info size-3.5 opacity-60"
        />
      </div>
      <div
        v-if="isLoading"
        class="w-16 h-8 rounded-md bg-muted animate-pulse mt-1"
      />
      <template v-else>
        <div
          class="text-[28px] font-semibold tracking-tight leading-none mt-1 text-foreground"
        >
          {{ value }}
        </div>
        <div class="text-[12px] text-muted-foreground">
          {{ $t('CSAT_REPORTS.METRIC.VS_PREVIOUS') }}
        </div>
      </template>
    </div>
  </div>
</template>
