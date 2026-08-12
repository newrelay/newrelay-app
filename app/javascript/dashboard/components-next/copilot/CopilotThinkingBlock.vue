<script setup>
import Icon from '../../components-next/icon/Icon.vue';
defineProps({
  content: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-2 p-3 rounded-lg bg-background/50 border border-border hover:bg-background/80 transition-colors duration-200"
  >
    <div class="flex items-start gap-2">
      <Icon
        icon="i-lucide-sparkles"
        class="w-4 h-4 mt-0.5 flex-shrink-0 text-muted-foreground"
      />
      <div class="text-sm text-foreground">
        {{ content }}
      </div>
    </div>
  </div>
</template>
