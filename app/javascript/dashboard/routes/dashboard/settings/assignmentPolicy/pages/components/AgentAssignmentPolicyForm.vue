<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import FairDistribution from 'dashboard/components-next/AssignmentPolicy/components/FairDistribution.vue';
import DataTable from 'dashboard/components-next/AssignmentPolicy/components/DataTable.vue';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import {
  OPTIONS,
  ROUND_ROBIN,
  EARLIEST_CREATED,
  DEFAULT_FAIR_DISTRIBUTION_LIMIT,
  DEFAULT_FAIR_DISTRIBUTION_WINDOW,
} from 'dashboard/routes/dashboard/settings/assignmentPolicy/constants';

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({
      name: '',
      description: '',
      assignmentOrder: ROUND_ROBIN,
      conversationPriority: EARLIEST_CREATED,
      fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
      fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
    }),
  },
  mode: {
    type: String,
    required: true,
    validator: value => ['CREATE', 'EDIT'].includes(value),
  },
  policyInboxes: {
    type: Array,
    default: () => [],
  },
  inboxList: {
    type: Array,
    default: () => [],
  },
  showInboxSection: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isInboxLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'submit',
  'cancel',
  'addInbox',
  'deleteInbox',
  'navigateToInbox',
]);

const { t } = useI18n();
const route = useRoute();

const accountId = computed(() => Number(route.params.accountId));
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY';

const OPTION_ICONS = {
  round_robin: 'i-lucide-chevron-right',
  balanced: 'i-lucide-scale',
  earliest_created: 'i-lucide-check',
  longest_waiting: 'i-lucide-filter',
};

const state = reactive({
  name: '',
  description: '',
  enabled: true,
  assignmentOrder: ROUND_ROBIN,
  conversationPriority: EARLIEST_CREATED,
  fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
  fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
});

const nameTouched = ref(false);

const isNameValid = computed(() => state.name.trim().length > 0);

const createOption = (
  type,
  key,
  stateKey,
  disabled = false,
  disabledMessage = '',
  disabledLabel = ''
) => ({
  key,
  icon: OPTION_ICONS[key],
  label: t(`${BASE_KEY}.FORM.${type}.${key.toUpperCase()}.LABEL`),
  description: t(`${BASE_KEY}.FORM.${type}.${key.toUpperCase()}.DESCRIPTION`),
  isActive: state[stateKey] === key,
  disabled,
  disabledMessage,
  disabledLabel,
});

const assignmentOrderOptions = computed(() => {
  const hasAdvancedAssignment = isFeatureEnabledonAccount.value(
    accountId.value,
    'advanced_assignment'
  );

  return OPTIONS.ORDER.map(key => {
    const isBalanced = key === 'balanced';
    const disabled = isBalanced && !hasAdvancedAssignment;
    return createOption(
      'ASSIGNMENT_ORDER',
      key,
      'assignmentOrder',
      disabled,
      disabled
        ? t(`${BASE_KEY}.FORM.ASSIGNMENT_ORDER.BALANCED.PREMIUM_MESSAGE`)
        : '',
      disabled
        ? t(`${BASE_KEY}.FORM.ASSIGNMENT_ORDER.BALANCED.PREMIUM_BADGE`)
        : ''
    );
  });
});

const assignmentPriorityOptions = computed(() =>
  OPTIONS.PRIORITY.map(key =>
    createOption('ASSIGNMENT_PRIORITY', key, 'conversationPriority')
  )
);

const radioSections = computed(() => [
  {
    key: 'assignmentOrder',
    label: t(`${BASE_KEY}.FORM.ASSIGNMENT_ORDER.LABEL`),
    options: assignmentOrderOptions.value,
  },
  {
    key: 'conversationPriority',
    label: t(`${BASE_KEY}.FORM.ASSIGNMENT_PRIORITY.LABEL`),
    options: assignmentPriorityOptions.value,
  },
]);

const buttonLabel = computed(() =>
  t(`${BASE_KEY}.${props.mode.toUpperCase()}.${props.mode}_BUTTON`)
);

const optionCardClass = option => [
  'flex flex-col text-left p-4 rounded-xl border transition-all',
  option.isActive
    ? 'border-primary bg-primary/5 ring-1 ring-primary/20'
    : 'border-border/60 bg-background hover:border-primary/40 shadow-sm',
  option.disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
];

const selectOption = (sectionKey, option) => {
  if (option.disabled) return;
  state[sectionKey] = option.key;
};

const resetForm = () => {
  Object.assign(state, {
    name: '',
    description: '',
    enabled: true,
    assignmentOrder: ROUND_ROBIN,
    conversationPriority: EARLIEST_CREATED,
    fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
    fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
  });
  nameTouched.value = false;
};

const handleSubmit = () => {
  nameTouched.value = true;
  if (!isNameValid.value) return;
  emit('submit', { ...state });
};

watch(
  () => props.initialData,
  newData => {
    Object.assign(state, newData);
  },
  { immediate: true, deep: true }
);

defineExpose({
  resetForm,
});
</script>

