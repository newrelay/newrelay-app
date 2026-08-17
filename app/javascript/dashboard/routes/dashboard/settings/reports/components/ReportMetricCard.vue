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
      class="capitalize flex items-center m-0 text-sm font-medium text-muted-foreground"
    >
      <span data-test-id="reportMetricLabel">{{ label }}</span>
      <RelayTooltip :content="infoText">
        <fluent-icon
          data-test-id="reportMetricInfo"
          size="14"
          icon="info"
          class="text-muted-foreground my-0 mx-1 mt-0.5"
        />
      </RelayTooltip>
    </h3>
    <h4
      data-test-id="reportMetricValue"
      class="capitalize mt-1 mb-0 text-2xl text-foreground"
    >
      {{ value }}
    </h4>
  </div>
</template>
