<script setup>
import { ref, computed, h, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useOperators } from 'dashboard/components-next/filter/operators';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import {
  generateAutomationPayload,
  getAttributes,
  getFileName,
  showActionInput,
} from 'dashboard/helper/automationHelper';
import { validateAutomation } from 'dashboard/helper/validations';
import { AUTOMATION_RULE_EVENTS, AUTOMATION_ACTION_TYPES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['create', 'edit'].includes(value),
  },
  automationTypes: {
    type: Object,
    required: true,
  },
  getConditionDropdownValues: {
    type: Function,
    required: true,
  },
  getActionDropdownValues: {
    type: Function,
    required: true,
  },
  appendNewCondition: {
    type: Function,
    required: true,
  },
  appendNewAction: {
    type: Function,
    required: true,
  },
  removeFilter: {
    type: Function,
    required: true,
  },
  removeAction: {
    type: Function,
    required: true,
  },
  resetAction: {
    type: Function,
    required: true,
  },
  onEventChange: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['save']);
const automation = defineModel('automation', { type: Object, default: null });

const INPUT_TYPE_MAP = {
  multi_select: 'multiSelect',
  search_select: 'searchSelect',
  plain_text: 'plainText',
  comma_separated_plain_text: 'plainText',
  date: 'date',
};

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { operators } = useOperators();

const dialogRef = ref(null);
const conditionsRef = useTemplateRef('conditionsRef');
const errors = ref({});

const isEditMode = computed(() => props.mode === 'edit');

const titleKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.TITLE' : 'AUTOMATION.ADD.TITLE'
);
const subtitleKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.DESC' : 'AUTOMATION.ADD.DESC'
);
const cancelKey = computed(() =>
  isEditMode.value
    ? 'AUTOMATION.EDIT.CANCEL_BUTTON_TEXT'
    : 'AUTOMATION.ADD.CANCEL_BUTTON_TEXT'
);
const submitKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.SUBMIT' : 'AUTOMATION.ADD.SUBMIT'
);

const getTranslatedAttributes = (type, event) => {
  return getAttributes(type, event).map(attribute => {
    const skipTranslation =
      attribute.customAttributeType ||
      ['contact_custom_attribute', 'conversation_custom_attribute'].includes(
        attribute.key
      );
    return {
      ...attribute,
      name: skipTranslation
        ? attribute.name
        : t(`AUTOMATION.ATTRIBUTES.${attribute.name}`),
    };
  });
};

const eventName = computed(() => automation.value?.event_name);

const filterTypes = computed(() => {
  const event = eventName.value;
  if (!event || !props.automationTypes[event]) return [];

  const attributes = getTranslatedAttributes(props.automationTypes, event);

  return attributes.map(attr => {
    if (attr.disabled) {
      return { value: attr.key, label: attr.name, disabled: true };
    }

    const mappedInputType = INPUT_TYPE_MAP[attr.inputType] || 'plainText';
    const options = props.getConditionDropdownValues(attr.key) || [];

    const filterOperators = (attr.filterOperators || []).map(op => {
      const enriched = operators.value[op.value];
      if (enriched) return enriched;
      return {
        value: op.value,
        label: t(`FILTER.OPERATOR_LABELS.${op.value}`),
        hasInput: true,
        inputOverride: null,
        icon: h('span', { class: 'i-ph-equals-bold !text-n-blue-11' }),
      };
    });

    return {
      attributeKey: attr.key,
      value: attr.key,
      attributeName: attr.name,
      label: attr.name,
      inputType: mappedInputType,
      options,
      filterOperators,
      dataType: 'text',
      attributeModel: attr.customAttributeType || 'standard',
    };
  });
});

const automationRuleEvents = computed(() =>
  AUTOMATION_RULE_EVENTS.map(event => ({
    ...event,
    value: t(`AUTOMATION.EVENTS.${event.value}`),
  }))
);

const hasAutomationMutated = computed(() => {
  return Boolean(
    automation.value?.conditions[0]?.values ||
      automation.value?.actions[0]?.action_params?.length
  );
});

