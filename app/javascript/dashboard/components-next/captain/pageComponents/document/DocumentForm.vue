<script setup>
import { reactive, computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { minLength, requiredIf, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainDocuments/getUIFlags'),
};

const initialState = {
  name: '',
  url: '',
  documentType: 'url',
  pdfFile: null,
};

const state = reactive({ ...initialState });
const fileInputRef = ref(null);

const validationRules = {
  url: {
    required: requiredIf(() => state.documentType === 'url'),
    url: requiredIf(() => state.documentType === 'url' && url),
    minLength: requiredIf(() => state.documentType === 'url' && minLength(1)),
  },
  pdfFile: {
    required: requiredIf(() => state.documentType === 'pdf'),
  },
};

const documentTypeOptions = [
  { value: 'url', label: t('CAPTAIN.DOCUMENTS.FORM.TYPE.URL') },
  { value: 'pdf', label: t('CAPTAIN.DOCUMENTS.FORM.TYPE.PDF') },
];

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const hasPdfFileError = computed(() => v$.value.pdfFile.$error);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.DOCUMENTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  url: getErrorMessage('url', 'URL'),
  pdfFile: getErrorMessage('pdfFile', 'PDF_FILE'),
}));

const handleCancel = () => emit('cancel');

const handleFileChange = event => {
  const file = event.target.files[0];
  if (file) {
    if (file.type !== 'application/pdf') {
      useAlert(t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.INVALID_TYPE'));
      event.target.value = '';
      return;
    }
    if (file.size > MAX_FILE_SIZE) {
      useAlert(t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.TOO_LARGE'));
      event.target.value = '';
      return;
    }
    state.pdfFile = file;
    state.name = file.name.replace(/\.pdf$/i, '');
  }
};

const openFileDialog = () => {
  nextTick(() => {
    if (fileInputRef.value) {
      fileInputRef.value.click();
    }
  });
};

const prepareDocumentDetails = () => {
  const formData = new FormData();
  formData.append('document[assistant_id]', props.assistantId);

  if (state.documentType === 'url') {
    formData.append('document[external_link]', state.url);
    formData.append('document[name]', state.name || state.url);
  } else {
    formData.append('document[pdf_file]', state.pdfFile);
    formData.append(
      'document[name]',
      state.name || state.pdfFile.name.replace('.pdf', '')
    );
  }

  return formData;
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareDocumentDetails());
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1">
      <RelayLabel html-for="documentType">
        {{ t('CAPTAIN.DOCUMENTS.FORM.TYPE.LABEL') }}
      </RelayLabel>
      <ComboBox
        id="documentType"
        v-model="state.documentType"
        :options="documentTypeOptions"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <div v-if="state.documentType === 'url'" class="flex flex-col gap-2">
      <RelayLabel html-for="document-url">
        {{ t('CAPTAIN.DOCUMENTS.FORM.URL.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="document-url"
        v-model="state.url"
        :placeholder="t('CAPTAIN.DOCUMENTS.FORM.URL.PLACEHOLDER')"
      />
      <p v-if="formErrors.url" class="text-xs text-n-ruby-11">
        {{ formErrors.url }}
      </p>
    </div>

    <div v-if="state.documentType === 'pdf'" class="flex flex-col gap-2">
      <RelayLabel>
        {{ t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.LABEL') }}
      </RelayLabel>
      <div class="relative">
        <input
          ref="fileInputRef"
          type="file"
          accept=".pdf"
          class="hidden"
          @change="handleFileChange"
        />
        <RelayButton
          type="button"
          :variant="hasPdfFileError ? 'destructive' : 'outline'"
          class="!h-auto w-full !justify-between !py-4"
          @click="openFileDialog"
        >
          <div class="flex items-center gap-2">
            <div
              class="flex size-10 items-center justify-center rounded-lg bg-n-slate-3"
            >
              <span class="i-ph-file-pdf text-xl text-n-slate-11" />
            </div>
            <div class="flex flex-1 flex-col items-start gap-1">
              <p class="m-0 text-sm font-medium text-n-slate-12">
                {{
                  state.pdfFile
                    ? state.pdfFile.name
                    : t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.CHOOSE_FILE')
                }}
              </p>
              <p class="m-0 text-xs text-n-slate-11">
                {{
                  state.pdfFile
                    ? `${(state.pdfFile.size / 1024 / 1024).toFixed(2)} MB`
                    : t('CAPTAIN.DOCUMENTS.FORM.PDF_FILE.HELP_TEXT')
                }}
              </p>
            </div>
          </div>
          <span class="i-lucide-upload text-n-slate-11" />
        </RelayButton>
      </div>
      <p v-if="formErrors.pdfFile" class="text-xs text-n-ruby-9">
        {{ formErrors.pdfFile }}
      </p>
    </div>

    <div class="flex flex-col gap-2">
      <RelayLabel html-for="document-name">
        {{ t('CAPTAIN.DOCUMENTS.FORM.NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="document-name"
        v-model="state.name"
        :placeholder="t('CAPTAIN.DOCUMENTS.FORM.NAME.PLACEHOLDER')"
      />
    </div>

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
        {{ t('CAPTAIN.FORM.CREATE') }}
      </RelayButton>
    </div>
  </form>
</template>
