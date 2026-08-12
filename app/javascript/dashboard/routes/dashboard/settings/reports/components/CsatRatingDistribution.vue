<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { CSAT_RATINGS } from 'shared/constants/messages';

const props = defineProps({
  ratingPercentage: {
    type: Object,
    default: () => ({}),
  },
  ratingCount: {
    type: Object,
    default: () => ({}),
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const sortedRatings = computed(() =>
  [...CSAT_RATINGS].sort((a, b) => b.value - a.value)
);

// Circle + dot colors per rating, ordered best → worst (matches sortedRatings)
const ratingStyles = [
  { circle: 'bg-primary/10', dot: 'bg-primary' },
  { circle: 'bg-success/15', dot: 'bg-success' },
  { circle: 'bg-warning/15', dot: 'bg-warning' },
  { circle: 'bg-priority-2/15', dot: 'bg-priority-2' },
  { circle: 'bg-destructive/10', dot: 'bg-destructive' },
];

const formatPercent = value => (value ? `${value}%` : '0%');

const getRatingLabel = value => {
  const rating = CSAT_RATINGS.find(r => r.value === value);
  // Translation strings are prefixed with the emoji (e.g. "😍 Excellent");
  // strip leading non-letters since the emoji is shown in its own circle.
  return rating
    ? t(rating.translationKey)
        .replace(/^[^\p{L}]+/u, '')
        .trim()
    : '';
};

const getRatingCount = value => {
  return props.ratingCount[value] || 0;
};
</script>

<template>
  <div
    class="rounded-xl border border-border bg-card shadow-sm p-6 flex flex-col gap-6"
  >
    <div
      class="flex items-center gap-1.5 text-[14px] font-medium text-foreground"
    >
      {{ $t('CSAT_REPORTS.METRIC.RATING_DISTRIBUTION') }}
      <span class="i-lucide-info size-3.5 text-muted-foreground opacity-60" />
    </div>

    <div v-if="isLoading">
      <div class="h-3 w-full rounded-full bg-muted animate-pulse" />
      <div class="flex gap-6 mt-6">
        <div
          v-for="n in 5"
          :key="n"
          class="flex-1 h-16 rounded-lg bg-muted animate-pulse"
        />
      </div>
    </div>

    <template v-else>
      <div class="h-3 w-full bg-muted/40 rounded-full overflow-hidden flex">
        <div
          v-for="rating in sortedRatings"
          :key="rating.value"
          v-tooltip="
            `${getRatingLabel(rating.value)}: ${formatPercent(ratingPercentage[rating.value])} (${getRatingCount(rating.value)})`
          "
          :style="{
            width: `${ratingPercentage[rating.value] || 0}%`,
            backgroundColor: rating.color,
          }"
          class="h-full transition-all duration-300"
        />
      </div>

      <div class="flex flex-col sm:flex-row items-stretch w-full">
        <div
          v-for="(rating, index) in sortedRatings"
          :key="rating.value"
          class="flex-1 flex items-center gap-4 justify-center py-3 sm:py-0 border-b sm:border-b-0 sm:border-r border-border/50 last:border-none"
        >
          <div class="flex flex-col items-center gap-2 shrink-0">
            <div
              class="size-10 rounded-full flex items-center justify-center text-[20px]"
              :class="ratingStyles[index].circle"
            >
              {{ rating.emoji }}
            </div>
            <div
              class="size-1.5 rounded-full"
              :class="ratingStyles[index].dot"
            />
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-[14px] text-muted-foreground font-medium">
              {{ getRatingLabel(rating.value) }}
            </span>
            <span
              class="text-[18px] font-semibold leading-none text-foreground"
            >
              {{ formatPercent(ratingPercentage[rating.value]) }}
            </span>
            <span class="text-[13px] text-muted-foreground/60">
              ({{ getRatingCount(rating.value) }})
            </span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
