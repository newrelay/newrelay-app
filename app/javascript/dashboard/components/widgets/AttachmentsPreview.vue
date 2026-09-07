<script setup>
import { computed } from 'vue';

const props = defineProps({
  attachments: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['removeAttachment']);

const nonRecordedAudioAttachments = computed(() => {
  return props.attachments.filter(attachment => !attachment?.isVoiceMessage);
});

const recordedAudioAttachments = computed(() =>
  props.attachments.filter(attachment => attachment.isVoiceMessage)
);

const onRemoveAttachment = itemIndex => {
  emit(
    'removeAttachment',
    nonRecordedAudioAttachments.value
      .filter((_, index) => index !== itemIndex)
      .concat(recordedAudioAttachments.value)
  );
};

const mediaType = file => {
  const type = file?.content_type || file?.type || '';
  if (type.includes('image')) return 'image';
  if (type.includes('video')) return 'video';
  return 'file';
};

const fileName = file => {
  return file.filename || file.name;
};
</script>

<template>
  <div class="flex max-h-[12.5rem] flex-wrap gap-2 overflow-auto">
    <div
      v-for="(attachment, index) in nonRecordedAudioAttachments"
      :key="attachment.id"
    >
      <div
        v-if="mediaType(attachment.resource) === 'image'"
        class="relative size-16 overflow-hidden rounded-lg border border-border bg-muted"
      >
        <img
          class="size-full object-cover"
          :src="attachment.thumb"
          :alt="fileName(attachment.resource)"
        />
        <button
          type="button"
          class="reset-base absolute right-0.5 top-0.5 flex size-5 items-center justify-center rounded-full border-0 bg-background/90 p-0 text-muted-foreground shadow-xs hover:text-destructive"
          @click="onRemoveAttachment(index)"
        >
          <span class="i-lucide-x size-3" />
        </button>
      </div>
      <div
        v-else-if="mediaType(attachment.resource) === 'video'"
        class="relative flex size-16 items-center justify-center overflow-hidden rounded-lg border border-border bg-muted"
      >
        <span class="i-lucide-video size-5 text-muted-foreground" />
        <button
          type="button"
          class="reset-base absolute right-0.5 top-0.5 flex size-5 items-center justify-center rounded-full border-0 bg-background/90 p-0 text-muted-foreground shadow-xs hover:text-destructive"
          @click="onRemoveAttachment(index)"
        >
          <span class="i-lucide-x size-3" />
        </button>
      </div>
      <div
        v-else
        class="flex items-center gap-1.5 rounded-md border border-border bg-muted px-2 py-1 text-[13px] font-medium"
      >
        <span
          class="i-lucide-paperclip size-3 shrink-0 text-muted-foreground"
        />
        <span class="max-w-[12rem] truncate">
          {{ fileName(attachment.resource) }}
        </span>
        <button
          type="button"
          class="reset-base ml-1 flex size-5 shrink-0 items-center justify-center rounded border-0 bg-transparent p-0 text-muted-foreground transition-colors hover:text-destructive"
          @click="onRemoveAttachment(index)"
        >
          <span class="i-lucide-x size-3" />
        </button>
      </div>
    </div>
  </div>
</template>
