<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayTextarea,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

defineProps({
  showActionButtons: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getSMSInboxes'),
};

const initialState = {
  title: '',
  message: '',
  inboxId: null,
  scheduledAt: null,
  selectedAudience: [],
};

const state = reactive({ ...initialState });

const rules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  // Added to disable the scheduled at field from being set to the current time
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const audienceList = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.SMS.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  message: getErrorMessage('message', 'MESSAGE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const isSubmitDisabled = computed(() => v$.value.$invalid);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const resetState = () => {
  Object.assign(state, initialState);
};

const handleCancel = () => emit('cancel');

const prepareCampaignDetails = () => ({
  title: state.title,
  message: state.message,
  inbox_id: state.inboxId,
  scheduled_at: formatToUTCString(state.scheduledAt),
  audience: state.selectedAudience?.map(id => ({
    id,
    type: 'Label',
  })),
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  resetState();
  handleCancel();
};

defineExpose({
  submit: handleSubmit,
  prepareCampaignDetails,
  isSubmitDisabled,
});
</script>

<template>
  <form class="flex flex-col gap-5" @submit.prevent="handleSubmit">
    <!-- Title -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.TITLE.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.title"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.TITLE.PLACEHOLDER')"
        class-name="h-9 text-[14px] shadow-sm rounded-md border-border/80 bg-muted/30 focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground/60"
      />
      <p v-if="formErrors.title" class="text-[12px] text-destructive">
        {{ formErrors.title }}
      </p>
    </div>

    <!-- Message -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.MESSAGE.LABEL') }}
      </RelayLabel>
      <RelayTextarea
        v-model="state.message"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.MESSAGE.PLACEHOLDER')"
        class-name="text-[14px] shadow-sm rounded-md border-border/80 bg-muted/30 focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground/60 min-h-[110px] resize-none"
      />
      <p v-if="formErrors.message" class="text-[12px] text-destructive">
        {{ formErrors.message }}
      </p>
    </div>

    <!-- Select Inbox -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.INBOX.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-muted/30 [&>div>button:not(.focused)]:dark:outline-border [&>div>button:not(.focused)]:hover:!outline-border"
      />
    </div>

    <!-- Audience -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.AUDIENCE.LABEL') }}
      </RelayLabel>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.SMS.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-muted/30"
      />
    </div>

    <!-- Scheduled time -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.SCHEDULED_AT.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.scheduledAt"
        type="datetime-local"
        :min="currentDateTime"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')"
        class-name="h-9 text-[14px] shadow-sm rounded-md border-border/80 bg-muted/30 focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
      />
      <p v-if="formErrors.scheduledAt" class="text-[12px] text-destructive">
        {{ formErrors.scheduledAt }}
      </p>
    </div>

    <!-- Action buttons (inline fallback) -->
    <div
      v-if="showActionButtons"
      class="flex items-center gap-3 pt-2 border-t border-border/60"
    >
      <RelayButton
        type="button"
        variant="outline"
        class="flex-1 h-9 bg-muted/30 text-foreground border-border/80 shadow-sm"
        @click="handleCancel"
      >
        {{ t('CAMPAIGN.SMS.CREATE.FORM.BUTTONS.CANCEL') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="flex-1 h-9 shadow-sm"
        :disabled="isCreating || isSubmitDisabled"
      >
        {{ t('CAMPAIGN.SMS.CREATE.FORM.BUTTONS.CREATE') }}
      </RelayButton>
    </div>
  </form>
</template>
