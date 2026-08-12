<script setup>
defineProps({
  heading: {
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
  <header class="flex flex-col items-start gap-1">
    <h2 class="text-base font-semibold tracking-tight text-foreground">
      {{ heading }}
    </h2>
    <p
      v-if="description"
      class="text-[13.5px] leading-relaxed text-muted-foreground"
    >
      {{ description }}
    </p>
  </header>
</template>
