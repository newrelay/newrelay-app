<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});
const { t } = useI18n();
const hasError = ref(false);
const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
};
</script>

<template>
  <button
    type="button"
    class="reset-base group relative w-[240px] max-w-full cursor-pointer overflow-hidden rounded-lg border-0 bg-muted/40 p-0"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex aspect-[4/3] max-h-[160px] flex-col items-center justify-center gap-1 text-center text-[11px] text-muted-foreground"
    >
      <span class="i-lucide-image-off size-4" />
      {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
    </div>
    <div
      v-else
      class="relative flex aspect-[4/3] max-h-[160px] items-center justify-center overflow-hidden"
    >
      <img
        class="skip-context-menu size-full object-cover transition-transform duration-300 group-hover:scale-105"
        :src="attachment.dataUrl"
        alt=""
        @error="handleError"
      />
      <div
        class="absolute inset-0 flex items-center justify-center bg-background/60 opacity-0 backdrop-blur-xs transition-opacity group-hover:opacity-100"
      >
        <span
          class="flex size-6.5 items-center justify-center rounded-full bg-background/90 text-foreground shadow-md"
          :aria-label="t('GALLERY_VIEW.EXPAND')"
        >
          <span class="i-lucide-maximize-2 size-3.5" />
        </span>
      </div>
    </div>
  </button>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="() => (showGallery = false)"
  />
</template>
