<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['optionClick']);

const { t } = useI18n();

const menuItems = computed(() => [
  {
    key: 'mark_all_read',
    label: t('INBOX.MENU_ITEM.MARK_ALL_READ'),
  },
  {
    key: 'delete_all',
    label: t('INBOX.MENU_ITEM.DELETE_ALL'),
  },
  {
    key: 'delete_all_read',
    label: t('INBOX.MENU_ITEM.DELETE_ALL_READ'),
  },
]);
</script>

<template>
  <div
    class="anim-pop z-50 w-40 overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
    data-state="open"
    role="menu"
  >
    <button
      v-for="item in menuItems"
      :key="item.key"
      type="button"
      role="menuitem"
      class="flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-xs text-foreground outline-none transition-colors hover:bg-accent hover:text-accent-foreground"
      @click.stop="emit('optionClick', item.key)"
    >
      {{ item.label }}
    </button>
  </div>
</template>
