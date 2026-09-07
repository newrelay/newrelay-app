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
const { updateUISettings, isContactSidebarOpen } = useUISettings();
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
    is_contact_sidebar_open: !isContactSidebarOpen.value,
  });
};
</script>

<template>
  <div
    class="relative flex h-16 min-w-0 shrink-0 items-center gap-2 overflow-hidden border-b border-border bg-card px-6"
  >
    <div class="relative min-h-0 min-w-0 flex-1 self-stretch">
      <div class="flex h-full min-w-0 items-center">
        <ConversationProfileSummary :chat="chat" class="min-w-0" />
      </div>
      <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0 -translate-x-2"
        enter-to-class="opacity-100 translate-x-0"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100 translate-x-0"
        leave-to-class="opacity-0 -translate-x-2"
      >
        <div
          v-if="isMessageSearchOpen"
          class="absolute inset-y-0 left-0 right-0 z-10 flex items-center bg-card pr-2"
        >
          <div class="relative w-full">
            <span
              class="i-lucide-search pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            />
            <input
              ref="messageSearchInput"
              v-model="messageSearchQuery"
              type="text"
              :placeholder="t('CONVERSATION.HEADER.SEARCH_PLACEHOLDER')"
              class="reset-base no-margin box-border h-9 w-full rounded-md border border-border/80 bg-muted/30 pl-8 pr-8 text-[14px] text-foreground shadow-sm placeholder:text-muted-foreground/70 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
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
        </div>
      </Transition>
    </div>

    <div class="relative z-20 flex shrink-0 items-center gap-1 bg-card pl-1">
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
        :inbox="currentInbox"
        :chat="chat"
        :button-class="[headerIconButtonClass, 'hover:text-success']"
      />

      <RelayTooltip :content="t('CONVERSATION.HEADER.SIMULATE_INCOMING_CALL')">
        <RelayButton
          variant="ghost"
          size="icon"
          class="hover:text-warning"
          :class="[headerIconButtonClass]"
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
        :class="[
          headerIconButtonClass,
          !isContactSidebarOpen ? 'bg-accent text-accent-foreground' : '',
        ]"
        :aria-label="t('CONVERSATION.SIDEBAR.CONTACT')"
        @click="toggleSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
  </div>
</template>
