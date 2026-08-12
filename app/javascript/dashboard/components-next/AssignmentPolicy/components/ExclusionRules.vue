<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { picoSearch } from '@scmmishra/pico-search';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const props = defineProps({
  tagsList: {
    type: Array,
    default: () => [],
  },
});

const excludedLabels = defineModel('excludedLabels', {
  type: Array,
  default: () => [],
});

const excludeOlderThanMinutes = defineModel('excludeOlderThanMinutes', {
  type: Number,
  default: null,
});

const MIN_DURATION_MINUTES = 1;
const MAX_DURATION_MINUTES = 1438560; // 999 days * 24 hours * 60 minutes

const { t } = useI18n();

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES';

const windowUnit = ref(DURATION_UNITS.MINUTES);
const showTimeUnitDropdown = ref(false);
const showTagDropdown = ref(false);
const tagSearch = ref('');

const addedTags = computed(() =>
  props.tagsList
    .filter(label => excludedLabels.value.includes(label.name))
    .map(label => ({ id: label.id, title: label.name, ...label }))
);

const availableTags = computed(() =>
  props.tagsList.filter(
    label => !addedTags.value.some(tag => tag.id === label.id)
  )
);

const filteredTags = computed(() => {
  if (!tagSearch.value) return availableTags.value;
  return picoSearch(availableTags.value, tagSearch.value.toLowerCase(), [
    'name',
  ]);
});

const detectUnit = minutes => {
  const m = Number(minutes) || 0;
  if (m === 0) return DURATION_UNITS.MINUTES;
  if (m % (24 * 60) === 0) return DURATION_UNITS.DAYS;
  if (m % 60 === 0) return DURATION_UNITS.HOURS;
  return DURATION_UNITS.MINUTES;
};

const convertToMinutes = value => {
  const n = Math.floor(Number(value) || 0);
  if (windowUnit.value === DURATION_UNITS.HOURS) return n * 60;
  if (windowUnit.value === DURATION_UNITS.DAYS) return n * 24 * 60;
  return n;
};

const displayDuration = computed({
  get() {
    if (
      excludeOlderThanMinutes.value == null ||
      excludeOlderThanMinutes.value === ''
    ) {
      return null;
    }
    const minutes = Number(excludeOlderThanMinutes.value) || 0;
    if (windowUnit.value === DURATION_UNITS.DAYS) {
      return Math.floor(minutes / (24 * 60));
    }
    if (windowUnit.value === DURATION_UNITS.HOURS) {
      return Math.floor(minutes / 60);
    }
    return minutes;
  },
  set(value) {
    if (value == null || value === '') {
      excludeOlderThanMinutes.value = null;
      return;
    }
    const minutes = convertToMinutes(value);
    excludeOlderThanMinutes.value = Math.min(
      Math.max(minutes, MIN_DURATION_MINUTES),
      MAX_DURATION_MINUTES
    );
  },
});

const unitLabel = computed(() => {
  if (windowUnit.value === DURATION_UNITS.DAYS) {
    return t('DURATION_INPUT.DAYS');
  }
  if (windowUnit.value === DURATION_UNITS.HOURS) {
    return t('DURATION_INPUT.HOURS');
  }
  return t('DURATION_INPUT.MINUTES');
});

const selectUnit = unit => {
  windowUnit.value = unit;
  showTimeUnitDropdown.value = false;
  if (excludeOlderThanMinutes.value == null) return;
  const minutes = convertToMinutes(displayDuration.value);
  excludeOlderThanMinutes.value = Math.min(
    Math.max(minutes, MIN_DURATION_MINUTES),
    MAX_DURATION_MINUTES
  );
};

const onClickAddTag = tag => {
  excludedLabels.value = [...excludedLabels.value, tag.name];
  showTagDropdown.value = false;
  tagSearch.value = '';
};

const onClickRemoveTag = tagName => {
  excludedLabels.value = excludedLabels.value.filter(name => name !== tagName);
};

const closeTagDropdown = () => {
  showTagDropdown.value = false;
};

onMounted(() => {
  windowUnit.value = detectUnit(excludeOlderThanMinutes.value);
});
</script>

