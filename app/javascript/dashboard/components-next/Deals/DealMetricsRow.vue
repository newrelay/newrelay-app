<script setup>
defineProps({
  metrics: { type: Array, default: () => [] },
});
</script>

<template>
  <div
    class="flex gap-4 overflow-x-auto border-b border-border bg-card px-6 py-5"
  >
    <div
      v-for="metric in metrics"
      :key="metric.key"
      class="flex min-w-[190px] flex-1 flex-col gap-3 rounded-[14px] border border-border/60 bg-background p-5 shadow-sm"
    >
      <span class="text-[13px] font-medium text-muted-foreground">
        {{ metric.label }}
      </span>
      <span class="text-3xl font-bold tracking-tight text-foreground">
        {{ metric.value }}
      </span>
    </div>
  </div>
</template>
