<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import BandwidthSms from './BandwidthSms.vue';
import Twilio from './Twilio.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    BandwidthSms,
  },
  data() {
    return {
      provider: 'twilio',
    };
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
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.LABEL') }}
      </label>
      <select
        v-model="provider"
        class="h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
      >
        <option value="twilio">
          {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.TWILIO') }}
        </option>
        <option value="360dialog">
          {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.BANDWIDTH') }}
        </option>
      </select>
    </div>
    <Twilio v-if="provider === 'twilio'" type="sms" />
    <BandwidthSms v-else />
  </div>
</template>
