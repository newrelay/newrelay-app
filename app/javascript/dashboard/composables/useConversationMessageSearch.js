import { computed, nextTick, ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import MessageApi from 'dashboard/api/inbox/message';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const MIN_QUERY_LENGTH = 2;
const SEARCH_DEBOUNCE_MS = 250;

export function highlightSearchHtml(html, rawQuery) {
  const q = String(rawQuery || '').trim();
  if (!html || q.length < MIN_QUERY_LENGTH) return html;
  const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return String(html).replace(
    new RegExp(`(${escaped})(?![^<]*>)`, 'gi'),
    '<mark class="rounded-[2px] bg-warning/50 px-0.5 text-foreground">$1</mark>'
  );
}

const query = ref('');
const matchIds = ref([]);
const activeIndex = ref(0);
const isSearching = ref(false);
let searchRequestId = 0;
let debounceTimer = null;

export function useConversationMessageSearch() {
  const store = useStore();

  const matchCount = computed(() => matchIds.value.length);
  const activeMatchId = computed(
    () => matchIds.value[activeIndex.value] ?? null
  );
  const hasQuery = computed(
    () => query.value.trim().length >= MIN_QUERY_LENGTH
  );

  const reset = () => {
    searchRequestId += 1;
    clearTimeout(debounceTimer);
    query.value = '';
    matchIds.value = [];
    activeIndex.value = 0;
    isSearching.value = false;
  };

  const jumpToActive = async () => {
    const messageId = activeMatchId.value;
    if (!messageId) return;

    const chat = store.getters.getSelectedChat;
    const messages = chat?.messages || [];
    const alreadyLoaded = messages.some(message => message.id === messageId);

    if (!alreadyLoaded && messages.length) {
      const oldestId = Math.min(...messages.map(message => message.id));
      if (messageId < oldestId) {
        await store.dispatch('fetchPreviousMessages', {
          conversationId: chat.id,
          after: messageId,
          before: oldestId,
        });
      }
    }

    await nextTick();
    emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
  };

  const applyResults = async ids => {
    matchIds.value = ids;
    activeIndex.value = 0;
    if (ids.length) {
      await jumpToActive();
    }
  };

  const runSearch = async (conversationId, rawQuery, requestId) => {
    const trimmed = rawQuery.trim();
    query.value = trimmed;

    if (!conversationId || trimmed.length < MIN_QUERY_LENGTH) {
      matchIds.value = [];
      activeIndex.value = 0;
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    try {
      const { data } = await MessageApi.search({
        conversationId,
        q: trimmed,
      });
      if (requestId !== searchRequestId) return;
      await applyResults(data?.payload?.ids || []);
    } catch (error) {
      if (requestId !== searchRequestId) return;
      matchIds.value = [];
      activeIndex.value = 0;
    } finally {
      if (requestId === searchRequestId) {
        isSearching.value = false;
      }
    }
  };

  const search = (conversationId, rawQuery) => {
    searchRequestId += 1;
    const requestId = searchRequestId;
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      runSearch(conversationId, rawQuery, requestId);
    }, SEARCH_DEBOUNCE_MS);
  };

  const goToNext = async () => {
    if (!matchCount.value) return;
    activeIndex.value = (activeIndex.value + 1) % matchCount.value;
    await jumpToActive();
  };

  const goToPrevious = async () => {
    if (!matchCount.value) return;
    activeIndex.value =
      (activeIndex.value - 1 + matchCount.value) % matchCount.value;
    await jumpToActive();
  };

  return {
    query,
    matchIds,
    activeIndex,
    activeMatchId,
    matchCount,
    isSearching,
    hasQuery,
    search,
    reset,
    goToNext,
    goToPrevious,
  };
}
