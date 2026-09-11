<script setup>
import { computed, inject, ref, watch, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

import InboxItemHeader from './components/InboxItemHeader.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';
import { RelayMessagesEmptyState } from 'dashboard/components-next/relay';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';

const route = useRoute();
const store = useStore();
const { uiSettings, isContactSidebarOpen } = useUISettings();

const isConversationLoading = ref(false);

const notification = useMapGetter('notifications/getFilteredNotifications');
const currentChat = useMapGetter('getSelectedChat');
const conversationById = useMapGetter('getConversationById');
const inboxListItems = inject(
  'inboxListItems',
  computed(() => [])
);
const inboxOpenConversation = inject('inboxOpenConversation', () => {});

const inboxId = computed(() => Number(route.params.inboxId));
const conversationId = computed(() => Number(route.params.id));

const activeSortOrder = computed(() => {
  const { inbox_filter_by: filterBy = {} } = uiSettings.value;
  const { sort_by: sortBy } = filterBy;
  return sortBy || 'desc';
});

const notifications = computed(() => {
  return notification.value({
    sortOrder: activeSortOrder.value,
  });
});

const activeNotification = computed(() => {
  return notifications.value?.find(
    n => n.primary_actor?.id === conversationId.value
  );
});

const totalInboxCount = computed(() => inboxListItems.value.length);

const showEmptyState = computed(() => !conversationId.value);

const activeInboxIndex = computed(() =>
  inboxListItems.value.findIndex(
    item => Number(item?.primaryActor?.id) === conversationId.value
  )
);

const isContactPanelOpen = computed(() => {
  if (currentChat.value.id) {
    return isContactSidebarOpen.value;
  }
  return false;
});

const findConversation = () => {
  return conversationById.value(conversationId.value);
};

const setActiveChat = async () => {
  const selectedConversation = findConversation();
  if (!selectedConversation) return;

  try {
    await store.dispatch('setActiveChat', { data: selectedConversation });
    emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
  } catch {
    // error
  }
};

const fetchConversationById = async () => {
  if (!conversationId.value) return;

  store.dispatch('clearSelectedState');
  const existingChat = findConversation();

  if (existingChat) {
    await setActiveChat();
    return;
  }

  isConversationLoading.value = true;

  try {
    await store.dispatch('getConversation', conversationId.value);
    await setActiveChat();
  } catch {
    // error
  } finally {
    isConversationLoading.value = false;
  }
};

const navigateToConversation = (activeIndex, direction) => {
  const isValidPrev = direction === 'prev' && activeIndex > 0;
  const isValidNext =
    direction === 'next' && activeIndex < totalInboxCount.value - 1;

  if (!isValidPrev && !isValidNext) return;

  const updatedIndex = direction === 'prev' ? activeIndex - 1 : activeIndex + 1;
  const target = inboxListItems.value[updatedIndex];

  if (target) {
    inboxOpenConversation(target);
  }
};

const onClickNext = () => {
  navigateToConversation(activeInboxIndex.value, 'next');
};

const onClickPrev = () => {
  navigateToConversation(activeInboxIndex.value, 'prev');
};

watch(
  conversationId,
  (newVal, oldVal) => {
    if (newVal !== oldVal) {
      fetchConversationById();
    }
  },
  { immediate: true }
);

onMounted(async () => {
  await store.dispatch('agents/get');
});
</script>

<template>
  <div class="h-full w-full flex-1">
    <div v-if="showEmptyState" class="flex w-full h-full">
      <RelayMessagesEmptyState
        class="flex-1"
        :title="$t('INBOX.LIST.EMPTY_STATE.TITLE')"
        :description="$t('INBOX.LIST.EMPTY_STATE.DESCRIPTION')"
      />
    </div>
    <div v-else class="flex flex-row w-full h-full min-w-0">
      <div class="flex flex-col flex-1 min-w-0 h-full">
        <InboxItemHeader
          :total-length="totalInboxCount"
          :current-index="activeInboxIndex"
          :active-notification="activeNotification"
          @next="onClickNext"
          @prev="onClickPrev"
        />
        <div
          v-if="isConversationLoading"
          class="flex items-center flex-1 my-4 justify-center bg-card"
        >
          <Spinner class="text-primary" />
        </div>
        <div v-else class="flex flex-1 min-w-0 h-full">
          <ConversationBox
            class="flex-1 [&.conversation-details-wrap]:!border-0"
            is-inbox-view
            :inbox-id="inboxId"
            :is-on-expanded-layout="false"
          />
        </div>
      </div>
      <ConversationSidebar
        v-if="isContactPanelOpen"
        :current-chat="currentChat"
      />
    </div>
  </div>
</template>
