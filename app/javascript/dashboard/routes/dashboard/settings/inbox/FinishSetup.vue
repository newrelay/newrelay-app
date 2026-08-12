<script setup>
import { computed, onMounted, reactive, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import EmailInboxFinish from './channels/emailChannels/EmailInboxFinish.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

const qrCodes = reactive({
  whatsapp: '',
  messenger: '',
  telegram: '',
});

const currentInbox = computed(() =>
  store.getters['inboxes/getInbox'](route.params.inbox_id)
);

// Use useInbox composable with the inbox ID
const {
  isAWhatsAppCloudChannel,
  isATwilioChannel,
  isASmsInbox,
  isALineChannel,
  isAnEmailChannel,
  isAWhatsAppChannel,
  isAFacebookInbox,
  isATelegramChannel,
  isATwilioWhatsAppChannel,
} = useInbox(route.params.inbox_id);

const hasDuplicateInstagramInbox = computed(() => {
  const instagramId = currentInbox.value.instagram_id;
  const facebookInbox =
    store.getters['inboxes/getFacebookInboxByInstagramId'](instagramId);

  return (
    currentInbox.value.channel_type === INBOX_TYPES.INSTAGRAM && facebookInbox
  );
});

const shouldShowWhatsAppWebhookDetails = computed(() => {
  return (
    isAWhatsAppCloudChannel.value &&
    currentInbox.value.provider_config?.source !== 'embedded_signup'
  );
});

const isWhatsAppEmbeddedSignup = computed(() => {
  return (
    isAWhatsAppCloudChannel.value &&
    currentInbox.value.provider_config?.source === 'embedded_signup'
  );
});

const message = computed(() => {
  if (isATwilioChannel.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isASmsInbox.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isALineChannel.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isAWhatsAppCloudChannel.value && shouldShowWhatsAppWebhookDetails.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (currentInbox.value.web_widget_script) {
    return t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
  }

  if (isWhatsAppEmbeddedSignup.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
    )}`;
  }

  return t('INBOX_MGMT.FINISH.MESSAGE');
});

const showEmailFinish = computed(
  () => isAnEmailChannel.value && !currentInbox.value.provider
);

async function generateQRCode(platform, identifier) {
  if (!identifier || !identifier.trim()) {
    // eslint-disable-next-line no-console
    console.warn(`Invalid identifier for ${platform} QR code`);
    return;
  }

  try {
    const platformUrls = {
      whatsapp: id => `https://wa.me/${id}`,
      messenger: id => `https://m.me/${id}`,
      telegram: id => `https://t.me/${id}`,
    };

    const url = platformUrls[platform](identifier);
    const qrDataUrl = await QRCode.toDataURL(url);
    qrCodes[platform] = qrDataUrl;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(`Error generating ${platform} QR code:`, error);
    qrCodes[platform] = '';
  }
}

async function generateQRCodes() {
  if (!currentInbox.value) return;

  // WhatsApp (both Cloud and Twilio)
  if (currentInbox.value.phone_number && isAWhatsAppChannel.value) {
    // For Twilio WhatsApp, phone_number format is "whatsapp:+1234567890"
    // Extract just the phone number part for QR code generation
    const phoneNumber = currentInbox.value.phone_number.replace(
      'whatsapp:',
      ''
    );
    await generateQRCode('whatsapp', phoneNumber);
  }

  // Facebook Messenger
  if (currentInbox.value.page_id && isAFacebookInbox.value) {
    await generateQRCode('messenger', currentInbox.value.page_id);
  }

  // Telegram
  if (isATelegramChannel.value && currentInbox.value.bot_name) {
    await generateQRCode('telegram', currentInbox.value.bot_name);
  }
}

// Watch for currentInbox changes and regenerate QR codes when available
watch(
  currentInbox,
  newInbox => {
    if (newInbox) {
      generateQRCodes();
    }
  },
  { immediate: true }
);

onMounted(() => {
  generateQRCodes();
});
</script>

