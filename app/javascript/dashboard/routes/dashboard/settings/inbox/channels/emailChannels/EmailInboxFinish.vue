<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  inboxId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();

const message = computed(() => {
  return props.inbox.forwarding_enabled
    ? t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE')
    : t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE_NO_FORWARDING');
});

const showForwardingAddress = computed(() => {
  return props.inbox.forwarding_enabled;
});
</script>

<template>
  <div class="w-full text-center">
    <p
      class="mx-auto mt-2 w-full text-[14px] leading-relaxed text-muted-foreground"
    >
      {{ message }}
    </p>

    <div
      v-if="showForwardingAddress"
      class="mx-auto mt-6 w-full max-w-md text-left"
    >
      <p class="mb-2 text-[13.5px] font-medium text-foreground">
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FORWARDING_ADDRESS_LABEL') }}
      </p>
      <woot-code lang="html" :script="inbox.forward_to_email" />
    </div>

    <p class="mt-6 pb-2 text-sm text-muted-foreground">
      <router-link
        :to="{
          name: 'settings_inbox_show',
          params: { inboxId: inboxId, tab: 'configuration' },
        }"
        class="font-medium text-primary underline hover:no-underline"
      >
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CONFIGURE_SMTP_IMAP_LINK') }}
      </router-link>
      {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CONFIGURE_SMTP_IMAP_TEXT') }}
    </p>
  </div>
</template>
