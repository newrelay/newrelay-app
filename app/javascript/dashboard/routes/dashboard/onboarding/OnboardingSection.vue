<script setup>
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
});
</script>

<template>
  <div class="mb-7">
    <div class="mb-2.5">
      <h2 class="text-[15.5px] font-semibold text-foreground">
        {{ title }}
      </h2>
      <p v-if="subtitle" class="text-[12.5px] text-muted-foreground mt-0.5">
        {{ subtitle }}
      </p>
    </div>

    <!-- Card -->
    <div
      class="bg-muted/40 dark:bg-card/40 rounded-2xl border border-border/80 p-4 space-y-3.5 shadow-2xs"
    >
      <slot />
    </div>
  </div>
</template>
