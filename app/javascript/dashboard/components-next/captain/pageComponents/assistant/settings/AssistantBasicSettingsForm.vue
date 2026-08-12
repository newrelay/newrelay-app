<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import {
  RelayButton,
  RelayCheckbox,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const initialState = {
  name: '',
  description: '',
  productName: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
    contactAttributes: false,
  },
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  productName: getErrorMessage('productName'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.productName = config.product_name;
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
    contactAttributes: config.feature_contact_attributes || false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
    v$.value.productName.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    config: {
      ...props.assistant.config,
      product_name: state.productName,
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
      feature_contact_attributes: state.features.contactAttributes,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex flex-col gap-2">
      <RelayLabel html-for="captain-assistant-settings-name">
        {{ t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-assistant-settings-name"
        v-model="state.name"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      />
      <p v-if="formErrors.name" class="text-xs text-destructive">
        {{ formErrors.name }}
      </p>
    </div>

    <div class="flex flex-col gap-2">
      <RelayLabel html-for="captain-assistant-settings-product-name">
        {{ t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-assistant-settings-product-name"
        v-model="state.productName"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
      />
      <p v-if="formErrors.productName" class="text-xs text-destructive">
        {{ formErrors.productName }}
      </p>
    </div>

    <Editor
      v-model="state.description"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      class="z-0"
    />

    <div class="space-y-3 pt-2">
      <RelayLabel class="text-[13.5px]">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </RelayLabel>
      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-assistant-feature-faqs"
          v-model="state.features.conversationFaqs"
        />
        <label
          for="captain-assistant-feature-faqs"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
      </div>
      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-assistant-feature-memories"
          v-model="state.features.memories"
        />
        <label
          for="captain-assistant-feature-memories"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
      </div>
      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-assistant-feature-citations"
          v-model="state.features.citations"
        />
        <label
          for="captain-assistant-feature-citations"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
      </div>
      <div class="flex items-center gap-3">
        <RelayCheckbox
          id="captain-assistant-feature-contact-attributes"
          v-model="state.features.contactAttributes"
        />
        <label
          for="captain-assistant-feature-contact-attributes"
          class="cursor-pointer select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONTACT_ATTRIBUTES') }}
        </label>
      </div>
    </div>

    <div>
      <RelayButton @click="handleBasicInfoUpdate">
        {{ t('CAPTAIN.ASSISTANTS.FORM.UPDATE') }}
      </RelayButton>
    </div>
  </div>
</template>
