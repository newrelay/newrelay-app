<script setup>
defineProps({
  title: { type: String, required: true },
  icon: { type: String, default: '' },
});
</script>

<template>
  <div class="bg-card border border-border rounded-xl p-5 flex flex-col gap-3">
    <h3 class="text-sm font-semibold text-foreground flex items-center gap-2">
      <span v-if="icon" :class="icon" class="size-4 text-primary" />
      {{ title }}
    </h3>
    <slot />
  </div>
</template>
