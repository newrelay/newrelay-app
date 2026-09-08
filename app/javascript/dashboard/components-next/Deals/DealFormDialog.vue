<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayDatePicker,
  RelayModalHeader,
  RelayActionDropdown,
} from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';
import {
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay/form/constants';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import ContactAPI from 'dashboard/api/contacts';
import { useCompaniesStore } from 'dashboard/stores/companies';
import { usePipelinesStore } from 'dashboard/stores/pipelines';

const props = defineProps({
  isLoading: { type: Boolean, default: false },
  stages: { type: Array, default: () => [] },
  deal: { type: Object, default: null },
});

const emit = defineEmits(['submit']);
const { t } = useI18n();
const route = useRoute();
const store = useStore();
const companiesStore = useCompaniesStore();
const pipelinesStore = usePipelinesStore();
const agents = useMapGetter('agents/getAgents');

const isOpen = ref(false);
const activeTab = ref('overview');
const showErrors = ref(false);
const contactOptions = ref([]);
const companyOptions = ref([]);
const companiesAvailable = ref(false);

const form = reactive({
  name: '',
  amount: '',
  pipelineStageId: '',
  closeOn: '',
  priority: 'medium',
  probability: 50,
  ownerId: '',
  contactId: '',
  companyId: '',
});

const DRAWER_TABS = computed(() => [
  { value: 'overview', label: t('DEALS.DRAWER.TABS.OVERVIEW') },
  { value: 'contacts', label: t('DEALS.DRAWER.TABS.CONTACTS') },
  { value: 'activity', label: t('DEALS.DRAWER.TABS.ACTIVITY') },
  { value: 'files', label: t('DEALS.DRAWER.TABS.FILES') },
  { value: 'notes', label: t('DEALS.DRAWER.TABS.NOTES') },
]);

const isEdit = computed(() => Boolean(props.deal?.id));

const stageOptions = computed(() =>
  (props.stages || []).map(stage => ({
    value: stage.id,
    label: stage.name,
  }))
);

const priorityOptions = computed(() => [
  { value: 'low', label: t('DEALS.PRIORITY.LOW') },
  { value: 'medium', label: t('DEALS.PRIORITY.MEDIUM') },
  { value: 'high', label: t('DEALS.PRIORITY.HIGH') },
]);

const ownerOptions = computed(() =>
  (agents.value || []).map(agent => ({
    value: agent.id,
    label: agent.name || agent.availableName || agent.email,
  }))
);

const isFormValid = computed(
  () => form.name.trim() !== '' && Boolean(form.pipelineStageId)
);

const selectedStage = computed(() =>
  (props.stages || []).find(
    stage => String(stage.id) === String(form.pipelineStageId)
  )
);

const stageBadgeClass = stage => {
  if (stage?.isWon) return 'bg-success/10 text-success';
  if (stage?.isLost) return 'bg-destructive/10 text-destructive';
  return 'bg-primary/10 text-primary';
};

const stageMenuItems = computed(() =>
  (props.stages || []).map(stage => ({
    label: stage.name,
    value: stage.id,
    action: 'stage',
  }))
);

const selectStage = ({ value }) => {
  form.pipelineStageId = value;
};

const pipelineName = computed(
  () => pipelinesStore.getDefaultPipeline?.name || t('PIPELINES.HEADER')
);

const optionalId = value => {
  if (value === '' || value === null || value === undefined) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const companyName = computed(() => {
  const fromOptions = companyOptions.value.find(
    option => String(option.value) === String(form.companyId)
  )?.label;
  return fromOptions || props.deal?.company?.name || '';
});

const companyRoute = computed(() => {
  const id = optionalId(form.companyId);
  if (!id) return null;
  return {
    name: 'companies_dashboard_show',
    params: {
      accountId: route.params.accountId,
      companyId: id,
    },
  };
});

const companyInitial = computed(() =>
  (companyName.value || '?').slice(0, 1).toUpperCase()
);

const selectedOwner = computed(() =>
  (agents.value || []).find(agent => String(agent.id) === String(form.ownerId))
);

const ownerLabel = computed(() => {
  const fromOptions = ownerOptions.value.find(
    option => String(option.value) === String(form.ownerId)
  )?.label;
  return (
    fromOptions ||
    props.deal?.owner?.availableName ||
    props.deal?.owner?.name ||
    ''
  );
});

const ownerAvatar = computed(
  () =>
    selectedOwner.value?.thumbnail ||
    selectedOwner.value?.avatarUrl ||
    props.deal?.owner?.thumbnail ||
    ''
);

const selectedContactLabel = computed(() => {
  const fromOptions = contactOptions.value.find(
    option => String(option.value) === String(form.contactId)
  )?.label;
  return fromOptions || props.deal?.contact?.name || '';
});

const formattedAmount = computed(() => {
  const amountNumber = Number.parseFloat(form.amount || '0');
  if (!Number.isFinite(amountNumber)) return t('DEALS.DRAWER.NO_VALUE');
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: props.deal?.currency || 'USD',
      maximumFractionDigits: 0,
    }).format(amountNumber);
  } catch {
    return `$${amountNumber.toFixed(0)}`;
  }
});

