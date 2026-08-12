<script setup>
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-2 p-3 rounded-xl bg-accent text-foreground max-w-80"
  >
    <div v-if="message.title" class="text-base font-bold">
      {{ message.title }}
    </div>

    <div v-if="message.content" class="text-sm font-medium prose prose-bubble">
      <span v-dompurify-html="message.content" />
    </div>

    <div v-if="message.footer" class="text-xs opacity-70 text-muted-foreground">
      {{ message.footer }}
    </div>
  </div>
</template>
