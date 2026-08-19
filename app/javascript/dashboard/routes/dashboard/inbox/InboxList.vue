<script setup>
import { computed, ref, watch, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import wootConstants from 'dashboard/constants/globals';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import ConversationApi from 'dashboard/api/inbox/conversation';

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
const showListFilterMenu = ref(false);
const showTabMoreMenu = ref(false);

// The Inbox lists the current user's assigned conversations. We keep the list in
// local state (not the global `conversations` store) so this view never clobbers
// the main Conversations page's filters/list, and vice versa.
const items = ref([]);
const isFetching = ref(false);
const totalCount = ref(0);

// Starred conversation ids are persisted in UI settings so favourites survive
// reloads and stay in sync across the agent's sessions.
const starredIds = computed(
  () => new Set(uiSettings.value?.starred_conversation_ids || [])
);

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

const isAllLoaded = computed(() => items.value.length >= totalCount.value);

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

const fetchConversations = async ({ append = false } = {}) => {
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
    const count = items.value.filter(
      n => n.primaryActor?.inboxId === inbox.id
    ).length;
    return { ...inbox, count };
  });
});

const viewCounts = computed(() => {
  const list = items.value;

  return {
    // All the loaded rows are the current user's conversations for the active
    // status tab; the total comes from the API's `mine_count`.
    all: totalCount.value || list.length,
    unread: list.filter(n => !n.readAt).length,
    assigned: list.length,
    starred: list.filter(n => starredIds.value.has(n.primaryActor?.id)).length,
    snoozed: list.filter(n => n.primaryActor?.status === 'snoozed').length,
    archived: list.filter(n => n.primaryActor?.status === 'resolved').length,
    spam: 0,
  };
});

const filteredConversations = computed(() => {
  let list = items.value;
  const view = activeView.value;

  if (view === 'unread') {
    list = list.filter(n => !n.readAt);
  } else if (view === 'starred') {
    list = list.filter(n => starredIds.value.has(n.primaryActor?.id));
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

const showEndOfList = computed(() => isAllLoaded.value && !isFetching.value);

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

// Switching the status tab changes which conversation status we fetch.
watch(activeStatusTab, () => reloadConversations());

watch(currentConversationId, () => {
  nextTick(scrollActiveIntoView);
});

onMounted(() => {
  scrollActiveIntoView();
  setSavedFilter();
  reloadConversations();
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
      <InboxListHeader @filter="onFilterChange" @redirect="redirectToInbox" />
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
            v-for="notificationItem in filteredConversations"
            :key="notificationItem.id"
            :inbox-item="notificationItem"
            :is-active="
              currentConversationId === notificationItem.primaryActor?.id
            "
            :is-starred="isStarred(notificationItem)"
            class="inbox-card"
            :class="{
              active:
                currentConversationId === notificationItem.primaryActor?.id,
            }"
            @toggle-star="toggleStar"
            @click="openConversation(notificationItem)"
          />

          <div v-if="isFetching" class="flex justify-center my-4">
            <Spinner class="text-primary" />
          </div>

          <div
            v-if="!isFetching && !filteredConversations.length"
            class="flex items-center justify-center py-16"
          >
            <InboxEmptyState />
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
