<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import RelayButton from 'dashboard/components-next/relay/button/Button.vue';
import {
  RELAY_MODAL_CLOSE_BUTTON_CLASS,
  RELAY_MODAL_TITLE_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
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

const isConfirmDisabled = computed(
  () =>
    responseForm.value?.isSubmitDisabled !== false ||
    responseForm.value?.isLoading
);

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    flush
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @confirm="submitForm"
    @close="handleClose"
  >
    <div class="flex flex-col gap-6">
      <div class="flex items-start justify-between gap-4">
        <div class="flex min-w-0 flex-col space-y-1.5 text-left">
          <h2 class="leading-none" :class="[RELAY_MODAL_TITLE_CLASS]">
            {{ t(`${i18nKey}.TITLE`) }}
          </h2>
          <p
            class="text-[14px] font-normal leading-normal text-muted-foreground"
          >
            {{ t('CAPTAIN.RESPONSES.FORM_DESCRIPTION') }}
          </p>
        </div>
        <button
          type="button"
          :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
          @click="handleCancel"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </div>

      <ResponseForm
        ref="responseForm"
        :mode="type"
        :response="selectedResponse"
        :show-action-buttons="false"
        @submit="handleSubmit"
        @cancel="handleCancel"
      />

      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <RelayButton
          type="button"
          variant="outline"
          size="lg"
          class="h-10 px-4"
          @click="handleCancel"
        >
          {{ t('CAPTAIN.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton
          type="submit"
          size="lg"
          class="h-10 px-6"
          :disabled="isConfirmDisabled"
        >
          <span
            v-if="responseForm?.isLoading"
            class="i-lucide-loader-circle size-4 animate-spin"
          />
          {{ t(type === 'edit' ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE') }}
        </RelayButton>
      </div>
    </div>
  </Dialog>
</template>
