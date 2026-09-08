<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { RelayButton, RelayTooltip } from 'dashboard/components-next/relay';

const props = defineProps({
  buttonClass: {
    type: String,
    default: '',
  },
  plain: {
    type: Boolean,
    default: false,
  },
});
const emit = defineEmits(['select']);
const ROW_HEIGHT_REM = 2.125;
const MAX_VISIBLE_ROWS = 5;
const LIST_MAX_HEIGHT = `${MAX_VISIBLE_ROWS * ROW_HEIGHT_REM}rem`;

const { t } = useI18n();
const store = useStore();
const { getPlainText } = useMessageFormatter();

const isOpen = ref(false);
const searchQuery = ref('');
const searchInput = ref(null);
const cannedResponses = useMapGetter('getCannedResponses');
const uiFlags = useMapGetter('getUIFlags');

const isLoading = computed(() => uiFlags.value.fetchingList);

const items = computed(() =>
  cannedResponses.value.map(response => ({
    id: response.id,
    shortCode: response.short_code || '',
    label: getPlainText(response.content || ''),
    content: response.content,
  }))
);

const filteredItems = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return items.value;

  return items.value.filter(item => {
    const shortCode = item.shortCode.toLowerCase();
    const label = item.label.toLowerCase();
    return shortCode.includes(query) || label.includes(query);
  });
});

const hasActiveSearch = computed(() => searchQuery.value.trim().length > 0);

const fetchCannedResponses = () => {
  store.dispatch('getCannedResponse', { searchKey: '' });
};

onMounted(() => {
  fetchCannedResponses();
});

const toggleDropdown = () => {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    fetchCannedResponses();
    nextTick(() => searchInput.value?.focus());
  }
};

const closeDropdown = () => {
  isOpen.value = false;
  searchQuery.value = '';
};

const handleSelect = content => {
  emit('select', content);
  closeDropdown();
};
</script>

<template>
  <div class="relative flex items-center justify-center">
    <RelayTooltip
      :content="t('CONVERSATION.REPLYBOX.TIP_CANNED_ICON')"
      side="top"
    >
      <button
        v-if="plain"
        type="button"
        :class="props.buttonClass"
        @click="toggleDropdown"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </button>
      <RelayButton
        v-else
        variant="ghost"
        :class="props.buttonClass"
        @click="toggleDropdown"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </RelayButton>
    </RelayTooltip>
    <div
      v-if="isOpen"
      v-on-click-outside="closeDropdown"
      class="absolute bottom-full left-0 mb-2 z-50 w-64 rounded-md border border-border bg-popover p-1 shadow-md"
    >
      <div class="text-xs font-medium text-muted-foreground px-2 py-1.5">
        {{ t('CONVERSATION.REPLYBOX.CANNED_RESPONSES_MENU_LABEL') }}
      </div>
      <div class="h-px bg-border mx-1" />
      <div class="relative px-1 py-1">
        <span
          class="pointer-events-none absolute i-lucide-search top-1/2 -translate-y-1/2 size-3.5 left-3 text-muted-foreground"
        />
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="search"
          :placeholder="t('CANNED_MGMT.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 pl-8 pr-2 bg-muted text-foreground placeholder:text-muted-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 text-[14px] shadow-sm rounded-md border-border/80 bg-background"
        />
      </div>
      <div v-if="isLoading" class="px-2 py-1.5 text-xs text-muted-foreground">
        {{ t('CANNED_MGMT.LOADING') }}
      </div>
      <div
        v-else-if="filteredItems.length"
        class="overflow-y-auto"
        :style="{ maxHeight: LIST_MAX_HEIGHT }"
      >
        <button
          v-for="item in filteredItems"
          :key="item.id"
          type="button"
          class="w-full truncate text-[13px] px-2 py-1.5 min-h-[2.125rem] hover:bg-accent hover:text-accent-foreground rounded-sm text-left"
          @click="handleSelect(item.content)"
        >
          {{ item.label }}
        </button>
      </div>
      <div v-else class="px-2 py-1.5 text-xs text-muted-foreground">
        {{
          hasActiveSearch
            ? t('CANNED_MGMT.NO_RESULTS')
            : t('CONVERSATION.REPLYBOX.CANNED_RESPONSES_EMPTY')
        }}
      </div>
    </div>
  </div>
</template>
