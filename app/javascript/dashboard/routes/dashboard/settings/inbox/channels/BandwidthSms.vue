<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

const shouldStartWithPlusSign = (value = '') => value.startsWith('+');

export default {
  components: {
    RelayButton,
    RelayInput,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      accountId: '',
      apiKey: '',
      apiSecret: '',
      applicationId: '',
      inboxName: '',
      phoneNumber: '',
      inputClass: INPUT_CLASS,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, shouldStartWithPlusSign },
    apiKey: { required },
    apiSecret: { required },
    applicationId: { required },
    accountId: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const smsChannel = await this.$store.dispatch('inboxes/createChannel', {
          name: this.inboxName?.trim(),
          channel: {
            type: 'sms',
            phone_number: this.phoneNumber,
            provider_config: {
              api_key: this.apiKey,
              api_secret: this.apiSecret,
              application_id: this.applicationId,
              account_id: this.accountId,
            },
          },
        });

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: smsChannel.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.SMS.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <form class="space-y-6" @submit.prevent="createChannel()">
    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.LABEL') }}
      </label>
      <RelayInput
        v-model="inboxName"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.inboxName.$touch"
      />
      <p v-if="v$.inboxName.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.LABEL') }}
      </label>
      <RelayInput
        v-model="phoneNumber"
        type="text"
        :placeholder="
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.PLACEHOLDER')
        "
        :class-name="inputClass"
        @blur="v$.phoneNumber.$touch"
      />
      <p v-if="v$.phoneNumber.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.LABEL') }}
      </label>
      <RelayInput
        v-model="accountId"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.accountId.$touch"
      />
      <p v-if="v$.accountId.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.LABEL') }}
      </label>
      <RelayInput
        v-model="applicationId"
        type="text"
        :placeholder="
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.PLACEHOLDER')
        "
        :class-name="inputClass"
        @blur="v$.applicationId.$touch"
      />
      <p v-if="v$.applicationId.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_KEY.LABEL') }}
      </label>
      <RelayInput
        v-model="apiKey"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_KEY.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.apiKey.$touch"
      />
      <p v-if="v$.apiKey.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_KEY.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_SECRET.LABEL') }}
      </label>
      <RelayInput
        v-model="apiSecret"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_SECRET.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.apiSecret.$touch"
      />
      <p v-if="v$.apiSecret.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_SECRET.ERROR') }}
      </p>
    </div>

    <div class="pt-4">
      <RelayButton
        type="submit"
        class="shadow-sm"
        :disabled="uiFlags.isCreating"
      >
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.SUBMIT_BUTTON') }}
      </RelayButton>
    </div>
  </form>
</template>
