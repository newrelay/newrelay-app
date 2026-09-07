<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});
</script>

<template>
  <BaseBubble
    class="min-w-[280px] overflow-hidden !rounded-xl !border !border-border !bg-card !p-3 !text-foreground shadow-xs"
    data-bubble-name="audio"
  >
    <AudioChip :attachment="attachment" class="skip-context-menu" />
  </BaseBubble>
</template>
