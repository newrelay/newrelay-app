<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import wootConstants from 'dashboard/constants/globals';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { RelayCheckbox, RelayLabel } from 'dashboard/components-next/relay';

const emit = defineEmits(['filter']);

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

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

const onSortOptionClick = option => {
  activeSort.value = option.key;
  saveSelectedDisplayFilter();
  emit('filter', option);
};

const SORT_OPTION_CLASSES =
  'flex w-full cursor-pointer select-none items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm text-foreground outline-none transition-colors hover:bg-accent hover:text-accent-foreground';

onMounted(() => {
  setSavedFilter();
});
</script>

<template>
  <div>
    <div class="flex items-center gap-2 px-1 py-1.5 text-sm text-foreground">
      <span class="i-lucide-arrow-down-up size-4 shrink-0" />
      {{ t('INBOX.DISPLAY_MENU.SORT') }}
    </div>
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
          circle
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
