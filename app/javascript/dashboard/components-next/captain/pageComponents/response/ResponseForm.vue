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
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-2">
      <RelayLabel html-for="captain-faq-question">
        {{ t('CAPTAIN.RESPONSES.FORM.QUESTION.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-faq-question"
        v-model="state.question"
        :placeholder="t('CAPTAIN.RESPONSES.FORM.QUESTION.PLACEHOLDER')"
      />
      <p v-if="formErrors.question" class="text-xs text-n-ruby-11">
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
    <div class="flex w-full items-center justify-between gap-3">
      <RelayButton
        type="button"
        variant="secondary"
        class="w-full"
        @click="handleCancel"
      >
        {{ t('CAPTAIN.FORM.CANCEL') }}
      </RelayButton>
      <RelayButton type="submit" class="w-full" :disabled="isLoading">
        <span
          v-if="isLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t(`CAPTAIN.FORM.${mode.toUpperCase()}`) }}
      </RelayButton>
    </div>
  </form>
</template>
