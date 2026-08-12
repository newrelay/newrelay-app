<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  message: {
    type: Object,
    required: true,
  },
  buttonText: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="flex flex-col gap-2.5 text-foreground max-w-80">
    <div class="p-3 rounded-xl bg-accent">
      <span
        v-dompurify-html="message.content"
        class="text-sm font-medium prose prose-bubble"
      />
    </div>
    <div class="flex gap-2">
      <Button :label="buttonText" slate class="!text-primary w-full" />
    </div>
  </div>
</template>
