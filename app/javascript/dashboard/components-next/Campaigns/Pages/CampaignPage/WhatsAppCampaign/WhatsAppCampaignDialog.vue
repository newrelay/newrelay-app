<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import {
  RelayButton,
  RelayModal,
  RELAY_MODAL_FORM_FOOTER_CLASS,
} from 'dashboard/components-next/relay';
import WhatsAppCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const formRef = ref(null);

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });

    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.WHATSAPP.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleSubmit = campaignDetails => {
  addCampaign(campaignDetails);
};

const handleClose = () => emit('close');

const submitForm = () => formRef.value?.submit();
</script>

<template>
  <RelayModal
    show
    flush
    size="lg"
    :title="t('CAMPAIGN.WHATSAPP.CREATE.TITLE')"
    :description="t('CAMPAIGN.WHATSAPP.CREATE.DESCRIPTION')"
    @close="handleClose"
  >
    <div class="flex min-h-0 flex-1 flex-col">
      <div class="flex-1 overflow-y-auto px-6 pb-6 pt-4">
        <WhatsAppCampaignForm
          ref="formRef"
          :show-action-buttons="false"
          @submit="handleSubmit"
          @cancel="handleClose"
        />
      </div>
      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton variant="outline" size="lg" @click="handleClose">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CANCEL') }}
        </RelayButton>
        <RelayButton
          size="lg"
          :disabled="formRef?.isSubmitDisabled !== false"
          @click="submitForm"
        >
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CREATE') }}
        </RelayButton>
      </div>
    </div>
  </RelayModal>
</template>
