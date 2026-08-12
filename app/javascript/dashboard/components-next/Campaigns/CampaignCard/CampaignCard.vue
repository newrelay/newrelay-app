<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import { RelayButton } from 'dashboard/components-next/relay';
import LiveChatCampaignDetails from './LiveChatCampaignDetails.vue';
import SMSCampaignDetails from './SMSCampaignDetails.vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
  isLiveChatType: {
    type: Boolean,
    default: false,
  },
  isEnabled: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: '',
  },
  sender: {
    type: Object,
    default: null,
  },
  inbox: {
    type: Object,
    default: null,
  },
  scheduledAt: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const STATUS_COMPLETED = 'completed';
const STATUS_PROCESSING = 'processing';

const { formatMessage } = useMessageFormatter();

const isActive = computed(() =>
  props.isLiveChatType ? props.isEnabled : props.status !== STATUS_COMPLETED
);

const statusColorClass = computed(() =>
  isActive.value
    ? 'text-emerald-600 bg-emerald-500/10 dark:text-emerald-400 dark:bg-emerald-500/20'
    : 'text-muted-foreground bg-muted'
);

const campaignStatus = computed(() => {
  if (props.isLiveChatType) {
    return props.isEnabled
      ? t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.DISABLED');
  }

  if (props.status === STATUS_COMPLETED) {
    return t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED');
  }

  if (props.status === STATUS_PROCESSING) {
    return t('CAMPAIGN.SMS.CARD.STATUS.PROCESSING');
  }

  return t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED');
});

const inboxName = computed(() => props.inbox?.name || '');

const inboxIcon = computed(() => {
  if (!props.inbox) return '';
  const { medium, channel_type: type } = props.inbox;
  return getInboxIconByType(type, medium);
});
</script>

<template>
  <div
    class="group flex items-center justify-between gap-4 p-5 rounded-xl border border-border bg-card shadow-sm transition-colors hover:border-border/80"
  >
    <div class="flex flex-col items-start flex-1 min-w-0">
      <div class="flex items-center gap-3 mb-2.5 w-fit">
        <span class="text-[15px] font-medium text-foreground line-clamp-1">
          {{ title }}
        </span>
        <span
          class="px-2 py-0.5 rounded-md text-[11.5px] font-medium shrink-0"
          :class="statusColorClass"
        >
          {{ campaignStatus }}
        </span>
      </div>
      <div
        v-dompurify-html="formatMessage(message, false, false, false)"
        class="text-[14px] text-muted-foreground line-clamp-1 [&>p]:mb-0 mb-3.5 h-5"
      />
      <div
        class="flex items-center w-full gap-1.5 overflow-hidden text-[13px] font-medium text-muted-foreground"
      >
        <LiveChatCampaignDetails
          v-if="isLiveChatType"
          :sender="sender"
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
        />
        <SMSCampaignDetails
          v-else
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
          :scheduled-at="scheduledAt"
        />
      </div>
    </div>
    <div
      class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
    >
      <RelayButton
        v-if="isLiveChatType"
        variant="ghost"
        size="sm"
        class="size-8 p-0 bg-muted/50 text-muted-foreground hover:text-foreground"
        :title="t('CAMPAIGN.LIVE_CHAT.EDIT.TITLE')"
        @click="emit('edit')"
      >
        <span class="i-lucide-sliders-horizontal size-4" />
      </RelayButton>
      <RelayButton
        variant="ghost"
        size="sm"
        class="size-8 p-0 bg-destructive/10 text-destructive/70 hover:bg-destructive/20 hover:text-destructive"
        :title="t('CAMPAIGN.CONFIRM_DELETE.CONFIRM')"
        @click="emit('delete')"
      >
        <span class="i-lucide-trash-2 size-4" />
      </RelayButton>
    </div>
  </div>
</template>
