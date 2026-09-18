<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, required: true },
  icon: { type: String, required: true },
});
</script>

<template>
  <div
    class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 sm:gap-3"
  >
    <div
      class="flex items-center gap-2.5 text-muted-foreground sm:w-44 shrink-0"
    >
      <Icon :icon="icon" class="size-4 text-muted-foreground/80" />
      <span class="text-[13.5px] font-medium text-foreground">{{ title }}</span>
    </div>
    <div class="flex-1 min-w-0 flex justify-end">
      <slot />
    </div>
  </div>
</template>