<template>
  <form class="flex w-full flex-col" @submit.prevent="handleSubmit">
    <div class="flex-1 space-y-6 overflow-y-auto p-5">
      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="assignment-policy-name"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ t(`${BASE_KEY}.FORM.NAME.LABEL`) }}
        </RelayLabel>
        <RelayInput
          id="assignment-policy-name"
          v-model="state.name"
          type="text"
          :placeholder="t(`${BASE_KEY}.FORM.NAME.PLACEHOLDER`)"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="nameTouched = true"
        />
        <p v-if="nameTouched && !isNameValid" class="text-xs text-destructive">
          {{ t(`${BASE_KEY}.FORM.NAME.ERROR`) }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="assignment-policy-description"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ t(`${BASE_KEY}.FORM.DESCRIPTION.LABEL`) }}
          <span class="font-normal text-muted-foreground">
            {{ t(`${BASE_KEY}.FORM.DESCRIPTION.OPTIONAL`) }}
          </span>
        </RelayLabel>
        <RelayInput
          id="assignment-policy-description"
          v-model="state.description"
          type="text"
          :placeholder="t(`${BASE_KEY}.FORM.DESCRIPTION.PLACEHOLDER`)"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>

      <div
        v-for="section in radioSections"
        :key="section.key"
        class="space-y-3 pt-2"
      >
        <label class="text-[13.5px] font-medium text-foreground">
          {{ section.label }}
        </label>
        <div class="grid grid-cols-1 gap-3 xs:grid-cols-2">
          <button
            v-for="option in section.options"
            :key="option.key"
            type="button"
            :disabled="option.disabled"
            :class="optionCardClass(option)"
            @click="selectOption(section.key, option)"
          >
            <div
              class="mb-3 flex size-8 items-center justify-center rounded-lg"
              :class="
                option.isActive
                  ? 'bg-primary/10 text-primary'
                  : 'bg-muted text-foreground'
              "
            >
              <Icon :icon="option.icon" class="size-4" />
            </div>
            <div class="mb-1 flex items-center gap-2">
              <span class="text-[14px] font-semibold text-foreground">
                {{ option.label }}
              </span>
              <span
                v-if="option.disabledLabel"
                class="rounded bg-amber-100 px-1.5 py-0.5 text-[10px] font-medium text-amber-700"
              >
                {{ option.disabledLabel }}
              </span>
            </div>
            <span class="text-[12px] leading-relaxed text-muted-foreground">
              {{
                option.disabled && option.disabledMessage
                  ? option.disabledMessage
                  : option.description
              }}
            </span>
          </button>
        </div>
      </div>

      <div class="space-y-4 border-t border-border/40 pt-4">
        <div>
          <h4 class="text-[14px] font-semibold text-foreground">
            {{ t(`${BASE_KEY}.FORM.FAIR_DISTRIBUTION.LABEL`) }}
          </h4>
          <p class="mt-1 text-[12.5px] leading-relaxed text-muted-foreground">
            {{ t(`${BASE_KEY}.FORM.FAIR_DISTRIBUTION.DESCRIPTION`) }}
          </p>
        </div>
        <FairDistribution
          v-model:fair-distribution-limit="state.fairDistributionLimit"
          v-model:fair-distribution-window="state.fairDistributionWindow"
        />
      </div>

      <div
        v-if="showInboxSection"
        class="flex flex-col gap-4 border-t border-border/40 pt-4"
      >
        <div class="flex w-full items-end justify-between gap-4">
          <div class="flex flex-col items-start gap-1 py-1">
            <label class="py-1 text-sm font-medium text-foreground">
              {{ t(`${BASE_KEY}.FORM.INBOXES.LABEL`) }}
            </label>
            <p class="mb-0 text-sm text-muted-foreground">
              {{ t(`${BASE_KEY}.FORM.INBOXES.DESCRIPTION`) }}
            </p>
          </div>
          <AddDataDropdown
            :label="t(`${BASE_KEY}.FORM.INBOXES.ADD_BUTTON`)"
            :search-placeholder="
              t(`${BASE_KEY}.FORM.INBOXES.DROPDOWN.SEARCH_PLACEHOLDER`)
            "
            :items="inboxList"
            @add="$emit('addInbox', $event)"
          />
        </div>
        <DataTable
          :items="policyInboxes"
          :is-fetching="isInboxLoading"
          :empty-state-message="t(`${BASE_KEY}.FORM.INBOXES.EMPTY_STATE`)"
          @delete="$emit('deleteInbox', $event)"
          @navigate="$emit('navigateToInbox', $event)"
        />
      </div>
    </div>

    <div
      class="flex justify-end gap-3 border-t border-border/40 bg-background/50 p-5"
    >
      <RelayButton type="button" variant="outline" @click="emit('cancel')">
        {{ t(`${BASE_KEY}.FORM.CANCEL_BUTTON`) }}
      </RelayButton>
      <RelayButton type="submit" :disabled="!isNameValid || isLoading">
        {{ buttonLabel }}
      </RelayButton>
    </div>
  </form>
</template>
