<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

import {
  RelayButton,
  RelayModal,
  RELAY_MODAL_FORM_FOOTER_CLASS,
} from 'dashboard/components-next/relay';
import DocumentForm from './DocumentForm.vue';

defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close', 'createSuccess']);
const { t } = useI18n();
const store = useStore();

const formRef = ref(null);

const i18nKey = 'CAPTAIN.DOCUMENTS.CREATE';

const handleSubmit = async newDocument => {
  try {
    await store.dispatch('captainDocuments/create', newDocument);
    emit('createSuccess');
    useAlert(t(`${i18nKey}.SUCCESS_MESSAGE`));
    emit('close');
  } catch (error) {
    const errorMessage =
      parseAPIErrorResponse(error) || t(`${i18nKey}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleClose = () => emit('close');

const submitForm = () => formRef.value?.submit();
</script>

<template>
  <RelayModal
    show
    flush
    size="lg"
    :title="t(`${i18nKey}.TITLE`)"
    :description="t('CAPTAIN.DOCUMENTS.FORM_DESCRIPTION')"
    @close="handleClose"
  >
    <div class="flex min-h-0 flex-1 flex-col">
      <div class="flex-1 overflow-visible px-6 pb-6 pt-4">
        <DocumentForm
          ref="formRef"
          :assistant-id="assistantId"
          :show-action-buttons="false"
          @submit="handleSubmit"
          @cancel="handleClose"
        />
      </div>
      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton variant="outline" size="lg" @click="handleClose">
          {{ t('CAPTAIN.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton
          size="lg"
          :disabled="formRef?.isSubmitDisabled !== false"
          @click="submitForm"
        >
          <span
            v-if="formRef?.isLoading"
            class="i-lucide-loader-circle size-4 animate-spin"
          />
          {{ t('CAPTAIN.FORM.CREATE') }}
        </RelayButton>
      </div>
    </div>
  </RelayModal>
</template>
