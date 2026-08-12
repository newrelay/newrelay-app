<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, email } from '@vuelidate/validators';
import router from '../../../../../index';
import PageHeader from '../../../SettingsSubPageHeader.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

export default {
  components: {
    PageHeader,
    RelayButton,
    RelayInput,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      email: '',
      alertMessage: '',
      inputClass: INPUT_CLASS,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    email: { required, email },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const emailChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName?.trim(),
            channel: {
              type: 'email',
              email: this.email,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: emailChannel.id,
          },
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage ||
          this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.API.ERROR_MESSAGE');
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC')"
    />
    <form class="space-y-6" @submit.prevent="createChannel()">
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.LABEL') }}
        </label>
        <RelayInput
          v-model="channelName"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
          "
          :class-name="inputClass"
          @blur="v$.channelName.$touch"
        />
        <p v-if="v$.channelName.$error" class="text-[12.5px] text-destructive">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.LABEL') }}
        </label>
        <RelayInput
          v-model="email"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.PLACEHOLDER')"
          :class-name="inputClass"
          @blur="v$.email.$touch"
        />
        <p class="text-[12.5px] text-muted-foreground">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.SUBTITLE') }}
        </p>
      </div>

      <div class="pt-4">
        <RelayButton
          type="submit"
          class="shadow-sm"
          :disabled="uiFlags.isCreating"
        >
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.SUBMIT_BUTTON') }}
        </RelayButton>
      </div>
    </form>
  </div>
</template>