const formattedCloseOn = computed(() => {
  if (!form.closeOn) return t('DEALS.DRAWER.NO_VALUE');
  return new Date(form.closeOn).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
});

const probabilityBarClass = computed(() => {
  const widths = [
    'w-0',
    'w-[10%]',
    'w-[20%]',
    'w-[30%]',
    'w-[40%]',
    'w-[50%]',
    'w-[60%]',
    'w-[70%]',
    'w-[80%]',
    'w-[90%]',
    'w-full',
  ];
  return widths[Math.min(10, Math.round(Number(form.probability || 0) / 10))];
});

const priorityClass = computed(() => {
  if (form.priority === 'high') return 'text-destructive';
  if (form.priority === 'low') return 'text-success';
  return 'text-warning';
});

const applyDealToForm = deal => {
  form.name = deal?.name || '';
  form.amount =
    deal?.amountCents != null
      ? (Number(deal.amountCents) / 100).toFixed(2)
      : '';
  form.pipelineStageId = deal?.pipelineStageId || props.stages?.[0]?.id || '';
  form.closeOn = deal?.closeOn || '';
  form.priority = deal?.priority || 'medium';
  form.probability = deal?.probability != null ? Number(deal.probability) : 50;
  form.ownerId = deal?.ownerId || '';
  form.contactId = deal?.contactId || '';
  form.companyId = deal?.companyId || '';
  showErrors.value = false;
};

const resetForm = () => applyDealToForm(props.deal);

watch(
  () => props.deal,
  () => {
    if (isOpen.value) resetForm();
  }
);

watch(
  () => props.stages,
  stages => {
    if (!form.pipelineStageId && stages?.length) {
      form.pipelineStageId = stages[0].id;
    }
  },
  { immediate: true }
);

const loadLinkOptions = async () => {
  try {
    await store.dispatch('agents/get');
  } catch {
    // agents may already be loaded
  }

  try {
    const { data } = await ContactAPI.get(1, 'name');
    const payload = data.payload || [];
    contactOptions.value = payload.map(contact => ({
      value: contact.id,
      label: contact.name || contact.email || `#${contact.id}`,
    }));
  } catch {
    contactOptions.value = [];
  }

  try {
    await companiesStore.get({ page: 1, sort: 'name' });
    companyOptions.value = (companiesStore.getCompaniesList || []).map(
      company => ({
        value: company.id,
        label: company.name,
      })
    );
    companiesAvailable.value = true;
  } catch {
    companyOptions.value = [];
    companiesAvailable.value = false;
  }
};

const open = (deal = null) => {
  isOpen.value = true;
  activeTab.value = 'overview';
  applyDealToForm(deal || props.deal);
  loadLinkOptions();
};

