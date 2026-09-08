<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import { RelayButton } from 'dashboard/components-next/relay';
import SMSCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignForm.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const formRef = ref(null);

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    // tracking this here instead of the store to track the type of campaign
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });

    useAlert(t('CAMPAIGN.SMS.CREATE.FORM.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.SMS.CREATE.FORM.API.ERROR_MESSAGE');
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
  <div
    class="w-[420px] z-50 min-w-0 absolute top-12 ltr:right-0 rtl:left-0 bg-card border border-border shadow-xl rounded-xl flex flex-col max-h-[80vh] animate-in fade-in slide-in-from-top-2 duration-200"
  >
    <div class="p-6 overflow-y-auto flex-1">
      <h2 class="text-[16px] font-medium text-foreground mb-6">
        {{ t('CAMPAIGN.SMS.CREATE.TITLE') }}
      </h2>
      <SMSCampaignForm
        ref="formRef"
        :show-action-buttons="false"
        @submit="handleSubmit"
        @cancel="handleClose"
      />
    </div>
    <div
      class="p-6 pt-4 border-t border-border/60 flex items-center gap-3 bg-card rounded-b-xl shrink-0"
    >
      <RelayButton
        variant="outline"
        class="flex-1 h-9 bg-muted/30 text-foreground border-border/80 shadow-sm"
        @click="handleClose"
      >
        {{ t('CAMPAIGN.SMS.CREATE.FORM.BUTTONS.CANCEL') }}
      </RelayButton>
      <RelayButton
        class="flex-1 h-9 shadow-sm"
        :disabled="formRef?.isSubmitDisabled !== false"
        @click="submitForm"
      >
        {{ t('CAMPAIGN.SMS.CREATE.FORM.BUTTONS.CREATE') }}
      </RelayButton>
    </div>
  </div>
</template>
