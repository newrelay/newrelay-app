<script setup>
import { computed, watch, onMounted } from 'vue';
import { useRoute, onBeforeRouteLeave } from 'vue-router';
import { useStore } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMapGetter } from 'dashboard/composables/store';
import ChatList from '../../../components/ChatList.vue';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import { emitter } from 'shared/helpers/mitt';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';

const props = defineProps({
  inboxId: {
    type: [String, Number],
    default: 0,
  },
  conversationId: {
    type: [String, Number],
    default: 0,
  },
  label: {
    type: String,
    default: '',
  },
  teamId: {
    type: String,
    default: '',
  },
  conversationType: {
    type: String,
    default: '',
  },
  foldersId: {
    type: [String, Number],
    default: 0,
  },
});

const route = useRoute();
const store = useStore();
const { uiSettings } = useUISettings();

const chatList = useMapGetter('getAllConversations');
const currentChat = useMapGetter('getSelectedChat');
const inboxesList = useMapGetter('inboxes/getInboxes');
const inboxUiFlags = useMapGetter('inboxes/getUIFlags');

const isOnExpandedLayout = computed(() => {
  const {
    LAYOUT_TYPES: { CONDENSED },
  } = wootConstants;
  const { conversation_display_type: conversationDisplayType = CONDENSED } =
    uiSettings.value;
  return conversationDisplayType !== CONDENSED;
});

const showFullWidthOnboarding = computed(() => {
  return !inboxUiFlags.value.isFetching && !inboxesList.value.length;
});

const showConversationList = computed(() => {
  if (showFullWidthOnboarding.value) return false;
  return isOnExpandedLayout.value ? !props.conversationId : true;
});

const showMessageView = computed(() => {
  if (showFullWidthOnboarding.value) return true;
  return props.conversationId ? true : !isOnExpandedLayout.value;
});

const shouldShowSidebar = computed(() => {
  if (!currentChat.value?.id) {
    return false;
  }
  const { is_contact_sidebar_open: isContactSidebarOpen } = uiSettings.value;
  return isContactSidebarOpen;
});

const findConversation = () => {
  const convId = parseInt(props.conversationId, 10);
  const [chat] = chatList.value.filter(c => c.id === convId);
  return chat;
};

const setActiveChat = () => {
  if (props.conversationId) {
    const selectedConversation = findConversation();
    if (
      !selectedConversation ||
      selectedConversation.id === currentChat.value?.id
    ) {
      return;
    }
    const { messageId } = route.query;
    store
      .dispatch('setActiveChat', {
        data: selectedConversation,
        after: messageId,
      })
      .then(() => {
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
      });
  } else {
    store.dispatch('clearSelectedState');
  }
};

const fetchConversationIfUnavailable = () => {
  if (!props.conversationId) {
    return;
  }
  const chat = findConversation();
  if (!chat) {
    store.dispatch('getConversation', props.conversationId);
  }
};

const onConversationLoad = () => {
  fetchConversationIfUnavailable();
};

const initialize = () => {
  store.dispatch('setActiveInbox', props.inboxId);
  setActiveChat();
};

onBeforeRouteLeave((to, from, next) => {
  if (props.conversationId) {
    store.dispatch('clearSelectedState');
  }
  next();
});

if (!props.conversationId) {
  store.dispatch('clearSelectedState');
}

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('portals/index');
  initialize();
});

watch(
  () => props.conversationId,
  () => {
    fetchConversationIfUnavailable();
  }
);

watch(
  () => route.fullPath,
  () => {
    initialize();
  }
);

watch(
  () => chatList.value.length,
  () => {
    setActiveChat();
  }
);
</script>

<template>
  <section
    class="flex w-full h-full min-w-0 bg-background text-foreground animate-in fade-in duration-300"
  >
    <ChatList
      :show-conversation-list="showConversationList"
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      :conversation-type="conversationType"
      :folders-id="foldersId"
      :is-on-expanded-layout="isOnExpandedLayout"
      class="border-0"
      @conversation-load="onConversationLoad"
    />
    <ConversationBox
      v-if="showMessageView"
      :inbox-id="inboxId"
      :is-on-expanded-layout="isOnExpandedLayout"
      class="flex-1 bg-background border-0"
    />
    <ConversationSidebar
      v-if="shouldShowSidebar"
      :current-chat="currentChat"
      class="w-[320px] bg-card border-l border-border/60 shrink-0"
    />
    <CmdBarConversationSnooze />
  </section>
</template>
