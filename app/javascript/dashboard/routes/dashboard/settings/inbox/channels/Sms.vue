<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import BandwidthSms from './BandwidthSms.vue';
import Twilio from './Twilio.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    BandwidthSms,
    ComboBox,
  },
  data() {
    return {
      provider: 'twilio',
    };
  },
  computed: {
    providerOptions() {
      return [
        {
          value: 'twilio',
          label: this.$t('INBOX_MGMT.ADD.SMS.PROVIDERS.TWILIO'),
        },
        {
          value: '360dialog',
          label: this.$t('INBOX_MGMT.ADD.SMS.PROVIDERS.BANDWIDTH'),
        },
      ];
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.SMS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.SMS.DESC')"
    />
    <div class="mb-6 flex flex-col gap-1.5">
      <label class="text-[13.5px] text-foreground font-[500]">
        {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.LABEL') }}
      </label>
      <ComboBox v-model="provider" :options="providerOptions" />
    </div>
    <Twilio v-if="provider === 'twilio'" type="sms" />
    <BandwidthSms v-else />
  </div>
</template>
