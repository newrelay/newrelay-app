<script setup>
import SLAMetricCard from './SLAMetricCard.vue';
defineProps({
  hitRate: {
    type: String,
    required: true,
  },
  noOfBreaches: {
    type: Number,
    required: true,
  },
  noOfConversations: {
    type: Number,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    class="rounded-xl border border-border bg-card shadow-sm flex sm:flex-row flex-col items-stretch sm:items-center p-6 gap-6"
  >
    <SLAMetricCard
      :label="$t('SLA_REPORTS.METRICS.HIT_RATE.LABEL')"
      :value="hitRate"
      :tooltip="$t('SLA_REPORTS.METRICS.HIT_RATE.TOOLTIP')"
      icon="i-lucide-target"
      :is-loading="isLoading"
    />

    <div class="w-full h-px sm:w-px sm:h-16 bg-border/60 shrink-0" />
    <SLAMetricCard
      :label="$t('SLA_REPORTS.METRICS.NO_OF_MISSES.LABEL')"
      :value="noOfBreaches"
      :tooltip="$t('SLA_REPORTS.METRICS.NO_OF_MISSES.TOOLTIP')"
      icon="i-lucide-circle-x"
      :is-loading="isLoading"
    />
    <div class="w-full h-px sm:w-px sm:h-16 bg-border/60 shrink-0" />
    <SLAMetricCard
      :label="$t('SLA_REPORTS.METRICS.NO_OF_CONVERSATIONS.LABEL')"
      :value="noOfConversations"
      :tooltip="$t('SLA_REPORTS.METRICS.NO_OF_CONVERSATIONS.TOOLTIP')"
      icon="i-lucide-message-square"
      :is-loading="isLoading"
    />
  </div>
</template>
