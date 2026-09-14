<script setup>
import { reactive, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { URLPattern } from 'urlpattern-polyfill';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayCheckbox,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
  RELAY_FORM_CHECKBOX_ROW_CLASS,
} from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCampaign: {
    type: Object,
    default: () => ({}),
  },
  showActionButtons: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();
const store = useStore();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  inboxes: useMapGetter('inboxes/getWebsiteInboxes'),
};

const senderList = ref([]);

const initialState = {
  title: '',
  message: '',
  inboxId: null,
  senderId: 0,
  enabled: true,
  triggerOnlyDuringBusinessHours: false,
  endPoint: '',
  timeOnPage: 10,
};

const state = reactive({ ...initialState });

const urlValidators = {
  shouldBeAValidURLPattern: value => {
    try {
      // eslint-disable-next-line
      new URLPattern(value);
      return true;
    } catch {
      return false;
    }
  },
  shouldStartWithHTTP: value =>
    value ? value.startsWith('https://') || value.startsWith('http://') : false,
};

const validationRules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  senderId: { required },
  endPoint: { required, ...urlValidators },
  timeOnPage: { required },
};

const v$ = useVuelidate(validationRules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const sendersAndBotList = computed(() => [
  { value: 0, label: 'Bot' },
  ...mapToOptions(senderList.value, 'id', 'name'),
]);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.LIVE_CHAT.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  message: getErrorMessage('message', 'MESSAGE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  endPoint: getErrorMessage('endPoint', 'END_POINT'),
  timeOnPage: getErrorMessage('timeOnPage', 'TIME_ON_PAGE'),
  sender: getErrorMessage('senderId', 'SENT_BY'),
}));

const resetState = () => Object.assign(state, initialState);

const handleCancel = () => emit('cancel');

const handleInboxChange = async inboxId => {
  if (!inboxId) {
    senderList.value = [];
    return;
  }

  try {
    const response = await store.dispatch('inboxMembers/get', { inboxId });
    senderList.value = response?.data?.payload ?? [];
  } catch (error) {
    senderList.value = [];
    useAlert(
      error?.response?.message ??
        t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.API.ERROR_MESSAGE')
    );
  }
};

const prepareCampaignDetails = () => ({
  title: state.title,
  message: state.message,
  inbox_id: state.inboxId,
  sender_id: state.senderId || null,
  enabled: state.enabled,
  trigger_only_during_business_hours: state.triggerOnlyDuringBusinessHours,
  trigger_rules: {
    url: state.endPoint,
    time_on_page: state.timeOnPage,
  },
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  if (props.mode === 'create') {
    resetState();
    handleCancel();
  }
};

const updateStateFromCampaign = campaign => {
  if (!campaign) return;

  const {
    title,
    message,
    inbox: { id: inboxId },
    sender,
    enabled,
    trigger_only_during_business_hours: triggerOnlyDuringBusinessHours,
    trigger_rules: { url: endPoint, time_on_page: timeOnPage },
  } = campaign;

  Object.assign(state, {
    title,
    message,
    inboxId,
    senderId: sender?.id ?? 0,
    enabled,
    triggerOnlyDuringBusinessHours,
    endPoint,
    timeOnPage,
  });
};

watch(
  () => state.inboxId,
  newInboxId => {
    if (newInboxId) {
      handleInboxChange(newInboxId);
    }
  },
  { immediate: true }
);

watch(
  () => props.selectedCampaign,
  newCampaign => {
    if (props.mode === 'edit' && newCampaign) {
      updateStateFromCampaign(newCampaign);
    }
  },
  { immediate: true }
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
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.TITLE.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.title"
        :placeholder="t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.TITLE.PLACEHOLDER')"
        class-name="h-9 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground/60"
      />
      <p v-if="formErrors.title" class="text-[12px] text-destructive">
        {{ formErrors.title }}
      </p>
    </div>

    <!-- Message -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.MESSAGE.LABEL') }}
      </RelayLabel>
      <Editor
        v-model="state.message"
        :placeholder="t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.MESSAGE.PLACEHOLDER')"
        :message="formErrors.message"
        :message-type="formErrors.message ? 'error' : 'info'"
      />
    </div>

    <!-- Select Inbox -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.INBOX.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-background [&>div>button:not(.focused)]:dark:outline-border [&>div>button:not(.focused)]:hover:!outline-border"
      />
    </div>

    <!-- Sent by -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.SENT_BY.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="sentBy"
        v-model="state.senderId"
        :options="sendersAndBotList"
        :has-error="!!formErrors.sender"
        :disabled="!state.inboxId"
        :placeholder="t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.SENT_BY.PLACEHOLDER')"
        class="[&>div>button]:bg-background [&>div>button:not(.focused)]:dark:outline-border [&>div>button:not(.focused)]:hover:!outline-border"
        :message="formErrors.sender"
      />
    </div>

    <!-- URL -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.END_POINT.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.endPoint"
        type="url"
        :placeholder="t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.END_POINT.PLACEHOLDER')"
        class-name="h-9 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground/60"
      />
      <p v-if="formErrors.endPoint" class="text-[12px] text-destructive">
        {{ formErrors.endPoint }}
      </p>
    </div>

    <!-- Time on page -->
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.TIME_ON_PAGE.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.timeOnPage"
        type="number"
        :placeholder="
          t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.TIME_ON_PAGE.PLACEHOLDER')
        "
        class-name="h-9 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground/60"
      />
      <p v-if="formErrors.timeOnPage" class="text-[12px] text-destructive">
        {{ formErrors.timeOnPage }}
      </p>
    </div>

    <!-- Other preferences -->
    <div class="flex flex-col gap-3">
      <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.OTHER_PREFERENCES.TITLE') }}
      </RelayLabel>
      <div class="flex flex-col gap-3">
        <label
          class="cursor-pointer group"
          :class="[RELAY_FORM_CHECKBOX_ROW_CLASS]"
        >
          <RelayCheckbox v-model="state.enabled" />
          <span
            class="text-[14px] text-muted-foreground group-hover:text-foreground transition-colors"
          >
            {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.OTHER_PREFERENCES.ENABLED') }}
          </span>
        </label>
        <label
          class="cursor-pointer group"
          :class="[RELAY_FORM_CHECKBOX_ROW_CLASS]"
        >
          <RelayCheckbox v-model="state.triggerOnlyDuringBusinessHours" />
          <span
            class="text-[14px] text-muted-foreground group-hover:text-foreground transition-colors"
          >
            {{
              t(
                'CAMPAIGN.LIVE_CHAT.CREATE.FORM.OTHER_PREFERENCES.TRIGGER_ONLY_BUSINESS_HOURS'
              )
            }}
          </span>
        </label>
      </div>
    </div>

    <!-- Action buttons (inline fallback when not used in dialog) -->
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
        {{ t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.BUTTONS.CANCEL') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="flex-1 h-9 shadow-sm"
        :disabled="isCreating || isSubmitDisabled"
      >
        {{ t(`CAMPAIGN.LIVE_CHAT.CREATE.FORM.BUTTONS.${mode.toUpperCase()}`) }}
      </RelayButton>
    </div>
  </form>
</template>
