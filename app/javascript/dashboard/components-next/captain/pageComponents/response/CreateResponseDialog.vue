<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ResponseForm from './ResponseForm.vue';

const props = defineProps({
  selectedResponse: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});
const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();
const route = useRoute();

const dialogRef = ref(null);
const responseForm = ref(null);

const updateResponse = responseDetails =>
  store.dispatch('captainResponses/update', {
    id: props.selectedResponse.id,
    ...responseDetails,
  });

const i18nKey = computed(() => `CAPTAIN.RESPONSES.${props.type.toUpperCase()}`);

const createResponse = responseDetails =>
  store.dispatch('captainResponses/create', responseDetails);

const handleSubmit = async updatedResponse => {
  try {
    if (props.type === 'edit') {
      await updateResponse({
        ...updatedResponse,
        assistant_id: route.params.assistantId,
      });
    } else {
      await createResponse({
        ...updatedResponse,
        assistant_id: route.params.assistantId,
      });
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      error?.response?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value.close();
};

const submitForm = () => responseForm.value?.submit();

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.RESPONSES.FORM_DESCRIPTION')"
    :cancel-button-label="t('CAPTAIN.FORM.CANCEL')"
    :confirm-button-label="
      t(type === 'edit' ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE')
    "
    :disable-confirm-button="
      responseForm?.isSubmitDisabled !== false || responseForm?.isLoading
    "
    :is-loading="responseForm?.isLoading"
    overflow-y-auto
    @confirm="submitForm"
    @close="handleClose"
  >
    <ResponseForm
      ref="responseForm"
      :mode="type"
      :response="selectedResponse"
      :show-action-buttons="false"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
  </Dialog>
</template>
