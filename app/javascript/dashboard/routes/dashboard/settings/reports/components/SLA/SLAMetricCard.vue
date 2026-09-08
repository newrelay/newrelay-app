<script>
import { RelayTooltip } from 'dashboard/components-next/relay';

export default {
  components: {
    RelayTooltip,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Number],
      required: true,
    },
    toolTip: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-2 items-start justify-center min-w-[10rem]">
    <span
      class="inline-flex items-center gap-1 text-sm font-medium text-muted-foreground"
    >
      {{ label }}
      <RelayTooltip :content="toolTip" side="right">
        <span
          class="i-lucide-info size-3.5 text-muted-foreground opacity-60 cursor-default"
        />
      </RelayTooltip>
    </span>
    <div
      v-if="isLoading"
      class="w-12 h-6 mb-0.5 rounded-md bg-muted animate-pulse"
    />

    <span v-else class="text-2xl font-medium text-foreground">
      {{ value }}
    </span>
  </div>
</template>
