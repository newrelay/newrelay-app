<script setup>
import { computed } from 'vue';
import { getFileInfo } from '@chatwoot/utils';
import { formatBytes } from 'shared/helpers/FileHelper';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const fileDetails = computed(() => {
  return getFileInfo(attachment?.dataUrl || '');
});

const fileExt = computed(() =>
  (attachment.extension || fileDetails.value.type || 'FILE').toUpperCase()
);

const isPdf = computed(() => fileExt.value === 'PDF');

const fileSizeLabel = computed(() => {
  const size = attachment.fileSize ?? attachment.file_size;
  if (size == null || size === '') return '';
  return formatBytes(size);
});

const subtext = computed(() => {
  if (fileSizeLabel.value && fileExt.value && fileExt.value !== 'FILE') {
    return `${fileSizeLabel.value} • ${fileExt.value}`;
  }
  return fileSizeLabel.value || '';
});
</script>

<template>
  <a
    :href="attachment.dataUrl"
    rel="noreferrer noopener nofollow"
    target="_blank"
    class="flex min-w-[280px] max-w-full items-center gap-4 rounded-xl border border-border bg-card p-3 text-inherit no-underline shadow-xs transition-colors hover:bg-muted/50"
  >
    <div
      class="flex size-10 shrink-0 items-center justify-center rounded-lg"
      :class="
        isPdf
          ? 'bg-destructive/10 text-destructive'
          : 'bg-primary/10 text-primary'
      "
    >
      <span class="text-[10px] font-bold">
        {{ fileExt }}
      </span>
    </div>
    <div class="flex min-w-0 flex-1 flex-col">
      <span
        class="truncate text-sm font-semibold text-foreground"
        :title="fileDetails.name"
      >
        {{ fileDetails.name }}
      </span>
      <span v-if="subtext" class="mt-0.5 text-[13px] text-muted-foreground">
        {{ subtext }}
      </span>
    </div>
  </a>
</template>