<template>
  <div
    class="mx-auto flex w-full max-w-md flex-col items-center justify-center text-center"
  >
    <DuplicateInboxBanner
      v-if="hasDuplicateInstagramInbox"
      :content="$t('INBOX_MGMT.ADD.INSTAGRAM.NEW_INBOX_SUGGESTION')"
    />

    <div
      class="mb-6 flex size-20 items-center justify-center rounded-full border border-green-100 bg-green-50 shadow-sm dark:border-green-900/40 dark:bg-green-950/40"
    >
      <Icon icon="i-lucide-check" class="size-10 text-green-600" />
    </div>

    <h2 class="mb-3 text-2xl font-bold tracking-tight text-foreground">
      {{ $t('INBOX_MGMT.FINISH.TITLE') }}
    </h2>
    <p
      v-if="!showEmailFinish"
      class="mb-8 text-[14px] leading-relaxed text-muted-foreground"
    >
      {{ message }}
    </p>

    <div class="w-full space-y-6">
      <div v-if="currentInbox.web_widget_script" class="w-full text-left">
        <woot-code :script="currentInbox.web_widget_script" />
      </div>

      <div v-if="isATwilioWhatsAppChannel" class="w-full text-left">
        <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
      </div>

      <div
        v-if="shouldShowWhatsAppWebhookDetails"
        class="w-full space-y-4 text-left"
      >
        <div>
          <p class="mb-2 text-[13.5px] font-medium text-foreground">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
        </div>
        <div>
          <p class="mb-2 text-[13.5px] font-medium text-foreground">
            {{
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_VERIFICATION_TOKEN'
              )
            }}
          </p>
          <woot-code
            lang="html"
            :script="currentInbox.provider_config.webhook_verify_token"
          />
        </div>
      </div>

      <div v-if="isALineChannel" class="w-full text-left">
        <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
      </div>

      <div v-if="isASmsInbox" class="w-full text-left">
        <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
      </div>

      <EmailInboxFinish
        v-if="showEmailFinish"
        :inbox="currentInbox"
        :inbox-id="$route.params.inbox_id"
      />

      <div
        v-if="isAWhatsAppChannel && qrCodes.whatsapp"
        class="flex flex-col items-center gap-3"
      >
        <p class="text-sm text-muted-foreground">
          {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION') }}
        </p>
        <div class="rounded-lg border border-border shadow-sm">
          <img
            :src="qrCodes.whatsapp"
            alt="WhatsApp QR Code"
            class="size-48 rounded-lg dark:invert"
          />
        </div>
      </div>

      <div
        v-if="isAFacebookInbox && qrCodes.messenger"
        class="flex flex-col items-center gap-3"
      >
        <p class="text-sm text-muted-foreground">
          {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_INSTRUCTION') }}
        </p>
        <div class="rounded-lg border border-border shadow-sm">
          <img
            :src="qrCodes.messenger"
            alt="Messenger QR Code"
            class="size-48 rounded-lg dark:invert"
          />
        </div>
      </div>

      <div
        v-if="isATelegramChannel && qrCodes.telegram"
        class="flex flex-col items-center gap-3"
      >
        <p class="text-sm text-muted-foreground">
          {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_INSTRUCTION') }}
        </p>
        <div class="rounded-lg border border-border shadow-sm">
          <img
            :src="qrCodes.telegram"
            alt="Telegram QR Code"
            class="size-48 rounded-lg dark:invert"
          />
        </div>
      </div>

      <div class="flex flex-wrap items-center justify-center gap-3 pt-2">
        <router-link
          :to="{
            name: 'settings_inbox_show',
            params: { inboxId: $route.params.inbox_id },
          }"
        >
          <RelayButton variant="outline" class="shadow-sm">
            {{ $t('INBOX_MGMT.FINISH.MORE_SETTINGS') }}
          </RelayButton>
        </router-link>
        <router-link
          :to="{
            name: 'inbox_dashboard',
            params: { inboxId: $route.params.inbox_id },
          }"
        >
          <RelayButton class="h-11 px-8 text-[14px] shadow-sm">
            {{ $t('INBOX_MGMT.FINISH.BUTTON_TEXT') }}
          </RelayButton>
        </router-link>
      </div>
    </div>
  </div>
</template>
