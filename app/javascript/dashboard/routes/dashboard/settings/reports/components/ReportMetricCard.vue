<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: String,
    required: true,
  },
  infoText: {
    type: String,
    required: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    data-test-id="reportMetricContainer"
    :class="{
      'grayscale pointer-events-none opacity-30': disabled,
    }"
  >
    <h3
      class="flex items-center gap-1 m-0 text-sm font-medium text-muted-foreground"
    >
      <span data-test-id="reportMetricLabel">{{ label }}</span>
      <RelayTooltip :content="infoText">
        <span
          data-test-id="reportMetricInfo"
          class="i-lucide-info size-3.5 text-muted-foreground opacity-60 cursor-default"
        />
      </RelayTooltip>
    </h3>
    <h4
      data-test-id="reportMetricValue"
      class="mt-1 mb-0 text-2xl text-foreground"
    >
      {{ value }}
    </h4>
  </div>
</template>
