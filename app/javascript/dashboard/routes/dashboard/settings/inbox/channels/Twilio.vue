<!-- Deprecated in favour of separate files for SMS and Whatsapp and also to implement new providers for each platform in the future-->
<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import {
  RelayButton,
  RelayInput,
  RelayCheckbox,
} from 'dashboard/components-next/relay';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

export default {
  components: {
    RelayButton,
    RelayInput,
    RelayCheckbox,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      accountSID: '',
      apiKeySID: '',
      authToken: '',
      medium: this.type,
      channelName: '',
      messagingServiceSID: '',
      useMessagingService: false,
      useAPIKey: false,
      phoneNumber: '',
      inputClass: INPUT_CLASS,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    authTokeni18nKey() {
      return this.useAPIKey ? 'API_KEY_SECRET' : 'AUTH_TOKEN';
    },
  },
  validations() {
    let validations = {
      channelName: { required },

      authToken: { required },
      accountSID: { required },
      medium: { required },
    };
    if (this.phoneNumber) {
      validations = {
        ...validations,
        phoneNumber: { required, isPhoneE164OrEmpty },
        messagingServiceSID: {},
      };
    } else {
      validations = {
        ...validations,
        messagingServiceSID: { required },
        phoneNumber: {},
      };
    }

    if (this.useAPIKey) {
      validations = {
        ...validations,
        apiKeySID: { required },
      };
    }
    return validations;
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const twilioChannel = await this.$store.dispatch(
          'inboxes/createTwilioChannel',
          {
            twilio_channel: {
              name: this.channelName?.trim(),
              medium: this.medium,
              account_sid: this.accountSID,
              api_key_sid: this.apiKeySID,
              auth_token: this.authToken,
              messaging_service_sid: this.messagingServiceSID,
              phone_number: this.messagingServiceSID
                ? null
                : `+${this.phoneNumber.replace(/\D/g, '')}`,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: twilioChannel.id,
          },
        });
      } catch (error) {
        const errorMessage =
          parseAPIErrorResponse(error) ||
          this.$t('INBOX_MGMT.ADD.TWILIO.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <form class="space-y-6" @submit.prevent="createChannel()">
    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.LABEL') }}
      </label>
      <RelayInput
        v-model="channelName"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.channelName.$touch"
      />
      <p v-if="v$.channelName.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.ERROR') }}
      </p>
    </div>

    <div v-if="useMessagingService" class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.LABEL') }}
      </label>
      <RelayInput
        v-model="messagingServiceSID"
        type="text"
        :placeholder="
          $t('INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.PLACEHOLDER')
        "
        :class-name="inputClass"
        @blur="v$.messagingServiceSID.$touch"
      />
      <p
        v-if="v$.messagingServiceSID.$error"
        class="text-[12.5px] text-destructive"
      >
        {{ $t('INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.ERROR') }}
      </p>
    </div>

    <div v-if="!useMessagingService" class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.LABEL') }}
      </label>
      <RelayInput
        v-model="phoneNumber"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.phoneNumber.$touch"
      />
      <p v-if="v$.phoneNumber.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.ERROR') }}
      </p>
    </div>

    <label class="flex items-center gap-3">
      <RelayCheckbox v-model="useMessagingService" />
      <span class="text-[13.5px] text-foreground">
        {{
          $t(
            'INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.USE_MESSAGING_SERVICE'
          )
        }}
      </span>
    </label>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.LABEL') }}
      </label>
      <RelayInput
        v-model="accountSID"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.accountSID.$touch"
      />
      <p v-if="v$.accountSID.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.ERROR') }}
      </p>
    </div>

    <label class="flex items-center gap-3">
      <RelayCheckbox v-model="useAPIKey" />
      <span class="text-[13.5px] text-foreground">
        {{ $t('INBOX_MGMT.ADD.TWILIO.API_KEY.USE_API_KEY') }}
      </span>
    </label>

    <div v-if="useAPIKey" class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.TWILIO.API_KEY.LABEL') }}
      </label>
      <RelayInput
        v-model="apiKeySID"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.TWILIO.API_KEY.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.apiKeySID.$touch"
      />
      <p v-if="v$.apiKeySID.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.TWILIO.API_KEY.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t(`INBOX_MGMT.ADD.TWILIO.${authTokeni18nKey}.LABEL`) }}
      </label>
      <RelayInput
        v-model="authToken"
        type="text"
        :placeholder="
          $t(`INBOX_MGMT.ADD.TWILIO.${authTokeni18nKey}.PLACEHOLDER`)
        "
        :class-name="inputClass"
        @blur="v$.authToken.$touch"
      />
      <p v-if="v$.authToken.$error" class="text-[12.5px] text-destructive">
        {{ $t(`INBOX_MGMT.ADD.TWILIO.${authTokeni18nKey}.ERROR`) }}
      </p>
    </div>

    <div class="pt-4">
      <RelayButton
        type="submit"
        class="shadow-sm"
        :disabled="uiFlags.isCreating"
      >
        {{ $t('INBOX_MGMT.ADD.TWILIO.SUBMIT_BUTTON') }}
      </RelayButton>
    </div>
  </form>
</template>
