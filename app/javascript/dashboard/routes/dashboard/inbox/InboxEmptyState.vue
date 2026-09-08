<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useChannelIcon } from 'dashboard/components-next/icon/provider';
import wootConstants from 'dashboard/constants/globals';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  activeView: { type: String, default: 'all' },
  channelName: { type: String, default: '' },
});

const store = useStore();
const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const uiFlags = computed(() => store.getters['notifications/getUIFlags']);
const inboxes = computed(() => store.getters['inboxes/getInboxes'] || []);
const hasInboxes = computed(() => inboxes.value.length > 0);
const isChannelView = computed(
  () =>
    hasInboxes.value &&
    String(props.activeView).startsWith('inbox:') &&
    Boolean(props.channelName)
);

const activeInbox = computed(() => {
  if (!String(props.activeView).startsWith('inbox:')) return {};
  const inboxId = Number(String(props.activeView).replace('inbox:', ''));
  return inboxes.value.find(inbox => Number(inbox.id) === inboxId) || {};
});

const channelMonoIcon = useChannelIcon(activeInbox);
const channelHeroIcon = computed(
  () => channelMonoIcon.value || 'i-lucide-inbox'
);

const supportedChannels = computed(() => [
  {
    key: 'whatsapp',
    icon: 'i-woot-whatsapp',
    label: t('INBOX.EMPTY.WHATSAPP'),
  },
  { key: 'email', icon: 'i-lucide-mail', label: t('INBOX.EMPTY.EMAIL') },
  {
    key: 'sms',
    icon: 'i-lucide-message-square-more',
    label: t('INBOX.EMPTY.SMS'),
  },
  {
    key: 'messenger',
    icon: 'i-woot-messenger',
    label: t('INBOX.EMPTY.MESSENGER'),
  },
  {
    key: 'instagram',
    icon: 'i-woot-instagram',
    label: t('INBOX.EMPTY.INSTAGRAM'),
  },
  {
    key: 'live-chat',
    icon: 'i-lucide-message-circle',
    label: t('INBOX.EMPTY.LIVE_CHAT'),
  },
]);

const connectChannel = () => {
  router.push(accountScopedRoute('settings_inbox_list'));
};

const goToConversations = () => {
  router.push(accountScopedRoute('home'));
};

const learnMore = () => {
  window.open(wootConstants.DOCS_URL, '_blank', 'noopener,noreferrer');
};
</script>

<template>
  <div
    class="flex-1 flex flex-col items-center justify-center p-6 lg:px-10 bg-background text-foreground animate-in fade-in duration-300 overflow-y-auto w-full h-full min-h-0"
  >
    <div v-if="uiFlags.isFetching" class="flex justify-center my-4">
      <Spinner class="text-primary" />
    </div>

    <!-- Channel view selected, list empty -->
    <div
      v-else-if="isChannelView"
      class="flex flex-col items-center w-full max-w-lg text-center"
    >
      <div
        class="relative mb-6 flex size-24 items-center justify-center rounded-full bg-primary/5"
      >
        <div
          class="absolute inset-2 flex items-center justify-center rounded-full border border-primary/10 bg-background"
        >
          <span class="size-10 text-primary" :class="channelHeroIcon" />
        </div>
      </div>
      <h2 class="text-[20px] font-[600] text-foreground mb-2 tracking-tight">
        {{ t('INBOX.EMPTY.CHANNEL_TITLE', { channel: channelName }) }}
      </h2>
      <p class="text-sm text-muted-foreground leading-relaxed">
        {{ t('INBOX.EMPTY.CHANNEL_DESCRIPTION', { channel: channelName }) }}
      </p>
    </div>

    <!-- Has channels, empty list on All / other views -->
    <div
      v-else-if="hasInboxes"
      class="flex flex-col items-center w-full max-w-lg text-center"
    >
      <div class="relative mb-8 flex items-center justify-center">
        <div
          class="flex size-20 items-center justify-center rounded-2xl border border-primary/20 bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-sm"
        >
          <span class="i-lucide-inbox size-10 text-primary" />
        </div>
      </div>
      <h2 class="text-[20px] font-[600] text-foreground mb-2 tracking-tight">
        {{ t('INBOX.LIST.NO_NOTIFICATIONS') }}
      </h2>
      <p class="text-sm text-muted-foreground leading-relaxed mb-6">
        {{ t('INBOX.LIST.404') }}
      </p>

      <RelayButton class="px-6 text-sm font-medium" @click="goToConversations">
        <span class="i-lucide-message-square size-4 mr-2" />
        {{ t('INBOX.LIST.CONVERSATIONS') }}
      </RelayButton>
    </div>

    <!-- No channels connected -->
    <div v-else class="flex flex-col items-center w-full max-w-4xl">
      <div class="flex flex-col items-center text-center mb-10 max-w-lg">
        <div
          class="mb-6 flex size-16 items-center justify-center rounded-full bg-primary/10 ring-8 ring-primary/5"
        >
          <span class="i-lucide-inbox size-8 text-primary" />
        </div>
        <h2 class="text-[20px] font-[600] text-foreground mb-2 tracking-tight">
          {{ t('INBOX.EMPTY.TITLE') }}
        </h2>
        <p class="text-sm text-muted-foreground leading-relaxed">
          {{ t('INBOX.EMPTY.DESCRIPTION') }}
        </p>
      </div>

      <div
        class="flex flex-col sm:flex-row items-center gap-3 mb-16 justify-center w-full"
      >
        <RelayButton
          class="px-6 text-sm font-medium min-w-[160px]"
          @click="connectChannel"
        >
          {{ t('INBOX.EMPTY.CONNECT_CHANNEL') }}
        </RelayButton>
        <RelayButton
          variant="ghost"
          class="border border-input hover:border-transparent px-6 text-sm font-medium min-w-[160px]"
          @click="learnMore"
        >
          {{ t('INBOX.EMPTY.LEARN_HOW_WORKS') }}
          <span class="i-lucide-external-link size-3.5 opacity-70" />
        </RelayButton>
      </div>

      <div class="w-full max-w-3xl flex flex-col items-center">
        <div class="w-full flex items-center mb-8 gap-4">
          <div class="h-px bg-border flex-1" />
          <span
            class="text-[14px] font-medium capitalize text-muted-foreground"
          >
            {{ t('INBOX.EMPTY.SUPPORTED_CHANNELS') }}
          </span>
          <div class="h-px bg-border flex-1" />
        </div>

        <div class="flex flex-wrap items-center justify-center gap-6 sm:gap-10">
          <div
            v-for="channel in supportedChannels"
            :key="channel.key"
            class="flex cursor-default flex-col items-center gap-2"
          >
            <div
              class="flex size-12 items-center justify-center rounded-xl border border-border bg-card"
            >
              <span class="size-6 text-primary" :class="channel.icon" />
            </div>
            <span class="text-sm font-normal text-muted-foreground">
              {{ channel.label }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
