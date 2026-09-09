<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import BaseBubble from './Base.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import { downloadFile, getFileInfo } from '@chatwoot/utils';
import { formatBytes } from 'shared/helpers/FileHelper';
import { MESSAGE_VARIANTS } from '../constants';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const { t } = useI18n();

const { filteredCurrentChatAttachments, attachments, variant } =
  useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry();

const showGallery = ref(false);
const isDownloading = ref(false);

const isOutgoing = computed(() =>
  [MESSAGE_VARIANTS.AGENT, MESSAGE_VARIANTS.BOT].includes(variant.value)
);

const cardClass = computed(() =>
  isOutgoing.value
    ? 'flex !w-[240px] max-w-[260px] cursor-pointer flex-col gap-1.5 overflow-hidden !rounded-2xl !border !border-primary/20 !bg-primary/5 !p-1.5 !text-foreground shadow-xs dark:!border-border dark:!bg-card'
    : 'flex !w-[240px] max-w-[260px] cursor-pointer flex-col gap-1.5 overflow-hidden !rounded-2xl !border !border-border !bg-card !p-1.5 !text-foreground shadow-xs'
);

const fileName = computed(() => {
  const url = attachment.value?.dataUrl || '';
  const fromInfo = getFileInfo(url)?.name;
  if (fromInfo) return fromInfo;
  if (!url) return t('GALLERY_VIEW.SHARED_IMAGE');
  const path = url.split('?')[0].split('#')[0];
  const name = path.substring(path.lastIndexOf('/') + 1);
  try {
    return decodeURIComponent(name) || t('GALLERY_VIEW.SHARED_IMAGE');
  } catch {
    return name || t('GALLERY_VIEW.SHARED_IMAGE');
  }
});

const fileSizeLabel = computed(() => {
  const size = attachment.value?.fileSize ?? attachment.value?.file_size;
  if (size == null || size === '') return '';
  return formatBytes(size);
});

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
    class="group"
    :class="cardClass"
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
    <template v-else-if="isLoaded">
      <div
        class="relative flex aspect-[4/3] max-h-[160px] cursor-pointer items-center justify-center overflow-hidden rounded-lg bg-muted/40"
      >
        <img
          class="skip-context-menu size-full object-cover transition-transform duration-300 group-hover:scale-105"
          :src="attachment.dataUrl"
          :width="attachment.width"
          :height="attachment.height"
          alt=""
        />
        <div
          class="absolute inset-0 flex items-center justify-center gap-1.5 bg-background/60 opacity-0 backdrop-blur-xs transition-opacity group-hover:opacity-100"
        >
          <button
            type="button"
            class="reset-base flex size-6.5 items-center justify-center rounded-full bg-background/90 p-0 text-foreground shadow-md transition-transform hover:scale-110 hover:bg-background"
            :aria-label="t('GALLERY_VIEW.EXPAND')"
          >
            <span class="i-lucide-maximize-2 size-3.5" />
          </button>
          <button
            type="button"
            class="reset-base flex size-6.5 items-center justify-center rounded-full bg-background/90 p-0 text-foreground shadow-md transition-transform hover:scale-110 hover:bg-background disabled:opacity-50"
            :aria-label="t('CONVERSATION.DOWNLOAD')"
            :disabled="isDownloading"
            @click.stop="downloadAttachment"
          >
            <span class="i-lucide-download size-3.5" />
          </button>
        </div>
      </div>
      <div
        class="flex items-center justify-between border-t border-border/40 px-1 pt-1 text-[10.5px] text-muted-foreground"
      >
        <span class="max-w-[140px] truncate font-medium">{{ fileName }}</span>
        <span v-if="fileSizeLabel">{{ fileSizeLabel }}</span>
      </div>
    </template>
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
