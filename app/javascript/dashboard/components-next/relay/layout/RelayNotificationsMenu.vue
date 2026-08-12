<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useTrack } from 'dashboard/composables';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { ACCOUNT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountId } = useAccount();

const isOpen = ref(false);

const notifications = useMapGetter('notifications/getNotifications');
const meta = useMapGetter('notifications/getMeta');
const uiFlags = useMapGetter('notifications/getUIFlags');

const hasUnread = computed(() => Boolean(meta.value?.unreadCount));
const previewNotifications = computed(() => notifications.value.slice(0, 8));
const isLoading = computed(() => uiFlags.value?.isFetching);
const showLoading = computed(
  () => isLoading.value && previewNotifications.value.length === 0
);
const isEmpty = computed(
  () => !isLoading.value && previewNotifications.value.length === 0
);

const notificationTitle = notification => {
  const typeKey = notification.notification_type;
  if (typeKey) {
    return t(`NOTIFICATIONS_PAGE.TYPE_LABEL.${typeKey}`);
  }
  return notification.push_message_title || t('NOTIFICATIONS_PAGE.HEADER');
};

const notificationBody = notification =>
  notification.push_message_title || t('INBOX.NO_CONTENT');

const notificationTime = notification => {
  if (!notification.last_activity_at) return '';
  return shortTimestamp(dynamicTime(notification.last_activity_at));
};

const closeMenu = () => {
  isOpen.value = false;
};

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    store.dispatch('notifications/get', { page: 1 });
  }
};

const onMarkAllRead = () => {
  if (!hasUnread.value) return;
  useTrack(ACCOUNT_EVENTS.MARK_AS_READ_NOTIFICATIONS);
  store.dispatch('notifications/readAll');
};

const openConversation = notification => {
  const {
    primary_actor_id: primaryActorId,
    primary_actor_type: primaryActorType,
    primary_actor: primaryActor,
    notification_type: notificationType,
  } = notification;

  const conversationId = primaryActor?.id;
  if (!conversationId) {
    closeMenu();
    return;
  }

  useTrack(ACCOUNT_EVENTS.OPEN_CONVERSATION_VIA_NOTIFICATION, {
    notificationType,
  });

  store.dispatch('notifications/read', {
    id: notification.id,
    primaryActorId,
    primaryActorType,
    unreadCount: meta.value.unreadCount,
  });

  closeMenu();
  router.push(
    `/app/accounts/${accountId.value}/conversations/${conversationId}`
  );
};
</script>

<template>
  <div v-on-click-outside="closeMenu" class="relative">
    <button
      type="button"
      class="relative inline-flex size-9 items-center justify-center rounded-full border border-input bg-background text-muted-foreground shadow-xs transition-colors hover:border-transparent hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      :class="{ 'bg-accent text-accent-foreground': isOpen }"
      :aria-label="t('SIDEBAR.NOTIFICATIONS')"
      :aria-expanded="isOpen"
      @click="toggleMenu"
    >
      <span class="i-lucide-bell size-4" />
      <span
        v-if="hasUnread"
        class="absolute top-1 right-1 size-2 rounded-full bg-destructive"
      />
      <span class="sr-only">{{ t('SIDEBAR.NOTIFICATIONS') }}</span>
    </button>

    <div
      v-if="isOpen"
      class="absolute top-full z-50 mt-1 w-[360px] overflow-hidden rounded-xl border border-border bg-popover text-popover-foreground shadow-sm ltr:right-0 rtl:left-0"
    >
      <div class="flex items-center justify-between px-4 py-3">
        <span class="text-sm font-semibold text-foreground">
          {{ t('NOTIFICATIONS_PAGE.HEADER') }}
        </span>
        <button
          type="button"
          class="text-xs text-muted-foreground transition-colors hover:text-foreground disabled:opacity-40"
          :disabled="!hasUnread || uiFlags.isUpdating"
          @click="onMarkAllRead"
        >
          {{ t('INBOX.MENU_ITEM.MARK_ALL_READ') }}
        </button>
      </div>

      <div class="max-h-[360px] overflow-y-auto">
        <div
          v-if="showLoading"
          class="border-t border-border px-4 py-6 text-center text-xs text-muted-foreground"
        >
          {{ t('NOTIFICATIONS_PAGE.LIST.LOADING_MESSAGE') }}
        </div>
        <div
          v-else-if="isEmpty"
          class="border-t border-border px-4 py-6 text-center text-xs text-muted-foreground"
        >
          {{ t('NOTIFICATIONS_PAGE.LIST.404') }}
        </div>
        <button
          v-for="notification in previewNotifications"
          :key="notification.id"
          type="button"
          class="flex w-full flex-col gap-0.5 border-t border-border px-4 py-3 text-left transition-colors hover:bg-accent"
          :class="{ 'bg-muted': !notification.read_at }"
          @click="openConversation(notification)"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="truncate text-sm font-medium text-foreground">
              {{ notificationTitle(notification) }}
            </span>
            <span class="shrink-0 text-xs text-muted-foreground">
              {{ notificationTime(notification) }}
            </span>
          </div>
          <span class="line-clamp-2 text-xs text-muted-foreground">
            {{ notificationBody(notification) }}
          </span>
        </button>
      </div>
    </div>
  </div>
</template>
