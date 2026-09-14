<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import WhatsAppCampaignForm from './WhatsAppCampaignForm.vue';

const props = defineProps({
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const formRef = ref(null);

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const isInvalid = computed(() => formRef.value?.isSubmitDisabled);

const handleSubmit = async campaignDetails => {
  try {
    await store.dispatch('campaigns/update', {
      id: props.selectedCampaign.id,
      ...campaignDetails,
    });
    useAlert(t('CAMPAIGN.WHATSAPP.EDIT.FORM.API.SUCCESS_MESSAGE'));
    dialogRef.value.close();
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CAMPAIGN.WHATSAPP.EDIT.FORM.API.ERROR_MESSAGE')
    );
  }
};

const submitForm = () => formRef.value?.submit();

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CAMPAIGN.WHATSAPP.EDIT.TITLE')"
    :description="t('CAMPAIGN.WHATSAPP.EDIT.DESCRIPTION')"
    :cancel-button-label="t('CAMPAIGN.WHATSAPP.EDIT.FORM.BUTTONS.CANCEL')"
    :confirm-button-label="t('CAMPAIGN.WHATSAPP.EDIT.FORM.BUTTONS.UPDATE')"
    :is-loading="isUpdating"
    :disable-confirm-button="isUpdating || isInvalid"
    overflow-y-auto
    @confirm="submitForm"
  >
    <WhatsAppCampaignForm
      ref="formRef"
      mode="edit"
      :selected-campaign="selectedCampaign"
      :show-action-buttons="false"
      @submit="handleSubmit"
    />
  </Dialog>
</template>
