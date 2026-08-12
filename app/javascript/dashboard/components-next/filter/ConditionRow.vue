<script setup>
import { computed, h, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import FilterSelect from './inputs/FilterSelect.vue';
import MultiSelect from './inputs/MultiSelect.vue';
import SingleSelect from './inputs/SingleSelect.vue';

import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { validateSingleFilter } from 'dashboard/helper/validations.js';

// filterTypes: import('vue').ComputedRef<FilterType[]>
const { filterTypes, stacked } = defineProps({
  showQueryOperator: { type: Boolean, default: false },
  filterTypes: { type: Array, required: true },
  stacked: { type: Boolean, default: false },
});

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);

const attributeKey = defineModel('attributeKey', {
  type: String,
  required: true,
});

const values = defineModel('values', {
  type: [String, Number, Array, Object],
  required: true,
});

const filterOperator = defineModel('filterOperator', {
  type: String,
  required: true,
});

const queryOperator = defineModel('queryOperator', {
  type: String,
  required: false,
  default: undefined,
  validator: value => ['and', 'or'].includes(value),
});

const getFilterFromFilterTypes = key =>
  filterTypes.find(filterObj => filterObj.attributeKey === key);

const currentFilter = computed(() =>
  getFilterFromFilterTypes(attributeKey.value)
);

const getOperator = (filter, selectedOperator) => {
  const operatorFromOptions = filter?.filterOperators?.find(
    operator => operator.value === selectedOperator
  );

  if (!operatorFromOptions) {
    return filter?.filterOperators?.[0];
  }

  return operatorFromOptions;
};

const currentOperator = computed(() =>
  getOperator(currentFilter.value, filterOperator.value)
);

const stackedOperatorLabel = computed(() => {
  const label = currentOperator.value?.label;
  if (!label) return '';
  const symbolByOp = {
    equal_to: '=',
    not_equal_to: '≠',
  };
  const symbol = symbolByOp[filterOperator.value];
  return symbol ? `${symbol} ${label}` : label;
});

const getInputType = (operator, filter) =>
  operator.inputOverride ?? filter.inputType;

const inputType = computed(() =>
  getInputType(currentOperator.value, currentFilter.value)
);

const queryOperatorOptions = computed(() => {
  return [
    {
      label: t(`FILTER.QUERY_DROPDOWN_LABELS.AND`),
      value: 'and',
      icon: h('span', { class: 'i-lucide-ampersands !text-n-blue-11' }),
    },
    {
      label: t(`FILTER.QUERY_DROPDOWN_LABELS.OR`),
      value: 'or',
      icon: h('span', { class: 'i-woot-logic-or !text-n-blue-11' }),
    },
  ];
});

const booleanOptions = computed(() => [
  { id: true, name: t('FILTER.ATTRIBUTE_LABELS.TRUE') },
  { id: false, name: t('FILTER.ATTRIBUTE_LABELS.FALSE') },
]);

const validationError = computed(() => {
  // TOOD: Migrate validateSingleFilter to use camelcase and then remove useSnakeCase here too
  return validateSingleFilter(
    useSnakeCase({
      attributeKey: attributeKey.value,
      filterOperator: filterOperator.value,
      values: values.value,
    })
  );
});

const inputFieldType = computed(() => {
  if (inputType.value === 'date') return 'date';
  if (inputType.value === 'number') return 'number';
  return 'text';
});

const resetModelOnAttributeKeyChange = newAttributeKey => {
  /**
   * Resets the filter values and operator when the attribute key changes. This ensures that
   * the values and operator remain compatible with the new attribute type. For example,
   * switching from a text field to a multi-select should reset the value from '' (empty string)
   * to an empty array.
   */
  const filter = getFilterFromFilterTypes(newAttributeKey);
  const newOperator = getOperator(filter, filterOperator.value);
  const newInputType = getInputType(newOperator, filter);
  if (newInputType === 'multiSelect') {
    values.value = [];
  } else if (['searchSelect', 'booleanSelect'].includes(newInputType)) {
    values.value = {};
  } else {
    values.value = '';
  }
  filterOperator.value = newOperator.value;
};

watch([attributeKey, values, filterOperator], () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !validationError.value;
};

const resetValidation = () => {
  showErrors.value = false;
};

defineExpose({ validate, resetValidation });
</script>

