<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { RelayTooltip } from 'dashboard/components-next/relay';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import wootConstants from 'dashboard/constants/globals';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  isOnExpandedLayout: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(['changeFilter']);

const store = useStore();
const { t } = useI18n();

const { updateUISettings } = useUISettings();

const chatStatusFilter = useMapGetter('getChatStatusFilter');
const chatSortFilter = useMapGetter('getChatSortFilter');

const triggerRef = ref(null);
const dropdownRef = ref(null);
const [showActionsDropdown, toggleDropdown] = useToggle();

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  showActionsDropdown,
  { align: props.isOnExpandedLayout ? 'end' : 'start' }
);

const openDropdown = async () => {
  toggleDropdown();
  await nextTick();
  updatePosition();
};

const currentStatusFilter = computed(() => {
  return chatStatusFilter.value || wootConstants.STATUS_TYPE.OPEN;
});

const currentSortBy = computed(() => {
  return (
    chatSortFilter.value || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC
  );
});

const chatStatusOptions = computed(() => [
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT'),
    value: 'open',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved.TEXT'),
    value: 'resolved',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending.TEXT'),
    value: 'pending',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed.TEXT'),
    value: 'snoozed',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.all.TEXT'),
    value: 'all',
  },
]);

const chatSortOptions = computed(() => [
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.last_activity_at_asc.TEXT'),
    value: 'last_activity_at_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.last_activity_at_desc.TEXT'),
    value: 'last_activity_at_desc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.created_at_desc.TEXT'),
    value: 'created_at_desc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.created_at_asc.TEXT'),
    value: 'created_at_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_desc.TEXT'),
    value: 'priority_desc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_asc.TEXT'),
    value: 'priority_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_desc_created_at_asc.TEXT'),
    value: 'priority_desc_created_at_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.waiting_since_asc.TEXT'),
    value: 'waiting_since_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.waiting_since_desc.TEXT'),
    value: 'waiting_since_desc',
  },
]);

const activeChatStatusLabel = computed(
  () =>
    chatStatusOptions.value.find(m => m.value === chatStatusFilter.value)
      ?.label || ''
);

const activeChatSortLabel = computed(
  () =>
    chatSortOptions.value.find(m => m.value === chatSortFilter.value)?.label ||
    ''
);

const saveSelectedFilter = (type, value) => {
  updateUISettings({
    conversations_filter_by: {
      status: type === 'status' ? value : currentStatusFilter.value,
      order_by: type === 'sort' ? value : currentSortBy.value,
    },
  });
};

const handleStatusChange = value => {
  emit('changeFilter', value, 'status');
  store.dispatch('setChatStatusFilter', value);
  saveSelectedFilter('status', value);
};

const handleSortChange = value => {
  emit('changeFilter', value, 'sort');
  store.dispatch('setChatSortFilter', value);
  saveSelectedFilter('sort', value);
};
</script>

<template>
  <div ref="triggerRef" class="relative flex">
    <RelayTooltip :content="$t('CHAT_LIST.SORT_TOOLTIP_LABEL')" side="right">
      <NextButton
        icon="i-lucide-arrow-up-down"
        slate
        faded
        xs
        @click="openDropdown()"
      />
    </RelayTooltip>
    <TeleportWithDirection to="body">
      <div
        v-if="showActionsDropdown"
        ref="dropdownRef"
        v-on-click-outside="[
          () => toggleDropdown(false),
          { ignore: ['[data-reka-popper-content-wrapper]', '[data-slot]'] },
        ]"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="flex w-72 flex-col gap-4 rounded-xl border border-border bg-accent p-4 shadow-md backdrop-blur-[100px]"
      >
        <div class="flex items-center justify-between gap-2">
          <span class="truncate text-[13px] font-normal text-foreground">
            {{ $t('CHAT_LIST.CHAT_SORT.STATUS') }}
          </span>
          <SelectMenu
            :model-value="chatStatusFilter"
            :options="chatStatusOptions"
            :label="activeChatStatusLabel"
            :sub-menu-position="isOnExpandedLayout ? 'left' : 'right'"
            @update:model-value="handleStatusChange"
          />
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="truncate text-[13px] font-normal text-foreground">
            {{ $t('CHAT_LIST.CHAT_SORT.ORDER_BY') }}
          </span>
          <SelectMenu
            :model-value="chatSortFilter"
            :options="chatSortOptions"
            :label="activeChatSortLabel"
            :sub-menu-position="isOnExpandedLayout ? 'left' : 'right'"
            @update:model-value="handleSortChange"
          />
        </div>
      </div>
    </TeleportWithDirection>
  </div>
</template>