const close = () => {
  isOpen.value = false;
  showErrors.value = false;
};

const onSuccess = () => close();

const submit = () => {
  if (!isFormValid.value) {
    showErrors.value = true;
    return;
  }
  const amountNumber = Number.parseFloat(form.amount || '0');
  emit('submit', {
    name: form.name.trim(),
    amountCents: Number.isFinite(amountNumber)
      ? Math.round(amountNumber * 100)
      : 0,
    pipelineStageId: Number(form.pipelineStageId),
    closeOn: form.closeOn || null,
    priority: form.priority,
    probability: Number(form.probability) || 0,
    ownerId: optionalId(form.ownerId),
    contactId: optionalId(form.contactId),
    companyId: optionalId(form.companyId),
  });
};

defineExpose({ open, close, onSuccess, dialogRef: { open, close } });
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      data-relay
      :class="RELAY_DIALOG_OVERLAY_CLASS"
      @click.self="close"
    >
      <div
        class="fixed inset-y-0 right-0 z-[210] flex w-full translate-x-0 animate-in slide-in-from-right flex-col border-l border-border bg-card shadow-2xl duration-300 sm:w-[480px]"
        role="dialog"
        aria-modal="true"
      >
        <form class="flex h-full min-h-0 flex-col" @submit.prevent="submit">
          <RelayModalHeader
            v-if="!isEdit"
            :title="$t('DEALS.FORM.CREATE_TITLE')"
            :description="$t('DEALS.FORM.DESCRIPTION')"
            @close="close"
          />

          <div v-else class="shrink-0 border-b border-border/60 p-6">
            <div class="mb-4 flex items-start justify-between gap-2">
              <div class="min-w-0 flex-1">
                <RelayInput
                  v-model="form.name"
                  :placeholder="$t('DEALS.FORM.NAME.PLACEHOLDER')"
                  class-name="h-auto border-0 bg-transparent px-0 py-0 text-xl font-bold tracking-tight shadow-none focus-visible:ring-1"
                />
                <p
                  v-if="showErrors && !form.name.trim()"
                  class="mt-1 text-[12px] text-destructive"
                >
                  {{ $t('DEALS.FORM.NAME.ERROR') }}
                </p>
              </div>
              <RelayButton
                type="button"
                variant="ghost"
                size="icon"
                class="size-8 shrink-0 text-muted-foreground hover:bg-muted"
                @click="close"
              >
                <span class="i-lucide-x size-4" />
              </RelayButton>
            </div>

            <div class="mb-6 flex items-center justify-between gap-3">
              <div class="flex min-w-0 items-center gap-2.5">
                <div
                  class="flex size-8 shrink-0 items-center justify-center rounded-lg border border-border bg-muted text-xs font-semibold text-foreground shadow-sm"
                >
                  {{ companyInitial }}
                </div>
                <span class="truncate font-medium text-foreground">
                  {{ companyName || $t('DEALS.DRAWER.NO_VALUE') }}
                </span>
              </div>
              <RelayButton
                v-if="companyRoute"
                as="router-link"
                :to="companyRoute"
                variant="outline"
                size="sm"
                class="h-8 shrink-0 gap-1.5 text-xs text-muted-foreground"
                @click="close"
              >
                {{ $t('DEALS.DRAWER.VIEW_COMPANY') }}
                <span class="i-lucide-external-link size-3" />
              </RelayButton>
            </div>

            <div class="grid grid-cols-3 gap-4 border-t border-border/60 pt-6">
              <div class="flex min-w-0 flex-col gap-1.5">
                <span class="text-xs font-medium text-muted-foreground">
                  {{ $t('DEALS.FORM.STAGE.LABEL') }}
                </span>
                <RelayActionDropdown
                  :menu-items="stageMenuItems"
                  align="start"
                  @action="selectStage"
                >
                  <template #trigger>
                    <RelayButton
                      type="button"
                      variant="outline"
                      size="sm"
                      class="h-8 w-full justify-between px-2 text-xs font-semibold"
                      :class="stageBadgeClass(selectedStage)"
                    >
                      {{
                        selectedStage?.name ||
                        $t('DEALS.FORM.STAGE.PLACEHOLDER')
                      }}
                      <span class="i-lucide-chevron-down size-3 opacity-50" />
                    </RelayButton>
                  </template>
                </RelayActionDropdown>
              </div>
              <div class="flex min-w-0 flex-col gap-1.5">
                <span class="text-xs font-medium text-muted-foreground">
                  {{ $t('DEALS.DRAWER.DEAL_VALUE') }}
                </span>
                <span
                  class="flex h-8 items-center text-sm font-semibold text-foreground"
                >
                  {{ formattedAmount }}
                </span>
              </div>
              <div class="flex min-w-0 flex-col gap-1.5">
                <span class="text-xs font-medium text-muted-foreground">
                  {{ $t('DEALS.DRAWER.CLOSE_DATE') }}
                </span>
                <span
                  class="flex h-8 items-center text-sm font-semibold text-foreground"
                >
                  {{ formattedCloseOn }}
                </span>
              </div>
            </div>
          </div>

          <div v-if="!isEdit" class="hide-scrollbar flex-1 overflow-y-auto p-6">
            <div class="flex flex-col gap-4">
              <div :class="RELAY_FORM_FIELD_CLASS">
                <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                  {{ $t('DEALS.FORM.NAME.LABEL') }}
                </RelayLabel>
                <RelayInput
                  v-model="form.name"
                  :placeholder="$t('DEALS.FORM.NAME.PLACEHOLDER')"
                />
                <p
                  v-if="showErrors && !form.name.trim()"
                  class="text-[12px] text-destructive"
                >
                  {{ $t('DEALS.FORM.NAME.ERROR') }}
                </p>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div :class="RELAY_FORM_FIELD_CLASS">
                  <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                    {{ $t('DEALS.FORM.AMOUNT.LABEL') }}
                  </RelayLabel>
                  <RelayInput
                    v-model="form.amount"
                    type="number"
                    step="0.01"
                    min="0"
                    :placeholder="$t('DEALS.FORM.AMOUNT.PLACEHOLDER')"
                  />
                </div>
                <div :class="RELAY_FORM_FIELD_CLASS">
                  <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                    {{ $t('DEALS.FORM.PROBABILITY.LABEL') }}
                  </RelayLabel>
                  <RelayInput
                    v-model="form.probability"
                    type="number"
                    min="0"
                    max="100"
                  />
                </div>
              </div>

              <div :class="RELAY_FORM_FIELD_CLASS">
                <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                  {{ $t('DEALS.FORM.STAGE.LABEL') }}
                </RelayLabel>
                <ComboBox
                  v-model="form.pipelineStageId"
                  :options="stageOptions"
                  :placeholder="$t('DEALS.FORM.STAGE.PLACEHOLDER')"
                />
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div :class="RELAY_FORM_FIELD_CLASS">
                  <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                    {{ $t('DEALS.FORM.CLOSE_ON.LABEL') }}
                  </RelayLabel>
                  <RelayDatePicker
                    v-model="form.closeOn"
                    value-format="yyyy-MM-dd"
                    display-format="MMM d, yyyy"
                    :placeholder="$t('DEALS.FORM.CLOSE_ON.LABEL')"
                  />
                </div>
                <div :class="RELAY_FORM_FIELD_CLASS">
                  <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                    {{ $t('DEALS.FORM.PRIORITY.LABEL') }}
                  </RelayLabel>
                  <ComboBox
                    v-model="form.priority"
                    :options="priorityOptions"
                  />
                </div>
              </div>

              <div :class="RELAY_FORM_FIELD_CLASS">
                <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                  {{ $t('DEALS.FORM.OWNER.LABEL') }}
                </RelayLabel>
                <ComboBox
                  v-model="form.ownerId"
                  :options="ownerOptions"
                  :placeholder="$t('DEALS.FORM.OWNER.PLACEHOLDER')"
                />
              </div>

              <div :class="RELAY_FORM_FIELD_CLASS">
                <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                  {{ $t('DEALS.FORM.CONTACT.LABEL') }}
                </RelayLabel>
                <ComboBox
                  v-model="form.contactId"
                  :options="contactOptions"
                  :placeholder="$t('DEALS.FORM.CONTACT.PLACEHOLDER')"
                />
              </div>

              <div v-if="companiesAvailable" :class="RELAY_FORM_FIELD_CLASS">
                <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
                  {{ $t('DEALS.FORM.COMPANY.LABEL') }}
                </RelayLabel>
                <ComboBox
                  v-model="form.companyId"
                  :options="companyOptions"
                  :placeholder="$t('DEALS.FORM.COMPANY.PLACEHOLDER')"
                />
              </div>
            </div>
          </div>

          <div
            v-else
            class="hide-scrollbar flex min-h-0 flex-1 flex-col overflow-y-auto bg-muted/10 dark:bg-background/30"
          >
            <div class="shrink-0 border-b border-border/60 bg-card px-6">
              <div
                class="flex w-full justify-start gap-6 overflow-x-auto"
                role="tablist"
              >
                <button
                  v-for="tab in DRAWER_TABS"
                  :key="tab.value"
                  type="button"
                  role="tab"
                  :aria-selected="activeTab === tab.value"
                  class="reset-base h-12 shrink-0 border-b-2 px-0 text-sm font-medium"
                  :class="
                    activeTab === tab.value
                      ? 'border-primary text-primary'
                      : 'border-transparent text-muted-foreground hover:text-foreground'
                  "
                  @click="activeTab = tab.value"
                >
                  {{ tab.label }}
                </button>
              </div>
            </div>

            <div
              v-if="activeTab === 'overview'"
              class="flex flex-1 flex-col gap-6 p-6"
            >
              <div class="flex flex-col gap-4">
                <h3 class="text-sm font-semibold text-foreground">
                  {{ $t('DEALS.DRAWER.DEAL_INFO') }}
                </h3>
                <div
                  class="grid grid-cols-[1fr_2fr] items-center gap-x-2 gap-y-4 text-sm"
                >
                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.DRAWER.PIPELINE') }}
                  </div>
                  <div class="font-medium">{{ pipelineName }}</div>

                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.FORM.OWNER.LABEL') }}
                  </div>
                  <div class="flex min-w-0 items-center gap-2">
                    <Avatar
                      v-if="ownerLabel"
                      :src="ownerAvatar"
                      :name="ownerLabel"
                      :size="20"
                      rounded-full
                    />
                    <div class="min-w-0 flex-1">
                      <ComboBox
                        v-model="form.ownerId"
                        :options="ownerOptions"
                        :placeholder="$t('DEALS.FORM.OWNER.PLACEHOLDER')"
                      />
                    </div>
                  </div>

                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.FORM.PRIORITY.LABEL') }}
                  </div>
                  <div class="flex min-w-0 items-center gap-1.5">
                    <span
                      class="i-lucide-flag size-3.5 shrink-0"
                      :class="priorityClass"
                    />
                    <div class="min-w-0 flex-1">
                      <ComboBox
                        v-model="form.priority"
                        :options="priorityOptions"
                      />
                    </div>
                  </div>

                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.FORM.PROBABILITY.LABEL') }}
                  </div>
                  <div class="flex w-full max-w-[220px] items-center gap-3">
                    <RelayInput
                      v-model="form.probability"
                      type="number"
                      min="0"
                      max="100"
                      class-name="h-9 w-14 px-2 text-sm font-medium"
                    />
                    <div
                      class="h-1.5 flex-1 overflow-hidden rounded-full bg-muted"
                    >
                      <div
                        class="h-full rounded-full bg-primary"
                        :class="probabilityBarClass"
                      />
                    </div>
                  </div>

                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.FORM.AMOUNT.LABEL') }}
                  </div>
                  <RelayInput
                    v-model="form.amount"
                    type="number"
                    step="0.01"
                    min="0"
                    :placeholder="$t('DEALS.FORM.AMOUNT.PLACEHOLDER')"
                  />

                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.FORM.CLOSE_ON.LABEL') }}
                  </div>
                  <RelayDatePicker
                    v-model="form.closeOn"
                    value-format="yyyy-MM-dd"
                    display-format="MMM d, yyyy"
                    :placeholder="$t('DEALS.FORM.CLOSE_ON.LABEL')"
                  />

                  <div class="flex items-center text-muted-foreground">
                    {{ $t('DEALS.FORM.CONTACT.LABEL') }}
                  </div>
                  <ComboBox
                    v-model="form.contactId"
                    :options="contactOptions"
                    :placeholder="$t('DEALS.FORM.CONTACT.PLACEHOLDER')"
                  />

                  <template v-if="companiesAvailable">
                    <div class="flex items-center text-muted-foreground">
                      {{ $t('DEALS.FORM.COMPANY.LABEL') }}
                    </div>
                    <ComboBox
                      v-model="form.companyId"
                      :options="companyOptions"
                      :placeholder="$t('DEALS.FORM.COMPANY.PLACEHOLDER')"
                    />
                  </template>
                </div>
              </div>
            </div>

            <div
              v-else-if="activeTab === 'contacts'"
              class="flex flex-1 flex-col p-6"
            >
              <div
                v-if="selectedContactLabel"
                class="flex items-center gap-3 rounded-xl border border-border bg-card p-4"
              >
                <div
                  class="flex size-10 items-center justify-center rounded-full bg-muted text-sm font-medium"
                >
                  {{ selectedContactLabel.slice(0, 1).toUpperCase() }}
                </div>
                <span class="text-sm font-medium text-foreground">
                  {{ selectedContactLabel }}
                </span>
              </div>
              <div
                v-else
                class="mx-auto flex max-w-sm flex-col items-center justify-center py-16 text-center opacity-60"
              >
                <p class="text-sm font-medium text-foreground">
                  {{ $t('DEALS.DRAWER.EMPTY.CONTACTS') }}
                </p>
              </div>
            </div>

            <div
              v-else
              class="mx-auto flex max-w-sm flex-1 flex-col items-center justify-center py-16 text-center opacity-60"
            >
              <p
                v-if="activeTab === 'activity'"
                class="text-sm font-medium text-foreground"
              >
                {{ $t('DEALS.DRAWER.EMPTY.ACTIVITY') }}
              </p>
              <p
                v-else-if="activeTab === 'files'"
                class="text-sm font-medium text-foreground"
              >
                {{ $t('DEALS.DRAWER.EMPTY.FILES') }}
              </p>
              <p v-else class="text-sm font-medium text-foreground">
                {{ $t('DEALS.DRAWER.EMPTY.NOTES') }}
              </p>
            </div>
          </div>

          <div
            class="flex shrink-0 items-center gap-3 border-t border-border bg-card p-4 shadow-sm"
          >
            <RelayButton
              type="button"
              variant="outline"
              class="h-10 flex-1 bg-transparent font-medium"
              @click="close"
            >
              {{ $t('DEALS.FORM.CANCEL') }}
            </RelayButton>
            <RelayButton
              type="submit"
              class="h-10 flex-1 font-medium"
              :disabled="!isFormValid || isLoading"
            >
              {{ isEdit ? $t('DEALS.FORM.SAVE') : $t('DEALS.FORM.CREATE') }}
            </RelayButton>
          </div>
        </form>
      </div>
    </div>
  </Teleport>
</template>
