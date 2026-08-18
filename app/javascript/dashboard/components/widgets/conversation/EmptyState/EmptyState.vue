<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import OnboardingView from '../OnboardingView.vue';
import EmptyStateMessage from './EmptyStateMessage.vue';
import { RelayMessagesEmptyState } from 'dashboard/components-next/relay';

export default {
  components: {
    OnboardingView,
    EmptyStateMessage,
    RelayMessagesEmptyState,
  },
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    const { isAdmin } = useAdmin();

    return {
      isAdmin,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      uiFlags: 'inboxes/getUIFlags',
      loadingChatList: 'getChatListLoadingStatus',
    }),
    loadingIndicatorMessage() {
      if (this.uiFlags.isFetching) {
        return this.$t('CONVERSATION.LOADING_INBOXES');
      }
      return this.$t('CONVERSATION.LOADING_CONVERSATIONS');
    },
    emptyClassName() {
      if (
        !this.inboxesList.length &&
        !this.uiFlags.isFetching &&
        !this.loadingChatList &&
        this.isAdmin
      ) {
        return 'h-full overflow-auto w-full bg-background';
      }
      return 'flex-1 min-w-0 px-0 flex flex-col items-center justify-center h-full bg-background';
    },
  },
};
</script>

<template>
  <div :class="emptyClassName">
    <woot-loading-state
      v-if="uiFlags.isFetching || loadingChatList"
      :message="loadingIndicatorMessage"
    />
    <!-- No inboxes attached -->
    <OnboardingView
      v-if="
        !inboxesList.length &&
        !uiFlags.isFetching &&
        !loadingChatList &&
        isAdmin
      "
    />
    <div
      v-else-if="!inboxesList.length && !uiFlags.isFetching && !loadingChatList"
      class="clearfix mx-auto"
    >
      <EmptyStateMessage :message="$t('CONVERSATION.NO_INBOX_AGENT')" />
    </div>

    <RelayMessagesEmptyState
      v-else-if="
        !uiFlags.isFetching && !loadingChatList && !allConversations.length
      "
      class="h-full w-full"
      icon="i-lucide-rocket"
      :title="$t('CONVERSATION.NO_MESSAGE_1')"
      :description="$t('CONVERSATION.NO_MESSAGE_1_DESCRIPTION')"
    />
    <RelayMessagesEmptyState
      v-else-if="
        !uiFlags.isFetching &&
        !loadingChatList &&
        allConversations.length &&
        !currentChat.id &&
        isOnExpandedLayout
      "
      class="h-full w-full"
      icon="i-lucide-rocket"
      :title="$t('CONVERSATION.404')"
      description=""
    />
    <RelayMessagesEmptyState
      v-else-if="
        !uiFlags.isFetching &&
        !loadingChatList &&
        allConversations.length &&
        !currentChat.id
      "
      class="h-full w-full"
      icon="i-lucide-rocket"
      :title="$t('CONVERSATION.SELECT_A_CONVERSATION')"
      :description="$t('CONVERSATION.SELECT_A_CONVERSATION_DESCRIPTION')"
    />
  </div>
</template>
