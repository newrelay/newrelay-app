<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Policy from 'dashboard/components/policy.vue';
import { INBOX_TYPES, getInboxIconByType } from 'dashboard/helper/inbox';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  inbox: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const inboxName = computed(() => {
  const inbox = props.inbox;
  if (!inbox?.name) {
    return '';
  }

  const isTwilioChannel = inbox.channel_type === INBOX_TYPES.TWILIO;
  const isWhatsAppChannel = inbox.channel_type === INBOX_TYPES.WHATSAPP;
  const isEmailChannel = inbox.channel_type === INBOX_TYPES.EMAIL;

  if (isTwilioChannel || isWhatsAppChannel) {
    const identifier = inbox.messaging_service_sid || inbox.phone_number;
    return identifier ? `${inbox.name} (${identifier})` : inbox.name;
  }

  if (isEmailChannel && inbox.email) {
    return `${inbox.name} (${inbox.email})`;
  }

  return inbox.name;
});

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.INBOXES.OPTIONS.DISCONNECT'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const icon = computed(() => {
  const { medium, channel_type: type } = props.inbox;
  return getInboxIconByType(type, medium, 'outline');
});

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <div
    class="group flex items-center justify-between rounded-xl border border-border bg-card px-5 py-4 transition-all hover:shadow-sm"
  >
    <div class="flex min-w-0 items-center gap-3.5">
      <div
        class="flex size-9 shrink-0 items-center justify-center rounded-lg border border-border/60 bg-muted/60 text-foreground"
      >
        <span class="size-4" :class="[icon]" />
      </div>
      <h3 class="truncate text-[15px] font-medium text-foreground">
        {{ inboxName }}
      </h3>
    </div>

    <Policy
      v-on-clickaway="() => toggleDropdown(false)"
      :permissions="['administrator']"
      class="relative shrink-0"
    >
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:bg-muted hover:text-foreground"
        @click="toggleDropdown()"
      >
        <span class="i-lucide-ellipsis-vertical size-4" />
      </RelayButton>
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="menuItems"
        class="top-full mt-1 ltr:right-0 rtl:left-0"
        @action="handleAction($event)"
      />
    </Policy>
  </div>
</template>
