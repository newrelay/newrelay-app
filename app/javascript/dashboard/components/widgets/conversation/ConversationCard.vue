<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'next/avatar/Avatar.vue';
import MessagePreview from './MessagePreview.vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  chat: { type: Object, required: true },
  currentContact: { type: Object, required: true },
  assignee: { type: Object, default: () => ({}) },
  inbox: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
  isActiveChat: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  showInboxName: { type: Boolean, default: false },
  hideThumbnail: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
  isStarred: { type: Boolean, default: false },
});

const emit = defineEmits([
  'click',
  'contextmenu',
  'selectConversation',
  'deSelectConversation',
  'toggleStar',
]);

const { t } = useI18n();
const accountLabels = useMapGetter('labels/getLabels');

const unreadCount = computed(() => props.chat.unread_count);
const hasUnread = computed(() => unreadCount.value > 0);
const lastMessageInChat = computed(() => getLastMessage(props.chat));

const lastActivityAt = computed(() => {
  const timestamp = props.chat?.timestamp;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

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
  const priority = props.chat.priority;
  if (priority === 'urgent') return 'bg-destructive';
  if (priority === 'high') return 'bg-primary';
  if (priority === 'medium') return 'bg-amber-500';
  if (priority === 'low') return 'bg-emerald-500';
  if (hasUnread.value) return 'bg-primary';
  if (props.chat.status === 'pending') return 'bg-amber-500';
  if (props.chat.status === 'snoozed') return 'bg-amber-500';
  if (props.chat.status === 'resolved') return 'bg-emerald-500';
  return 'bg-primary';
});

const onSelectConversation = checked => {
  if (checked) {
    emit('selectConversation', props.chat.id, props.inbox.id);
  } else {
    emit('deSelectConversation', props.chat.id, props.inbox.id);
  }
};

const selectedModel = computed({
  get: () => props.selected,
  set: value => onSelectConversation(value),
});
</script>

<template>
  <div
    class="flex gap-3 p-3 mx-2 mb-1 rounded-lg text-left transition-colors relative cursor-pointer group"
    :class="[
      isActiveChat
        ? 'bg-primary/5'
        : selected
          ? 'bg-primary/10'
          : 'hover:bg-muted/40',
      compact ? 'mx-0' : '',
    ]"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <button
      v-if="false && !hideThumbnail"
      type="button"
      class="size-[18px] rounded-full border flex items-center justify-center transition-colors shrink-0 mt-1.5"
      :class="
        selectedModel
          ? 'bg-primary border-primary text-primary-foreground opacity-100'
          : 'border-input opacity-0 group-hover:opacity-100 bg-background hover:border-primary/50'
      "
      @click.stop="selectedModel = !selectedModel"
    >
      <span v-if="selectedModel" class="i-lucide-check size-3" />
    </button>

    <button
      v-if="false"
      type="button"
      class="size-4 flex items-center justify-center shrink-0 mt-1.5"
      @click.stop="emit('toggleStar', chat)"
    >
      <span
        v-if="isStarred"
        class="size-4 hover:text-warning cursor-pointer i-ri-star-fill text-warning opacity-100"
      />
      <span
        v-else
        class="size-4 hover:text-warning cursor-pointer i-lucide-star text-muted-foreground opacity-30 group-hover:opacity-100 transition-opacity"
      />
    </button>

    <div class="relative shrink-0 mt-0.5">
      <Avatar
        v-if="!hideThumbnail"
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="40"
        hide-offline-status
        rounded-full
      />
    </div>

    <div class="flex-1 min-w-0 flex flex-col gap-1">
      <div class="flex items-center justify-between gap-2">
        <div class="flex items-center gap-2 min-w-0">
          <span
            class="text-sm truncate text-foreground"
            :class="hasUnread ? 'font-semibold' : 'font-medium'"
          >
            {{ currentContact.name }}
          </span>
          <span
            v-if="statusBadge"
            class="text-[10px] font-medium px-2 rounded-full shrink-0 border"
            :class="badgeClass"
          >
            {{ statusBadge.text }}
          </span>
        </div>
        <span class="text-[11px] text-muted-foreground shrink-0 font-medium">
          {{ lastActivityAt }}
        </span>
      </div>

      <div class="flex items-center justify-between gap-2 mt-0.5">
        <MessagePreview
          v-if="lastMessageInChat"
          :message="lastMessageInChat"
          class="text-[13px] text-muted-foreground truncate flex-1 leading-snug !my-0 !mx-0"
          :class="hasUnread ? 'font-medium text-foreground/80' : ''"
        />
        <p
          v-else
          class="text-[13px] text-muted-foreground truncate flex-1 leading-snug"
        >
          {{ $t('CHAT_LIST.NO_MESSAGES') }}
        </p>
        <div class="size-2 rounded-full shrink-0" :class="statusDotClass" />
      </div>

      <div
        v-if="(showAssignee && assignee.name) || showInboxName"
        class="text-[11px] text-muted-foreground truncate"
      >
        <span v-if="showInboxName">{{ inbox.name }}</span>
        <span v-if="showInboxName && showAssignee && assignee.name"> · </span>
        <span v-if="showAssignee && assignee.name">{{ assignee.name }}</span>
      </div>
    </div>
  </div>
</template>
