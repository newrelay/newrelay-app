<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import {
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay/form/constants';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  response: {
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

const formState = {
  uiFlags: useMapGetter('captainResponses/getUIFlags'),
};

const initialState = {
  question: '',
  answer: '',
};

const state = reactive({ ...initialState });

const validationRules = {
  question: { required, minLength: minLength(1) },
  answer: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.RESPONSES.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  question: getErrorMessage('question', 'QUESTION'),
  answer: getErrorMessage('answer', 'ANSWER'),
}));

const handleCancel = () => emit('cancel');

const prepareDocumentDetails = () => ({
  question: state.question,
  answer: state.answer,
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareDocumentDetails());
};

const updateStateFromResponse = response => {
  if (!response) return;

  const { question, answer } = response;

  Object.assign(state, {
    question,
    answer,
  });
};

watch(
  () => props.response,
  newResponse => {
    if (props.mode === 'edit' && newResponse) {
      updateStateFromResponse(newResponse);
    }
  },
  { immediate: true }
);

defineExpose({
  submit: handleSubmit,
  isSubmitDisabled,
  isLoading,
});
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel
        html-for="captain-faq-question"
        :class="RELAY_FORM_LABEL_CLASS"
      >
        {{ t('CAPTAIN.RESPONSES.FORM.QUESTION.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-faq-question"
        v-model="state.question"
        :placeholder="t('CAPTAIN.RESPONSES.FORM.QUESTION.PLACEHOLDER')"
      />
      <p v-if="formErrors.question" class="text-[12px] text-destructive">
        {{ formErrors.question }}
      </p>
    </div>
    <Editor
      v-model="state.answer"
      :label="t('CAPTAIN.RESPONSES.FORM.ANSWER.LABEL')"
      :placeholder="t('CAPTAIN.RESPONSES.FORM.ANSWER.PLACEHOLDER')"
      :message="formErrors.answer"
      :max-length="10000"
      :message-type="formErrors.answer ? 'error' : 'info'"
    />
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
      <RelayButton
        type="submit"
        size="lg"
        :disabled="isLoading || isSubmitDisabled"
      >
        <span
          v-if="isLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t(`CAPTAIN.FORM.${mode.toUpperCase()}`) }}
      </RelayButton>
    </div>
  </form>
</template>
