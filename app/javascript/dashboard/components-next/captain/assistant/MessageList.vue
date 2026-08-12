<script setup>
import { useI18n } from 'vue-i18n';
import { ref, watch, nextTick } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  messages: {
    type: Array,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const messageContainer = ref(null);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const isUserMessage = sender => sender === 'user';

const getAvatarLabel = sender =>
  isUserMessage(sender)
    ? t('CAPTAIN.PLAYGROUND.USER').charAt(0)
    : t('CAPTAIN.PLAYGROUND.ASSISTANT').charAt(0);

const scrollToBottom = async () => {
  await nextTick();
  if (messageContainer.value) {
    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
  }
};

watch(() => props.messages.length, scrollToBottom);
watch(() => props.isLoading, scrollToBottom);
</script>

<template>
  <div ref="messageContainer" class="flex-1 space-y-5 overflow-y-auto py-6">
    <template v-for="(message, index) in messages" :key="index">
      <div
        v-if="isUserMessage(message.sender)"
        class="flex items-start justify-end gap-2.5"
      >
        <div class="flex max-w-[80%] flex-col items-end">
          <div
            class="rounded-2xl rounded-tr-xs border border-primary/20 bg-primary/10 px-4 py-2.5 text-[14px] leading-relaxed text-foreground shadow-xs"
            v-html="formatMessage(message.content)"
          />
        </div>
        <div
          class="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/20 text-[11px] font-bold text-emerald-600 shadow-xs dark:text-emerald-400"
        >
          {{ getAvatarLabel(message.sender) }}
        </div>
      </div>

      <div v-else class="flex items-start justify-start gap-2.5">
        <div
          class="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-primary/10 text-[11px] font-bold text-primary shadow-xs"
        >
          {{ getAvatarLabel(message.sender) }}
        </div>
        <div class="flex max-w-[80%] flex-col items-start">
          <div
            class="rounded-2xl rounded-tl-xs border border-border/60 bg-muted/60 px-4 py-2.5 text-[14px] leading-relaxed text-foreground shadow-xs"
            v-html="formatMessage(message.content)"
          />
        </div>
      </div>
    </template>

    <div v-if="isLoading" class="flex items-start justify-start gap-2.5">
      <div
        class="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-primary/10 text-[11px] font-bold text-primary shadow-xs"
      >
        {{ getAvatarLabel('assistant') }}
      </div>
      <div
        class="flex items-center gap-1.5 rounded-2xl rounded-tl-xs border border-border/60 bg-muted/60 px-4 py-3 shadow-xs"
      >
        <span class="size-2 animate-bounce rounded-full bg-primary/70" />
        <span
          class="size-2 animate-bounce rounded-full bg-primary/70 [animation-delay:0.2s]"
        />
        <span
          class="size-2 animate-bounce rounded-full bg-primary/70 [animation-delay:0.4s]"
        />
      </div>
    </div>
  </div>
</template>
