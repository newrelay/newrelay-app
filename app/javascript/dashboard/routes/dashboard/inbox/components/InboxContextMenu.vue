<script setup>
import { useI18n } from 'vue-i18n';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import {
  DROPDOWN_MENU_CONTENT_CLASS,
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  DROPDOWN_MENU_ITEM_CLASS,
  DROPDOWN_MENU_ITEM_DESTRUCTIVE_CLASS,
  DROPDOWN_MENU_SEPARATOR_CLASS,
} from 'dashboard/components-next/relay';

defineProps({
  x: { type: Number, default: 0 },
  y: { type: Number, default: 0 },
  isUnread: { type: Boolean, default: false },
});

const emit = defineEmits([
  'close',
  'markAsUnread',
  'markAsRead',
  'resolve',
  'pending',
  'snooze',
  'delete',
]);

const { t } = useI18n();

const itemClass = [
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  DROPDOWN_MENU_ITEM_CLASS,
  'p-0 !px-2 !py-1.5 text-left',
].join(' ');

const destructiveClass = [
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  DROPDOWN_MENU_ITEM_DESTRUCTIVE_CLASS,
  'p-0 !px-2 !py-1.5 text-left',
].join(' ');
</script>

<template>
  <ContextMenu :x="x" :y="y" @close="emit('close')">
    <div class="min-w-56" :class="[DROPDOWN_MENU_CONTENT_CLASS]">
      <button
        v-if="isUnread"
        type="button"
        :class="itemClass"
        @click.stop="emit('markAsRead')"
      >
        <span class="i-lucide-mail size-4 shrink-0 text-muted-foreground" />
        {{ t('CONVERSATION.CARD_CONTEXT_MENU.MARK_AS_READ') }}
      </button>
      <button
        v-else
        type="button"
        :class="itemClass"
        @click.stop="emit('markAsUnread')"
      >
        <span class="i-lucide-mail size-4 shrink-0 text-muted-foreground" />
        {{ t('CONVERSATION.CARD_CONTEXT_MENU.MARK_AS_UNREAD') }}
      </button>
      <button type="button" :class="itemClass" @click.stop="emit('resolve')">
        <span class="i-lucide-check size-4 shrink-0 text-muted-foreground" />
        {{ t('CONVERSATION.CARD_CONTEXT_MENU.RESOLVED') }}
      </button>
      <button type="button" :class="itemClass" @click.stop="emit('pending')">
        <span
          class="i-lucide-hourglass size-4 shrink-0 text-muted-foreground"
        />
        {{ t('CONVERSATION.CARD_CONTEXT_MENU.PENDING') }}
      </button>
      <button type="button" :class="itemClass" @click.stop="emit('snooze')">
        <span class="i-lucide-clock size-4 shrink-0 text-muted-foreground" />
        {{ t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TITLE') }}
      </button>

      <div :class="DROPDOWN_MENU_SEPARATOR_CLASS" />

      <button
        type="button"
        :class="destructiveClass"
        @click.stop="emit('delete')"
      >
        <span class="i-lucide-trash-2 size-4 shrink-0" />
        {{ t('CONVERSATION.CARD_CONTEXT_MENU.DELETE') }}
      </button>
    </div>
  </ContextMenu>
</template>
