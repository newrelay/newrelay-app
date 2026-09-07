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
const hasError = ref(false);
const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
};
</script>

<template>
  <div
    class="h-[120px] w-[160px] cursor-pointer overflow-hidden rounded-xl border border-border shadow-xs"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex size-full flex-col items-center justify-center gap-1 bg-muted text-center text-[11px] text-muted-foreground"
    >
      <span class="i-lucide-image-off size-4" />
      {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
    </div>
    <img
      v-else
      class="skip-context-menu size-full object-cover"
      :src="attachment.dataUrl"
      alt=""
      @error="handleError"
    />
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
