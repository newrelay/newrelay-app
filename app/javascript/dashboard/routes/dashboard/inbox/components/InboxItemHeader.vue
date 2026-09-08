<script>
import { mapGetters } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { getUnixTime } from 'date-fns';
import {
  CMD_SNOOZE_NOTIFICATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';
import wootConstants from 'dashboard/constants/globals';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import PaginationButton from './PaginationButton.vue';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';
import { emitter } from 'shared/helpers/mitt';
import {
  RelayButton,
  RelayActionDropdown,
  RelayModal,
} from 'dashboard/components-next/relay';
import ConversationProfileSummary from 'dashboard/components/widgets/conversation/ConversationProfileSummary.vue';

export default {
  components: {
    PaginationButton,
    RelayButton,
    RelayActionDropdown,
    RelayModal,
    CustomSnoozeModal,
    ConversationProfileSummary,
  },
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
    activeNotification: {
      type: Object,
      default: null,
    },
  },
  emits: ['next', 'prev'],
  setup() {
    const { updateUISettings, isContactSidebarOpen } = useUISettings();
    return { updateUISettings, isContactSidebarOpen };
  },
  data() {
    return {
      showCustomSnoozeModal: false,
    };
  },
  computed: {
    ...mapGetters({ meta: 'notifications/getMeta' }),
    currentChat() {
      return this.$store.getters.getSelectedChat;
    },
    moreActionsItems() {
      const items = [];
      const currentChat = this.$store.getters.getSelectedChat;
      if (!currentChat) return items;

      const isOpen = currentChat.status === wootConstants.STATUS_TYPE.OPEN;
      const isResolved =
        currentChat.status === wootConstants.STATUS_TYPE.RESOLVED;
      const isPending =
        currentChat.status === wootConstants.STATUS_TYPE.PENDING;
      const isSnoozed =
        currentChat.status === wootConstants.STATUS_TYPE.SNOOZED;

      if (isOpen || isPending || isSnoozed) {
        items.push({
          icon: 'i-lucide-check-circle',
          label: this.$t('CONVERSATION.HEADER.RESOLVE_ACTION'),
          action: 'resolve',
          value: 'resolve',
        });
      }

      if (isResolved || isPending || isSnoozed) {
        items.push({
          icon: 'i-lucide-rotate-ccw',
          label: isResolved
            ? this.$t('CONVERSATION.HEADER.REOPEN_ACTION')
            : this.$t('CONVERSATION.HEADER.OPEN_ACTION'),
          action: 'open',
          value: 'open',
        });
      }

      if (!isPending) {
        items.push({
          icon: 'i-lucide-circle-dot-dashed',
          label: this.$t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING'),
          action: 'pending',
          value: 'pending',
        });
      }

      items.push({
        icon: 'i-lucide-bell-minus',
        label: this.$t('INBOX.ACTION_HEADER.SNOOZE'),
        action: 'snooze',
        value: 'snooze',
      });

      items.push({
        icon: 'i-lucide-trash-2',
        label: this.$t('INBOX.ACTION_HEADER.DELETE'),
        action: 'delete',
        value: 'delete',
        destructive: true,
      });

      return items;
    },
  },
  mounted() {
    emitter.on(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  unmounted() {
    emitter.off(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  methods: {
    openSnoozeNotificationModal() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_notification' });
    },
    hideCustomSnoozeModal() {
      this.showCustomSnoozeModal = false;
    },
    async snoozeNotification(snoozedUntil) {
      try {
        await this.$store.dispatch('notifications/snooze', {
          id: this.activeNotification?.id,
          snoozedUntil,
        });

        useAlert(this.$t('INBOX.ALERTS.SNOOZE'));
      } catch (error) {
        // Silently fail without any change in the UI
      }
    },
    onCmdSnoozeNotification(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomSnoozeModal = true;
      } else if (typeof snoozeType === 'number') {
        this.snoozeNotification(snoozeType);
      } else {
        const snoozedUntil = findSnoozeTime(snoozeType) || null;
        this.snoozeNotification(snoozedUntil);
      }
    },
    scheduleCustomSnooze(customSnoozeTime) {
      this.showCustomSnoozeModal = false;
      if (customSnoozeTime) {
        const snoozedUntil = getUnixTime(customSnoozeTime) || null;
        this.snoozeNotification(snoozedUntil);
      }
    },
    deleteNotification() {
      useTrack(INBOX_EVENTS.DELETE_NOTIFICATION);
      this.$store
        .dispatch('notifications/delete', {
          notification: this.activeNotification,
          unreadCount: this.meta.unreadCount,
          count: this.meta.count,
        })
        .then(() => {
          useAlert(this.$t('INBOX.ALERTS.DELETE'));
        });
      this.$router.replace({ name: 'inbox_view' });
    },
    onClickNext() {
      this.$emit('next');
    },
    onClickPrev() {
      this.$emit('prev');
    },
    onClickGoToInboxList() {
      this.$router.replace({ name: 'inbox_view' });
    },
    toggleContactSidebar() {
      this.updateUISettings({
        is_contact_sidebar_open: !this.isContactSidebarOpen,
        is_copilot_panel_open: false,
      });
    },
    handleActionClick({ action }) {
      const currentChatId = this.$store.getters.getSelectedChat?.id;

      if (action === 'snooze') {
        this.openSnoozeNotificationModal();
      } else if (action === 'delete') {
        this.deleteNotification();
      } else if (action === 'resolve') {
        emitter.emit(CMD_RESOLVE_CONVERSATION);
      } else if (action === 'open') {
        emitter.emit(CMD_REOPEN_CONVERSATION);
      } else if (action === 'pending') {
        this.$store
          .dispatch('toggleStatus', {
            conversationId: currentChatId,
            status: wootConstants.STATUS_TYPE.PENDING,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
          });
      }
    },
  },
};
</script>

<template>
  <div
    class="flex h-14 shrink-0 items-center gap-3 border-b border-border bg-card/50 px-4"
  >
    <RelayButton
      variant="ghost"
      size="icon"
      class="size-9 shrink-0 border-transparent text-muted-foreground hover:border-transparent hover:text-foreground"
      :aria-label="$t('INBOX.ACTION_HEADER.BACK')"
      @click="onClickGoToInboxList"
    >
      <span class="i-lucide-arrow-left size-4" />
    </RelayButton>

    <ConversationProfileSummary
      v-if="currentChat?.id"
      :chat="currentChat"
      class="min-w-0 flex-1"
    />

    <div class="flex shrink-0 items-center gap-1">
      <PaginationButton
        :total-length="totalLength || 1"
        :current-index="currentIndex + 1"
        @next="onClickNext"
        @prev="onClickPrev"
      />
      <RelayActionDropdown
        :menu-items="moreActionsItems"
        align="end"
        content-class="w-48"
        @action="handleActionClick"
      >
        <template #trigger>
          <RelayButton
            variant="ghost"
            size="icon"
            class="ml-1 size-8 border-transparent text-muted-foreground hover:border-transparent hover:text-foreground"
            :aria-label="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
          >
            <span class="i-lucide-ellipsis size-4" />
          </RelayButton>
        </template>
      </RelayActionDropdown>
      <RelayButton
        variant="ghost"
        size="icon"
        class="ml-1 size-9 shrink-0 border-transparent text-muted-foreground hover:border-transparent hover:text-foreground focus-visible:ring-0"
        @click="toggleContactSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
    <RelayModal
      :show="showCustomSnoozeModal"
      :title="$t('CONVERSATION.CUSTOM_SNOOZE.TITLE')"
      @close="hideCustomSnoozeModal"
    >
      <CustomSnoozeModal
        @close="hideCustomSnoozeModal"
        @choose-time="scheduleCustomSnooze"
      />
    </RelayModal>
  </div>
</template>
