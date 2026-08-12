<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { INBOX_TYPES, getInboxIconByType } from 'dashboard/helper/inbox';

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
  return getInboxIconByType(type, medium);
};

const channelLabel = channel => {
  const type = channel.channelType || channel.channel_type;
  const medium = channel.medium;
  if (type === INBOX_TYPES.WHATSAPP || medium === 'whatsapp') {
    return t('INBOX.CHANNELS.WHATSAPP');
  }
  if (type === INBOX_TYPES.EMAIL) return t('INBOX.CHANNELS.EMAIL');
  if (type === INBOX_TYPES.INSTAGRAM) return t('INBOX.CHANNELS.INSTAGRAM');
  if (type === INBOX_TYPES.WEB) return t('INBOX.CHANNELS.LIVE_CHAT');
  if (
    type === INBOX_TYPES.SMS ||
    type === INBOX_TYPES.TWILIO ||
    medium === 'sms'
  ) {
    return t('INBOX.CHANNELS.SMS');
  }
  return channel.name;
};

const selectView = id => emit('select', id);

const addChannel = () => {
  router.push(accountScopedRoute('settings_inbox_list'));
};
</script>

<template>
  <div class="flex-1 overflow-y-auto py-4 px-3 flex flex-col gap-6 min-h-0">
    <!-- Views -->
    <div class="w-full">
      <button
        type="button"
        class="flex items-center gap-2 px-3 mb-2 hover:opacity-80 transition-opacity outline-none"
        @click="isViewsOpen = !isViewsOpen"
      >
        <span
          class="text-xs font-bold text-muted-foreground uppercase tracking-wider"
        >
          {{ t('INBOX.VIEWS.TITLE') }}
        </span>
        <span
          class="i-lucide-chevron-down size-3.5 text-muted-foreground transition-transform duration-200"
          :class="{ '-rotate-90': !isViewsOpen }"
        />
      </button>
      <div v-show="isViewsOpen" class="space-y-0.5">
        <button
          v-for="view in viewsList"
          :key="view.id"
          type="button"
          class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm font-medium transition-colors relative"
          :class="
            activeView === view.id
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'
          "
          @click="selectView(view.id)"
        >
          <div
            v-if="activeView === view.id"
            class="absolute left-0 top-1/2 -translate-y-1/2 h-4 w-[3px] bg-primary rounded-r-full"
          />
          <div class="flex items-center gap-3 min-w-0">
            <span class="size-4 shrink-0" :class="[view.icon]" />
            <span class="truncate">{{ view.label }}</span>
          </div>
          <span
            class="text-[11px] font-semibold px-2 py-0.5 rounded-full shrink-0"
            :class="
              activeView === view.id
                ? 'text-primary'
                : 'bg-muted/50 text-muted-foreground'
            "
          >
            {{ view.count }}
          </span>
        </button>
      </div>
    </div>

    <!-- Channels -->
    <div class="w-full">
      <div class="flex items-center justify-between px-3 mb-2">
        <button
          type="button"
          class="flex items-center gap-2 hover:opacity-80 transition-opacity outline-none"
          @click="isChannelsOpen = !isChannelsOpen"
        >
          <span
            class="text-xs font-bold text-muted-foreground uppercase tracking-wider"
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
          class="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-md hover:bg-muted"
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
          class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm font-medium transition-colors relative"
          :class="
            activeView === `inbox:${channel.id}`
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'
          "
          @click="selectView(`inbox:${channel.id}`)"
        >
          <div
            v-if="activeView === `inbox:${channel.id}`"
            class="absolute left-0 top-1/2 -translate-y-1/2 h-4 w-[3px] bg-primary rounded-r-full"
          />
          <div class="flex items-center gap-3 min-w-0">
            <span class="size-4 shrink-0" :class="[channelIcon(channel)]" />
            <span class="truncate">{{ channelLabel(channel) }}</span>
          </div>
          <span
            class="text-[11px] font-semibold px-2 py-0.5 rounded-full shrink-0"
            :class="
              activeView === `inbox:${channel.id}`
                ? 'text-primary'
                : 'bg-muted/50 text-muted-foreground'
            "
          >
            {{ channel.count ?? 0 }}
          </span>
        </button>
      </div>
    </div>
  </div>
</template>