<template>
  <component :is="stacked ? 'div' : 'li'" :class="{ 'list-none': !stacked }">
    <!-- Stacked drawer layout (NewRelay / contacts filter drawer) -->
    <div
      v-if="stacked"
      class="flex flex-col gap-3"
      :class="{ 'animate-wiggle': showErrors && validationError }"
    >
      <div
        v-if="showQueryOperator"
        class="absolute -top-2.5 left-4 z-10 bg-card px-2"
      >
        <FilterSelect
          v-model="queryOperator"
          hide-icon
          :options="queryOperatorOptions"
        >
          <template #trigger="{ toggle }">
            <button
              type="button"
              class="text-xs font-bold uppercase tracking-wide text-muted-foreground hover:text-foreground"
              @click="toggle"
            >
              {{
                queryOperator === 'or'
                  ? t('FILTER.QUERY_DROPDOWN_LABELS.OR')
                  : t('FILTER.QUERY_DROPDOWN_LABELS.AND')
              }}
            </button>
          </template>
        </FilterSelect>
      </div>
      <div class="flex items-center gap-2">
        <div class="min-w-0 flex-1">
          <FilterSelect
            v-model="attributeKey"
            :options="filterTypes"
            @update:model-value="resetModelOnAttributeKeyChange"
          >
            <template #trigger="{ toggle }">
              <RelayButton
                variant="outline"
                class="h-9 w-full justify-between border-border/80 bg-background px-3 text-sm font-medium shadow-sm hover:border-border/80 hover:bg-muted/50"
                @click="toggle"
              >
                <span class="truncate">{{ currentFilter?.label }}</span>
                <span
                  class="i-lucide-chevron-down size-4 shrink-0 opacity-50"
                />
              </RelayButton>
            </template>
          </FilterSelect>
        </div>
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-9 shrink-0 rounded-md border border-border/50 bg-background text-muted-foreground hover:border-border/50 hover:text-destructive"
          @click.stop="emit('remove')"
        >
          <span class="i-lucide-trash-2 size-4" />
        </RelayButton>
      </div>
      <FilterSelect
        v-model="filterOperator"
        :options="currentFilter?.filterOperators"
      >
        <template #trigger="{ toggle }">
          <RelayButton
            variant="outline"
            class="h-9 w-full justify-between border-border/80 bg-background px-3 text-sm font-medium text-primary shadow-sm hover:border-border/80 hover:bg-muted/50 hover:text-primary"
            @click="toggle"
          >
            <span class="truncate">{{ stackedOperatorLabel }}</span>
            <span class="i-lucide-chevron-down size-4 shrink-0 opacity-50" />
          </RelayButton>
        </template>
      </FilterSelect>
      <template v-if="currentOperator?.hasInput">
        <MultiSelect
          v-if="inputType === 'multiSelect'"
          v-model="values"
          :options="currentFilter.options"
          dropdown-max-height="max-h-72"
        />
        <SingleSelect
          v-else-if="inputType === 'searchSelect'"
          v-model="values"
          :options="currentFilter.options"
          dropdown-max-height="max-h-64"
        />
        <SingleSelect
          v-else-if="inputType === 'booleanSelect'"
          v-model="values"
          disable-search
          :options="booleanOptions"
        />
        <div v-else class="flex w-full flex-col">
          <RelayInput
            v-model="values"
            :type="inputFieldType"
            :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
            :class-name="
              showErrors && validationError
                ? 'border-destructive/60 focus-visible:ring-destructive/20'
                : 'border-border/80'
            "
          />
        </div>
      </template>
      <span
        v-if="showErrors && validationError"
        class="text-[11.5px] font-medium text-destructive"
      >
        {{ t(`FILTER.ERRORS.${validationError}`) }}
      </span>
    </div>

    <!-- Default horizontal row layout -->
    <div
      v-else
      class="flex items-center gap-2 rounded-md"
      :class="{
        'animate-wiggle': showErrors && validationError,
      }"
    >
      <FilterSelect
        v-if="showQueryOperator"
        v-model="queryOperator"
        variant="faded"
        hide-icon
        class="text-sm"
        :options="queryOperatorOptions"
      />
      <FilterSelect
        v-model="attributeKey"
        variant="faded"
        :options="filterTypes"
        @update:model-value="resetModelOnAttributeKeyChange"
      />
      <FilterSelect
        v-model="filterOperator"
        variant="ghost"
        :options="currentFilter?.filterOperators"
      />
      <template v-if="currentOperator?.hasInput">
        <MultiSelect
          v-if="inputType === 'multiSelect'"
          v-model="values"
          :options="currentFilter.options"
          dropdown-max-height="max-h-72"
        />
        <SingleSelect
          v-else-if="inputType === 'searchSelect'"
          v-model="values"
          :options="currentFilter.options"
          dropdown-max-height="max-h-64"
        />
        <SingleSelect
          v-else-if="inputType === 'booleanSelect'"
          v-model="values"
          disable-search
          :options="booleanOptions"
        />
        <Input
          v-else
          v-model="values"
          :type="inputFieldType"
          class="[&>input]:h-8 [&>input]:py-1.5 [&>input]:outline-offset-0"
          :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
        />
      </template>
      <Button
        sm
        solid
        slate
        icon="i-lucide-trash"
        class="flex-shrink-0"
        @click.stop="emit('remove')"
      />
    </div>
    <span
      v-if="!stacked && showErrors && validationError"
      class="text-sm text-n-ruby-11"
    >
      {{ t(`FILTER.ERRORS.${validationError}`) }}
    </span>
  </component>
</template>
