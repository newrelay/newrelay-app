<script setup>
import { reactive, computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';

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
  inboxes: useMapGetter('inboxes/getWhatsAppInboxes'),
  getFilteredWhatsAppTemplates: useMapGetter(
    'inboxes/getFilteredWhatsAppTemplates'
  ),
};

const initialState = {
  title: '',
  inboxId: null,
  templateId: null,
  scheduledAt: null,
  selectedAudience: [],
};

const state = reactive({ ...initialState });
const templateParserRef = ref(null);

const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  templateId: { required },
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

const templateOptions = computed(() => {
  if (!state.inboxId) return [];
  const templates = formState.getFilteredWhatsAppTemplates.value(state.inboxId);
  return templates.map(template => {
    // Create a more user-friendly label from template name
    const friendlyName = template.name
      .replace(/_/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase());

    return {
      value: template.id,
      label: `${friendlyName} (${template.language || 'en'})`,
      template: template,
    };
  });
});

const selectedTemplate = computed(() => {
  if (!state.templateId) return null;
  return templateOptions.value.find(option => option.value === state.templateId)
    ?.template;
});

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.WHATSAPP.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  template: getErrorMessage('templateId', 'TEMPLATE'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const hasRequiredTemplateParams = computed(() => {
  return templateParserRef.value?.v$?.$invalid === false || true;
});

const isSubmitDisabled = computed(
  () => v$.value.$invalid || !hasRequiredTemplateParams.value
);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const resetState = () => {
  Object.assign(state, initialState);
  v$.value.$reset();
};

const handleCancel = () => emit('cancel');

const prepareCampaignDetails = () => {
  // Find the selected template to get its content
  const currentTemplate = selectedTemplate.value;
  const parserData = templateParserRef.value;

  // Extract template content - this should be the template message body
  const templateContent = parserData?.renderedTemplate || '';

  // Prepare template_params object with the same structure as used in contacts
  const templateParams = {
    name: currentTemplate?.name || '',
    namespace: currentTemplate?.namespace || '',
    category: currentTemplate?.category || 'UTILITY',
    language: currentTemplate?.language || 'en_US',
    processed_params: parserData?.processedParams || {},
  };

  return {
    title: state.title,
    message: templateContent,
    template_params: templateParams,
    inbox_id: state.inboxId,
    scheduled_at: formatToUTCString(state.scheduledAt),
    audience: state.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
  };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  resetState();
  handleCancel();
};

// Reset template selection when inbox changes
watch(
  () => state.inboxId,
  () => {
    state.templateId = null;
  }
);

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
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.title"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')"
        class-name="h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-muted/30 focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground/60"
      />
      <p v-if="formErrors.title" class="text-[12px] text-destructive">
        {{ formErrors.title }}
      </p>
    </div>

    <!-- Select Inbox -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-muted/30 [&>div>button:not(.focused)]:dark:outline-border [&>div>button:not(.focused)]:hover:!outline-border"
      />
    </div>

    <!-- WhatsApp Template -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="template"
        v-model="state.templateId"
        :options="templateOptions"
        :has-error="!!formErrors.template"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.PLACEHOLDER')"
        :message="formErrors.template"
        class="[&>div>button]:bg-muted/30 [&>div>button:not(.focused)]:dark:outline-border [&>div>button:not(.focused)]:hover:!outline-border"
      />
      <p class="text-[12px] text-muted-foreground">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.INFO') }}
      </p>
    </div>

    <!-- Template Parser -->
    <WhatsAppTemplateParser
      v-if="selectedTemplate"
      ref="templateParserRef"
      :template="selectedTemplate"
    />

    <!-- Audience -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.LABEL') }}
      </RelayLabel>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-muted/30"
      />
    </div>

    <!-- Scheduled time -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.scheduledAt"
        type="datetime-local"
        :min="currentDateTime"
        :placeholder="
          t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')
        "
        class-name="h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-muted/30 focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
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
        class="flex-1 h-10 bg-muted/30 text-foreground border-border/80 shadow-sm"
        @click="handleCancel"
      >
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CANCEL') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="flex-1 h-10 shadow-sm"
        :disabled="isCreating || isSubmitDisabled"
      >
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CREATE') }}
      </RelayButton>
    </div>
  </form>
</template>
