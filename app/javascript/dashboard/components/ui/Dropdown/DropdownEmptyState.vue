<script setup>
defineProps({
  message: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="flex items-center justify-center h-10 text-sm text-muted-foreground"
  >
    {{ message }}
  </div>
</template>
