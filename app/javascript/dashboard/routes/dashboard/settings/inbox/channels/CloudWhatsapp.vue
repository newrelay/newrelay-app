<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty, isNumber } from 'shared/helpers/Validators';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

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
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      phoneNumberId: '',
      businessAccountId: '',
      inputClass: INPUT_CLASS,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiKey: { required },
    phoneNumberId: { required, isNumber },
    businessAccountId: { required, isNumber },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName?.trim(),
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'whatsapp_cloud',
              provider_config: {
                api_key: this.apiKey,
                phone_number_id: this.phoneNumberId,
                business_account_id: this.businessAccountId,
              },
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <form class="space-y-6" @submit.prevent="createChannel()">
    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
      </label>
      <RelayInput
        v-model="inboxName"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.inboxName.$touch"
      />
      <p v-if="v$.inboxName.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
      </label>
      <RelayInput
        v-model="phoneNumber"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.phoneNumber.$touch"
      />
      <p v-if="v$.phoneNumber.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.LABEL') }}
      </label>
      <RelayInput
        v-model="phoneNumberId"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.phoneNumberId.$touch"
      />
      <p v-if="v$.phoneNumberId.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.LABEL') }}
      </label>
      <RelayInput
        v-model="businessAccountId"
        type="text"
        :placeholder="
          $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.PLACEHOLDER')
        "
        :class-name="inputClass"
        @blur="v$.businessAccountId.$touch"
      />
      <p
        v-if="v$.businessAccountId.$error"
        class="text-[12.5px] text-destructive"
      >
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
      </label>
      <RelayInput
        v-model="apiKey"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')"
        :class-name="inputClass"
        @blur="v$.apiKey.$touch"
      />
      <p v-if="v$.apiKey.$error" class="text-[12.5px] text-destructive">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
      </p>
    </div>

    <div class="pt-4">
      <RelayButton
        type="submit"
        class="shadow-sm"
        :disabled="uiFlags.isCreating"
      >
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON') }}
      </RelayButton>
    </div>
  </form>
</template>
