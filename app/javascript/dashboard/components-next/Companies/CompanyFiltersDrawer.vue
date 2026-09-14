<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  activeFilters: { type: Array, default: () => [] },
});

const emit = defineEmits(['update:open', 'apply', 'clear']);

const { t } = useI18n();

const showFilterErrors = ref(false);
const openPropertyMenu = ref(null);
const openOperatorMenu = ref(null);

const PROPERTY_OPTIONS = [
  { value: 'name', labelKey: 'COMPANIES.FILTERS.PROPERTIES.NAME' },
  { value: 'industry', labelKey: 'COMPANIES.FILTERS.PROPERTIES.INDUSTRY' },
  { value: 'contacts', labelKey: 'COMPANIES.FILTERS.PROPERTIES.CONTACTS' },
  { value: 'phone', labelKey: 'COMPANIES.FILTERS.PROPERTIES.PHONE' },
  { value: 'email', labelKey: 'COMPANIES.FILTERS.PROPERTIES.EMAIL' },
  { value: 'website', labelKey: 'COMPANIES.FILTERS.PROPERTIES.WEBSITE' },
  { value: 'owner', labelKey: 'COMPANIES.FILTERS.PROPERTIES.OWNER' },
];

const OPERATOR_OPTIONS = [
  {
    value: 'equal',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.EQUAL',
    hasInput: true,
  },
  {
    value: 'not_equal',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.NOT_EQUAL',
    hasInput: true,
  },
  {
    value: 'contains',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.CONTAINS',
    hasInput: true,
  },
  {
    value: 'does_not_contain',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.DOES_NOT_CONTAIN',
    hasInput: true,
  },
  {
    value: 'starts_with',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.STARTS_WITH',
    hasInput: true,
  },
  {
    value: 'is_present',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.IS_PRESENT',
    hasInput: false,
  },
  {
    value: 'is_not_present',
    labelKey: 'COMPANIES.FILTERS.OPERATORS.IS_NOT_PRESENT',
    hasInput: false,
  },
];

const createDraft = () => ({
  id: Date.now() + Math.random(),
  property: 'name',
  operator: 'equal',
  value: '',
  queryOperator: 'and',
});

const filterDrafts = ref([createDraft()]);

watch(
  () => props.open,
  isOpen => {
    if (!isOpen) return;
    filterDrafts.value =
      props.activeFilters.length > 0
        ? props.activeFilters.map(f => ({
            ...f,
            queryOperator: f.queryOperator || 'and',
          }))
        : [createDraft()];
    showFilterErrors.value = false;
    openPropertyMenu.value = null;
    openOperatorMenu.value = null;
  }
);

const operatorHasInput = operator => {
  const opt = OPERATOR_OPTIONS.find(item => item.value === operator);
  return opt ? opt.hasInput : true;
};

const isApplyDisabled = computed(() =>
  filterDrafts.value.some(
    draft =>
      operatorHasInput(draft.operator) && !String(draft.value || '').trim()
  )
);

const propertyLabel = value => {
  const opt = PROPERTY_OPTIONS.find(item => item.value === value);
  return opt ? t(opt.labelKey) : value;
};

const operatorLabel = value => {
  const opt = OPERATOR_OPTIONS.find(item => item.value === value);
  return opt ? t(opt.labelKey) : value;
};

const toggleQueryOperator = index => {
  const previous = filterDrafts.value[index - 1];
  if (!previous) return;
  previous.queryOperator = previous.queryOperator === 'or' ? 'and' : 'or';
};

const close = () => emit('update:open', false);

const addFilterDraft = () => {
  filterDrafts.value.push(createDraft());
  showFilterErrors.value = false;
};

const removeFilterDraft = index => {
  filterDrafts.value.splice(index, 1);
  if (filterDrafts.value.length === 0) addFilterDraft();
};

const clearFilters = () => {
  filterDrafts.value = [createDraft()];
  showFilterErrors.value = false;
  emit('clear');
  close();
};

const handleDisabledApplyClick = () => {
  if (isApplyDisabled.value) showFilterErrors.value = true;
};

