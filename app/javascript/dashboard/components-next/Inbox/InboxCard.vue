<script setup>
import { computed, ref, onBeforeMount } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import InboxContextMenu from 'dashboard/routes/dashboard/inbox/components/InboxContextMenu.vue';
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
  'contextMenuOpen',
  'contextMenuClose',
  'markNotificationAsRead',
  'markNotificationAsUnRead',
  'deleteNotification',
  'toggleStar',
  'toggleSelect',
]);

const { t } = useI18n();

const isContextMenuOpen = ref(false);
const contextMenuPosition = ref({ x: null, y: null });

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

const subject = computed(() => {
  const attrs = primaryActor.value?.additionalAttributes || {};
  if (attrs.mailSubject) return attrs.mailSubject;
  const type = props.inboxItem?.notificationType?.toUpperCase();
  if (type) return t(`INBOX.TYPES_NEXT.${type}`);
  return t('INBOX.NO_CONTENT');
});

const snippet = computed(() => {
  const body = props.inboxItem?.pushMessageBody || '';
  return body.replace(/^[^:]+:\s*/, '').trim();
});

const snippetWithSeparator = computed(() =>
  snippet.value ? `- ${snippet.value}` : ''
);

const attachments = computed(() => {
  const messages = primaryActor.value?.messages || [];
  const lastMessage = messages[0] || {};
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
    return 'bg-red-100 text-red-600 border-red-200/60';
  return 'bg-primary/10 text-primary border-primary/20';
};

const menuItems = computed(() => [
  {
    key: isUnread.value ? 'mark_as_read' : 'mark_as_unread',
    icon: isUnread.value ? 'mail' : 'mail-unread',
    label: t(`INBOX.MENU_ITEM.MARK_AS_${isUnread.value ? 'READ' : 'UNREAD'}`),
  },
  { key: 'delete', icon: 'delete', label: t('INBOX.MENU_ITEM.DELETE') },
]);

const contextMenuActions = {
  close: () => {
    isContextMenuOpen.value = false;
    contextMenuPosition.value = { x: null, y: null };
    emit('contextMenuClose');
  },
  open: e => {
    e.preventDefault();
    contextMenuPosition.value = {
      x: e.pageX || e.clientX,
      y: e.pageY || e.clientY,
    };
    isContextMenuOpen.value = true;
    emit('contextMenuOpen');
  },
  handle: key => {
    const actions = {
      mark_as_read: () => emit('markNotificationAsRead', props.inboxItem),
      mark_as_unread: () => emit('markNotificationAsUnRead', props.inboxItem),
      delete: () => emit('deleteNotification', props.inboxItem),
    };
    actions[key]?.();
  },
};

onBeforeMount(contextMenuActions.close);
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
    @contextmenu="contextMenuActions.open($event)"
    @click="emit('click')"
  >
    <!-- Select + Star + Avatar -->
    <div class="flex items-center gap-3 shrink-0">
      <button
        type="button"
        class="size-[18px] p-0 rounded-full border flex items-center justify-center transition-colors shrink-0"
        :class="
          isSelected
            ? 'bg-primary border-primary text-primary-foreground opacity-100'
            : 'border-input opacity-0 group-hover:opacity-100 bg-background hover:border-primary/50'
        "
        :aria-label="t('INBOX.LIST.SELECT_CONVERSATION')"
        :aria-pressed="isSelected"
        @click.stop="emit('toggleSelect', inboxItem)"
      >
        <span v-if="isSelected" class="i-lucide-check size-3" />
      </button>
      <button
        type="button"
        class="flex items-center justify-center"
        :aria-label="t('INBOX.VIEWS.STARRED')"
        @click.stop="emit('toggleStar', inboxItem)"
      >
        <span
          v-if="isStarred"
          class="size-4 cursor-pointer i-ri-star-fill text-[#b6872d] opacity-100"
        />
        <span
          v-else
          class="size-4 cursor-pointer i-lucide-star text-muted-foreground opacity-30 group-hover:opacity-100 transition-opacity hover:text-[#b6872d]"
        />
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
        class="shrink-0 flex items-center justify-center size-3.5 rounded-full bg-primary/10 text-primary"
      >
        <span :class="channelIcon" class="size-2.5" />
      </span>
      <span
        v-if="contactStatus === 'online'"
        class="size-1.5 rounded-full bg-primary shrink-0 ml-0.5"
      />
    </div>

    <!-- Subject & Snippet -->
    <div class="flex-1 min-w-0 truncate text-[14px]">
      <span
        class="text-foreground pr-1"
        :class="isUnread ? 'font-bold' : 'font-medium'"
      >
        {{ subject }}
      </span>
      <span
        v-if="snippetWithSeparator"
        class="text-muted-foreground hidden sm:inline"
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

    <InboxContextMenu
      v-if="isContextMenuOpen"
      :context-menu-position="contextMenuPosition"
      :menu-items="menuItems"
      @close="contextMenuActions.close"
      @select-action="contextMenuActions.handle"
    />
  </div>
</template>
