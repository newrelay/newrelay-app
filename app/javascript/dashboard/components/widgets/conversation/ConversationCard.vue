<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'next/avatar/Avatar.vue';
import MessagePreview from './MessagePreview.vue';
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';

const props = defineProps({
  chat: { type: Object, required: true },
  currentContact: { type: Object, required: true },
  assignee: { type: Object, default: () => ({}) },
  inbox: { type: Object, default: () => ({}) },
  isActiveChat: { type: Boolean, default: false },
  hideThumbnail: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
});

defineEmits(['click', 'contextmenu']);

const { t } = useI18n();

const unreadCount = computed(() => props.chat.unread_count);
const hasUnread = computed(() => unreadCount.value > 0);
const lastMessageInChat = computed(() => getLastMessage(props.chat));

const lastActivityAt = computed(() => {
  const timestamp = props.chat?.timestamp;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

const priorityBadge = computed(() => {
  const priority = props.chat.priority;
  if (!priority) return null;

  const badgeMap = {
    [CONVERSATION_PRIORITY.URGENT]: {
      text: t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
      className: 'border-transparent bg-primary text-primary-foreground',
    },
    [CONVERSATION_PRIORITY.HIGH]: {
      text: t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
      className: 'border-transparent bg-primary text-primary-foreground',
    },
    [CONVERSATION_PRIORITY.MEDIUM]: {
      text: t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
      className: 'border-transparent bg-warning/10 text-warning',
    },
    [CONVERSATION_PRIORITY.LOW]: {
      text: t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
      className: 'border-transparent bg-success/10 text-success',
    },
  };

  return badgeMap[priority] || null;
});

const priorityBadgeBaseClass =
  'inline-flex h-5 shrink-0 items-center rounded-sm border px-1.5 py-0 text-[10px] font-medium transition-colors focus:outline-hidden focus:ring-1 focus:ring-ring';

const statusDotClass = computed(() => {
  const priority = props.chat.priority;
  if (priority === CONVERSATION_PRIORITY.URGENT) return 'bg-destructive';
  if (priority === CONVERSATION_PRIORITY.HIGH) return 'bg-primary';
  if (priority === CONVERSATION_PRIORITY.MEDIUM) return 'bg-warning';
  if (priority === CONVERSATION_PRIORITY.LOW) return 'bg-success';
  if (hasUnread.value) return 'bg-primary';
  if (props.chat.status === 'pending') return 'bg-warning';
  if (props.chat.status === 'snoozed') return 'bg-warning';
  if (props.chat.status === 'resolved') return 'bg-success';
  return 'bg-primary';
});

const channelSubtext = computed(() => {
  const parts = [];

  if (props.inbox?.name) {
    parts.push(props.inbox.name);
  }

  if (props.assignee?.name) {
    parts.push(props.assignee.name);
  }

  return parts.join(' · ');
});
</script>

<template>
  <button
    type="button"
    class="conversation relative flex w-full gap-3 rounded-lg p-3 text-left transition-colors"
    :class="[
      isActiveChat ? 'active bg-primary/5' : 'hover:bg-accent/50',
      compact ? 'mx-0' : '',
    ]"
    @click="$emit('click', $event)"
    @contextmenu.prevent="$emit('contextmenu', $event)"
  >
    <div class="relative mt-1 shrink-0">
      <img
        v-if="!hideThumbnail && currentContact.thumbnail"
        :src="currentContact.thumbnail"
        :alt="currentContact.name"
        class="size-10 rounded-full border border-border/50 object-cover"
      />
      <Avatar
        v-else-if="!hideThumbnail"
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="40"
        hide-offline-status
        rounded-full
        class="size-10 rounded-full border border-border/50"
      />
    </div>

    <div class="flex min-w-0 flex-1 flex-col gap-1">
      <div class="flex items-center justify-between gap-2">
        <div class="flex min-w-0 items-center gap-2">
          <span class="truncate text-sm font-semibold text-foreground">
            {{ currentContact.name }}
          </span>
          <span
            v-if="priorityBadge"
            :class="[priorityBadgeBaseClass, priorityBadge.className]"
          >
            {{ priorityBadge.text }}
          </span>
        </div>
        <span class="shrink-0 text-[11px] font-medium text-muted-foreground">
          {{ lastActivityAt }}
        </span>
      </div>

      <div class="mt-0.5 flex items-start justify-between gap-2">
        <div class="flex min-w-0 flex-1 flex-col gap-0.5">
          <MessagePreview
            v-if="lastMessageInChat"
            :message="lastMessageInChat"
            :show-message-type="false"
            class="!mx-0 !my-0 truncate text-[13px] leading-snug text-muted-foreground"
            :class="hasUnread ? 'font-medium text-foreground/80' : ''"
          />
          <p
            v-else
            class="truncate text-[13px] leading-snug text-muted-foreground"
          >
            {{ $t('CHAT_LIST.NO_MESSAGES') }}
          </p>
          <p
            v-if="channelSubtext"
            class="truncate text-[12px] text-muted-foreground/70"
          >
            {{ channelSubtext }}
          </p>
        </div>
        <div
          class="mt-1.5 size-2 shrink-0 rounded-full"
          :class="statusDotClass"
        />
      </div>
    </div>
  </button>
</template>
