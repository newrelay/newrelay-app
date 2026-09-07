<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

const { attachments } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});
</script>

<template>
  <BaseBubble
    class="overflow-hidden !rounded-xl !border !border-border !bg-card !p-0 !text-foreground shadow-xs"
    data-bubble-name="embed"
  >
    <div
      class="h-[70vh] max-h-[680px] min-h-[520px] w-full max-w-[360px] sm:max-w-[420px]"
    >
      <iframe
        class="size-full border-0"
        :title="t('CHAT_LIST.ATTACHMENTS.embed.CONTENT')"
        :src="attachment.dataUrl"
        loading="lazy"
        allow="autoplay; encrypted-media; picture-in-picture"
        allowfullscreen
      />
    </div>
  </BaseBubble>
</template>
