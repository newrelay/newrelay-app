<script setup>
import { computed, ref } from 'vue';
import { getFileInfo } from '@chatwoot/utils';
import { formatBytes } from 'shared/helpers/FileHelper';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

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

const galleryAttachment = computed(() => ({
  ...useSnakeCase(attachment),
  file_type: 'file',
}));

const showPreview = ref(false);

const openPreview = event => {
  if (!isPdf.value) return;
  event.preventDefault();
  showPreview.value = true;
};
</script>

<template>
  <a
    :href="attachment.dataUrl"
    rel="noreferrer noopener nofollow"
    :target="isPdf ? undefined : '_blank'"
    class="flex min-w-[280px] max-w-full items-center gap-4 rounded-xl border border-border bg-background/70 p-3 text-inherit no-underline shadow-none backdrop-blur-sm transition-[background,backdrop-filter] hover:bg-background/40 hover:backdrop-blur-md"
    @click="openPreview"
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
  <GalleryView
    v-if="showPreview"
    v-model:show="showPreview"
    :attachment="galleryAttachment"
    :all-attachments="[galleryAttachment]"
    @close="() => (showPreview = false)"
  />
</template>
