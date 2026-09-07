<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { RelayButton } from 'dashboard/components-next/relay';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const inboxesList = useMapGetter('inboxes/getInboxes');
const allConversations = useMapGetter('getAllConversations');
const contactsMeta = useMapGetter('contacts/getMeta');
const chatListFilters = useMapGetter('getChatListFilters');
const appliedFilters = useMapGetter('getAppliedConversationFilters');

const hasContacts = computed(() => (contactsMeta.value?.count ?? 0) > 0);
const hasChannels = computed(() => inboxesList.value.length > 0);
const hasConversations = computed(() => allConversations.value.length > 0);

const isFilteredView = computed(() => {
  const unfilteredRoutes = ['home', 'inbox_conversation'];
  if (!unfilteredRoutes.includes(route.name)) return true;
  const assigneeType = chatListFilters.value?.assigneeType;
  if (assigneeType && assigneeType !== 'all') return true;
  const status = chatListFilters.value?.status;
  if (status && status !== 'open') return true;
  return Boolean(appliedFilters.value?.length);
});

const conversationStepStatus = (channelDone, conversationDone) => {
  if (conversationDone) return 'completed';
  if (channelDone) return 'active';
  return 'pending';
};

const steps = computed(() => {
  const channelDone = hasChannels.value;
  const conversationDone = hasConversations.value;
  // Contacts meta is often unloaded on this page; treat as done when channels
  // are still missing so the empty surface matches STEP 3 OF 4.
  const contactsDone = hasContacts.value || !channelDone;

  return [
    {
      key: 'workspace',
      label: t('ONBOARDING.STEPS.CREATE_WORKSPACE'),
      status: 'completed',
    },
    {
      key: 'contacts',
      label: t('ONBOARDING.STEPS.IMPORT_CONTACTS'),
      status: contactsDone ? 'completed' : 'pending',
    },
    {
      key: 'channel',
      label: t('ONBOARDING.STEPS.CONNECT_CHANNEL'),
      status: channelDone ? 'completed' : 'active',
    },
    {
      key: 'conversation',
      label: t('ONBOARDING.STEPS.FIRST_CONVERSATION'),
      status: conversationStepStatus(channelDone, conversationDone),
    },
  ];
});

const currentStepNumber = computed(() => {
  const activeIndex = steps.value.findIndex(step => step.status === 'active');
  if (activeIndex >= 0) return activeIndex + 1;
  const firstPending = steps.value.findIndex(step => step.status === 'pending');
  if (firstPending >= 0) return firstPending + 1;
  return steps.value.length;
});

const channels = computed(() => [
  {
    key: 'whatsapp',
    title: t('ONBOARDING.CHANNELS.WHATSAPP.TITLE'),
    description: t('ONBOARDING.CHANNELS.WHATSAPP.DESCRIPTION'),
    icon: 'i-logos-whatsapp-icon',
    iconWrap: 'bg-emerald-500/10',
    iconClass: 'opacity-90',
    cardClass:
      'border-2 border-emerald-500/20 bg-emerald-50/30 dark:bg-emerald-500/5 hover:border-emerald-500/40',
    buttonVariant: 'default',
    buttonClass:
      'h-8 px-4 text-[13px] font-medium bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm shrink-0',
    buttonLabel: t('ONBOARDING.CHANNELS.CONNECT'),
    route: 'whatsapp',
  },
  {
    key: 'email',
    title: t('ONBOARDING.CHANNELS.EMAIL.TITLE'),
    description: t('ONBOARDING.CHANNELS.EMAIL.DESCRIPTION'),
    icon: 'i-lucide-mail',
    iconWrap: 'bg-primary/10',
    iconClass: 'text-primary',
    cardClass: 'border border-border/60 bg-card hover:border-border',
    buttonVariant: 'outline',
    buttonClass:
      'h-8 px-4 text-[13px] font-medium bg-background shadow-sm shrink-0',
    buttonLabel: t('ONBOARDING.CHANNELS.CONNECT'),
    route: 'email',
  },
  {
    key: 'facebook',
    title: t('ONBOARDING.CHANNELS.MESSENGER.TITLE'),
    description: t('ONBOARDING.CHANNELS.MESSENGER.DESCRIPTION'),
    icon: 'i-logos-messenger',
    iconWrap: 'bg-primary/10',
    iconClass: 'opacity-90',
    cardClass: 'border border-border/60 bg-card hover:border-border',
    buttonVariant: 'outline',
    buttonClass:
      'h-8 px-4 text-[13px] font-medium bg-background shadow-sm shrink-0',
    buttonLabel: t('ONBOARDING.CHANNELS.CONNECT'),
    route: 'facebook',
  },
  {
    key: 'website',
    title: t('ONBOARDING.CHANNELS.LIVE_CHAT.TITLE'),
    description: t('ONBOARDING.CHANNELS.LIVE_CHAT.DESCRIPTION'),
    icon: 'i-lucide-bot',
    iconWrap: 'bg-primary/10',
    iconClass: 'text-primary',
    cardClass: 'border border-border/60 bg-card hover:border-border',
    buttonVariant: 'outline',
    buttonClass:
      'h-8 px-4 text-[13px] font-medium bg-background shadow-sm shrink-0',
    buttonLabel: t('ONBOARDING.CHANNELS.SETUP'),
    route: 'website',
  },
]);

