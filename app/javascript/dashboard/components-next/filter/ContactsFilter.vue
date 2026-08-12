<script setup>
import { useTemplateRef, onBeforeUnmount, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useContactFilterContext } from './contactProvider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import ConditionRow from './ConditionRow.vue';

const props = defineProps({
  isSegmentView: { type: Boolean, default: false },
  segmentName: { type: String, default: '' },
});

const emit = defineEmits([
  'applyFilter',
  'updateSegment',
  'close',
  'clearFilters',
]);
const { filterTypes } = useContactFilterContext();

const filters = defineModel({
  type: Array,
  default: [],
});
const segmentNameLocal = ref(props.segmentName);

const DEFAULT_FILTER = {
  attributeKey: 'name',
  filterOperator: 'equal_to',
  values: '',
  queryOperator: 'and',
  attributeModel: 'standard',
};

const { t } = useI18n();
const store = useStore();

const close = () => emit('close');

const resetFilter = () => {
  emit('clearFilters');
  filters.value = [{ ...DEFAULT_FILTER }];
  close();
};

const removeFilter = index => {
  if (filters.value.length === 1) {
    filters.value = [{ ...DEFAULT_FILTER }];
  } else {
    filters.value.splice(index, 1);
  }
};

const addFilter = () => {
  filters.value.push({ ...DEFAULT_FILTER });
};

const conditionsRef = useTemplateRef('conditionsRef');

const isConditionsValid = () => {
  return conditionsRef.value.every(condition => condition.validate());
};

const updateSavedSegment = () => {
  if (isConditionsValid()) {
    emit('updateSegment', filters.value, segmentNameLocal.value);
  }
};

function validateAndSubmit() {
  if (!isConditionsValid()) return;

  store.dispatch(
    'contacts/setContactFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
  useTrack(CONTACTS_EVENTS.APPLY_FILTER, {
    appliedFilters: filters.value.map(filter => ({
      key: filter.attributeKey,
      operator: filter.filterOperator,
      queryOperator: filter.queryOperator,
    })),
  });
}

const filterModalHeaderTitle = computed(() => {
  return !props.isSegmentView
    ? t('CONTACTS_LAYOUT.FILTER.TITLE')
    : t('CONTACTS_LAYOUT.FILTER.EDIT_SEGMENT');
});

onBeforeUnmount(() => emit('close'));
</script>

<template>
  <Teleport to="body">
    <div
      data-relay
      class="fixed inset-0 z-[60] bg-background/80 backdrop-blur-sm transition-all duration-300"
      @click.self="close"
    >
      <div
        class="fixed inset-y-0 right-0 z-[60] flex w-full max-w-[450px] translate-x-0 animate-in slide-in-from-right flex-col border-l border-border bg-card p-6 shadow-2xl duration-300"
      >
        <div class="mb-6 flex shrink-0 items-center justify-between">
          <h2 class="text-base font-medium tracking-tight text-foreground">
            {{ filterModalHeaderTitle }}
          </h2>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 text-muted-foreground hover:text-foreground"
            @click="close"
          >
            <span class="i-lucide-x size-4" />
          </RelayButton>
        </div>

        <div class="hide-scrollbar flex-1 overflow-y-auto pr-2">
          <div
            v-if="props.isSegmentView"
            class="mb-6 flex flex-col gap-1.5 border-b border-border pb-6"
          >
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.FILTER.SEGMENT.LABEL') }}
            </label>
            <RelayInput
              v-model="segmentNameLocal"
              :placeholder="
                t('CONTACTS_LAYOUT.FILTER.SEGMENT.INPUT_PLACEHOLDER')
              "
              class-name="h-9 border-border bg-background text-sm shadow-sm"
            />
          </div>

          <ul class="mb-6 list-none space-y-4">
            <template v-for="(filter, index) in filters" :key="filter.id">
              <li
                class="relative flex flex-col gap-3 rounded-xl border border-border/80 bg-muted/10 p-4 shadow-sm"
              >
                <ConditionRow
                  v-if="index === 0"
                  ref="conditionsRef"
                  :key="`filter-${filter.attributeKey}-0`"
                  v-model:attribute-key="filter.attributeKey"
                  v-model:filter-operator="filter.filterOperator"
                  v-model:values="filter.values"
                  :filter-types="filterTypes"
                  :show-query-operator="false"
                  stacked
                  @remove="removeFilter(index)"
                />
                <ConditionRow
                  v-else
                  :key="`filter-${filter.attributeKey}-${index}`"
                  ref="conditionsRef"
                  v-model:attribute-key="filter.attributeKey"
                  v-model:filter-operator="filter.filterOperator"
                  v-model:query-operator="filters[index - 1].queryOperator"
                  v-model:values="filter.values"
                  show-query-operator
                  stacked
                  :filter-types="filterTypes"
                  @remove="removeFilter(index)"
                />
              </li>
            </template>
          </ul>

          <RelayButton
            variant="ghost"
            class="h-10 w-full justify-start rounded-lg border border-transparent px-4 text-sm font-medium text-primary hover:border-primary/20 hover:bg-primary/10 hover:text-primary"
            @click="addFilter"
          >
            <span class="i-lucide-plus mr-2 size-4" />
            {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.ADD_FILTER') }}
          </RelayButton>
        </div>

        <div class="mt-6 flex shrink-0 gap-3 border-t border-border pt-6">
          <RelayButton
            variant="outline"
            class="h-10 flex-1 text-sm font-medium"
            @click="resetFilter"
          >
            {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.CLEAR_FILTERS') }}
          </RelayButton>
          <div class="flex-1">
            <RelayButton
              v-if="isSegmentView"
              class="h-10 w-full bg-primary text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90"
              :disabled="!segmentNameLocal"
              @click="updateSavedSegment"
            >
              {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.UPDATE_SEGMENT') }}
            </RelayButton>
            <RelayButton
              v-else
              class="h-10 w-full bg-primary text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90"
              @click="validateAndSubmit"
            >
              {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.APPLY_FILTERS') }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
