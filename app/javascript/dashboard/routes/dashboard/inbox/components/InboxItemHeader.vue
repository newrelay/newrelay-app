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
import { RelayButton } from 'dashboard/components-next/relay';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

export default {
  components: {
    PaginationButton,
    RelayButton,
    CustomSnoozeModal,
    DropdownMenu,
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
    const { uiSettings, updateUISettings } = useUISettings();
    return { uiSettings, updateUISettings };
  },
  data() {
    return {
      showCustomSnoozeModal: false,
      showMoreActionsDropdown: false,
    };
  },
  computed: {
    ...mapGetters({ meta: 'notifications/getMeta' }),
    isContactSidebarOpen() {
      return this.uiSettings.is_contact_sidebar_open;
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
      this.showMoreActionsDropdown = false;
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
    class="flex items-center justify-between w-full px-4 h-14 border-b border-border bg-card/50 shrink-0"
  >
    <div class="flex items-center">
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 text-muted-foreground hover:text-foreground"
        :aria-label="$t('INBOX.ACTION_HEADER.BACK')"
        @click="onClickGoToInboxList"
      >
        <span class="i-lucide-arrow-left size-4" />
      </RelayButton>
    </div>

    <div class="flex items-center gap-1">
      <PaginationButton
        v-if="totalLength > 1"
        :total-length="totalLength"
        :current-index="currentIndex + 1"
        @next="onClickNext"
        @prev="onClickPrev"
      />
      <div
        v-on-clickaway="
          () => {
            showMoreActionsDropdown = false;
          }
        "
        class="relative flex items-center group"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 text-muted-foreground hover:text-foreground"
          :aria-label="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
          @click="showMoreActionsDropdown = !showMoreActionsDropdown"
        >
          <span class="i-lucide-more-horizontal size-4" />
        </RelayButton>
        <DropdownMenu
          v-if="showMoreActionsDropdown"
          :menu-items="moreActionsItems"
          class="mt-1 ltr:right-0 rtl:left-0 top-full"
          @action="handleActionClick"
        />
      </div>
      <div class="w-px h-4 bg-border mx-1" />
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 text-muted-foreground hover:text-foreground"
        :class="{ 'bg-accent text-accent-foreground': isContactSidebarOpen }"
        @click="toggleContactSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
    <woot-modal
      v-model:show="showCustomSnoozeModal"
      :on-close="hideCustomSnoozeModal"
    >
      <CustomSnoozeModal
        @close="hideCustomSnoozeModal"
        @choose-time="scheduleCustomSnooze"
      />
    </woot-modal>
  </div>
</template>
