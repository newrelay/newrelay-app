<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import {
  RelayButton,
  RelayActionDropdown,
} from 'dashboard/components-next/relay';
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
      <h3 class="capitalize truncate text-[15px] font-medium text-foreground">
        {{ inboxName }}
      </h3>
    </div>

    <Policy :permissions="['administrator']" class="relative shrink-0">
      <RelayActionDropdown
        :menu-items="menuItems"
        align="end"
        @action="handleAction($event)"
      >
        <template #trigger>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:bg-muted hover:text-foreground"
          >
            <span class="i-lucide-ellipsis-vertical size-4" />
          </RelayButton>
        </template>
      </RelayActionDropdown>
    </Policy>
  </div>
</template>
