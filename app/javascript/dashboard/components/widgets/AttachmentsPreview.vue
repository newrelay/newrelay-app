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

const isTypeImage = file => {
  const type = file.content_type || file.type;
  return type.includes('image');
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
      class="flex items-center gap-1.5 rounded-md border border-border bg-muted px-2 py-1 text-[13px] font-medium"
    >
      <img
        v-if="isTypeImage(attachment.resource)"
        class="size-3.5 shrink-0 rounded-sm object-cover"
        :src="attachment.thumb"
      />
      <span
        v-else
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
</template>
