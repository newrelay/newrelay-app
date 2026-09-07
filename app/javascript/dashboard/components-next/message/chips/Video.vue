<script setup>
import { ref } from 'vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const showGallery = ref(false);
const hasError = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
};
</script>

<template>
  <div
    class="relative h-[120px] w-[160px] cursor-pointer overflow-hidden rounded-xl border border-border shadow-xs"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex size-full flex-col items-center justify-center gap-1 bg-muted text-center text-[11px] text-muted-foreground"
    >
      <span class="i-lucide-video-off size-4" />
      {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
    </div>
    <template v-else>
      <video
        :src="attachment.dataUrl"
        class="size-full object-cover"
        muted
        playsinline
        preload="metadata"
        @error="handleError"
      />
      <div
        class="pointer-events-none absolute inset-0 flex items-center justify-center bg-foreground/10"
      >
        <div
          class="flex size-8 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm"
        >
          <span class="i-lucide-play ml-0.5 size-3.5" />
        </div>
      </div>
    </template>
  </div>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="() => (showGallery = false)"
  />
</template>