const automationActionTypes = computed(() => {
  const actionTypes = isCloudFeatureEnabled('sla')
    ? AUTOMATION_ACTION_TYPES
    : AUTOMATION_ACTION_TYPES.filter(({ key }) => key !== 'add_sla');

  return actionTypes.map(action => ({
    ...action,
    label: t(`AUTOMATION.ACTIONS.${action.label}`),
  }));
});

const hasConditionErrors = computed(() =>
  Object.keys(errors.value).some(key => key.startsWith('condition_'))
);

const hasActionErrors = computed(() =>
  Object.keys(errors.value).some(key => key.startsWith('action_'))
);

watch(
  () => automation.value,
  () => {
    if (Object.keys(errors.value).length) {
      errors.value = {};
    }
  },
  { deep: true }
);

const isConditionsValid = () => {
  if (!conditionsRef.value) return true;
  return conditionsRef.value.every(condition => condition.validate());
};

const resetValidation = () => {
  errors.value = {};
  conditionsRef.value?.forEach(c => c.resetValidation());
};

const syncCustomAttributeTypes = () => {
  automation.value.conditions.forEach(condition => {
    const filterType = filterTypes.value.find(
      ft => ft.attributeKey === condition.attribute_key
    );
    condition.custom_attribute_type =
      filterType?.attributeModel === 'standard'
        ? ''
        : filterType?.attributeModel || '';
  });
};

const open = () => {
  resetValidation();
  dialogRef.value?.open();
};

const close = () => {
  resetValidation();
  dialogRef.value?.close();
};

