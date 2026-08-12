<script>
import { useAlert } from 'dashboard/composables';
import twitterClient from '../../../../../api/channel/twitterClient';
import { RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    RelayButton,
  },
  data() {
    return { isRequestingAuthorization: false };
  },
  methods: {
    async requestAuthorization() {
      try {
        this.isRequestingAuthorization = true;
        const response = await twitterClient.generateAuthorization();
        const {
          data: { url },
        } = response;
        window.location.href = url;
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.TWITTER.ERROR_MESSAGE'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="flex w-full max-w-2xl flex-col items-center justify-center py-16 text-center"
  >
    <form @submit.prevent="requestAuthorization">
      <RelayButton
        type="submit"
        class="shadow-sm"
        :disabled="isRequestingAuthorization"
      >
        {{ $t('INBOX_MGMT.ADD.TWITTER.SIGN_IN') }}
      </RelayButton>
    </form>
    <p class="mt-6 max-w-md text-[13px] leading-relaxed text-muted-foreground">
      {{ $t('INBOX_MGMT.ADD.TWITTER.HELP') }}
    </p>
  </div>
</template>
