<script setup>
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useLocale } from 'shared/composables/useLocale';
import { useAppearanceHotKeys } from 'dashboard/composables/commands/useAppearanceHotKeys';
import { useInboxHotKeys } from 'dashboard/composables/commands/useInboxHotKeys';
import { useGoToCommandHotKeys } from 'dashboard/composables/commands/useGoToCommandHotKeys';
import { useBulkActionsHotKeys } from 'dashboard/composables/commands/useBulkActionsHotKeys';
import { useConversationHotKeys } from 'dashboard/composables/commands/useConversationHotKeys';
import wootConstants from 'dashboard/constants/globals';
import {
  GENERAL_EVENTS,
  SNOOZE_EVENTS,
} from 'dashboard/helper/AnalyticsHelper/events';
import { generateSnoozeSuggestions } from 'dashboard/helper/snoozeHelpers';
import { ICON_SNOOZE_CONVERSATION } from 'dashboard/helper/commandbar/icons';
import {
  CMD_SNOOZE_CONVERSATION,
  CMD_SNOOZE_NOTIFICATION,
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';
import { emitter } from 'shared/helpers/mitt';

const store = useStore();
const { t, tm } = useI18n();
const { resolvedLocale } = useLocale();

const ninjakeys = ref(null);
const searchInputRef = ref(null);
const itemRefs = ref([]);

const isOpen = ref(false);
const searchQuery = ref('');
const selectedIndex = ref(0);
const selectedSnoozeType = ref(null);

const { goToAppearanceHotKeys } = useAppearanceHotKeys();
const { inboxHotKeys } = useInboxHotKeys();
const { goToCommandHotKeys } = useGoToCommandHotKeys();
const { bulkActionsHotKeys } = useBulkActionsHotKeys();
const { conversationHotKeys } = useConversationHotKeys();

const SNOOZE_PARENT_IDS = [
  'snooze_conversation',
  'snooze_notification',
  'bulk_action_snooze_conversation',
];
const DYNAMIC_SNOOZE_PREFIX = 'dynamic_snooze_';
const CUSTOM_SNOOZE = wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME;

const dynamicSnoozeActions = ref([]);
const currentCommandRoot = ref(null);

const SNOOZE_PRESET_IDS = new Set(Object.values(wootConstants.SNOOZE_OPTIONS));

const placeholder = computed(() =>
  SNOOZE_PARENT_IDS.includes(currentCommandRoot.value)
    ? t('COMMAND_BAR.SNOOZE_PLACEHOLDER')
    : t('COMMAND_BAR.SEARCH_PLACEHOLDER')
);

const hotKeys = computed(() => {
  const allActions = [
    ...dynamicSnoozeActions.value,
    ...inboxHotKeys.value,
    ...goToCommandHotKeys.value,
    ...goToAppearanceHotKeys.value,
    ...bulkActionsHotKeys.value,
    ...conversationHotKeys.value,
  ];
  if (!dynamicSnoozeActions.value.length) return allActions;
  return allActions.filter(
    a => !SNOOZE_PRESET_IDS.has(a.id) || !SNOOZE_PARENT_IDS.includes(a.parent)
  );
});

const parentTitle = computed(() => {
  if (!currentCommandRoot.value) return '';
  const found = hotKeys.value.find(a => a.id === currentCommandRoot.value);
  if (found) return found.title;
  if (currentCommandRoot.value === 'snooze_conversation')
    return t('COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION');
  if (currentCommandRoot.value === 'snooze_notification')
    return t('COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION');
  if (currentCommandRoot.value === 'bulk_action_snooze_conversation')
    return t('COMMAND_BAR.SECTIONS.BULK_ACTIONS');
  return currentCommandRoot.value;
});

const SNOOZE_EVENT_MAP = {
  snooze_conversation: CMD_SNOOZE_CONVERSATION,
  snooze_notification: CMD_SNOOZE_NOTIFICATION,
  bulk_action_snooze_conversation: CMD_BULK_ACTION_SNOOZE_CONVERSATION,
};

const SNOOZE_SECTION_MAP = {
  snooze_conversation: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
  snooze_notification: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
  bulk_action_snooze_conversation: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
};

const snoozeTranslations = computed(() => {
  const raw = tm('SNOOZE_PARSER');
  if (!raw || typeof raw !== 'object') return {};
  return JSON.parse(JSON.stringify(raw));
});

const buildDynamicSnoozeActions = (search, parentId) => {
  const suggestions = generateSnoozeSuggestions(search, new Date(), {
    translations: snoozeTranslations.value,
    locale: resolvedLocale.value,
  });
  if (!suggestions.length) return [];

  const busEvent = SNOOZE_EVENT_MAP[parentId];
  const section = t(SNOOZE_SECTION_MAP[parentId]);

  return suggestions.map((parsed, index) => ({
    id: `${DYNAMIC_SNOOZE_PREFIX}${index}`,
    title:
      parsed.label !== parsed.formattedDate
        ? `${parsed.label} - ${parsed.formattedDate}`
        : parsed.formattedDate,
    parent: parentId,
    section,
    icon: ICON_SNOOZE_CONVERSATION,
    keywords: search,
    handler: () => {
      emitter.emit(busEvent, parsed.resolve());
      useTrack(SNOOZE_EVENTS.NLP_SNOOZE_APPLIED, { label: parsed.label });
    },
  }));
};

const resetSnoozeState = () => {
  currentCommandRoot.value = null;
  dynamicSnoozeActions.value = [];
};

// Filtered Actions based on root level, parent hierarchy, and search query
const visibleActions = computed(() => {
  let actions = hotKeys.value;

  // Level filtering
  if (currentCommandRoot.value) {
    actions = actions.filter(a => a.parent === currentCommandRoot.value);
  } else {
    actions = actions.filter(a => !a.parent);
  }

  // Search filtering
  const query = searchQuery.value.trim().toLowerCase();
  if (query) {
    actions = actions.filter(item => {
      const titleMatch = item.title?.toLowerCase().includes(query);
      const sectionMatch = item.section?.toLowerCase().includes(query);
      const keywordsMatch = item.keywords?.toLowerCase().includes(query);
      return titleMatch || sectionMatch || keywordsMatch;
    });
  }

  return actions;
});

// Grouped Actions by section
const groupedActions = computed(() => {
  const groups = [];
  const map = new Map();

  visibleActions.value.forEach(action => {
    const sec =
      action.section || t('COMMAND_BAR.SECTIONS.GENERAL') || 'General';
    if (!map.has(sec)) {
      map.set(sec, []);
      groups.push({ section: sec, items: map.get(sec) });
    }
    map.get(sec).push(action);
  });

  return groups;
});

// Flat array of visible items for indexing
const flatVisibleActions = computed(() => {
  return groupedActions.value.flatMap(group => group.items);
});

watch(searchQuery, newQuery => {
  selectedIndex.value = 0;
  const normalizedSearch = newQuery.trim();

  if (
    normalizedSearch &&
    SNOOZE_PARENT_IDS.includes(currentCommandRoot.value || '')
  ) {
    dynamicSnoozeActions.value = buildDynamicSnoozeActions(
      normalizedSearch,
      currentCommandRoot.value
    );
  } else {
    dynamicSnoozeActions.value = [];
  }
});

watch(currentCommandRoot, () => {
  selectedIndex.value = 0;
});

const scrollToSelected = () => {
  nextTick(() => {
    const el = itemRefs.value[selectedIndex.value];
    if (el && typeof el.scrollIntoView === 'function') {
      el.scrollIntoView({ block: 'nearest' });
    }
  });
};

watch(selectedIndex, () => {
  scrollToSelected();
});

const focusSearchInput = () => {
  nextTick(() => {
    searchInputRef.value?.focus?.();
  });
};

const open = (options = {}) => {
  isOpen.value = true;
  currentCommandRoot.value = options.parent || null;
  searchQuery.value = '';
  selectedIndex.value = 0;
  dynamicSnoozeActions.value = [];
  focusSearchInput();
};

const close = () => {
  isOpen.value = false;
  if (selectedSnoozeType.value !== CUSTOM_SNOOZE) {
    store.dispatch('setContextMenuChatId', null);
  }
  resetSnoozeState();
};

const handleSelectAction = item => {
  if (!item) return;

  selectedSnoozeType.value = item.id === CUSTOM_SNOOZE ? item.id : null;
  useTrack(GENERAL_EVENTS.COMMAND_BAR, {
    section: item.section,
    action: item.title,
  });

  if (Array.isArray(item.children) && item.children.length) {
    currentCommandRoot.value = item.id;
    searchQuery.value = '';
    selectedIndex.value = 0;
    return;
  }

  close();

  if (typeof item.handler === 'function') {
    item.handler();
  }
};

const clearParent = () => {
  currentCommandRoot.value = null;
  searchQuery.value = '';
  selectedIndex.value = 0;
  focusSearchInput();
};

const handleKeyDown = event => {
  if (!isOpen.value) return;

  if (event.key === 'ArrowDown') {
    event.preventDefault();
    if (flatVisibleActions.value.length > 0) {
      selectedIndex.value =
        (selectedIndex.value + 1) % flatVisibleActions.value.length;
    }
  } else if (event.key === 'ArrowUp') {
    event.preventDefault();
    if (flatVisibleActions.value.length > 0) {
      selectedIndex.value =
        (selectedIndex.value - 1 + flatVisibleActions.value.length) %
        flatVisibleActions.value.length;
    }
  } else if (event.key === 'Enter') {
    event.preventDefault();
    if (flatVisibleActions.value.length > 0) {
      handleSelectAction(flatVisibleActions.value[selectedIndex.value]);
    }
  } else if (event.key === 'Escape') {
    event.preventDefault();
    if (currentCommandRoot.value) {
      clearParent();
    } else {
      close();
    }
  } else if (
    event.key === 'Backspace' &&
    !searchQuery.value &&
    currentCommandRoot.value
  ) {
    clearParent();
  }
};

const handleGlobalKeyDown = event => {
  const isModK =
    (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k';
  if (isModK) {
    event.preventDefault();
    if (isOpen.value) {
      close();
    } else {
      open();
    }
  }
};

onMounted(() => {
  window.addEventListener('keydown', handleGlobalKeyDown);

  // Attach programmatic API to ninja-keys custom element for backward compatibility
  if (ninjakeys.value) {
    ninjakeys.value.open = open;
    ninjakeys.value.close = close;
  }
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleGlobalKeyDown);
});
</script>

<template>
  <ninja-keys ref="ninjakeys" class="contents">
    <Teleport to="body">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-[99999] flex items-start justify-center bg-foreground/50 p-4 pt-[15vh]"
        @click.self="close"
        @keydown="handleKeyDown"
      >
        <div
          data-relay
          class="bg-popover text-popover-foreground w-full max-w-lg overflow-hidden rounded-xl border border-border shadow-lg"
          @click.stop
        >
          <div class="flex items-center gap-2 border-b border-border px-3">
            <button
              v-if="currentCommandRoot"
              type="button"
              class="text-muted-foreground hover:text-foreground shrink-0 rounded-sm p-1 transition-colors"
              :aria-label="parentTitle"
              @click="clearParent"
            >
              <span class="i-lucide-arrow-left size-4" />
            </button>
            <span
              v-else
              class="i-lucide-search size-4 shrink-0 text-muted-foreground"
            />
            <input
              ref="searchInputRef"
              v-model="searchQuery"
              type="text"
              :placeholder="placeholder"
              class="placeholder:text-muted-foreground h-11 w-full bg-transparent text-sm outline-none"
            />
            <button
              type="button"
              class="text-muted-foreground hover:text-foreground shrink-0 rounded-sm p-1 transition-colors"
              :aria-label="t('COMMAND_BAR.KEYS.CLOSE')"
              @click="close"
            >
              <span class="i-lucide-x size-4" />
            </button>
          </div>

          <div class="max-h-80 overflow-y-auto p-1">
            <p
              v-if="flatVisibleActions.length === 0"
              class="text-muted-foreground py-6 text-center text-sm"
            >
              {{ t('COMMAND_BAR.NO_MATCHING_COMMANDS') }}
            </p>
            <template v-else>
              <template
                v-for="group in groupedActions"
                :key="group.section"
              >
                <div
                  class="text-muted-foreground px-2 py-1.5 text-xs font-medium"
                >
                  {{ group.section }}
                </div>
                <button
                  v-for="item in group.items"
                  :key="item.id"
                  :ref="
                    el => {
                      if (el) itemRefs[flatVisibleActions.indexOf(item)] = el;
                    }
                  "
                  type="button"
                  class="flex w-full items-center gap-2 rounded-md px-2 py-2 text-left text-sm"
                  :class="
                    flatVisibleActions.indexOf(item) === selectedIndex
                      ? 'bg-accent text-accent-foreground'
                      : 'hover:bg-accent/50'
                  "
                  @click="handleSelectAction(item)"
                  @mousemove="selectedIndex = flatVisibleActions.indexOf(item)"
                >
                  <span
                    class="flex size-4 shrink-0 items-center justify-center text-muted-foreground"
                    v-html="item.icon"
                  />
                  <span class="min-w-0 flex-1 truncate">{{ item.title }}</span>
                  <span
                    v-if="
                      Array.isArray(item.children) && item.children.length
                    "
                    class="i-lucide-chevron-right size-4 shrink-0 text-muted-foreground"
                  />
                </button>
              </template>
            </template>
          </div>
        </div>
      </div>
    </Teleport>
  </ninja-keys>
</template>
