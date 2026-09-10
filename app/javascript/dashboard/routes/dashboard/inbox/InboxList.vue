<script setup>
import { computed, ref, watch, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import wootConstants from 'dashboard/constants/globals';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import ConversationApi from 'dashboard/api/inbox/conversation';
import {
  mineCountFromMeta,
  mineCountFromList,
  unreadCountFromConversations,
  inboxesForChannelNav,
  viewCountsFromTotals,
  mergeInboxCounts,
} from './helpers/inboxNavTotals';

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
const sortOrder = ref(wootConstants.INBOX_SORT_BY.NEWEST);
const activeView = ref('all');
const activeStatusTab = ref('new');
// The Inbox lists the current user's assigned conversations. We keep the list in
// local state (not the global `conversations` store) so this view never clobbers
// the main Conversations page's filters/list, and vice versa.
const items = ref([]);
const isFetching = ref(false);
const totalCount = ref(0);
// Sidebar badges must stay as all-status totals. They used to be derived from
// `items`, which is refetched per New / In Progress / On Hold / Closed tab.
const navTotals = ref({
  all: 0,
  unread: 0,
  snoozed: 0,
  archived: 0,
  byInbox: {},
});

// Starred conversation ids are persisted in UI settings so favourites survive
// reloads and stay in sync across the agent's sessions. Always coerce to
// Number — Conversations starring stores numbers, JSONB may round-trip strings.
const starredIds = computed(() => {
  const ids = (uiSettings.value?.starred_conversation_ids || []).map(Number);
  return new Set(ids.filter(id => Number.isFinite(id) && id > 0));
});

const conversationIdOf = item => Number(item?.primaryActor?.id);

const STATUS_TAB_MAP = {
  new: wootConstants.STATUS_TYPE.OPEN,
  'in-progress': wootConstants.STATUS_TYPE.PENDING,
  'on-hold': wootConstants.STATUS_TYPE.SNOOZED,
  closed: wootConstants.STATUS_TYPE.RESOLVED,
};

const infiniteLoaderOptions = computed(() => ({
  root: notificationList.value,
  rootMargin: '100px 0px 100px 0px',
}));

const inboxesList = useMapGetter('inboxes/getInboxes');

const currentConversationId = computed(() => Number(route.params.id));

const statusForFetch = computed(
  () => STATUS_TAB_MAP[activeStatusTab.value] || wootConstants.STATUS_TYPE.OPEN
);

const sortByParam = computed(() =>
  sortOrder.value === wootConstants.INBOX_SORT_BY.OLDEST
    ? wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_ASC
    : wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC
);

const isAllLoaded = computed(
  () => activeView.value === 'starred' || items.value.length >= totalCount.value
);

// Adapt an API conversation into the shape InboxCard expects (the conversation
// is the notification's "primary actor" in the original notification-driven UI).
const adaptConversation = conversation => {
  const camelized = useCamelCase(conversation, { deep: true });
  return {
    id: camelized.id,
    primaryActorId: camelized.id,
    primaryActorType: 'Conversation',
    primaryActor: camelized,
    notificationType: 'conversation_assignment',
    lastActivityAt: camelized.lastActivityAt,
    readAt: camelized.unreadCount ? null : new Date().toISOString(),
  };
};

const isGoneStarredError = error => {
  const status = error?.response?.status;
  return status === 404 || status === 403;
};

// Drop deleted/inaccessible ids so the sidebar badge matches the Starred list.
const pruneStarredIds = missingIds => {
  if (!missingIds.length) return;
  const drop = new Set(missingIds.map(Number));
  const next = [...starredIds.value].filter(id => !drop.has(id));
  updateUISettings({ starred_conversation_ids: next });
};

const resolveStarredConversations = async () => {
  const ids = [...starredIds.value];
  if (!ids.length) return [];

  const results = await Promise.all(
    ids.map(id =>
      ConversationApi.show(id)
        .then(response => ({ id, conversation: response.data }))
        .catch(error => ({
          id,
          conversation: null,
          missing: isGoneStarredError(error),
        }))
    )
  );

  pruneStarredIds(
    results.filter(result => result.missing).map(result => result.id)
  );

  return results.map(result => result.conversation).filter(Boolean);
};

const fetchStarredConversations = async () => {
  isFetching.value = true;
  try {
    const conversations = await resolveStarredConversations();
    items.value = conversations.map(adaptConversation);
    totalCount.value = items.value.length;
  } catch {
    items.value = [];
    totalCount.value = 0;
  } finally {
    isFetching.value = false;
  }
};

const fetchConversations = async ({ append = false } = {}) => {
  if (activeView.value === 'starred' && !append) {
    await fetchStarredConversations();
    return;
  }

  isFetching.value = true;
  try {
    const {
      data: { data: { payload = [], meta = {} } = {} },
    } = await ConversationApi.get({
      assigneeType: wootConstants.ASSIGNEE_TYPE.ME,
      status: statusForFetch.value,
      page: page.value,
      sortBy: sortByParam.value,
    });
    const adapted = payload.map(adaptConversation);
    items.value = append ? [...items.value, ...adapted] : adapted;
    // An empty appended page means we've reached the end regardless of what the
    // server's mine_count says, so clamp to what we actually loaded.
    totalCount.value =
      append && !payload.length
        ? items.value.length
        : (meta.mine_count ?? items.value.length);
  } catch (error) {
    if (!append) items.value = [];
  } finally {
    isFetching.value = false;
  }
};

const reloadConversations = () => {
  page.value = 1;
  fetchConversations();
};

let navTotalsRequestId = 0;

const fetchNavTotals = async () => {
  const assigneeType = wootConstants.ASSIGNEE_TYPE.ME;
  const statusAll = wootConstants.STATUS_TYPE.ALL;
  const channelInboxes = inboxesForChannelNav(inboxesList.value);
  navTotalsRequestId += 1;
  const requestId = navTotalsRequestId;

  try {
    const [allList, snoozedMeta, archivedMeta, ...inboxMetas] =
      await Promise.all([
        ConversationApi.get({
          assigneeType,
          status: statusAll,
          page: 1,
        }),
        ConversationApi.meta({
          assigneeType,
          status: wootConstants.STATUS_TYPE.SNOOZED,
        }),
        ConversationApi.meta({
          assigneeType,
          status: wootConstants.STATUS_TYPE.RESOLVED,
        }),
        ...channelInboxes.map(inbox =>
          ConversationApi.meta({
            assigneeType,
            status: statusAll,
            inboxId: inbox.id,
          })
        ),
      ]);

    const payload = allList?.data?.data?.payload || [];
    const byInbox = {};
    channelInboxes.forEach((inbox, index) => {
      byInbox[inbox.id] = mineCountFromMeta(inboxMetas[index]);
    });

    if (requestId !== navTotalsRequestId) return;

    navTotals.value = {
      all: mineCountFromList(allList) || payload.length,
      // ponytail: unread is first page of assigned conversations (status=all).
      // Upgrade: add unread_count to GET /conversations/meta.
      unread: unreadCountFromConversations(payload),
      snoozed: mineCountFromMeta(snoozedMeta),
      archived: mineCountFromMeta(archivedMeta),
      byInbox,
    };
  } catch {
    // Keep the last totals rather than flashing zeros on a failed refresh.
  }
};

const channelsForNav = computed(() =>
  mergeInboxCounts(
    inboxesForChannelNav(inboxesList.value),
    navTotals.value.byInbox
  )
);

const activeChannelName = computed(() => {
  if (!activeView.value.startsWith('inbox:')) return '';
  const inboxId = Number(activeView.value.replace('inbox:', ''));
  const inbox = channelsForNav.value.find(
    channel => Number(channel.id) === inboxId
  );
  return inbox?.name || inbox?.phoneNumber || inbox?.email || '';
});

const filteredConversations = computed(() => {
  let list = items.value;
  const view = activeView.value;

  if (view === 'unread') {
    list = list.filter(n => !n.readAt);
  } else if (view === 'starred') {
    list = list.filter(n => starredIds.value.has(conversationIdOf(n)));
  } else if (view === 'spam') {
    list = [];
  } else if (view.startsWith('inbox:')) {
    const inboxId = Number(view.replace('inbox:', ''));
    list = list.filter(n => n.primaryActor?.inboxId === inboxId);
  }
  // 'all'/'assigned' show every loaded row; 'snoozed'/'archived' are handled by
  // the status tab, which refetches with the matching conversation status.

  return list;
});

const viewCounts = computed(() =>
  viewCountsFromTotals({
    all: navTotals.value.all,
    unread: navTotals.value.unread,
    starred:
      activeView.value === 'starred' && !isFetching.value
        ? filteredConversations.value.length
        : starredIds.value.size,
    snoozed: navTotals.value.snoozed,
    archived: navTotals.value.archived,
  })
);

const showEndOfList = computed(() => isAllLoaded.value && !isFetching.value);

const statusTabs = computed(() => [
  { value: 'new', label: t('INBOX.TABS.NEW') },
  { value: 'in-progress', label: t('INBOX.TABS.IN_PROGRESS') },
  { value: 'on-hold', label: t('INBOX.TABS.ON_HOLD') },
  { value: 'closed', label: t('INBOX.TABS.CLOSED') },
]);

const isStarred = notificationItem =>
  starredIds.value.has(conversationIdOf(notificationItem));

const toggleStar = notificationItem => {
  const conversationId = conversationIdOf(notificationItem);
  if (!conversationId) return;

  const next = new Set(starredIds.value);
  if (next.has(conversationId)) next.delete(conversationId);
  else next.add(conversationId);
  updateUISettings({ starred_conversation_ids: [...next] });
};

const selectedIds = ref([]);

const visibleConversationIds = computed(() =>
  filteredConversations.value.map(conversationIdOf).filter(Boolean)
);

const allVisibleSelected = computed(
  () =>
    visibleConversationIds.value.length > 0 &&
    visibleConversationIds.value.every(id => selectedIds.value.includes(id))
);

const isSelected = notificationItem =>
  selectedIds.value.includes(conversationIdOf(notificationItem));

const toggleSelection = notificationItem => {
  const conversationId = conversationIdOf(notificationItem);
  if (!conversationId) return;
  selectedIds.value = selectedIds.value.includes(conversationId)
    ? selectedIds.value.filter(id => id !== conversationId)
    : [...selectedIds.value, conversationId];
};

const toggleSelectAll = () => {
  selectedIds.value = allVisibleSelected.value
    ? []
    : [...visibleConversationIds.value];
};

const markSelectedAsRead = async () => {
  const selected = filteredConversations.value.filter(item =>
    selectedIds.value.includes(conversationIdOf(item))
  );
  if (!selected.length) return;

  try {
    await Promise.all(
      selected.map(item =>
        store.dispatch('markMessagesRead', { id: item.primaryActor.id })
      )
    );
    const now = new Date().toISOString();
    const selectedSet = new Set(selectedIds.value);
    items.value = items.value.map(item =>
      selectedSet.has(conversationIdOf(item))
        ? { ...item, readAt: item.readAt || now }
        : item
    );
    selectedIds.value = [];
    useAlert(t('INBOX.ALERTS.MARK_ALL_READ'));
  } catch {
    useAlert(t('INBOX.ALERTS.MARK_AS_READ'));
  }
};

const deleteSelected = async () => {
  const ids = [...selectedIds.value];
  if (!ids.length) return;

  try {
    await Promise.all(ids.map(id => store.dispatch('deleteConversation', id)));
    const removed = new Set(ids);
    items.value = items.value.filter(
      item => !removed.has(conversationIdOf(item))
    );
    selectedIds.value = [];
    useAlert(t('INBOX.ALERTS.DELETE'));
  } catch {
    useAlert(t('INBOX.ALERTS.DELETE'));
  }
};

watch([activeView, activeStatusTab], () => {
  selectedIds.value = [];
});

const scrollActiveIntoView = () => {
  const activeEl = notificationList.value?.querySelector('.inbox-card.active');
  activeEl?.scrollIntoView({ block: 'center', behavior: 'smooth' });
};

const redirectToInbox = () => {
  if (route.name === 'inbox_view') return;
  router.replace({ name: 'inbox_view' });
};

const loadMoreConversations = () => {
  if (isAllLoaded.value || isFetching.value) return;
  page.value += 1;
  fetchConversations({ append: true });
};

const onFilterChange = option => {
  const { SORT_ORDER } = wootConstants.INBOX_FILTER_TYPE;
  if (option.type === SORT_ORDER) {
    sortOrder.value = option.key;
    reloadConversations();
  }
};

const onOptionClick = async key => {
  if (key !== 'mark_all_read') return;

  try {
    useTrack(INBOX_EVENTS.MARK_ALL_NOTIFICATIONS_AS_READ);
    await store.dispatch('notifications/readAll');
    const unread = items.value.filter(
      item => !item.readAt && item.primaryActor?.id
    );
    await Promise.all(
      unread.map(item =>
        store.dispatch('markMessagesRead', { id: item.primaryActor.id })
      )
    );
    items.value = items.value.map(item => ({
      ...item,
      readAt: item.readAt || new Date().toISOString(),
    }));
    useAlert(t('INBOX.ALERTS.MARK_ALL_READ'));
  } catch {
    // Notification store actions already flag UI errors; avoid a second toast.
  }
};

const setSavedFilter = () => {
  const { inbox_filter_by: filterBy = {} } = uiSettings.value;
  const { sort_by: sortBy } = filterBy;
  sortOrder.value =
    sortBy === wootConstants.INBOX_SORT_BY.OLDEST
      ? wootConstants.INBOX_SORT_BY.OLDEST
      : wootConstants.INBOX_SORT_BY.NEWEST;
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

const openConversation = notificationItem => {
  const {
    primaryActor: { inboxId, id: conversationId } = {},
    notificationType,
  } = notificationItem;

  if (!conversationId || route.params.id === String(conversationId)) return;

  useTrack(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, { notificationType });

  router.push({
    name: 'inbox_view_conversation',
    params: { inboxId, type: 'conversation', id: conversationId },
  });
};

// Switching the status tab changes which conversation status we fetch.
watch(activeStatusTab, () => {
  if (activeView.value === 'starred') return;
  reloadConversations();
});

watch(activeView, (view, previous) => {
  if (view === 'starred' || previous === 'starred') reloadConversations();
});

watch(currentConversationId, () => {
  nextTick(scrollActiveIntoView);
});

watch(inboxesList, fetchNavTotals, { immediate: true });

onMounted(() => {
  scrollActiveIntoView();
  setSavedFilter();
  reloadConversations();
  store.dispatch('inboxes/get');
  resolveStarredConversations();
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
        @filter="onFilterChange"
        @redirect="redirectToInbox"
        @option-click="onOptionClick"
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
      <!-- Conversations list: the status tabs stay mounted even when a tab has
           no conversations, so the empty state never hides them. -->
      <div
        v-if="!currentConversationId"
        class="flex-1 flex flex-col bg-card overflow-hidden"
      >
        <div
          class="flex h-14 shrink-0 items-center justify-between border-b border-border px-4"
        >
          <div
            class="flex h-14 min-w-0 flex-1 items-center justify-start gap-6 overflow-hidden"
            role="tablist"
          >
            <button
              v-for="tab in statusTabs"
              :key="tab.value"
              type="button"
              role="tab"
              :aria-selected="activeStatusTab === tab.value"
              class="relative h-14 shrink-0 px-1 text-sm font-medium transition-colors"
              :class="
                activeStatusTab === tab.value
                  ? 'text-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              "
              @click="activeStatusTab = tab.value"
            >
              {{ tab.label }}
              <span
                v-if="activeStatusTab === tab.value"
                class="absolute bottom-0 left-0 right-0 h-px rounded-t-full bg-primary"
              />
            </button>
          </div>
          <div class="flex shrink-0 items-center gap-2 pl-4">
            <RelayButton
              v-if="filteredConversations.length"
              variant="ghost"
              size="sm"
              class="mr-1 h-8 text-xs text-muted-foreground hover:text-foreground"
              @click="toggleSelectAll"
            >
              {{
                allVisibleSelected
                  ? t('INBOX.LIST.DESELECT_ALL')
                  : t('INBOX.LIST.SELECT_ALL')
              }}
            </RelayButton>
            <template v-if="selectedIds.length">
              <RelayButton
                variant="ghost"
                size="sm"
                class="h-8 text-xs text-muted-foreground hover:text-foreground"
                @click="markSelectedAsRead"
              >
                <span class="i-lucide-check-check size-3.5" />
                {{ t('INBOX.MENU_ITEM.MARK_ALL_READ') }}
              </RelayButton>
              <RelayButton
                variant="ghost"
                size="sm"
                class="h-8 text-xs text-destructive hover:bg-destructive/10 hover:text-destructive"
                @click="deleteSelected"
              >
                <span class="i-lucide-trash-2 size-3.5" />
                {{ t('INBOX.LIST.DELETE') }}
              </RelayButton>
            </template>
          </div>
        </div>

        <div
          ref="notificationList"
          class="flex min-h-0 flex-1 flex-col overflow-x-hidden overflow-y-auto"
        >
          <InboxCard
            v-for="notificationItem in filteredConversations"
            :key="notificationItem.id"
            :inbox-item="notificationItem"
            :is-active="
              currentConversationId === notificationItem.primaryActor?.id
            "
            :is-starred="isStarred(notificationItem)"
            :is-selected="isSelected(notificationItem)"
            class="inbox-card"
            :class="{
              active:
                currentConversationId === notificationItem.primaryActor?.id,
            }"
            @toggle-star="toggleStar"
            @toggle-select="toggleSelection"
            @click="openConversation(notificationItem)"
          />

          <div v-if="isFetching" class="flex justify-center my-4">
            <Spinner class="text-primary" />
          </div>

          <div
            v-if="!isFetching && !filteredConversations.length"
            class="m-auto flex w-full flex-1 items-center justify-center"
          >
            <InboxEmptyState
              :active-view="activeView"
              :channel-name="activeChannelName"
            />
          </div>

          <div
            v-if="!showEndOfList && !isFetching"
            class="py-4 flex justify-center"
          >
            <button
              type="button"
              class="text-xs font-medium text-muted-foreground hover:text-foreground hover:underline transition-colors"
              @click="loadMoreConversations"
            >
              {{ t('INBOX.LIST.LOAD_MORE') }}
            </button>
            <IntersectionObserver
              :options="infiniteLoaderOptions"
              @observed="loadMoreConversations"
            />
          </div>
        </div>
      </div>

      <!-- Conversation detail -->
      <router-view v-else />
    </div>

    <CmdBarConversationSnooze />
  </section>
</template>
