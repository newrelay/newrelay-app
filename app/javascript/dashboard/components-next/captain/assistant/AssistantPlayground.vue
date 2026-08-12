<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';
import MessageList from './MessageList.vue';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const { assistantId } = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const messages = ref([]);
const newMessage = ref('');
const isLoading = ref(false);

const formatMessagesForApi = () => {
  return messages.value.map(message => {
    const payload = {
      role: message.sender,
      content: message.content,
    };

    if (message.sender === 'assistant' && message.agentName) {
      payload.agent_name = message.agentName;
    }

    return payload;
  });
};

const resetConversation = () => {
  messages.value = [];
  newMessage.value = '';
};

watch(
  () => assistantId,
  (newId, oldId) => {
    if (oldId && newId !== oldId) {
      resetConversation();
    }
  }
);

const sendMessage = async () => {
  if (!newMessage.value.trim() || isLoading.value) return;

  const userMessage = {
    content: newMessage.value,
    sender: 'user',
    timestamp: new Date().toISOString(),
  };
  messages.value.push(userMessage);
  const currentMessage = newMessage.value;
  newMessage.value = '';

  try {
    isLoading.value = true;
    const { data } = await CaptainAssistant.playground({
      assistantId,
      messageContent: currentMessage,
      messageHistory: formatMessagesForApi(),
    });

    messages.value.push({
      content: data.response,
      sender: 'assistant',
      agentName: data.agent_name,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error getting assistant response:', error);
  } finally {
    isLoading.value = false;
  }
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
};
</script>

<template>
  <div
    class="flex h-full min-h-[500px] flex-col overflow-hidden rounded-2xl border border-border bg-card p-6 shadow-sm"
  >
    <div
      class="flex shrink-0 items-start justify-between gap-4 border-b border-border/40 pb-4"
    >
      <div class="space-y-1">
        <h2 class="text-base font-semibold tracking-tight text-foreground">
          {{ t('CAPTAIN.PLAYGROUND.HEADER') }}
        </h2>
        <p class="text-[13.5px] leading-relaxed text-muted-foreground">
          {{ t('CAPTAIN.PLAYGROUND.DESCRIPTION') }}
        </p>
      </div>
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 shrink-0 rounded-lg border border-border text-muted-foreground hover:border-transparent hover:text-foreground"
        :title="t('CAPTAIN.PLAYGROUND.HEADER')"
        @click="resetConversation"
      >
        <span class="i-lucide-rotate-ccw size-4" />
      </RelayButton>
    </div>

    <MessageList :messages="messages" :is-loading="isLoading" />

    <div class="shrink-0 space-y-2 border-t border-border/40 pt-4">
      <div
        class="relative flex items-center rounded-xl border border-border/80 bg-background p-2 shadow-sm transition-all focus-within:ring-1 focus-within:ring-primary/30"
      >
        <input
          v-model="newMessage"
          class="mb-0 h-10 flex-1 border-none bg-transparent px-3 text-[14px] text-foreground placeholder:text-muted-foreground/60 focus:outline-none"
          :placeholder="t('CAPTAIN.PLAYGROUND.MESSAGE_PLACEHOLDER')"
          @keydown.enter.exact="handleEnterKey"
        />
        <RelayButton
          size="icon"
          class="ml-2 size-9 shrink-0 rounded-lg"
          :disabled="!newMessage.trim() || isLoading"
          @click="sendMessage"
        >
          <span
            v-if="isLoading"
            class="i-lucide-loader-circle size-4 animate-spin"
          />
          <span v-else class="i-lucide-send size-4" />
        </RelayButton>
      </div>

      <p class="text-center text-[12px] text-muted-foreground/70">
        {{ t('CAPTAIN.PLAYGROUND.CREDIT_NOTE') }}
      </p>
    </div>
  </div>
</template>
