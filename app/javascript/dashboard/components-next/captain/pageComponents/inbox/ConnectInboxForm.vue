<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import { RelayButton, RelayLabel } from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
  showActionButtons: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainInboxes/getUIFlags'),
  inboxes: useMapGetter('inboxes/getInboxes'),
  captainInboxes: useMapGetter('captainInboxes/getRecords'),
};

const initialState = {
  inboxId: null,
};

const state = reactive({ ...initialState });

const validationRules = {
  inboxId: { required },
};

const inboxList = computed(() => {
  const captainInboxIds = formState.captainInboxes.value.map(inbox => inbox.id);

  return formState.inboxes.value
    .filter(inbox => !captainInboxIds.includes(inbox.id))
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }));
});

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.INBOXES.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  inboxId: getErrorMessage('inboxId', 'INBOX'),
}));

const handleCancel = () => emit('cancel');

const prepareInboxPayload = () => ({
  inboxId: state.inboxId,
  assistantId: props.assistantId,
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareInboxPayload());
};

defineExpose({
  submit: handleSubmit,
  isSubmitDisabled,
  isLoading,
});
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1.5">
      <RelayLabel html-for="inbox">
        {{ t('CAPTAIN.INBOXES.FORM.INBOX.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxList"
        :has-error="!!formErrors.inboxId"
        :placeholder="t('CAPTAIN.INBOXES.FORM.INBOX.PLACEHOLDER')"
        class="[&>div>button:not(.focused)]:dark:outline-border [&>div>button:not(.focused)]:hover:!outline-border"
        :message="formErrors.inboxId"
      />
    </div>

    <div
      v-if="showActionButtons"
      class="flex w-full items-center justify-end gap-3"
    >
      <RelayButton
        type="button"
        variant="outline"
        size="lg"
        @click="handleCancel"
      >
        {{ t('CAPTAIN.FORM.CANCEL') }}
      </RelayButton>
      <RelayButton type="submit" size="lg" :disabled="isLoading">
        <span
          v-if="isLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t('CAPTAIN.FORM.CREATE') }}
      </RelayButton>
    </div>
  </form>
</template>
