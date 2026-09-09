<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import MediaAlbum from '../chips/MediaAlbum.vue';
import { useMessageContext } from '../provider.js';
import { ATTACHMENT_TYPES, MESSAGE_VARIANTS } from '../constants';

const { attachments, variant } = useMessageContext();

const media = computed(() =>
  (attachments.value || []).filter(attachment =>
    [
      ATTACHMENT_TYPES.IMAGE,
      ATTACHMENT_TYPES.VIDEO,
      ATTACHMENT_TYPES.IG_REEL,
    ].includes(attachment.fileType)
  )
);

const isOutgoing = computed(() =>
  [MESSAGE_VARIANTS.AGENT, MESSAGE_VARIANTS.BOT].includes(variant.value)
);

const cardClass = computed(() =>
  isOutgoing.value
    ? 'flex !w-[250px] max-w-[260px] flex-col gap-1.5 overflow-hidden !rounded-2xl !border !border-primary/20 !bg-primary/5 !p-1.5 !text-foreground shadow-xs dark:!border-border dark:!bg-card'
    : 'flex !w-[250px] max-w-[260px] flex-col gap-1.5 overflow-hidden !rounded-2xl !border !border-border !bg-card !p-1.5 !text-foreground shadow-xs'
);
</script>

<template>
  <BaseBubble :class="cardClass" data-bubble-name="media-album">
    <MediaAlbum :attachments="media" />
  </BaseBubble>
</template>
