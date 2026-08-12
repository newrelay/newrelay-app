<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div>
    <span class="text-xs text-muted-foreground">
      {{ label }}
    </span>
    <div class="mt-1.5 text-base font-medium text-foreground">
      {{ value }}
    </div>
  </div>
</template>
