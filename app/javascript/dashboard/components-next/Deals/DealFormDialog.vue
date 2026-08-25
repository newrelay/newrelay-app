<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayDatePicker,
} from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  isLoading: { type: Boolean, default: false },
  stages: { type: Array, default: () => [] },
  deal: { type: Object, default: null },
});

const emit = defineEmits(['submit']);
const { t } = useI18n();

const isOpen = ref(false);
const showErrors = ref(false);

const form = reactive({
  name: '',
  amount: '',
  pipelineStageId: '',
  closeOn: '',
  priority: 'medium',
  probability: 50,
});

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

const isFormValid = computed(
  () => form.name.trim() !== '' && Boolean(form.pipelineStageId)
);

const resetForm = () => {
  form.name = props.deal?.name || '';
  form.amount =
    props.deal?.amountCents != null
      ? (Number(props.deal.amountCents) / 100).toFixed(2)
      : '';
  form.pipelineStageId = props.deal?.pipelineStageId || props.stages?.[0]?.id || '';
  form.closeOn = props.deal?.closeOn || '';
  form.priority = props.deal?.priority || 'medium';
  form.probability =
    props.deal?.probability != null ? Number(props.deal.probability) : 50;
  showErrors.value = false;
};

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

const open = (deal = null) => {
  // deal override via prop watch; parent sets :deal before open
  isOpen.value = true;
  resetForm();
  if (deal) {
    form.name = deal.name || '';
    form.amount =
      deal.amountCents != null
        ? (Number(deal.amountCents) / 100).toFixed(2)
        : '';
    form.pipelineStageId = deal.pipelineStageId || props.stages?.[0]?.id || '';
    form.closeOn = deal.closeOn || '';
    form.priority = deal.priority || 'medium';
    form.probability = deal.probability != null ? Number(deal.probability) : 50;
  }
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
  });
};

defineExpose({ open, close, onSuccess, dialogRef: { open, close } });
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4"
    >
      <div
        :class="RELAY_DIALOG_OVERLAY_CLASS"
        class="absolute inset-0"
        @click="close"
      />
      <div
        class="relative z-10 flex w-full max-w-lg flex-col overflow-hidden rounded-xl border border-border bg-card shadow-lg"
        role="dialog"
        aria-modal="true"
      >
        <RelayModalHeader
          :title="
            isEdit ? $t('DEALS.FORM.EDIT_TITLE') : $t('DEALS.FORM.CREATE_TITLE')
          "
          :description="$t('DEALS.FORM.DESCRIPTION')"
          @close="close"
        />
        <form :class="RELAY_MODAL_BODY_CLASS" @submit.prevent="submit">
          <div class="flex flex-col gap-4">
            <div class="flex flex-col gap-1.5">
              <RelayLabel class="text-[13.5px] font-medium text-foreground">
                {{ $t('DEALS.FORM.NAME.LABEL') }}
              </RelayLabel>
              <RelayInput
                v-model="form.name"
                :placeholder="$t('DEALS.FORM.NAME.PLACEHOLDER')"
                class="text-[14px]"
              />
              <p
                v-if="showErrors && !form.name.trim()"
                class="text-[12px] text-destructive"
              >
                {{ $t('DEALS.FORM.NAME.ERROR') }}
              </p>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="flex flex-col gap-1.5">
                <RelayLabel class="text-[13.5px] font-medium text-foreground">
                  {{ $t('DEALS.FORM.AMOUNT.LABEL') }}
                </RelayLabel>
                <RelayInput
                  v-model="form.amount"
                  type="number"
                  step="0.01"
                  min="0"
                  :placeholder="$t('DEALS.FORM.AMOUNT.PLACEHOLDER')"
                  class="text-[14px]"
                />
              </div>
              <div class="flex flex-col gap-1.5">
                <RelayLabel class="text-[13.5px] font-medium text-foreground">
                  {{ $t('DEALS.FORM.PROBABILITY.LABEL') }}
                </RelayLabel>
                <RelayInput
                  v-model="form.probability"
                  type="number"
                  min="0"
                  max="100"
                  class="text-[14px]"
                />
              </div>
            </div>

            <div class="flex flex-col gap-1.5">
              <RelayLabel class="text-[13.5px] font-medium text-foreground">
                {{ $t('DEALS.FORM.STAGE.LABEL') }}
              </RelayLabel>
              <ComboBox
                v-model="form.pipelineStageId"
                :options="stageOptions"
                :placeholder="$t('DEALS.FORM.STAGE.PLACEHOLDER')"
              />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="flex flex-col gap-1.5">
                <RelayLabel class="text-[13.5px] font-medium text-foreground">
                  {{ $t('DEALS.FORM.CLOSE_ON.LABEL') }}
                </RelayLabel>
                <RelayDatePicker
                  v-model="form.closeOn"
                  value-format="yyyy-MM-dd"
                  display-format="MMM d, yyyy"
                  :placeholder="$t('DEALS.FORM.CLOSE_ON.LABEL')"
                />
              </div>
              <div class="flex flex-col gap-1.5">
                <RelayLabel class="text-[13.5px] font-medium text-foreground">
                  {{ $t('DEALS.FORM.PRIORITY.LABEL') }}
                </RelayLabel>
                <ComboBox
                  v-model="form.priority"
                  :options="priorityOptions"
                />
              </div>
            </div>
          </div>

          <div class="mt-6 flex justify-end gap-3">
            <RelayButton
              type="button"
              variant="outline"
              class="h-9 border-border px-5 text-[13px] font-medium"
              @click="close"
            >
              {{ $t('DEALS.FORM.CANCEL') }}
            </RelayButton>
            <RelayButton
              type="submit"
              class="h-9 px-5 text-[13px] font-medium"
              :disabled="!isFormValid || isLoading"
            >
              {{
                isEdit ? $t('DEALS.FORM.SAVE') : $t('DEALS.FORM.CREATE')
              }}
            </RelayButton>
          </div>
        </form>
      </div>
    </div>
  </Teleport>
</template>
