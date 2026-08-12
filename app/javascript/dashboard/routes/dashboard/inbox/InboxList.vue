<script setup>
import { computed, ref, watch, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import wootConstants from 'dashboard/constants/globals';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

import InboxCard from 'dashboard/components-next/Inbox/InboxCard.vue';
import InboxListHeader from './components/InboxListHeader.vue';
import InboxSidebarNav from './components/InboxSidebarNav.vue';
import InboxEmptyState from './InboxEmptyState.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();

const notificationList = ref(null);
const page = ref(1);
const status = ref('');
const type = ref('');
const sortOrder = ref(wootConstants.INBOX_SORT_BY.NEWEST);
const isInboxContextMenuOpen = ref(false);
const activeView = ref('all');
const activeStatusTab = ref('new');
const showListFilterMenu = ref(false);
const showTabMoreMenu = ref(false);
const selectedIds = ref(new Set());

// Starred conversation ids are persisted in UI settings so favourites survive
// reloads and stay in sync across the agent's sessions.
const starredIds = computed(
  () => new Set(uiSettings.value?.starred_conversation_ids || [])
);

const STATUS_TAB_MAP = {
  new: 'open',
  'in-progress': 'pending',
  'on-hold': 'snoozed',
  closed: 'resolved',
};

const infiniteLoaderOptions = computed(() => ({
  root: notificationList.value,
  rootMargin: '100px 0px 100px 0px',
}));

const meta = useMapGetter('notifications/getMeta');
const uiFlags = useMapGetter('notifications/getUIFlags');
const records = useMapGetter('notifications/getFilteredNotificationsV4');
const inboxesList = useMapGetter('inboxes/getInboxes');
const currentUser = useMapGetter('getCurrentUser');

const currentConversationId = computed(() => Number(route.params.id));

const inboxFilters = computed(() => ({
  page: page.value,
  status: status.value,
  type: type.value,
  sortOrder: sortOrder.value,
}));

const allNotifications = computed(() => records.value(inboxFilters.value));

const channelsForNav = computed(() => {
  const preferred = [
    INBOX_TYPES.WHATSAPP,
    INBOX_TYPES.EMAIL,
    INBOX_TYPES.INSTAGRAM,
    INBOX_TYPES.WEB,
    INBOX_TYPES.SMS,
    INBOX_TYPES.TWILIO,
  ];
  const list = (inboxesList.value || []).filter(inbox => {
    const channelType = inbox.channelType || inbox.channel_type;
    return preferred.includes(channelType);
  });

  return list.map(inbox => {
    const count = allNotifications.value.filter(
      n => n.primaryActor?.inboxId === inbox.id
    ).length;
    return { ...inbox, count };
  });
});

const viewCounts = computed(() => {
  const items = allNotifications.value;
  const currentUserId = currentUser.value?.id;
  return {
    all: meta.value?.count ?? items.length,
    unread: meta.value?.unreadCount ?? items.filter(n => !n.readAt).length,
    assigned: items.filter(
      n =>
        n.notificationType === 'conversation_assignment' ||
        n.primaryActor?.meta?.assignee?.id === currentUserId
    ).length,
    // Counted from the loaded list rather than the saved id set, so the badge
    // always matches what the Starred view actually renders.
    starred: items.filter(n => starredIds.value.has(n.primaryActor?.id)).length,
    snoozed: items.filter(
      n => n.snoozedUntil || n.primaryActor?.status === 'snoozed'
    ).length,
    archived: items.filter(n => n.primaryActor?.status === 'resolved').length,
    spam: 0,
  };
});

const filteredNotifications = computed(() => {
  let items = allNotifications.value;
  const view = activeView.value;
  const currentUserId = currentUser.value?.id;

  if (view === 'unread') {
    items = items.filter(n => !n.readAt);
  } else if (view === 'assigned') {
    items = items.filter(
      n =>
        n.notificationType === 'conversation_assignment' ||
        n.primaryActor?.meta?.assignee?.id === currentUserId
    );
  } else if (view === 'starred') {
    items = items.filter(n => starredIds.value.has(n.primaryActor?.id));
  } else if (view === 'snoozed') {
    items = items.filter(
      n => n.snoozedUntil || n.primaryActor?.status === 'snoozed'
    );
  } else if (view === 'archived') {
    items = items.filter(n => n.primaryActor?.status === 'resolved');
  } else if (view === 'spam') {
    items = [];
  } else if (view.startsWith('inbox:')) {
    const inboxId = Number(view.replace('inbox:', ''));
    items = items.filter(n => n.primaryActor?.inboxId === inboxId);
  }

  // Starred is an explicit user-curated view: showing it through the status
  // tabs would hide favourites whose conversation sits in another status.
  const statusKey = STATUS_TAB_MAP[activeStatusTab.value];
  if (
    statusKey &&
    view !== 'snoozed' &&
    view !== 'archived' &&
    view !== 'starred'
  ) {
    items = items.filter(n => {
      const conversationStatus = n.primaryActor?.status;
      if (!conversationStatus) return activeStatusTab.value === 'new';
      return conversationStatus === statusKey;
    });
  }

  return items;
});

const showEndOfList = computed(() => {
  return uiFlags.value.isAllNotificationsLoaded && !uiFlags.value.isFetching;
});

const showEmptyState = computed(() => {
  return !uiFlags.value.isFetching && !allNotifications.value.length;
});

const showFilledList = computed(() => {
  return !currentConversationId.value && !showEmptyState.value;
});

const statusTabs = computed(() => [
  { value: 'new', label: t('INBOX.TABS.NEW') },
  { value: 'in-progress', label: t('INBOX.TABS.IN_PROGRESS') },
  { value: 'on-hold', label: t('INBOX.TABS.ON_HOLD') },
  { value: 'closed', label: t('INBOX.TABS.CLOSED') },
]);

const isStarred = notificationItem =>
  starredIds.value.has(notificationItem.primaryActor?.id);

const toggleStar = notificationItem => {
  const next = new Set(starredIds.value);
  const conversationId = notificationItem.primaryActor?.id;
  if (!conversationId) return;

  if (next.has(conversationId)) next.delete(conversationId);
  else next.add(conversationId);
  updateUISettings({ starred_conversation_ids: [...next] });
};

const toggleSelect = notificationItem => {
  const next = new Set(selectedIds.value);
  if (next.has(notificationItem.id)) next.delete(notificationItem.id);
  else next.add(notificationItem.id);
  selectedIds.value = next;
};

const selectedCount = computed(() => selectedIds.value.size);

const allSelected = computed(
  () =>
    filteredNotifications.value.length > 0 &&
    selectedCount.value === filteredNotifications.value.length
);

const toggleSelectAll = () => {
  selectedIds.value = allSelected.value
    ? new Set()
    : new Set(filteredNotifications.value.map(item => item.id));
};

const selectedNotifications = () =>
  filteredNotifications.value.filter(item => selectedIds.value.has(item.id));

// The store derives the next unread count from the value handed to it, so these
// run sequentially and re-read `meta` each pass; dispatching in parallel would
// make every call start from the same stale count.
const markSelectedAsRead = async () => {
  const items = selectedNotifications().filter(item => !item.readAt);
  // eslint-disable-next-line no-restricted-syntax
  for (const { id, primaryActorId, primaryActorType } of items) {
    // eslint-disable-next-line no-await-in-loop
    await store.dispatch('notifications/read', {
      id,
      primaryActorId,
      primaryActorType,
      unreadCount: meta.value.unreadCount,
    });
  }
  selectedIds.value = new Set();
  store.dispatch('notifications/unReadCount');
  useAlert(t('INBOX.ALERTS.MARK_AS_READ'));
};

const deleteSelected = async () => {
  const items = selectedNotifications();
  // eslint-disable-next-line no-restricted-syntax
  for (const notification of items) {
    // eslint-disable-next-line no-await-in-loop
    await store.dispatch('notifications/delete', {
      notification,
      count: meta.value.count,
      unreadCount: meta.value.unreadCount,
    });
  }
  selectedIds.value = new Set();
  store.dispatch('notifications/unReadCount');
  useAlert(t('INBOX.ALERTS.DELETE'));
};

const fetchNotifications = () => {
  page.value = 1;
  store.dispatch('notifications/clear');
  store.dispatch('notifications/index', inboxFilters.value);
};

const scrollActiveIntoView = () => {
  const activeEl = notificationList.value?.querySelector('.inbox-card.active');
  activeEl?.scrollIntoView({ block: 'center', behavior: 'smooth' });
};

const redirectToInbox = () => {
  if (route.name === 'inbox_view') return;
  router.replace({ name: 'inbox_view' });
};

const loadMoreNotifications = () => {
  if (uiFlags.value.isAllNotificationsLoaded) return;
  page.value += 1;
  store.dispatch('notifications/index', {
    page: page.value,
    status: status.value,
    type: type.value,
    sortOrder: sortOrder.value,
  });
};

const markNotificationAsRead = async notificationItem => {
  useTrack(INBOX_EVENTS.MARK_NOTIFICATION_AS_READ);
  const { id, primaryActorId, primaryActorType } = notificationItem;
  try {
    await store.dispatch('notifications/read', {
      id,
      primaryActorId,
      primaryActorType,
      unreadCount: meta.value.unreadCount,
    });
    useAlert(t('INBOX.ALERTS.MARK_AS_READ'));
    store.dispatch('notifications/unReadCount');
  } catch {
    // error
  }
};

const markNotificationAsUnRead = async notificationItem => {
  useTrack(INBOX_EVENTS.MARK_NOTIFICATION_AS_UNREAD);
  redirectToInbox();
  const { id } = notificationItem;
  try {
    await store.dispatch('notifications/unread', { id });
    useAlert(t('INBOX.ALERTS.MARK_AS_UNREAD'));
    store.dispatch('notifications/unReadCount');
  } catch {
    // error
  }
};

const deleteNotification = async notificationItem => {
  useTrack(INBOX_EVENTS.DELETE_NOTIFICATION);
  redirectToInbox();
  try {
    await store.dispatch('notifications/delete', {
      notification: notificationItem,
      unreadCount: meta.value.unreadCount,
      count: meta.value.count,
    });
    useAlert(t('INBOX.ALERTS.DELETE'));
  } catch {
    // error
  }
};

const onFilterChange = option => {
  const { STATUS, TYPE, SORT_ORDER } = wootConstants.INBOX_FILTER_TYPE;
  if (option.type === STATUS) {
    status.value = option.selected ? option.key : '';
  }
  if (option.type === TYPE) {
    type.value = option.selected ? option.key : '';
  }
  if (option.type === SORT_ORDER) {
    sortOrder.value = option.key;
  }
  fetchNotifications();
};

const setSavedFilter = () => {
  const { inbox_filter_by: filterBy = {} } = uiSettings.value;
  const { status: savedStatus, type: savedType, sort_by: sortBy } = filterBy;
  status.value = savedStatus;
  type.value = savedType;
  sortOrder.value = sortBy || wootConstants.INBOX_SORT_BY.NEWEST;
  store.dispatch('notifications/setNotificationFilters', inboxFilters.value);
};

const onSelectView = viewId => {
  activeView.value = viewId;
  if (viewId === 'snoozed') {
    activeStatusTab.value = 'on-hold';
  } else if (viewId === 'archived') {
    activeStatusTab.value = 'closed';
  }
  redirectToInbox();
};

const openConversation = async notificationItem => {
  const {
    id,
    primaryActorId,
    primaryActorType,
    primaryActor: { inboxId, id: conversationId },
    notificationType,
  } = notificationItem;

  if (route.params.id === String(conversationId)) return;

  useTrack(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, {
    notificationType,
  });

  try {
    await store.dispatch('notifications/read', {
      id,
      primaryActorId,
      primaryActorType,
      unreadCount: meta.value.unreadCount,
    });
    store.dispatch('notifications/unReadCount');
    router.push({
      name: 'inbox_view_conversation',
      params: { inboxId, type: 'conversation', id: conversationId },
    });
  } catch {
    // error
  }
};

const applyListFilter = key => {
  showListFilterMenu.value = false;
  if (key === 'assigned') onSelectView('assigned');
  if (key === 'oldest') {
    onFilterChange({
      type: wootConstants.INBOX_FILTER_TYPE.SORT_ORDER,
      key: wootConstants.INBOX_SORT_BY.OLDEST,
    });
  }
  if (key === 'archived') onSelectView('archived');
  if (key === 'snoozed') onSelectView('snoozed');
  if (key === 'spam') onSelectView('spam');
};

watch(
  inboxFilters,
  (newVal, oldVal) => {
    if (newVal !== oldVal) {
      store.dispatch('notifications/updateNotificationFilters', newVal);
    }
  },
  { deep: true }
);

watch(currentConversationId, () => {
  nextTick(scrollActiveIntoView);
});

onMounted(() => {
  scrollActiveIntoView();
  setSavedFilter();
  fetchNotifications();
  store.dispatch('inboxes/get');
});
</script>

<template>
  <section
    class="flex w-full h-full bg-background text-foreground animate-in fade-in duration-300 overflow-hidden"
  >
    <!-- Middle Inbox sidebar -->
    <aside
      class="w-[260px] border-r border-border flex flex-col shrink-0 bg-card"
      :class="currentConversationId ? 'hidden xl:flex' : 'flex'"
    >
      <InboxListHeader
        :is-context-menu-open="isInboxContextMenuOpen"
        @filter="onFilterChange"
        @redirect="redirectToInbox"
      />
      <InboxSidebarNav
        :active-view="activeView"
        :view-counts="viewCounts"
        :channels="channelsForNav"
        @select="onSelectView"
      />
    </aside>

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <!-- Filled conversations list -->
      <div
        v-if="showFilledList"
        class="flex-1 flex flex-col bg-card overflow-hidden"
      >
        <div
          class="flex items-center justify-between px-4 border-b border-border h-14 shrink-0"
        >
          <div
            class="flex items-center justify-start gap-6 h-14 flex-1 min-w-0 overflow-hidden"
            role="tablist"
          >
            <button
              v-for="tab in statusTabs"
              :key="tab.value"
              type="button"
              role="tab"
              :aria-selected="activeStatusTab === tab.value"
              class="relative h-14 px-1 text-sm font-medium transition-colors shrink-0"
              :class="
                activeStatusTab === tab.value
                  ? 'text-foreground font-semibold'
                  : 'text-muted-foreground hover:text-foreground'
              "
              @click="activeStatusTab = tab.value"
            >
              {{ tab.label }}
              <!-- Active Bottom Border Indicator -->
              <span
                v-if="activeStatusTab === tab.value"
                class="absolute bottom-0 left-0 right-0 h-0.5 rounded-t-full bg-primary"
              />
            </button>
          </div>

          <div class="flex items-center gap-1 pl-4 shrink-0">
            <RelayButton
              v-if="filteredNotifications.length"
              variant="ghost"
              size="sm"
              class="h-8 text-xs text-muted-foreground hover:text-foreground"
              @click="toggleSelectAll"
            >
              {{
                allSelected
                  ? t('INBOX.LIST.DESELECT_ALL')
                  : t('INBOX.LIST.SELECT_ALL')
              }}
            </RelayButton>
            <template v-if="selectedCount > 0">
              <RelayButton
                variant="ghost"
                size="sm"
                class="h-8 text-xs text-muted-foreground hover:text-foreground"
                @click="markSelectedAsRead"
              >
                <span class="i-lucide-check-check size-3.5 mr-1" />
                {{ t('INBOX.LIST.MARK_READ') }}
              </RelayButton>
              <RelayButton
                variant="ghost"
                size="sm"
                class="h-8 text-xs text-destructive hover:text-destructive hover:bg-destructive/10"
                @click="deleteSelected"
              >
                <span class="i-lucide-trash-2 size-3.5 mr-1" />
                {{ t('INBOX.LIST.DELETE') }}
              </RelayButton>
            </template>
            <div class="relative">
              <RelayButton
                variant="outline"
                size="icon"
                class="h-8 w-8 shrink-0"
                :aria-label="t('INBOX.LIST.FILTER_TOOLTIP')"
                @click="showListFilterMenu = !showListFilterMenu"
              >
                <span class="i-lucide-list-filter size-4" />
              </RelayButton>
              <div
                v-if="showListFilterMenu"
                v-on-clickaway="() => (showListFilterMenu = false)"
                class="absolute right-0 mt-1.5 z-50 w-48 rounded-md border border-border bg-popover p-1 shadow-md"
              >
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
                  @click="applyListFilter('assigned')"
                >
                  <span class="i-lucide-user size-4 text-muted-foreground" />
                  {{ t('INBOX.FILTER_MENU.ASSIGNED_TO_ME') }}
                </button>
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
                  @click="applyListFilter('oldest')"
                >
                  <span class="i-lucide-clock size-4 text-muted-foreground" />
                  {{ t('INBOX.FILTER_MENU.OLDEST_FIRST') }}
                </button>
                <div class="my-1 h-px bg-border" />
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
                  @click="applyListFilter('archived')"
                >
                  <span class="i-lucide-archive size-4 text-muted-foreground" />
                  {{ t('INBOX.FILTER_MENU.ARCHIVED') }}
                </button>
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted text-foreground"
                  @click="applyListFilter('snoozed')"
                >
                  <span
                    class="i-lucide-alarm-clock size-4 text-muted-foreground"
                  />
                  {{ t('INBOX.FILTER_MENU.SNOOZED') }}
                </button>
              </div>
            </div>
            <div class="relative shrink-0">
              <RelayButton
                variant="ghost"
                size="icon"
                class="h-8 w-8 text-muted-foreground"
                :aria-label="t('INBOX.LIST.MORE_OPTIONS')"
                @click="showTabMoreMenu = !showTabMoreMenu"
              >
                <span class="i-lucide-ellipsis size-4" />
              </RelayButton>
              <div
                v-if="showTabMoreMenu"
                v-on-clickaway="() => (showTabMoreMenu = false)"
                class="absolute right-0 mt-1.5 z-50 w-40 rounded-md border border-border bg-popover p-1 shadow-md"
              >
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted"
                  @click="
                    applyListFilter('archived');
                    showTabMoreMenu = false;
                  "
                >
                  <span class="i-lucide-archive size-4 text-muted-foreground" />
                  {{ t('INBOX.FILTER_MENU.ARCHIVED') }}
                </button>
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted"
                  @click="
                    applyListFilter('snoozed');
                    showTabMoreMenu = false;
                  "
                >
                  <span
                    class="i-lucide-alarm-clock size-4 text-muted-foreground"
                  />
                  {{ t('INBOX.FILTER_MENU.SNOOZED') }}
                </button>
                <div class="my-1 h-px bg-border" />
                <button
                  type="button"
                  class="w-full flex items-center gap-2 px-2 py-1.5 text-sm rounded-sm hover:bg-muted"
                  @click="
                    applyListFilter('spam');
                    showTabMoreMenu = false;
                  "
                >
                  <span class="i-lucide-ban size-4 text-muted-foreground" />
                  {{ t('INBOX.FILTER_MENU.SPAM') }}
                </button>
              </div>
            </div>
          </div>
        </div>

        <div
          ref="notificationList"
          class="flex-1 overflow-y-auto overflow-x-hidden min-h-0"
        >
          <InboxCard
            v-for="notificationItem in filteredNotifications"
            :key="notificationItem.id"
            :inbox-item="notificationItem"
            :is-active="
              currentConversationId === notificationItem.primaryActor?.id
            "
            :is-starred="isStarred(notificationItem)"
            :is-selected="selectedIds.has(notificationItem.id)"
            class="inbox-card"
            :class="{
              active:
                currentConversationId === notificationItem.primaryActor?.id,
            }"
            @mark-notification-as-read="markNotificationAsRead"
            @mark-notification-as-un-read="markNotificationAsUnRead"
            @delete-notification="deleteNotification"
            @toggle-star="toggleStar"
            @toggle-select="toggleSelect"
            @context-menu-open="isInboxContextMenuOpen = true"
            @context-menu-close="isInboxContextMenuOpen = false"
            @click="openConversation(notificationItem)"
          />

          <div v-if="uiFlags.isFetching" class="flex justify-center my-4">
            <Spinner class="text-primary" />
          </div>

          <p
            v-if="!uiFlags.isFetching && !filteredNotifications.length"
            class="p-4 text-sm font-medium text-center text-muted-foreground"
          >
            {{ t('INBOX.LIST.NO_NOTIFICATIONS') }}
          </p>

          <div
            v-if="!showEndOfList && !uiFlags.isFetching"
            class="py-4 flex justify-center"
          >
            <button
              type="button"
              class="text-xs font-medium text-muted-foreground hover:text-foreground hover:underline transition-colors"
              @click="loadMoreNotifications"
            >
              {{ t('INBOX.LIST.LOAD_MORE') }}
            </button>
            <IntersectionObserver
              :options="infiniteLoaderOptions"
              @observed="loadMoreNotifications"
            />
          </div>
        </div>
      </div>

      <!-- Empty state (no notifications) -->
      <InboxEmptyState v-else-if="!currentConversationId && showEmptyState" />

      <!-- Conversation detail -->
      <router-view v-else-if="currentConversationId" />

      <!-- Loading while first fetch -->
      <div
        v-else-if="uiFlags.isFetching"
        class="flex-1 flex items-center justify-center"
      >
        <Spinner class="text-primary" />
      </div>
    </div>

    <CmdBarConversationSnooze />
  </section>
</template>