const emitSaveAutomation = () => {
  syncCustomAttributeTypes();
  const conditionsValid = isConditionsValid();
  errors.value = validateAutomation(automation.value);
  if (Object.keys(errors.value).length === 0 && conditionsValid) {
    const payload = generateAutomationPayload(automation.value);
    emit('save', payload, props.mode);
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    position="top"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
  >
    <div v-if="automation" class="flex w-full flex-col">
      <div class="mb-6 flex items-start gap-3">
        <div
          class="flex size-10 shrink-0 items-center justify-center rounded-xl border border-primary/20 bg-primary/10 shadow-sm"
        >
          <Icon icon="i-lucide-zap" class="size-5 text-primary" />
        </div>
        <div>
          <h3 class="text-base font-medium text-foreground">
            {{ $t(titleKey) }}
          </h3>
          <p class="mt-0.5 text-[13px] text-muted-foreground">
            {{ $t(subtitleKey) }}
          </p>
        </div>
      </div>

      <div class="space-y-6">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="automation-name"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('AUTOMATION.ADD.FORM.NAME.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="automation-name"
            v-model="automation.name"
            type="text"
            :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
            :class-name="
              errors.name
                ? 'h-9 border-destructive/80 text-[14px] shadow-sm focus-visible:ring-destructive/30'
                : 'h-9 border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30'
            "
          />
          <p
            v-if="errors.name"
            class="text-[12.5px] font-medium text-destructive"
          >
            {{ $t('AUTOMATION.ADD.FORM.NAME.ERROR') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="automation-description"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('AUTOMATION.ADD.FORM.DESC.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="automation-description"
            v-model="automation.description"
            type="text"
            :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
            :class-name="
              errors.description
                ? 'h-9 border-destructive/80 text-[14px] shadow-sm focus-visible:ring-destructive/30'
                : 'h-9 border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30'
            "
          />
          <p
            v-if="errors.description"
            class="text-[12.5px] font-medium text-destructive"
          >
            {{ $t('AUTOMATION.ADD.FORM.DESC.ERROR') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="automation-event"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
          </RelayLabel>
          <select
            id="automation-event"
            v-model="automation.event_name"
            class="flex h-9 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
            :class="{ 'border-destructive/80': errors.event_name }"
            @change="onEventChange()"
          >
            <option
              v-for="event in automationRuleEvents"
              :key="event.key"
              :value="event.key"
            >
              {{ event.value }}
            </option>
          </select>
          <p
            v-if="errors.event_name"
            class="text-[12.5px] font-medium text-destructive"
          >
            {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
          </p>
          <p
            v-if="!isEditMode && hasAutomationMutated"
            class="pt-1 text-right text-xs text-muted-foreground"
          >
            {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
          </p>
        </div>

        <section class="space-y-3">
          <div>
            <h4 class="text-[14px] font-semibold text-foreground">
              {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
            </h4>
            <p class="mt-1 text-[12.5px] leading-relaxed text-muted-foreground">
              {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.DESC') }}
            </p>
          </div>
          <ul
            class="mb-0 grid list-none gap-4 rounded-xl border border-border/40 bg-background p-3 shadow-xs"
            :class="
              hasConditionErrors ? 'border-destructive/40 bg-destructive/5' : ''
            "
          >
            <template v-for="(condition, i) in automation.conditions" :key="i">
              <ConditionRow
                v-if="i === 0"
                ref="conditionsRef"
                v-model:attribute-key="automation.conditions[i].attribute_key"
                v-model:filter-operator="
                  automation.conditions[i].filter_operator
                "
                v-model:values="automation.conditions[i].values"
                :filter-types="filterTypes"
                :show-query-operator="false"
                @remove="removeFilter(i)"
              />
              <ConditionRow
                v-else
                ref="conditionsRef"
                v-model:attribute-key="automation.conditions[i].attribute_key"
                v-model:filter-operator="
                  automation.conditions[i].filter_operator
                "
                v-model:query-operator="
                  automation.conditions[i - 1].query_operator
                "
                v-model:values="automation.conditions[i].values"
                :filter-types="filterTypes"
                show-query-operator
                @remove="removeFilter(i)"
              />
            </template>
            <div>
              <RelayButton
                variant="outline"
                class="h-9 border-dashed border-border text-[13px] font-medium text-muted-foreground shadow-sm hover:bg-muted/50 hover:text-foreground"
                @click="appendNewCondition"
              >
                <Icon icon="i-lucide-plus" class="size-4" />
                {{ $t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL') }}
              </RelayButton>
            </div>
          </ul>
        </section>

        <section class="space-y-3">
          <div>
            <h4 class="text-[14px] font-semibold text-foreground">
              {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
            </h4>
            <p class="mt-1 text-[12.5px] leading-relaxed text-muted-foreground">
              {{ $t('AUTOMATION.ADD.FORM.ACTIONS.DESC') }}
            </p>
          </div>
          <ul
            class="mb-0 grid list-none rounded-xl border border-border/40 bg-background p-3 shadow-xs"
            :class="
              hasActionErrors ? 'border-destructive/40 bg-destructive/5' : ''
            "
          >
            <AutomationActionInput
              v-for="(action, i) in automation.actions"
              :key="i"
              v-model="automation.actions[i]"
              :action-types="automationActionTypes"
              dropdown-max-height="max-h-[7.5rem]"
              :dropdown-values="getActionDropdownValues(action.action_name)"
              :show-action-input="
                showActionInput(automationActionTypes, action.action_name)
              "
              :error-message="
                errors[`action_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
                  : ''
              "
              :initial-file-name="
                isEditMode ? getFileName(action, automation.files) : ''
              "
              @reset-action="resetAction(i)"
              @remove-action="removeAction(i)"
            />
            <div class="pt-2">
              <RelayButton
                variant="outline"
                class="h-9 border-dashed border-border text-[13px] font-medium text-muted-foreground shadow-sm hover:bg-muted/50 hover:text-foreground"
                @click="appendNewAction"
              >
                <Icon icon="i-lucide-plus" class="size-4" />
                {{ $t('AUTOMATION.ADD.ACTION_BUTTON_LABEL') }}
              </RelayButton>
            </div>
          </ul>
        </section>
      </div>

      <div class="mt-8 flex justify-end gap-3 border-t border-border/40 pt-6">
        <RelayButton
          type="button"
          variant="outline"
          class="h-9 rounded-lg px-4 text-foreground"
          @click="close"
        >
          {{ $t(cancelKey) }}
        </RelayButton>
        <RelayButton
          type="button"
          class="h-9 rounded-lg px-4 shadow-sm"
          @click="emitSaveAutomation"
        >
          {{ $t(submitKey) }}
        </RelayButton>
      </div>
    </div>
  </Dialog>
</template>