const comingSoon = computed(() => [
  {
    key: 'telegram',
    label: t('ONBOARDING.COMING_SOON.TELEGRAM'),
    icon: 'i-lucide-send',
    iconClass: 'text-primary',
  },
  {
    key: 'apple',
    label: t('ONBOARDING.COMING_SOON.APPLE'),
    icon: 'i-lucide-message-square',
    iconClass: 'text-green-500',
  },
  {
    key: 'google',
    label: t('ONBOARDING.COMING_SOON.GOOGLE'),
    icon: 'i-lucide-map-pin',
    iconClass: 'text-primary',
    hideOnMobile: true,
  },
  {
    key: 'slack',
    label: t('ONBOARDING.COMING_SOON.SLACK'),
    icon: 'i-lucide-hash',
    iconClass: 'text-primary',
  },
]);

const connectChannel = channelKey => {
  router.push(
    accountScopedRoute('settings_inboxes_page_channel', {
      sub_page: channelKey,
    })
  );
};

const learnMore = () => {
  window.open('https://www.chatwoot.com/docs', '_blank', 'noopener,noreferrer');
};
</script>

<template>
  <div
    class="flex-1 overflow-y-auto bg-background flex flex-col relative p-6 w-full h-full min-h-0"
  >
    <div
      class="flex-1 flex flex-col items-center justify-center text-center max-w-2xl mx-auto w-full animate-in fade-in zoom-in-95 duration-500 my-auto py-8"
    >
      <!-- No channels: stepper + integration cards -->
      <div v-if="!hasChannels" class="w-full flex flex-col items-center">
        <div
          class="size-16 rounded-full bg-primary/10 flex items-center justify-center mb-6 ring-8 ring-primary/5"
        >
          <span class="i-lucide-message-square size-8 text-primary" />
        </div>

        <h2 class="text-base font-medium tracking-tight text-foreground mb-2">
          {{ t('ONBOARDING.CONNECT.TITLE') }}
        </h2>
        <p class="text-muted-foreground mb-8 text-sm max-w-lg">
          {{ t('ONBOARDING.CONNECT.DESCRIPTION') }}
        </p>

        <div
          class="w-full max-w-3xl bg-card/50 border border-border/50 rounded-xl p-5 mb-8 text-left shadow-sm backdrop-blur-sm relative overflow-hidden mx-auto"
        >
          <div
            class="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-2xl -translate-y-1/2 translate-x-1/4 pointer-events-none"
          />

          <h3
            class="text-sm font-semibold text-foreground mb-4 flex items-center justify-between"
          >
            {{ t('ONBOARDING.CONNECT.GETTING_STARTED') }}
            <span
              class="text-[10px] font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-full tracking-wide uppercase"
            >
              {{
                t('ONBOARDING.CONNECT.STEP_BADGE', {
                  current: currentStepNumber,
                  total: steps.length,
                })
              }}
            </span>
          </h3>

          <div class="flex flex-col relative ml-1">
            <div
              class="absolute left-[11px] top-3 bottom-3 w-px bg-border z-0"
            />

            <div
              v-for="step in steps"
              :key="step.key"
              class="flex items-center gap-4 py-2.5 z-10"
              :class="{
                'opacity-60 hover:opacity-100 transition-opacity':
                  step.status === 'pending',
              }"
            >
              <div
                v-if="step.status === 'completed'"
                class="size-[22px] rounded-full bg-primary flex items-center justify-center shrink-0 ring-4 ring-card"
              >
                <span class="i-lucide-check size-3 text-primary-foreground" />
              </div>
              <div
                v-else-if="step.status === 'active'"
                class="size-[22px] rounded-full border-2 border-primary bg-card flex items-center justify-center shrink-0 ring-4 ring-card shadow-sm shadow-primary/20"
              >
                <div class="size-1.5 rounded-full bg-primary animate-pulse" />
              </div>
              <div
                v-else
                class="size-[22px] rounded-full border-2 border-muted-foreground/30 bg-card flex items-center justify-center shrink-0 ring-4 ring-card transition-colors"
              />

              <span
                class="text-sm"
                :class="{
                  'font-medium text-muted-foreground line-through':
                    step.status === 'completed',
                  'font-semibold text-foreground': step.status === 'active',
                  'font-medium text-foreground transition-colors':
                    step.status === 'pending',
                }"
              >
                {{ step.label }}
              </span>
            </div>
          </div>
        </div>

        <div
          class="grid grid-cols-1 sm:grid-cols-2 gap-3 w-full mb-10 text-left"
        >
          <div
            v-for="channel in channels"
            :key="channel.key"
            class="group flex items-center gap-4 p-3 rounded-xl shadow-sm transition-all"
            :class="channel.cardClass"
          >
            <div
              class="size-10 rounded-lg flex items-center justify-center shrink-0"
              :class="channel.iconWrap"
            >
              <span class="size-5" :class="[channel.icon, channel.iconClass]" />
            </div>
            <div class="flex flex-col flex-1 min-w-0">
              <span class="font-semibold text-sm text-foreground">
                {{ channel.title }}
              </span>
              <span
                class="text-[13px] text-muted-foreground line-clamp-1 mt-0.5"
              >
                {{ channel.description }}
              </span>
            </div>
            <RelayButton
              :variant="channel.buttonVariant"
              size="sm"
              :class="channel.buttonClass"
              @click="connectChannel(channel.route)"
            >
              {{ channel.buttonLabel }}
            </RelayButton>
          </div>
        </div>

        <div class="flex flex-col items-center gap-6 mt-2">
          <div
            class="flex items-center gap-5 px-5 py-2.5 bg-card rounded-full border border-border/50 shadow-sm opacity-80 mt-4 mb-4 flex-wrap justify-center"
          >
            <span
              class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider mr-1"
            >
              {{ t('ONBOARDING.COMING_SOON.LABEL') }}
            </span>
            <div
              v-for="item in comingSoon"
              :key="item.key"
              class="items-center gap-1.5"
              :class="item.hideOnMobile ? 'hidden sm:flex' : 'flex'"
            >
              <span class="size-4" :class="[item.icon, item.iconClass]" />
              <span class="text-[13px] font-medium text-foreground">
                {{ item.label }}
              </span>
            </div>
          </div>

          <button
            type="button"
            class="text-sm font-medium text-primary hover:underline flex items-center gap-1.5 transition-colors mt-12"
            @click="learnMore"
          >
            <span class="i-lucide-lightbulb size-4" />
            {{ t('ONBOARDING.CONNECT.LEARN_HOW') }}
          </button>
        </div>
      </div>

      <!-- Filter with no results -->
      <div
        v-else-if="isFilteredView"
        class="w-full max-w-sm mx-auto flex flex-col items-center text-center"
      >
        <div
          class="size-[72px] rounded-2xl bg-primary/10 ring-1 ring-inset ring-primary/5 shadow-sm flex items-center justify-center mb-6"
        >
          <span class="i-lucide-archive size-8 text-primary" />
        </div>
        <h2 class="text-[20px] font-[600] text-foreground mb-3">
          {{ t('CONVERSATION.NO_MESSAGE_1') }}
        </h2>
        <p
          class="text-[14.5px] text-muted-foreground mb-8 leading-relaxed max-w-[280px]"
        >
          {{ t('CONVERSATION.NO_MESSAGE_1_DESCRIPTION') }}
        </p>
      </div>

      <!-- Channels connected, no chats -->
      <div
        v-else
        class="w-full flex flex-col items-center animate-in fade-in zoom-in-95 duration-500 text-center"
      >
        <div class="size-20 mb-6 relative">
          <div
            class="absolute inset-0 bg-primary/20 rounded-full animate-ping opacity-75"
          />
          <div
            class="relative size-full bg-primary/10 border border-primary/10 rounded-full flex items-center justify-center shadow-sm"
          >
            <span class="i-lucide-rocket size-8 text-primary" />
          </div>
        </div>
        <h2 class="text-[20px] font-[600] text-foreground mb-3">
          {{ t('ONBOARDING.ALL_SET.TITLE') }}
        </h2>
        <p
          class="text-[14.5px] text-muted-foreground mb-8 leading-relaxed max-w-[340px]"
        >
          {{ t('ONBOARDING.ALL_SET.DESCRIPTION') }}
        </p>
      </div>
    </div>
  </div>
</template>
