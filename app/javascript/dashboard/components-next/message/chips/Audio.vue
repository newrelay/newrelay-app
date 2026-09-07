<script setup>
import { computed, ref } from 'vue';
import VoiceCallRecordingPlayer from 'next/message/chips/VoiceCallRecordingPlayer.vue';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  showTranscribedText: {
    type: Boolean,
    default: true,
  },
});

defineOptions({
  inheritAttrs: false,
});

const TRANSCRIPT_PREVIEW_LENGTH = 200;
const isTranscriptExpanded = ref(false);
const isTranscriptLong = computed(
  () => (attachment.transcribedText?.length || 0) > TRANSCRIPT_PREVIEW_LENGTH
);
const displayedTranscript = computed(() => {
  const text = attachment.transcribedText || '';
  if (!isTranscriptLong.value || isTranscriptExpanded.value) return text;
  return `${text.slice(0, TRANSCRIPT_PREVIEW_LENGTH).trimEnd()}…`;
});
</script>

<template>
  <div v-bind="$attrs" class="flex w-full min-w-[280px] flex-col gap-2">
    <VoiceCallRecordingPlayer :attachment="attachment" />
    <div
      v-if="attachment.transcribedText && showTranscribedText"
      class="w-full break-words rounded-lg bg-muted p-3 text-sm text-foreground"
    >
      {{ displayedTranscript }}
      <button
        v-if="isTranscriptLong"
        type="button"
        class="reset-base mt-1 block border-0 bg-transparent p-0 font-medium text-muted-foreground hover:text-foreground"
        @click="isTranscriptExpanded = !isTranscriptExpanded"
      >
        {{
          isTranscriptExpanded
            ? $t('CONVERSATION.VOICE_CALL.TRANSCRIPT_SHOW_LESS')
            : $t('CONVERSATION.VOICE_CALL.TRANSCRIPT_SHOW_MORE')
        }}
      </button>
    </div>
  </div>
</template>
