<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getFileInfo } from '@chatwoot/utils';

import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';
import { formatBytes } from 'shared/helpers/FileHelper';

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
</script>

<template>
  <BaseBubble
    class="min-w-[280px] cursor-pointer overflow-hidden !rounded-xl !border !border-border !bg-card !p-3 !text-foreground shadow-xs hover:!bg-muted/50"
    data-bubble-name="file"
  >
    <a
      :href="url"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="flex min-w-0 items-center gap-4 text-inherit no-underline"
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
</template>
