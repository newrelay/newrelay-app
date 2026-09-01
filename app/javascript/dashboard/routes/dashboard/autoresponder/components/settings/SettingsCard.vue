<script setup>
defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
});
</script>

<template>
  <div class="bg-card border border-border rounded-xl p-6 flex flex-col gap-6">
    <div class="flex items-start justify-between gap-4">
      <div class="flex flex-col gap-1">
        <h3 class="text-sm font-semibold text-foreground">{{ title }}</h3>
        <p v-if="description" class="text-xs text-muted-foreground">
          {{ description }}
        </p>
      </div>
      <slot name="header-action" />
    </div>
    <slot />
  </div>
</template>
