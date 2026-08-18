<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import wootConstants from 'dashboard/constants/globals';
import { useUISettings } from 'dashboard/composables/useUISettings';
import {
  RelayButton,
  RelayCheckbox,
  RelayLabel,
  DROPDOWN_MENU_CONTENT_CLASS,
} from 'dashboard/components-next/relay';
import { cn } from 'dashboard/components-next/relay/utils/cn';

const emit = defineEmits(['filter']);

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

const showSortMenu = ref(false);
const sortTriggerRef = ref(null);
const sortMenuStyle = ref({});

const displayOptions = ref([
  {
    id: 'display-snoozed',
    name: t('INBOX.DISPLAY_MENU.DISPLAY_OPTIONS.SNOOZED'),
    key: wootConstants.INBOX_DISPLAY_BY.SNOOZED,
    selected: false,
    type: wootConstants.INBOX_FILTER_TYPE.STATUS,
  },
  {
    id: 'display-read',
    name: t('INBOX.DISPLAY_MENU.DISPLAY_OPTIONS.READ'),
    key: wootConstants.INBOX_DISPLAY_BY.READ,
    selected: false,
    type: wootConstants.INBOX_FILTER_TYPE.TYPE,
  },
]);

const sortOptions = computed(() => [
  {
    name: t('INBOX.DISPLAY_MENU.SORT_OPTIONS.NEWEST'),
    key: wootConstants.INBOX_SORT_BY.NEWEST,
    type: wootConstants.INBOX_FILTER_TYPE.SORT_ORDER,
  },
  {
    name: t('INBOX.DISPLAY_MENU.SORT_OPTIONS.OLDEST'),
    key: wootConstants.INBOX_SORT_BY.OLDEST,
    type: wootConstants.INBOX_FILTER_TYPE.SORT_ORDER,
  },
]);

const activeSort = ref(wootConstants.INBOX_SORT_BY.NEWEST);
const activeDisplayFilter = ref({
  status: '',
  type: '',
});

const activeSortOption = computed(
  () =>
    sortOptions.value.find(option => option.key === activeSort.value)?.name ||
    ''
);

const saveSelectedDisplayFilter = () => {
  updateUISettings({
    inbox_filter_by: {
      ...activeDisplayFilter.value,
      sort_by: activeSort.value || wootConstants.INBOX_SORT_BY.NEWEST,
    },
  });
};

const setSavedFilter = () => {
  const { inbox_filter_by: filterBy = {} } = uiSettings.value;
  const { status, type, sort_by: sortBy } = filterBy;
  activeSort.value = sortBy || wootConstants.INBOX_SORT_BY.NEWEST;

  displayOptions.value.forEach(option => {
    option.selected =
      option.type === wootConstants.INBOX_FILTER_TYPE.STATUS
        ? option.key === status
        : option.key === type;
    activeDisplayFilter.value[option.type] = option.selected ? option.key : '';
  });
};

const updateDisplayOption = option => {
  activeDisplayFilter.value[option.type] = option.selected ? option.key : '';
  saveSelectedDisplayFilter();
  emit('filter', option);
};

const toggleSortMenu = () => {
  showSortMenu.value = !showSortMenu.value;
};

const updateSortMenuPosition = () => {
  const trigger = sortTriggerRef.value;
  if (!trigger || !showSortMenu.value) return;

  const rect = trigger.getBoundingClientRect();
  const isRtl = document.documentElement.dir === 'rtl';
  const sideOffset = 4;

  sortMenuStyle.value = isRtl
    ? {
        position: 'fixed',
        top: `${rect.top}px`,
        right: `${window.innerWidth - rect.left + sideOffset}px`,
        zIndex: 60,
      }
    : {
        position: 'fixed',
        top: `${rect.top}px`,
        left: `${rect.right + sideOffset}px`,
        zIndex: 60,
      };
};

watch(showSortMenu, async open => {
  if (!open) return;
  await nextTick();
  updateSortMenuPosition();
});

const onSortOptionClick = option => {
  activeSort.value = option.key;
  showSortMenu.value = false;
  saveSelectedDisplayFilter();
  emit('filter', option);
};

const SORT_OPTION_CLASSES =
  'flex w-full cursor-pointer select-none items-center justify-between rounded-sm px-2 py-1.5 text-left text-xs text-foreground outline-none transition-colors hover:bg-accent hover:text-accent-foreground';

onMounted(() => {
  setSavedFilter();
});
</script>

<template>
  <div
    :class="cn(DROPDOWN_MENU_CONTENT_CLASS, 'w-56 overflow-visible p-2')"
    data-state="open"
  >
    <div class="relative flex items-center justify-between px-1 py-1.5">
      <div class="flex items-center gap-2 text-sm text-foreground">
        <span class="i-lucide-arrow-down-up size-4 shrink-0" />
        {{ t('INBOX.DISPLAY_MENU.SORT') }}
      </div>
      <div ref="sortTriggerRef" class="relative">
        <RelayButton
          variant="outline"
          size="sm"
          class="h-7 gap-1 px-2 text-xs outline-none"
          :class="
            showSortMenu ? 'bg-background hover:bg-background' : undefined
          "
          @click="toggleSortMenu"
        >
          {{ activeSortOption }}
          <span class="i-lucide-chevron-down size-3 shrink-0" />
        </RelayButton>
        <Teleport to="body">
          <div
            v-if="showSortMenu"
            :style="sortMenuStyle"
            :class="DROPDOWN_MENU_CONTENT_CLASS"
            data-state="open"
            role="menu"
          >
            <button
              v-for="option in sortOptions"
              :key="option.key"
              type="button"
              role="menuitem"
              :class="SORT_OPTION_CLASSES"
              @click.stop="onSortOptionClick(option)"
            >
              {{ option.name }}
              <span
                v-if="activeSort === option.key"
                class="i-lucide-check size-3 shrink-0"
              />
            </button>
          </div>
        </Teleport>
      </div>
    </div>

    <div class="mt-1 px-1 py-1">
      <span class="text-xs text-muted-foreground">
        {{ t('INBOX.DISPLAY_MENU.DISPLAY') }}
      </span>
    </div>

    <div class="flex flex-col gap-3 px-1 py-1.5">
      <div
        v-for="option in displayOptions"
        :key="option.key"
        class="flex items-center gap-2"
      >
        <RelayCheckbox
          :id="option.id"
          v-model="option.selected"
          :aria-label="option.name"
          @update:model-value="updateDisplayOption(option)"
        />
        <RelayLabel
          :html-for="option.id"
          class="cursor-pointer text-sm font-normal"
        >
          {{ option.name }}
        </RelayLabel>
      </div>
    </div>
  </div>
</template>
