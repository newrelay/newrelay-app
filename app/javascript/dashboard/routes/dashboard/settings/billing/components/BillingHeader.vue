<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
  >
    <div class="min-w-0 flex-1">
      <h3 class="text-base font-medium text-foreground">
        {{ title }}
      </h3>
      <p
        v-if="description || $slots.description"
        class="mt-1 text-sm text-muted-foreground"
      >
        <slot name="description">{{ description }}</slot>
      </p>
    </div>
    <div
      v-if="$slots.default"
      class="flex shrink-0 flex-wrap items-center gap-3"
    >
      <slot />
    </div>
  </div>
</template>
