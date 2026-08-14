<script setup>
import { computed } from 'vue';

const props = defineProps({
  count: { type: [Number, String], default: 0 },
});

const normalizedCount = computed(() => {
  const count = Number(props.count);
  return Number.isFinite(count) && count > 0 ? count : 0;
});

const displayCount = computed(() =>
  normalizedCount.value > 99 ? '99+' : String(normalizedCount.value)
);
</script>

<template>
  <span
    v-if="normalizedCount > 0"
    data-test-id="sidebar-unread-badge"
    class="inline-flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full bg-primary px-1.5 text-[11px] font-medium text-primary-foreground"
  >
    {{ displayCount }}
  </span>
  <span v-else class="hidden" />
</template>
