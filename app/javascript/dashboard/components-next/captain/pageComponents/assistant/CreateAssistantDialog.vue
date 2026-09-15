<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import AssistantForm from './AssistantForm.vue';

const props = defineProps({
  selectedAssistant: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});
const emit = defineEmits(['close', 'created']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const assistantForm = ref(null);

const updateAssistant = assistantDetails =>
  store.dispatch('captainAssistants/update', {
    id: props.selectedAssistant.id,
    ...assistantDetails,
  });

const i18nKey = computed(
  () => `CAPTAIN.ASSISTANTS.${props.type.toUpperCase()}`
);

const createAssistant = async assistantDetails => {
  try {
    const newAssistant = await store.dispatch(
      'captainAssistants/create',
      assistantDetails
    );
    emit('created', newAssistant);
  } catch (error) {
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleSubmit = async updatedAssistant => {
  try {
    if (props.type === 'edit') {
      await updateAssistant(updatedAssistant);
    } else {
      await createAssistant(updatedAssistant);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value.close();
};

const submitForm = () => assistantForm.value?.submit();

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t(`${i18nKey}.TITLE`)"
    :description="t('CAPTAIN.ASSISTANTS.FORM_DESCRIPTION')"
    :cancel-button-label="t('CAPTAIN.FORM.CANCEL')"
    :confirm-button-label="
      t(type === 'edit' ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE')
    "
    :disable-confirm-button="
      assistantForm?.isSubmitDisabled !== false || assistantForm?.isLoading
    "
    :is-loading="assistantForm?.isLoading"
    overflow-y-auto
    @confirm="submitForm"
    @close="handleClose"
  >
    <AssistantForm
      ref="assistantForm"
      :mode="type"
      :assistant="selectedAssistant"
      :show-action-buttons="false"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
  </Dialog>
</template>
