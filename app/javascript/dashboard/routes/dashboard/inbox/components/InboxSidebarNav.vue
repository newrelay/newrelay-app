<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import Icon from 'next/icon/Icon.vue';
import IconWhatsApp from 'dashboard/components-next/icons/IconWhatsApp.vue';

const props = defineProps({
  activeView: { type: String, default: 'all' },
  viewCounts: {
    type: Object,
    default: () => ({}),
  },
  channels: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const isViewsOpen = ref(true);
const isChannelsOpen = ref(true);

const viewsList = computed(() => [
  {
    id: 'all',
    label: t('INBOX.VIEWS.ALL'),
    icon: 'i-lucide-inbox',
    count: props.viewCounts.all ?? 0,
  },
  {
    id: 'unread',
    label: t('INBOX.VIEWS.UNREAD'),
    icon: 'i-lucide-clock',
    count: props.viewCounts.unread ?? 0,
  },
  {
    id: 'assigned',
    label: t('INBOX.VIEWS.ASSIGNED'),
    icon: 'i-lucide-user',
    count: props.viewCounts.assigned ?? 0,
  },
  {
    id: 'starred',
    label: t('INBOX.VIEWS.STARRED'),
    icon: 'i-lucide-star',
    count: props.viewCounts.starred ?? 0,
  },
  {
    id: 'snoozed',
    label: t('INBOX.VIEWS.SNOOZED'),
    icon: 'i-lucide-alarm-clock',
    count: props.viewCounts.snoozed ?? 0,
  },
  {
    id: 'archived',
    label: t('INBOX.VIEWS.ARCHIVED'),
    icon: 'i-lucide-archive',
    count: props.viewCounts.archived ?? 0,
  },
  {
    id: 'spam',
    label: t('INBOX.VIEWS.SPAM'),
    icon: 'i-lucide-circle-alert',
    count: props.viewCounts.spam ?? 0,
  },
]);

const channelIcon = channel => {
  const type = channel.channelType || channel.channel_type;
  const medium = channel.medium;

  if (type === INBOX_TYPES.WEB) return 'i-lucide-globe';
  if (type === INBOX_TYPES.EMAIL) return 'i-lucide-mail';
  if (type === INBOX_TYPES.INSTAGRAM) return 'i-lucide-instagram';
  if (type === INBOX_TYPES.FB) return 'i-lucide-message-circle';
  if (
    type === INBOX_TYPES.SMS ||
    type === INBOX_TYPES.TWILIO ||
    medium === 'sms'
  ) {
    return 'i-lucide-message-square-more';
  }

  return 'i-lucide-inbox';
};

const isWhatsAppChannel = channel => {
  const type = channel.channelType || channel.channel_type;
  const medium = channel.medium;
  return type === INBOX_TYPES.WHATSAPP || medium === 'whatsapp';
};

const NAV_ICON_CLASS = 'size-4 shrink-0';

const channelLabel = channel => {
  return channel.name || channel.phoneNumber || channel.email;
};

const selectView = id => emit('select', id);

const addChannel = () => {
  router.push(accountScopedRoute('settings_inbox_list'));
};

const NAV_ITEM_BASE_CLASS =
  'relative flex h-9 w-full items-center justify-between rounded-md border-0 px-3 text-sm font-medium transition-colors outline-none';

const navItemClass = active =>
  active
    ? 'bg-primary/10 text-primary'
    : 'bg-transparent text-muted-foreground hover:bg-accent hover:text-foreground';

const navBadgeClass = active =>
  [
    'shrink-0 h-5 min-w-[20px] px-1.5 rounded-full text-[11px] font-semibold',
    active
      ? 'bg-transparent text-primary'
      : 'bg-muted/50 text-muted-foreground',
  ].join(' ');
</script>

<template>
  <div class="flex-1 overflow-y-auto py-4 px-3 flex flex-col gap-6 min-h-0">
    <!-- Views -->
    <div class="w-full">
      <div class="mb-2 flex items-center justify-between px-3">
        <button
          type="button"
          class="flex items-center gap-2 p-0 outline-none transition-opacity hover:opacity-80"
          @click="isViewsOpen = !isViewsOpen"
        >
          <span
            class="text-xs font-bold uppercase tracking-wider text-muted-foreground"
          >
            {{ t('INBOX.VIEWS.TITLE') }}
          </span>
          <span
            class="i-lucide-chevron-down size-3.5 text-muted-foreground transition-transform duration-200"
            :class="{ '-rotate-90': !isViewsOpen }"
          />
        </button>
      </div>
      <div v-show="isViewsOpen" class="space-y-0.5">
        <button
          v-for="view in viewsList"
          :key="view.id"
          type="button"
          :class="[NAV_ITEM_BASE_CLASS, navItemClass(activeView === view.id)]"
          @click="selectView(view.id)"
        >
          <div
            v-if="activeView === view.id"
            class="absolute left-0 top-1/2 h-4 w-[3px] -translate-y-1/2 rounded-r-full bg-primary"
          />
          <div class="flex min-w-0 items-center gap-3">
            <Icon :icon="view.icon" :class="NAV_ICON_CLASS" />
            <span class="truncate">{{ view.label }}</span>
          </div>
          <span :class="navBadgeClass(activeView === view.id)">
            {{ view.count }}
          </span>
        </button>
      </div>
    </div>

    <!-- Channels -->
    <div class="w-full">
      <div class="mb-2 flex items-center justify-between px-3">
        <button
          type="button"
          class="flex items-center gap-2 p-0 outline-none transition-opacity hover:opacity-80"
          @click="isChannelsOpen = !isChannelsOpen"
        >
          <span
            class="text-xs font-bold uppercase tracking-wider text-muted-foreground"
          >
            {{ t('INBOX.CHANNELS.TITLE') }}
          </span>
          <span
            class="i-lucide-chevron-down size-3.5 text-muted-foreground transition-transform duration-200"
            :class="{ '-rotate-90': !isChannelsOpen }"
          />
        </button>
        <button
          type="button"
          class="rounded-md p-1 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          :aria-label="t('INBOX.CHANNELS.ADD')"
          @click="addChannel"
        >
          <span class="i-lucide-plus size-4" />
        </button>
      </div>
      <div v-show="isChannelsOpen" class="space-y-0.5">
        <button
          v-for="channel in channels"
          :key="channel.id"
          type="button"
          :class="[
            NAV_ITEM_BASE_CLASS,
            navItemClass(activeView === `inbox:${channel.id}`),
          ]"
          @click="selectView(`inbox:${channel.id}`)"
        >
          <div
            v-if="activeView === `inbox:${channel.id}`"
            class="absolute left-0 top-1/2 h-4 w-[3px] -translate-y-1/2 rounded-r-full bg-primary"
          />
          <div class="flex min-w-0 items-center gap-3">
            <IconWhatsApp
              v-if="isWhatsAppChannel(channel)"
              :class="NAV_ICON_CLASS"
            />
            <Icon v-else :icon="channelIcon(channel)" :class="NAV_ICON_CLASS" />
            <span class="truncate">{{ channelLabel(channel) }}</span>
          </div>
          <span :class="navBadgeClass(activeView === `inbox:${channel.id}`)">
            {{ channel.count ?? 0 }}
          </span>
        </button>
      </div>
    </div>
  </div>
</template>
