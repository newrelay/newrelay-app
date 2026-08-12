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
  RelayCheckbox,
} from 'dashboard/components-next/relay';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainAssistants/getUIFlags'),
};

const initialState = {
  name: '',
  description: '',
  productName: '',
  featureFaq: false,
  featureMemory: false,
  featureCitation: false,
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.ASSISTANTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name', 'NAME'),
  description: getErrorMessage('description', 'DESCRIPTION'),
  productName: getErrorMessage('productName', 'PRODUCT_NAME'),
}));

const handleCancel = () => emit('cancel');

const prepareAssistantDetails = () => ({
  name: state.name,
  description: state.description,
  config: {
    product_name: state.productName,
    feature_faq: state.featureFaq,
    feature_memory: state.featureMemory,
    feature_citation: state.featureCitation,
  },
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareAssistantDetails());
};

const updateStateFromAssistant = assistant => {
  if (!assistant) return;

  const { name, description, config } = assistant;

  Object.assign(state, {
    name,
    description,
    productName: config.product_name,
    featureFaq: config.feature_faq || false,
    featureMemory: config.feature_memory || false,
    featureCitation: config.feature_citation || false,
  });
};

watch(
  () => props.assistant,
  newAssistant => {
    if (props.mode === 'edit' && newAssistant) {
      updateStateFromAssistant(newAssistant);
    }
  },
  { immediate: true }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-2">
      <RelayLabel html-for="captain-assistant-name">
        {{ t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-assistant-name"
        v-model="state.name"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      />
      <p v-if="formErrors.name" class="text-xs text-n-ruby-11">
        {{ formErrors.name }}
      </p>
    </div>

    <Editor
      v-model="state.description"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-2">
      <RelayLabel html-for="captain-assistant-product-name">
        {{ t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-assistant-product-name"
        v-model="state.productName"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
      />
      <p v-if="formErrors.productName" class="text-xs text-n-ruby-11">
        {{ formErrors.productName }}
      </p>
    </div>

    <fieldset class="flex flex-col gap-2.5">
      <legend class="mb-3 text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </legend>

      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-create-feature-faqs"
          v-model="state.featureFaq"
        />
        <label
          for="captain-create-feature-faqs"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
      </div>

      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-create-feature-memories"
          v-model="state.featureMemory"
        />
        <label
          for="captain-create-feature-memories"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
      </div>

      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-create-feature-citations"
          v-model="state.featureCitation"
        />
        <label
          for="captain-create-feature-citations"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
      </div>
    </fieldset>

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
