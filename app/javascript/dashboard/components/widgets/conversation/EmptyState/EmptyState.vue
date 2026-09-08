<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import OnboardingView from '../OnboardingView.vue';
import EmptyStateMessage from './EmptyStateMessage.vue';
import { RelayMessagesEmptyState } from 'dashboard/components-next/relay';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

export default {
  components: {
    OnboardingView,
    EmptyStateMessage,
    RelayMessagesEmptyState,
    Spinner,
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
        !this.uiFlags.isFetching &&
        !this.loadingChatList &&
        !this.allConversations.length &&
        (this.inboxesList.length || this.isAdmin)
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
    <div
      v-if="uiFlags.isFetching || loadingChatList"
      class="flex flex-col items-center justify-center gap-3"
    >
      <Spinner class="text-primary" />
      <p class="mb-0 text-sm text-muted-foreground">
        {{ loadingIndicatorMessage }}
      </p>
    </div>
    <!-- No inboxes (admin) → stepper; has inboxes + empty list → all-set or filter empty -->
    <OnboardingView
      v-if="
        !uiFlags.isFetching &&
        !loadingChatList &&
        !allConversations.length &&
        (inboxesList.length || isAdmin)
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
