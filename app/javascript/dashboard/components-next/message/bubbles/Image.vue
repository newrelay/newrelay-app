<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import BaseBubble from './Base.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import { downloadFile } from '@chatwoot/utils';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const { t } = useI18n();

const { filteredCurrentChatAttachments, attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry();

const showGallery = ref(false);
const isDownloading = ref(false);

onMounted(() => {
  if (attachment.value?.dataUrl) {
    loadWithRetry(attachment.value.dataUrl);
  }
});

const downloadAttachment = async () => {
  const { fileType, dataUrl, extension } = attachment.value;
  try {
    isDownloading.value = true;
    await downloadFile({ url: dataUrl, type: fileType, extension });
  } catch {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  } finally {
    isDownloading.value = false;
  }
};

const handleImageError = () => {
  hasError.value = true;
};
</script>

<template>
  <BaseBubble
    class="cursor-pointer overflow-hidden !rounded-xl !border !border-border !bg-card !p-0 !text-foreground shadow-xs"
    data-bubble-name="image"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex items-center gap-2 px-3 py-2.5 text-muted-foreground"
    >
      <span class="i-lucide-image-off size-4 shrink-0" />
      <p class="mb-0 text-[13px]">
        {{ $t('COMPONENTS.MEDIA.IMAGE_UNAVAILABLE') }}
      </p>
    </div>
    <div v-else-if="isLoaded" class="group relative overflow-hidden">
      <img
        class="skip-context-menu block max-h-[360px] w-auto max-w-[320px] object-contain"
        :src="attachment.dataUrl"
        :width="attachment.width"
        :height="attachment.height"
        alt=""
      />
      <div
        class="pointer-events-none absolute inset-0 hidden bg-gradient-to-t from-foreground/30 via-transparent to-transparent group-hover:block"
      />
      <div class="absolute bottom-2 right-2 hidden gap-1.5 group-hover:flex">
        <button
          type="button"
          class="reset-base pointer-events-none flex size-8 items-center justify-center rounded-full border border-border bg-background/90 p-0 text-foreground shadow-xs"
          :aria-label="t('GALLERY_VIEW.EXPAND')"
        >
          <span class="i-lucide-expand size-3.5" />
        </button>
        <button
          type="button"
          class="reset-base flex size-8 items-center justify-center rounded-full border border-border bg-background/90 p-0 text-foreground shadow-xs hover:bg-background disabled:opacity-50"
          :aria-label="t('CONVERSATION.DOWNLOAD')"
          :disabled="isDownloading"
          @click.stop="downloadAttachment"
        >
          <span class="i-lucide-download size-3.5" />
        </button>
      </div>
    </div>
  </BaseBubble>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleImageError"
    @close="() => (showGallery = false)"
  />
</template>
