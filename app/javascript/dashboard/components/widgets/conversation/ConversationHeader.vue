<script setup>
import { computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useCallActions } from 'dashboard/composables/useCallSession';
import MoreActions from './MoreActions.vue';
import ConversationProfileSummary from './ConversationProfileSummary.vue';
import ConversationCallButton from './ConversationCallButton.vue';
import { RelayButton, RelayTooltip } from 'dashboard/components-next/relay';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();
const { simulateIncomingCall, hasActiveCall, incomingCalls } = useCallActions();

const isSimulateCallDisabled = computed(
  () => hasActiveCall.value || incomingCalls.value.length > 0
);

const isMessageSearchOpen = ref(false);
const messageSearchQuery = ref('');
const messageSearchInput = ref(null);

const headerIconButtonClass =
  'size-8 shrink-0 border-transparent text-muted-foreground shadow-none hover:border-transparent hover:text-foreground focus-visible:ring-0';

const currentInbox = computed(() =>
  store.getters['inboxes/getInbox'](props.chat.inbox_id)
);

const receiveCall = () => {
  const sender = props.chat?.meta?.sender;
  if (!sender || !props.chat?.id) return;

  simulateIncomingCall({
    conversationId: props.chat.id,
    inboxId: props.chat.inbox_id,
    caller: {
      name: sender.name,
      phone: sender.phone_number,
      avatar: sender.avatar || sender.thumbnail,
    },
  });
};

const openMessageSearch = () => {
  isMessageSearchOpen.value = true;
  nextTick(() => {
    messageSearchInput.value?.focus();
  });
};

const closeMessageSearch = () => {
  isMessageSearchOpen.value = false;
  messageSearchQuery.value = '';
};

const toggleSidebar = () => {
  updateUISettings({
    is_contact_sidebar_open: !uiSettings.value.is_contact_sidebar_open,
  });
};
</script>

<template>
  <div
    class="flex h-16 min-w-0 shrink-0 items-center justify-between overflow-hidden border-b border-border bg-card px-6"
  >
    <ConversationProfileSummary :chat="chat" class="min-w-0 flex-1" />

    <div class="flex shrink-0 items-center gap-1">
      <div
        v-if="isMessageSearchOpen"
        class="relative mr-2 w-[220px] max-w-[220px] shrink-0"
      >
        <span
          class="i-lucide-search pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <input
          ref="messageSearchInput"
          v-model="messageSearchQuery"
          type="text"
          :placeholder="t('CONVERSATION.HEADER.SEARCH_PLACEHOLDER')"
          class="reset-base no-margin box-border h-9 w-full rounded-md border border-border/80 bg-muted/30 pl-8 pr-8 text-[13px] text-foreground placeholder:text-muted-foreground/70 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          @keydown.esc="closeMessageSearch"
        />
        <button
          type="button"
          class="reset-base absolute right-1 top-1/2 flex size-7 -translate-y-1/2 items-center justify-center rounded-sm border-0 bg-transparent p-0 text-muted-foreground transition-colors hover:bg-muted/50 hover:text-foreground"
          :aria-label="t('CONVERSATION.HEADER.CLOSE')"
          @click="closeMessageSearch"
        >
          <span class="i-lucide-x size-3.5" />
        </button>
      </div>

      <RelayButton
        v-if="!isMessageSearchOpen"
        variant="ghost"
        size="icon"
        :class="headerIconButtonClass"
        :aria-label="t('CONVERSATION.HEADER.SEARCH_ACTION')"
        @click="openMessageSearch"
      >
        <span class="i-lucide-search size-4" />
      </RelayButton>

      <ConversationCallButton
        v-if="!isMessageSearchOpen"
        :inbox="currentInbox"
        :chat="chat"
        :button-class="headerIconButtonClass"
      />

      <RelayTooltip
        v-if="!isMessageSearchOpen"
        :content="t('CONVERSATION.HEADER.SIMULATE_INCOMING_CALL')"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          :class="headerIconButtonClass"
          :disabled="isSimulateCallDisabled"
          :aria-label="t('CONVERSATION.HEADER.SIMULATE_INCOMING_CALL')"
          @click="receiveCall"
        >
          <span class="i-lucide-phone-incoming size-4" />
        </RelayButton>
      </RelayTooltip>

      <MoreActions :button-class="headerIconButtonClass" />

      <RelayButton
        variant="ghost"
        size="icon"
        class="ml-1"
        :class="[headerIconButtonClass]"
        :aria-label="t('CONVERSATION.SIDEBAR.CONTACT')"
        @click="toggleSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
  </div>
</template>
