<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { getFileInfo } from '@chatwoot/utils';

import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';
import { formatBytes } from 'shared/helpers/FileHelper';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const { attachments } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => attachments.value?.[0] || {});

const url = computed(() => attachment.value.dataUrl || '');

const fileDetails = computed(() => getFileInfo(url.value || ''));

const fileName = computed(() => {
  const fromInfo = fileDetails.value?.name;
  if (fromInfo) return fromInfo;

  if (url.value) {
    const path = url.value.split('?')[0].split('#')[0];
    const filename = path.substring(path.lastIndexOf('/') + 1);
    try {
      return (
        decodeURIComponent(filename) || t('CONVERSATION.UNKNOWN_FILE_TYPE')
      );
    } catch {
      return filename || t('CONVERSATION.UNKNOWN_FILE_TYPE');
    }
  }
  return t('CONVERSATION.UNKNOWN_FILE_TYPE');
});

const fileExt = computed(() => {
  const fromAttachment = attachment.value.extension;
  const fromInfo = fileDetails.value?.type;
  const raw = (
    fromAttachment ||
    fromInfo ||
    fileName.value.split('.').pop() ||
    ''
  )
    .toString()
    .replace(/^\./, '');
  return raw.toUpperCase();
});

const isPdf = computed(() => fileExt.value === 'PDF');

const fileSizeLabel = computed(() => {
  const size = attachment.value.fileSize ?? attachment.value.file_size;
  if (size == null || size === '') return '';
  return formatBytes(size);
});

const subtext = computed(() => {
  if (fileSizeLabel.value && fileExt.value) {
    return `${fileSizeLabel.value} • ${fileExt.value}`;
  }
  return fileSizeLabel.value || fileExt.value;
});

const iconWrapClass = computed(() =>
  isPdf.value
    ? 'bg-destructive/10 text-destructive'
    : 'bg-primary/10 text-primary'
);

const showPreview = ref(false);

const openPreview = event => {
  if (!isPdf.value) return;
  event.preventDefault();
  showPreview.value = true;
};
</script>

<template>
  <BaseBubble
    class="min-w-[280px] cursor-pointer overflow-hidden !rounded-xl !border !border-border !bg-background/70 !p-3 !text-foreground shadow-none backdrop-blur-sm transition-[background,backdrop-filter] hover:!bg-background/40 hover:!backdrop-blur-md"
    data-bubble-name="file"
  >
    <a
      :href="url"
      rel="noreferrer noopener nofollow"
      :target="isPdf ? undefined : '_blank'"
      class="flex min-w-0 items-center gap-4 text-inherit no-underline"
      @click="openPreview"
    >
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-lg"
        :class="iconWrapClass"
      >
        <span class="text-[10px] font-bold">{{ fileExt || 'FILE' }}</span>
      </div>
      <div class="flex min-w-0 flex-1 flex-col">
        <span class="truncate text-sm font-semibold text-foreground">
          {{ fileName }}
        </span>
        <span v-if="subtext" class="mt-0.5 text-[13px] text-muted-foreground">
          {{ subtext }}
        </span>
      </div>
    </a>
  </BaseBubble>
  <GalleryView
    v-if="showPreview"
    v-model:show="showPreview"
    :attachment="{ ...useSnakeCase(attachment), file_type: 'file' }"
    :all-attachments="[{ ...useSnakeCase(attachment), file_type: 'file' }]"
    @close="() => (showPreview = false)"
  />
</template>
