<script setup>
defineProps({
  detailsLabel: {
    type: String,
    default: '',
  },
  actionsLabel: {
    type: String,
    default: '',
  },
  showColumnHeaders: {
    type: Boolean,
    default: true,
  },
});
</script>

<template>
  <div
    class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
  >
    <div
      v-if="$slots.toolbar"
      class="flex flex-col justify-between gap-4 border-b border-border/40 p-4 sm:p-6 md:flex-row md:items-center"
    >
      <slot name="toolbar" />
    </div>

    <div
      v-if="showColumnHeaders && (detailsLabel || actionsLabel)"
      class="grid grid-cols-[1fr_auto] gap-4 border-b border-border/40 bg-muted/20 p-4"
    >
      <div
        class="pl-2 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
      >
        {{ detailsLabel }}
      </div>
      <div
        class="pr-2 text-right text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
      >
        {{ actionsLabel }}
      </div>
    </div>

    <div class="divide-y divide-border/40">
      <slot />
    </div>

    <div v-if="$slots.empty" class="py-20">
      <slot name="empty" />
    </div>
  </div>
</template>
