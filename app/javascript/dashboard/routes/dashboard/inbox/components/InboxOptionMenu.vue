<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  DROPDOWN_MENU_CONTENT_CLASS,
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  getDropdownItemInteractionClass,
} from 'dashboard/components-next/relay/dropdown-menu/constants';
import { cn } from 'dashboard/components-next/relay/utils/cn';

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
    destructive: true,
  },
  {
    key: 'delete_all_read',
    label: t('INBOX.MENU_ITEM.DELETE_ALL_READ'),
    destructive: true,
  },
]);
</script>

<template>
  <div
    :class="cn(DROPDOWN_MENU_CONTENT_CLASS, 'w-40')"
    data-state="open"
    role="menu"
  >
    <button
      v-for="item in menuItems"
      :key="item.key"
      type="button"
      role="menuitem"
      :class="
        cn(DROPDOWN_MENU_ITEM_BASE_CLASS, getDropdownItemInteractionClass(item))
      "
      @click.stop="emit('optionClick', item.key)"
    >
      {{ item.label }}
    </button>
  </div>
</template>
