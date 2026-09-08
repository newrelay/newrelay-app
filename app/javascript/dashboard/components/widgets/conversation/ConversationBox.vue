<script>
import { mapGetters } from 'vuex';
import ConversationHeader from './ConversationHeader.vue';
import DashboardAppFrame from '../DashboardApp/Frame.vue';
import EmptyState from './EmptyState/EmptyState.vue';
import MessagesView from './MessagesView.vue';
import OnCallBanner from 'dashboard/components-next/call/OnCallBanner.vue';

export default {
  components: {
    ConversationHeader,
    DashboardAppFrame,
    EmptyState,
    MessagesView,
    OnCallBanner,
  },
  props: {
    inboxId: {
      type: [Number, String],
      default: '',
      required: false,
    },
    isInboxView: {
      type: Boolean,
      default: false,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: true,
    },
    isOnExpandedLayout: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return { activeIndex: 0 };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      dashboardApps: 'dashboardApps/getRecords',
    }),
    dashboardAppTabs() {
      return [
        {
          key: 'messages',
          index: 0,
          name: this.$t('CONVERSATION.DASHBOARD_APP_TAB_MESSAGES'),
        },
        ...this.dashboardApps.map((dashboardApp, index) => ({
          key: `dashboard-${dashboardApp.id}`,
          index: index + 1,
          name: dashboardApp.title,
        })),
      ];
    },
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
  },
  watch: {
    'currentChat.inbox_id': {
      immediate: true,
      handler(inboxId) {
        if (inboxId) {
          this.$store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
        }
      },
    },
    'currentChat.id'() {
      this.fetchLabels();
      this.activeIndex = 0;
    },
  },
  mounted() {
    this.fetchLabels();
    this.$store.dispatch('dashboardApps/get');
  },
  methods: {
    fetchLabels() {
      if (!this.currentChat.id) {
        return;
      }
      this.$store.dispatch('conversationLabels/get', this.currentChat.id);
    },
    onDashboardAppTabChange(index) {
      this.activeIndex = index;
    },
  },
};
</script>

<template>
  <div
    class="conversation-details-wrap relative flex min-w-0 w-full flex-col"
    :class="{
      'bg-muted/10 dark:bg-background': !isInboxView,
      'bg-background': isInboxView,
    }"
  >
    <ConversationHeader
      v-if="currentChat.id && !isInboxView"
      :chat="currentChat"
      :show-back-button="isOnExpandedLayout && !isInboxView"
    />
    <OnCallBanner v-if="currentChat.id" :conversation-id="currentChat.id" />
    <div
      v-if="dashboardApps.length && currentChat.id"
      class="flex h-10 shrink-0 items-end gap-6 border-b border-border px-4"
      role="tablist"
    >
      <button
        v-for="tab in dashboardAppTabs"
        :key="tab.key"
        type="button"
        role="tab"
        :aria-selected="activeIndex === tab.index"
        class="relative -mb-px px-1 pb-2.5 text-sm font-medium transition-colors"
        :class="
          activeIndex === tab.index
            ? 'text-foreground'
            : 'text-muted-foreground hover:text-foreground'
        "
        @click="onDashboardAppTabChange(tab.index)"
      >
        {{ tab.name }}
        <span
          v-if="activeIndex === tab.index"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
          aria-hidden="true"
        />
      </button>
    </div>
    <div v-show="!activeIndex" class="flex h-full min-h-0 m-0">
      <MessagesView
        v-if="currentChat.id"
        :inbox-id="inboxId"
        :is-inbox-view="isInboxView"
      />
      <EmptyState
        v-if="!currentChat.id && !isInboxView"
        :is-on-expanded-layout="isOnExpandedLayout"
      />
      <slot />
    </div>
    <DashboardAppFrame
      v-for="(dashboardApp, index) in dashboardApps"
      v-show="activeIndex - 1 === index"
      :key="currentChat.id + '-' + dashboardApp.id"
      :is-visible="activeIndex - 1 === index"
      :config="dashboardApps[index].content"
      :position="index"
      :current-chat="currentChat"
    />
  </div>
</template>
