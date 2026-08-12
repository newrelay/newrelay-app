<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

const shouldBeWebhookUrl = (value = '') =>
  value ? value.startsWith('http') : true;

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
      webhookUrl: '',
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
    webhookUrl: { shouldBeWebhookUrl },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const apiChannel = await this.$store.dispatch('inboxes/createChannel', {
          name: this.channelName?.trim(),
          channel: {
            type: 'api',
            webhook_url: this.webhookUrl,
          },
        });

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: apiChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.API_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.API_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.API_CHANNEL.DESC')"
    />
    <form class="space-y-6" @submit.prevent="createChannel()">
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.CHANNEL_NAME.LABEL') }}
        </label>
        <RelayInput
          v-model="channelName"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.API_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
          "
          :class-name="inputClass"
          @blur="v$.channelName.$touch"
        />
        <p v-if="v$.channelName.$error" class="text-[12.5px] text-destructive">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.CHANNEL_NAME.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.WEBHOOK_URL.LABEL') }}
        </label>
        <RelayInput
          v-model="webhookUrl"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.API_CHANNEL.WEBHOOK_URL.PLACEHOLDER')
          "
          :class-name="inputClass"
          @blur="v$.webhookUrl.$touch"
        />
        <p class="text-[12.5px] text-muted-foreground">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.WEBHOOK_URL.SUBTITLE') }}
        </p>
      </div>

      <div class="pt-4">
        <RelayButton
          type="submit"
          class="shadow-sm"
          :disabled="uiFlags.isCreating"
        >
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.SUBMIT_BUTTON') }}
        </RelayButton>
      </div>
    </form>
  </div>
</template>
