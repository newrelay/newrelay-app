<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import {
  RelayButton,
  RelayActionDropdown,
} from 'dashboard/components-next/relay';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
  contactId: {
    type: [String, Number],
    default: null,
  },
});

const emit = defineEmits([
  'back',
  'scheduleMeeting',
  'logActivity',
  'block',
  'delete',
]);

const { t } = useI18n();
const { checkPermissions } = usePolicy();

const attrs = computed(() => props.contact?.additionalAttributes || {});

const subtitle = computed(() => {
  const role = attrs.value.description?.trim();
  const company = attrs.value.companyName?.trim();
  if (role && company) return `${role} at ${company}`;
  if (company) return company;
  if (role) return role;
  return '';
});

const lastActiveLabel = computed(() => {
  if (!props.contact?.lastActivityAt) return '';
  return t('CONTACTS_LAYOUT.DETAILS.LAST_ACTIVITY', {
    date: dynamicTime(props.contact.lastActivityAt),
  });
});

const isBlocked = computed(() => Boolean(props.contact?.blocked));

const moreMenuItems = computed(() => {
  const items = [];
  if (props.contact?.phoneNumber) {
    items.push({
      label: t('CONTACTS_LAYOUT.DETAIL.ACTIONS.CALL'),
      action: 'call',
      value: 'call',
      icon: 'i-lucide-phone',
    });
  }
  items.push({
    label: isBlocked.value
      ? t('CONTACTS_LAYOUT.HEADER.UNBLOCK_CONTACT')
      : t('CONTACTS_LAYOUT.HEADER.BLOCK_CONTACT'),
    action: 'block',
    value: 'block',
    icon: isBlocked.value ? 'i-lucide-lock-open' : 'i-lucide-ban',
    destructive: true,
  });
  if (checkPermissions(['administrator'])) {
    items.push({
      label: t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT'),
      action: 'delete',
      value: 'delete',
      icon: 'i-lucide-trash-2',
      destructive: true,
    });
  }
  return items;
});

const handleMoreAction = ({ action }) => {
  if (action === 'call' && props.contact?.phoneNumber) {
    window.open(`tel:${props.contact.phoneNumber}`, '_self');
    return;
  }
  if (action === 'block') emit('block', isBlocked.value);
  if (action === 'delete') emit('delete');
};
</script>

<template>
  <header
    class="flex shrink-0 items-center justify-between gap-4 border-b border-border/40 bg-card px-6 py-4"
  >
    <div class="flex min-w-0 items-center gap-4">
      <RelayButton
        variant="ghost"
        size="icon"
        class="-ml-2 size-9 text-muted-foreground hover:bg-muted/50 hover:text-foreground border border-border hover:border-transparent"
        :aria-label="t('CONTACTS_LAYOUT.DETAIL.BACK')"
        @click="emit('back')"
      >
        <span class="i-lucide-chevron-left size-5" />
      </RelayButton>

      <div class="flex min-w-0 items-center gap-3">
        <Avatar
          :src="contact?.thumbnail || ''"
          :name="contact?.name || ''"
          :size="40"
          rounded-full
        />
        <div class="min-w-0">
          <h1
            class="capitalize truncate text-[16px] font-[500] text-foreground"
          >
            {{ contact?.name || t('CONTACTS_LAYOUT.CARD.UNNAMED_CONTACT') }}
          </h1>
          <p class="truncate text-xs text-muted-foreground">
            <template v-if="subtitle">
              {{ subtitle }}
              <span
                v-if="lastActiveLabel"
                class="mx-1.5 text-muted-foreground/50"
                aria-hidden="true"
              >
                &bull;
              </span>
            </template>
            <span v-if="lastActiveLabel">{{ lastActiveLabel }}</span>
          </p>
        </div>
      </div>
    </div>

    <div class="flex shrink-0 items-center gap-2">
      <RelayButton
        variant="outline"
        class="hidden h-9 rounded-lg px-4 text-sm font-medium shadow-sm sm:inline-flex"
        @click="emit('scheduleMeeting')"
      >
        <span class="i-lucide-calendar size-4" />
        {{ t('CONTACTS_LAYOUT.DETAIL.ACTIONS.SCHEDULE_MEETING') }}
      </RelayButton>
      <RelayButton
        variant="outline"
        class="hidden h-9 rounded-lg px-4 text-sm font-medium shadow-sm sm:inline-flex"
        @click="emit('logActivity')"
      >
        <span class="i-lucide-activity size-4" />
        {{ t('CONTACTS_LAYOUT.DETAIL.ACTIONS.LOG_ACTIVITY') }}
      </RelayButton>

      <ComposeConversation :contact-id="String(contactId || '')">
        <template #trigger>
          <RelayButton
            class="h-9 rounded-lg px-4 text-sm font-medium shadow-sm"
          >
            <span class="i-lucide-mail size-4" />
            {{ t('CONTACTS_LAYOUT.DETAIL.ACTIONS.EMAIL') }}
          </RelayButton>
        </template>
      </ComposeConversation>

      <RelayActionDropdown
        :menu-items="moreMenuItems"
        align="end"
        content-class="w-48"
        @action="handleMoreAction"
      >
        <template #trigger>
          <RelayButton
            variant="outline"
            size="icon"
            class="size-9 rounded-lg text-muted-foreground shadow-sm hover:text-foreground"
            :aria-label="t('CONVERSATION.HEADER.MORE_ACTIONS')"
          >
            <span class="i-lucide-ellipsis-vertical size-4" />
          </RelayButton>
        </template>
      </RelayActionDropdown>
    </div>
  </header>
</template>
