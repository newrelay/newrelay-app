<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
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
  'upload',
  'avatarDelete',
]);

const { t } = useI18n();
const route = useRoute();
const { checkPermissions } = usePolicy();

const avatarPreviewUrl = ref('');

watch(
  () => props.contact?.id,
  () => {
    avatarPreviewUrl.value = '';
  }
);

const avatarSrc = computed(
  () => avatarPreviewUrl.value || props.contact?.thumbnail || ''
);

const attrs = computed(() => props.contact?.additionalAttributes || {});

const role = computed(() => attrs.value.description?.trim() || '');
// Prefer the real linked Company record; fall back to the legacy free-text
// attribute for contacts that only have a typed-in company name.
const companyName = computed(
  () => props.contact?.company?.name || attrs.value.companyName?.trim() || ''
);

const companyRoute = computed(() => {
  const id = props.contact?.companyId;
  if (!id) return null;
  return {
    name: 'companies_dashboard_show',
    params: {
      accountId: route.params.accountId,
      companyId: id,
    },
  };
});

const lastActiveLabel = computed(() => {
  if (!props.contact?.lastActivityAt) return '';
  return t('CONTACTS_LAYOUT.DETAILS.LAST_ACTIVITY', {
    date: dynamicTime(props.contact.lastActivityAt),
  });
});

const hasMetaLine = computed(() =>
  Boolean(role.value || companyName.value || lastActiveLabel.value)
);

const isBlocked = computed(() => Boolean(props.contact?.blocked));

const callPhoneNumbers = computed(() => {
  const extras =
    props.contact?.additionalAttributes?.phoneNumbers ||
    props.contact?.additionalAttributes?.phone_numbers ||
    [];
  return [
    ...new Set(
      [props.contact?.phoneNumber, ...extras]
        .map(n => String(n || '').trim())
        .filter(Boolean)
    ),
  ];
});

const moreMenuItems = computed(() => {
  const items = [
    {
      label: t('CONTACTS_LAYOUT.DETAIL.ACTIONS.CALL'),
      action: 'call',
      value: 'call',
      icon: 'i-lucide-phone',
      disabled: !callPhoneNumbers.value.length,
    },
    {
      label: isBlocked.value
        ? t('CONTACTS_LAYOUT.HEADER.UNBLOCK_CONTACT')
        : t('CONTACTS_LAYOUT.HEADER.BLOCK_CONTACT'),
      action: 'block',
      value: 'block',
      icon: isBlocked.value ? 'i-lucide-lock-open' : 'i-lucide-ban',
      destructive: true,
    },
  ];
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

const callContact = phone => {
  if (!phone) return;
  window.open(`tel:${phone}`, '_self');
};

const handleMoreAction = ({ action }) => {
  if (action === 'call') callContact(callPhoneNumbers.value[0]);
  if (action === 'block') emit('block', isBlocked.value);
  if (action === 'delete') emit('delete');
};

const handleAvatarUpload = payload => {
  avatarPreviewUrl.value = payload.url;
  emit('upload', payload);
};

const handleAvatarDelete = () => {
  avatarPreviewUrl.value = '';
  emit('avatarDelete');
};
</script>

<template>
  <header
    class="flex shrink-0 flex-col gap-3 border-b border-border/40 bg-card px-6 py-4 lg:flex-row lg:items-center lg:justify-between"
  >
    <div class="flex min-w-0 items-center gap-4">
      <RelayButton
        variant="ghost"
        size="icon"
        class="-ml-2 size-9 text-muted-foreground hover:bg-muted/50 hover:text-foreground"
        :aria-label="t('CONTACTS_LAYOUT.DETAIL.BACK')"
        @click="emit('back')"
      >
        <span class="i-lucide-chevron-left size-5" />
      </RelayButton>

      <div class="flex min-w-0 items-center gap-3">
        <span class="inline-flex shrink-0 rounded-full">
          <Avatar
            :src="avatarSrc"
            :name="contact?.name || ''"
            :size="40"
            rounded-full
            allow-upload
            @upload="handleAvatarUpload"
            @delete="handleAvatarDelete"
          />
        </span>
        <div class="min-w-0">
          <h1 class="truncate text-base font-semibold text-foreground">
            {{ contact?.name || t('CONTACTS_LAYOUT.CARD.UNNAMED_CONTACT') }}
          </h1>
          <p v-if="hasMetaLine" class="truncate text-xs text-muted-foreground">
            <template v-if="role && companyName">
              {{ role }} {{ t('CONTACTS_LAYOUT.DETAIL.AT') }}
              <router-link
                v-if="companyRoute"
                :to="companyRoute"
                class="font-medium text-primary transition-colors hover:underline"
              >
                {{ companyName }}
              </router-link>
              <span v-else>{{ companyName }}</span>
            </template>
            <template v-else-if="companyName || role">
              <router-link
                v-if="companyName && companyRoute"
                :to="companyRoute"
                class="font-medium text-primary transition-colors hover:underline"
              >
                {{ companyName }}
              </router-link>
              <span v-else>{{ companyName || role }}</span>
            </template>
            <span
              v-if="(role || companyName) && lastActiveLabel"
              class="mx-1.5 text-muted-foreground/50"
            >
              •
            </span>
            {{ lastActiveLabel }}
          </p>
        </div>
      </div>
    </div>

    <div class="flex flex-wrap items-center gap-2 lg:shrink-0 lg:flex-nowrap">
      <RelayButton
        variant="outline"
        class="h-9 rounded-lg px-4 text-sm font-medium shadow-sm"
        @click="emit('scheduleMeeting')"
      >
        <span class="i-lucide-calendar size-4" />
        {{ t('CONTACTS_LAYOUT.DETAIL.ACTIONS.SCHEDULE_MEETING') }}
      </RelayButton>
      <RelayButton
        variant="outline"
        class="h-9 rounded-lg px-4 text-sm font-medium shadow-sm"
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
        content-class="min-w-48"
        @action="handleMoreAction"
      >
        <template #trigger>
          <RelayButton
            variant="outline"
            size="icon"
            class="size-9 rounded-lg text-muted-foreground shadow-sm hover:text-foreground"
            :aria-label="t('CONVERSATION.HEADER.MORE_ACTIONS')"
          >
            <span class="i-lucide-ellipsis size-4" />
          </RelayButton>
        </template>
      </RelayActionDropdown>
    </div>
  </header>
</template>
