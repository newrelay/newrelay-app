<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  consumed: {
    type: Number,
    required: true,
  },
  totalCount: {
    type: Number,
    required: true,
  },
  icon: {
    type: String,
    default: '',
  },
  showPercent: {
    type: Boolean,
    default: true,
  },
});

const percent = computed(() => {
  if (!props.totalCount) return 0;
  return Math.min(
    100,
    Math.round((props.consumed / props.totalCount) * 1000) / 10
  );
});

const percentLabel = computed(() => {
  if (percent.value % 1 === 0) return `${percent.value}%`;
  return `${percent.value}%`;
});

const formattedConsumed = computed(() => props.consumed.toLocaleString());
const formattedTotal = computed(() => props.totalCount.toLocaleString());
</script>

<template>
  <div class="flex items-start gap-4 py-3">
    <div v-if="icon" class="mt-0.5 shrink-0 text-muted-foreground">
      <Icon :icon="icon" class="size-[18px]" />
    </div>
    <div class="min-w-0 flex-1">
      <div class="mb-2 flex items-center justify-between gap-3">
        <span class="text-[14px] font-medium text-foreground">
          {{ title }}
        </span>
        <div class="flex items-center gap-4 text-[14px]">
          <span class="font-medium tabular-nums text-foreground">
            {{ formattedConsumed }} / {{ formattedTotal }}
          </span>
          <span
            v-if="showPercent"
            class="w-10 text-right font-medium tabular-nums text-primary"
          >
            {{ percentLabel }}
          </span>
        </div>
      </div>
      <div class="h-1.5 w-full overflow-hidden rounded-full bg-muted">
        <div
          class="h-full rounded-full bg-primary transition-[width] duration-300"
          :style="{ width: `${percent}%` }"
        />
      </div>
    </div>
  </div>
</template>
