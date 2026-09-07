<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import MediaAlbum from '../chips/MediaAlbum.vue';
import { useMessageContext } from '../provider.js';
import { ATTACHMENT_TYPES } from '../constants';

const { attachments } = useMessageContext();

const media = computed(() =>
  (attachments.value || []).filter(attachment =>
    [
      ATTACHMENT_TYPES.IMAGE,
      ATTACHMENT_TYPES.VIDEO,
      ATTACHMENT_TYPES.IG_REEL,
    ].includes(attachment.fileType)
  )
);
</script>

<template>
  <BaseBubble
    class="overflow-hidden !rounded-xl !border !border-border !bg-card !p-0 !text-foreground shadow-xs"
    data-bubble-name="media-album"
  >
    <MediaAlbum :attachments="media" />
  </BaseBubble>
</template>