<template>
  <div class="space-y-6">
    <div class="space-y-2 border-t border-border/40 pt-2">
      <label class="block text-[13.5px] font-medium text-foreground">
        {{ t(`${BASE_KEY}.TAGS.LABEL`) }}
      </label>
      <div v-if="addedTags.length" class="mb-2 flex flex-wrap gap-2">
        <span
          v-for="tag in addedTags"
          :key="tag.id"
          class="inline-flex items-center gap-1.5 rounded-md border border-border/60 bg-accent px-2.5 py-1 text-[12px] font-medium text-foreground"
        >
          <span
            v-if="tag.color"
            class="size-2.5 shrink-0 rounded-sm"
            :style="{ backgroundColor: tag.color }"
          />
          {{ tag.title }}
          <button
            type="button"
            class="text-muted-foreground hover:text-destructive"
            @click="onClickRemoveTag(tag.name)"
          >
            <Icon icon="i-lucide-x" class="size-3.5" />
          </button>
        </span>
      </div>
      <div v-on-click-outside="closeTagDropdown" class="relative">
        <RelayButton
          type="button"
          variant="outline"
          class="h-9 w-full justify-start border-border/80 bg-background text-[13px] font-medium text-muted-foreground shadow-sm hover:bg-muted/50"
          @click="showTagDropdown = !showTagDropdown"
        >
          <Icon icon="i-lucide-plus" class="size-3.5" />
          {{ t(`${BASE_KEY}.TAGS.ADD_TAG`) }}
        </RelayButton>
        <div
          v-if="showTagDropdown"
          class="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-md border border-border/60 bg-card shadow-lg"
        >
          <div class="relative border-b border-border/40 p-2">
            <Icon
              icon="i-lucide-search"
              class="absolute left-4 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground"
            />
            <input
              v-model="tagSearch"
              type="text"
              class="w-full rounded-md bg-muted/50 py-1.5 pl-8 pr-3 text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
              :placeholder="t(`${BASE_KEY}.TAGS.DROPDOWN.SEARCH_PLACEHOLDER`)"
            />
          </div>
          <ul class="max-h-40 overflow-y-auto p-1">
            <li
              v-for="tag in filteredTags"
              :key="tag.id"
              class="flex cursor-pointer items-center justify-between rounded-sm px-3 py-2 text-[13px] text-foreground hover:bg-accent"
              @click="onClickAddTag(tag)"
            >
              <span class="flex items-center gap-2">
                <span
                  v-if="tag.color"
                  class="size-2.5 shrink-0 rounded-sm"
                  :style="{ backgroundColor: tag.color }"
                />
                {{ tag.name }}
              </span>
            </li>
            <li
              v-if="!filteredTags.length"
              class="px-3 py-2 text-[13px] text-muted-foreground"
            >
              {{ t(`${BASE_KEY}.TAGS.EMPTY_STATE`) }}
            </li>
          </ul>
        </div>
      </div>
    </div>

    <div class="space-y-2 border-t border-border/40 pt-2">
      <label class="block text-[13.5px] font-medium text-foreground">
        {{ t(`${BASE_KEY}.DURATION.LABEL`) }}
      </label>
      <div class="mt-2 flex items-center gap-2">
        <RelayInput
          v-model="displayDuration"
          type="number"
          :placeholder="t(`${BASE_KEY}.DURATION.PLACEHOLDER`)"
          class-name="h-9 w-32 px-3 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
        <div class="relative min-w-[120px]">
          <button
            type="button"
            class="flex h-9 w-full items-center justify-between rounded-md border border-border/80 bg-background px-3 text-left text-[13.5px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
            @click="showTimeUnitDropdown = !showTimeUnitDropdown"
          >
            {{ unitLabel }}
            <Icon
              icon="i-lucide-chevron-down"
              class="size-4 text-muted-foreground"
            />
          </button>
          <div
            v-if="showTimeUnitDropdown"
            class="absolute left-0 top-full z-50 mt-1 w-full overflow-hidden rounded-md border border-border/80 bg-card py-1 shadow-lg"
          >
            <button
              type="button"
              class="w-full px-3 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-muted"
              @click="selectUnit(DURATION_UNITS.MINUTES)"
            >
              {{ t('DURATION_INPUT.MINUTES') }}
            </button>
            <button
              type="button"
              class="w-full px-3 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-muted"
              @click="selectUnit(DURATION_UNITS.HOURS)"
            >
              {{ t('DURATION_INPUT.HOURS') }}
            </button>
            <button
              type="button"
              class="w-full px-3 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-muted"
              @click="selectUnit(DURATION_UNITS.DAYS)"
            >
              {{ t('DURATION_INPUT.DAYS') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
