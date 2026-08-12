<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'next/avatar/Avatar.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import MoreActions from './MoreActions.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();
const { t } = useI18n();
const accountLabels = useMapGetter('labels/getLabels');

const toggleSidebar = () => {
  updateUISettings({
    is_contact_sidebar_open: !uiSettings.value.is_contact_sidebar_open,
  });
};

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

const customerSince = computed(() => {
  const createdAt = currentContact.value?.created_at;
  if (!createdAt) return '';
  const date = new Date(createdAt * 1000);
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
});

const unreadCount = computed(() => props.chat.unread_count);
const hasUnread = computed(() => unreadCount.value > 0);

const primaryLabel = computed(() => {
  const titles = props.chat.labels || [];
  if (!titles.length) return null;
  return (
    accountLabels.value.find(label => label.title === titles[0]) || {
      title: titles[0],
      color: null,
    }
  );
});

const statusBadge = computed(() => {
  if (primaryLabel.value) {
    return { text: primaryLabel.value.title, variant: 'label' };
  }
  const status = props.chat.status;
  if (status === 'pending') {
    return {
      text: t('CHAT_LIST.STATUS_TABS.IN_PROGRESS'),
      variant: 'secondary',
    };
  }
  if (status === 'snoozed') {
    return { text: t('CHAT_LIST.STATUS_TABS.ON_HOLD'), variant: 'warning' };
  }
  if (props.chat.priority === 'urgent' || props.chat.priority === 'high') {
    return {
      text: t(
        `CONVERSATION.PRIORITY.OPTIONS.${props.chat.priority.toUpperCase()}`
      ),
      variant: 'default',
    };
  }
  return null;
});

const badgeClass = computed(() => {
  const variant = statusBadge.value?.variant;
  if (variant === 'default') {
    return 'bg-primary text-primary-foreground border-transparent';
  }
  if (variant === 'secondary') {
    return 'bg-primary/10 text-primary border-primary/20';
  }
  if (variant === 'warning') {
    return 'bg-background text-foreground border-border';
  }
  return 'bg-primary text-primary-foreground border-transparent';
});

const statusDotClass = computed(() => {
  const priority = props.chat?.priority;
  if (priority === 'urgent') return 'bg-destructive';
  if (priority === 'high') return 'bg-primary';
  if (priority === 'medium') return 'bg-warning';
  if (priority === 'low') return 'bg-success';
  if (hasUnread.value) return 'bg-primary';
  return 'bg-muted-foreground/30';
});

const statusTextColorClass = computed(() => {
  return (
    statusDotClass.value?.replace('bg-', 'text-').split('/')[0] || 'bg-white'
  );
});
</script>

<template>
  <div
    class="h-16 px-6 border-b border-border bg-card flex items-center justify-between shrink-0"
  >
    <div class="flex items-center gap-3 min-w-0">
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="40"
        :status="currentContact.availability_status"
        hide-offline-status
        rounded-full
        class="border border-border/50 shrink-0"
      />
      <div class="flex flex-col min-w-0">
        <div class="flex items-center gap-2">
          <span
            class="font-semibold text-foreground hover:text-primary transition-colors cursor-pointer text-base truncate"
          >
            {{ currentContact.name }}
          </span>
          <span
            v-if="statusBadge"
            class="inline-flex items-center border transition-colors focus:outline-hidden focus:ring-1 focus:ring-ring border-transparent bg-primary text-primary-foreground text-[10px] font-medium px-1.5 py-0 rounded-sm"
            :class="badgeClass"
          >
            {{ statusBadge.text }}
          </span>
          <span
            class="text-[11px] font-medium flex items-center gap-1 shrink-0"
            :class="statusTextColorClass"
          >
            <span class="size-1.5 rounded-full" :class="statusDotClass" />
            {{ chat.id }}
          </span>
        </div>
        <div
          class="flex items-center gap-2 text-[13px] text-muted-foreground mt-0.5"
        >
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template -->
          <span class="truncate">Customer Since {{ customerSince }}</span>
        </div>
      </div>
    </div>

    <div class="flex items-center gap-1 shrink-0">
      <MoreActions />
      <RelayButton
        variant="ghost"
        size="icon"
        class="text-muted-foreground shrink-0 focus-visible:ring-0"
        @click="toggleSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
  </div>
</template>