const applyFilters = () => {
  if (isApplyDisabled.value) {
    showFilterErrors.value = true;
    return;
  }
  emit(
    'apply',
    filterDrafts.value.map(draft => ({
      ...draft,
      value: String(draft.value).trim(),
    }))
  );
  close();
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      data-relay
      :class="RELAY_DIALOG_OVERLAY_CLASS"
      @click.self="close"
    >
      <div
        class="fixed inset-y-0 right-0 z-[60] flex w-full max-w-[450px] translate-x-0 animate-in slide-in-from-right flex-col border-l border-border bg-card p-0 shadow-2xl duration-300"
      >
        <RelayModalHeader
          :title="t('COMPANIES.FILTERS.TITLE')"
          :description="t('COMPANIES.FILTERS.DESCRIPTION')"
          @close="close"
        />

        <div class="hide-scrollbar flex-1 overflow-y-auto px-6">
          <div class="mb-6 space-y-4">
            <div
              v-for="(draft, index) in filterDrafts"
              :key="draft.id"
              class="relative flex flex-col gap-3 rounded-xl border border-border bg-muted/10 p-4 shadow-sm"
            >
              <button
                v-if="index > 0"
                type="button"
                class="absolute -top-2.5 left-4 bg-card px-2 text-[13px] font-normal text-muted-foreground hover:text-foreground"
                @click="toggleQueryOperator(index)"
              >
                {{
                  filterDrafts[index - 1].queryOperator === 'or'
                    ? t('COMPANIES.FILTERS.OR')
                    : t('COMPANIES.FILTERS.AND')
                }}
              </button>

              <div class="flex items-center gap-2">
                <div
                  v-on-click-outside="() => (openPropertyMenu = null)"
                  class="relative w-full"
                >
                  <RelayButton
                    variant="outline"
                    class="h-9 w-full justify-between border-border bg-background px-3 text-[13px] font-normal shadow-sm hover:bg-muted/50"
                    @click="
                      openPropertyMenu =
                        openPropertyMenu === draft.id ? null : draft.id
                    "
                  >
                    {{ propertyLabel(draft.property) }}
                    <span class="i-lucide-chevron-down size-4 opacity-50" />
                  </RelayButton>
                  <div
                    v-if="openPropertyMenu === draft.id"
                    class="absolute left-0 top-full z-[70] mt-1 w-full min-w-[240px] overflow-hidden rounded-md border border-border bg-popover p-1 shadow-md"
                  >
                    <button
                      v-for="prop in PROPERTY_OPTIONS"
                      :key="prop.value"
                      type="button"
                      class="flex w-full cursor-pointer rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent"
                      @click="
                        draft.property = prop.value;
                        openPropertyMenu = null;
                      "
                    >
                      {{ t(prop.labelKey) }}
                    </button>
                  </div>
                </div>
                <RelayButton
                  variant="ghost"
                  size="icon"
                  class="size-9 shrink-0 rounded-md border border-border bg-background text-muted-foreground hover:text-destructive"
                  @click="removeFilterDraft(index)"
                >
                  <span class="i-lucide-trash-2 size-4" />
                </RelayButton>
              </div>

              <div
                v-on-click-outside="() => (openOperatorMenu = null)"
                class="relative w-full"
              >
                <RelayButton
                  variant="outline"
                  class="h-9 w-full justify-between border-border bg-background px-3 text-[13px] font-normal text-primary shadow-sm hover:bg-muted/50"
                  @click="
                    openOperatorMenu =
                      openOperatorMenu === draft.id ? null : draft.id
                  "
                >
                  {{ operatorLabel(draft.operator) }}
                  <span class="i-lucide-chevron-down size-4 opacity-50" />
                </RelayButton>
                <div
                  v-if="openOperatorMenu === draft.id"
                  class="absolute left-0 top-full z-[70] mt-1 w-full overflow-hidden rounded-md border border-border bg-popover p-1 shadow-md"
                >
                  <button
                    v-for="op in OPERATOR_OPTIONS"
                    :key="op.value"
                    type="button"
                    class="flex w-full cursor-pointer rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent"
                    @click="
                      draft.operator = op.value;
                      if (!op.hasInput) draft.value = '';
                      openOperatorMenu = null;
                    "
                  >
                    {{ t(op.labelKey) }}
                  </button>
                </div>
              </div>

              <div
                v-if="operatorHasInput(draft.operator)"
                class="flex w-full flex-col"
              >
                <RelayInput
                  v-model="draft.value"
                  :placeholder="t('COMPANIES.FILTERS.VALUE_PLACEHOLDER')"
                  class-name="h-9 w-full bg-background text-sm shadow-sm"
                  :class="
                    showFilterErrors && !String(draft.value || '').trim()
                      ? 'border-destructive'
                      : 'border-border'
                  "
                  @update:model-value="showFilterErrors = false"
                />
                <span
                  v-if="showFilterErrors && !String(draft.value || '').trim()"
                  class="mt-1.5 text-[11.5px] font-medium text-destructive"
                >
                  {{ t('COMPANIES.FILTERS.VALUE_REQUIRED') }}
                </span>
              </div>
            </div>
          </div>

          <RelayButton
            variant="ghost"
            class="h-9 w-full justify-start rounded-lg border border-border px-4 text-[13px] font-normal text-primary hover:border-transparent hover:bg-primary/10 hover:text-primary"
            @click="addFilterDraft"
          >
            <span class="i-lucide-plus mr-2 size-4" />
            {{ t('COMPANIES.FILTERS.ADD_CONDITION') }}
          </RelayButton>
        </div>

        <div class="mt-6 flex shrink-0 gap-3 border-t border-border px-6 py-6">
          <RelayButton
            variant="outline"
            class="h-9 flex-1 text-sm font-medium"
            @click="clearFilters"
          >
            {{ t('COMPANIES.FILTERS.CLEAR') }}
          </RelayButton>
          <div class="flex-1" @click="handleDisabledApplyClick">
            <RelayButton
              class="h-9 w-full text-sm font-medium shadow-sm"
              :disabled="isApplyDisabled"
              @click="applyFilters"
            >
              {{ t('COMPANIES.FILTERS.APPLY') }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
