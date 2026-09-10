<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import InboxStarIcon from 'dashboard/components-next/Inbox/InboxStarIcon.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { getInboxIconByType } from 'dashboard/helper/inbox';

const props = defineProps({
  inboxItem: { type: Object, default: () => ({}) },
  isActive: { type: Boolean, default: false },
  isStarred: { type: Boolean, default: false },
  isSelected: { type: Boolean, default: false },
});

const emit = defineEmits([
  'click',
  'toggleStar',
  'toggleSelect',
  'contextmenu',
]);

const { t } = useI18n();

const primaryActor = computed(() => props.inboxItem?.primaryActor || {});
const meta = computed(() => primaryActor.value?.meta || {});
const sender = computed(() => meta.value?.sender || {});
const isUnread = computed(() => !props.inboxItem?.readAt);

const inboxesList = useMapGetter('inboxes/getInboxes');
const inbox = computed(() =>
  (inboxesList.value || []).find(i => i.id === primaryActor.value?.inboxId)
);
const channelIcon = computed(() => {
  if (!inbox.value) return '';
  const type = inbox.value.channel_type || inbox.value.channelType;
  const medium = inbox.value.medium;
  return getInboxIconByType(type, medium, 'fill');
});

const contactName = computed(() => sender.value?.name || t('INBOX.NO_CONTENT'));
const contactThumbnail = computed(() => sender.value?.thumbnail || '');
const contactStatus = computed(() => sender.value?.availabilityStatus || null);

const lastActivityAt = computed(() => {
  const timestamp = props.inboxItem?.lastActivityAt;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

// The last message of the conversation drives the row snippet.
const snippet = computed(() => {
  const messages = primaryActor.value?.messages || [];
  const lastMessage = messages[messages.length - 1] || {};
  return (lastMessage.content || '').trim();
});

// Email conversations lead with their subject; everything else leads with the
// message snippet, so we only prefix a separator when both are present.
const subject = computed(() => {
  const attrs = primaryActor.value?.additionalAttributes || {};
  return attrs.mailSubject || '';
});

const snippetWithSeparator = computed(() => {
  if (!snippet.value) return '';
  return subject.value ? `- ${snippet.value}` : snippet.value;
});

const attachments = computed(() => {
  const messages = primaryActor.value?.messages || [];
  const lastMessage = messages[messages.length - 1] || {};
  const files = lastMessage.attachments || [];
  return files
    .map(file => {
      if (file.fallbackTitle) return file.fallbackTitle;
      if (file.fileName) return file.fileName;
      if (file.filename) return file.filename;
      if (file.extension) return `attachment.${file.extension}`;
      const url = file.dataUrl || '';
      if (url.includes('/')) {
        const part = url.split('/').pop()?.split('?')[0];
        if (part && part.includes('.')) return part;
      }
      return null;
    })
    .filter(Boolean)
    .slice(0, 3);
});

const attachmentPillClass = name => {
  const lower = String(name).toLowerCase();
  if (lower.endsWith('.pdf'))
    return 'bg-destructive/10 text-destructive border-destructive/20';
  return 'bg-primary/10 text-primary border-primary/20';
};
</script>

<template>
  <div
    role="button"
    class="flex items-center gap-4 px-5 py-3 text-left transition-colors w-full group border-b border-border/60 hover:shadow-sm cursor-pointer"
    :class="[
      isSelected
        ? 'bg-primary/10 hover:bg-primary/15'
        : isActive
          ? 'bg-primary/5 hover:bg-primary/5'
          : isUnread
            ? 'bg-background hover:bg-muted/20'
            : 'bg-muted/10 hover:bg-muted/30',
    ]"
    @click="emit('click')"
    @contextmenu.prevent="emit('contextmenu', $event)"
  >
    <!-- Star + Avatar -->
    <div class="flex items-center gap-3 shrink-0">
      <div
        role="checkbox"
        class="group/checkbox flex size-5 shrink-0 cursor-pointer items-center justify-center p-0"
        :aria-label="t('INBOX.LIST.SELECT_CONVERSATION')"
        :aria-checked="isSelected"
        @click.stop="emit('toggleSelect', inboxItem)"
      >
        <span
          class="flex size-[18px] items-center justify-center rounded-full border transition-colors"
          :class="
            isSelected
              ? 'border-primary bg-primary text-primary-foreground opacity-100'
              : 'border-input bg-background opacity-0 group-hover:opacity-100 group-hover/checkbox:border-primary/50'
          "
        >
          <svg
            v-if="isSelected"
            class="size-3"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="3"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <polyline points="20 6 9 17 4 12" />
          </svg>
        </span>
      </div>
      <button
        type="button"
        class="flex size-4 shrink-0 items-center justify-center p-0"
        :aria-label="t('INBOX.VIEWS.STARRED')"
        @click.stop="emit('toggleStar', inboxItem)"
      >
        <InboxStarIcon :filled="isStarred" />
      </button>
      <div class="relative shrink-0 ml-1">
        <Avatar
          :name="contactName"
          :src="contactThumbnail"
          :size="32"
          rounded-full
        />
        <div
          v-if="isUnread"
          class="absolute -top-0.5 -right-0.5 size-2 rounded-full bg-primary border border-card"
        />
      </div>
    </div>

    <!-- Sender -->
    <div class="w-40 xl:w-48 shrink-0 flex items-center gap-1.5 truncate">
      <span
        class="text-[14px] text-foreground truncate"
        :class="isUnread ? 'font-bold' : 'font-medium'"
      >
        {{ contactName }}
      </span>
      <span
        v-if="channelIcon"
        class="flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary"
      >
        <span :class="channelIcon" class="size-3.5" />
      </span>
      <span
        v-if="contactStatus === 'online'"
        class="size-1.5 rounded-full bg-primary shrink-0 ml-0.5"
      />
    </div>

    <!-- Subject & Snippet -->
    <div class="flex-1 min-w-0 truncate text-[14px]">
      <span
        v-if="subject"
        class="text-foreground pr-1"
        :class="isUnread ? 'font-bold' : 'font-medium'"
      >
        {{ subject }}
      </span>
      <span
        v-if="snippetWithSeparator"
        class="text-muted-foreground"
        :class="{ 'text-foreground font-medium': isUnread && !subject }"
      >
        {{ snippetWithSeparator }}
      </span>
    </div>

    <!-- Attachments -->
    <div
      v-if="attachments.length"
      class="flex gap-1.5 shrink-0 ml-2 hidden lg:flex"
    >
      <span
        v-for="name in attachments"
        :key="name"
        class="inline-flex items-center gap-1 text-[11px] font-medium px-2 py-0.5 rounded-md border bg-background/50"
        :class="attachmentPillClass(name)"
      >
        <span class="i-lucide-paperclip size-2.5" />
        {{ name }}
      </span>
    </div>

    <!-- Time -->
    <div class="w-20 shrink-0 text-right">
      <span
        class="text-[12px] text-muted-foreground"
        :class="isUnread ? 'font-bold text-foreground' : ''"
      >
        {{ lastActivityAt }}
      </span>
    </div>
  </div>
</template>
