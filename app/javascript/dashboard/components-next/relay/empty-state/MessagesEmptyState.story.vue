<script setup>
import MessagesEmptyState from './MessagesEmptyState.vue';
</script>

<template>
  <Story
    title="Relay/MessagesEmptyState"
    :layout="{ type: 'single', iframe: true }"
  >
    <Variant title="Default">
      <MessagesEmptyState />
    </Variant>

    <Variant title="Custom copy">
      <MessagesEmptyState
        title="No conversations yet"
        description="New conversations from your customers will show up here."
        icon="i-lucide-rocket"
      />
    </Variant>
  </Story>
</template>
