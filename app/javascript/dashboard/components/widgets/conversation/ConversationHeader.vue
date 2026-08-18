<script setup>
import { ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import MoreActions from './MoreActions.vue';
import ConversationProfileSummary from './ConversationProfileSummary.vue';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

const isMessageSearchOpen = ref(false);
const messageSearchQuery = ref('');
const messageSearchInput = ref(null);

const headerIconButtonClass =
  'size-8 shrink-0 border-transparent text-muted-foreground shadow-none hover:border-transparent hover:text-foreground focus-visible:ring-0';

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
    class="flex h-16 shrink-0 items-center justify-between border-b border-border bg-card px-6"
  >
    <ConversationProfileSummary :chat="chat" class="min-w-0 flex-1" />

    <div class="flex shrink-0 items-center gap-1">
      <div v-if="isMessageSearchOpen" class="relative mr-2 flex items-center">
        <span
          class="i-lucide-search pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <input
          ref="messageSearchInput"
          v-model="messageSearchQuery"
          type="text"
          :placeholder="t('CONVERSATION.HEADER.SEARCH_PLACEHOLDER')"
          class="h-9 w-[220px] rounded-md border border-border/80 bg-muted/30 pl-8 pr-8 text-[13px] transition-all duration-300 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          @keydown.esc="closeMessageSearch"
        />
        <button
          type="button"
          class="absolute right-1 top-1/2 flex size-7 -translate-y-1/2 items-center justify-center rounded-sm text-muted-foreground transition-colors hover:bg-muted/50 hover:text-foreground"
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
