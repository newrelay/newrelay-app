<script setup>
import { ref, computed } from 'vue';
import BaseBubble from './Base.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import { ATTACHMENT_TYPES } from '../constants';

const emit = defineEmits(['error']);
const hasError = ref(false);
const showGallery = ref(false);
const { filteredCurrentChatAttachments, attachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
  emit('error');
};

const attachment = computed(() => {
  return attachments.value[0];
});

const isReel = computed(() => {
  return attachment.value.fileType === ATTACHMENT_TYPES.IG_REEL;
});
</script>

<template>
  <BaseBubble
    class="cursor-pointer overflow-hidden !rounded-xl !border !border-border !bg-card !p-0 !text-foreground shadow-xs"
    data-bubble-name="video"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex items-center gap-2 px-3 py-2.5 text-muted-foreground"
    >
      <span class="i-lucide-video-off size-4 shrink-0" />
      <p class="mb-0 text-[13px]">
        {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
      </p>
    </div>
    <div v-else class="group relative overflow-hidden">
      <video
        class="skip-context-menu block max-h-[360px] w-auto object-contain"
        :class="isReel ? 'max-w-48' : 'max-w-[320px]'"
        :src="attachment.dataUrl"
        muted
        playsinline
        preload="metadata"
        @error="handleError"
      />
      <div
        v-if="isReel"
        class="pointer-events-none absolute right-2 top-2 flex size-7 items-center justify-center rounded-full border border-border bg-background/90"
      >
        <span class="i-lucide-instagram size-3.5 text-foreground" />
      </div>
      <div
        class="pointer-events-none absolute inset-0 flex items-center justify-center bg-foreground/10"
      >
        <div
          class="flex size-10 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm"
        >
          <span class="i-lucide-play ml-0.5 size-4" />
        </div>
      </div>
    </div>
  </BaseBubble>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="() => (showGallery = false)"
  />
</template>
