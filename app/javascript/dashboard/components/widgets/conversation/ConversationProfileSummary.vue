<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'next/avatar/Avatar.vue';

const props = defineProps({
  chat: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const route = useRoute();
const { t } = useI18n();
const accountLabels = useMapGetter('labels/getLabels');

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta?.sender?.id)
);

const contactProfileLink = computed(() => {
  const contactId = currentContact.value?.id;
  if (!contactId) return null;
  return `/app/accounts/${route.params.accountId}/contacts/${contactId}`;
});

const customerSince = computed(() => {
  const createdAt = currentContact.value?.created_at;
  if (!createdAt) return '';
  const date = new Date(createdAt * 1000);
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
});

const customerSinceLabel = computed(() => {
  if (!customerSince.value) return '';
  return t('CONVERSATION.HEADER.CUSTOMER_SINCE', { date: customerSince.value });
});

const primaryLabel = computed(() => {
  const titles = props.chat.labels || [];
  if (!titles.length) return null;
  return (
    accountLabels.value.find(label => label.title === titles[0]) || {
      title: titles[0],
      color: null,
    }
  );
});

const statusBadge = computed(() => {
  if (primaryLabel.value) {
    return { text: primaryLabel.value.title, variant: 'label' };
  }
  const status = props.chat.status;
  if (status === 'pending') {
    return {
      text: t('CHAT_LIST.STATUS_TABS.IN_PROGRESS'),
      variant: 'secondary',
    };
  }
  if (status === 'snoozed') {
    return { text: t('CHAT_LIST.STATUS_TABS.ON_HOLD'), variant: 'warning' };
  }
  if (props.chat.priority === 'urgent' || props.chat.priority === 'high') {
    return {
      text: t(
        `CONVERSATION.PRIORITY.OPTIONS.${props.chat.priority.toUpperCase()}`
      ),
      variant: 'default',
    };
  }
  return null;
});

const badgeBaseClass =
  'inline-flex h-5 shrink-0 items-center rounded-sm border px-1.5 py-0 text-[10px] font-medium transition-colors focus:outline-hidden focus:ring-1 focus:ring-ring';

const badgeClass = computed(() => {
  const variant = statusBadge.value?.variant;
  if (variant === 'secondary') {
    return 'bg-primary/10 text-primary border-primary/20';
  }
  if (variant === 'warning') {
    return 'bg-background text-foreground border-border';
  }
  return 'bg-primary text-primary-foreground border-transparent';
});

const scoreValue = computed(() => props.chat.id);
</script>

<template>
  <div class="flex min-w-0 items-center gap-3">
    <Avatar
      :name="currentContact.name"
      :src="currentContact.thumbnail"
      :size="40"
      :status="currentContact.availability_status"
      hide-offline-status
      rounded-full
      class="size-10 shrink-0 rounded-full border border-border/50 object-cover"
    />
    <div class="flex min-w-0 flex-col">
      <div class="flex min-w-0 items-center gap-2">
        <a
          v-if="contactProfileLink"
          :href="contactProfileLink"
          class="cursor-pointer truncate font-semibold text-base text-foreground transition-colors hover:text-primary"
        >
          {{ currentContact.name }}
        </a>
        <span v-else class="truncate font-semibold text-base text-foreground">
          {{ currentContact.name }}
        </span>
        <span v-if="statusBadge" :class="[badgeBaseClass, badgeClass]">
          {{ statusBadge.text }}
        </span>
        <span
          v-if="scoreValue"
          class="flex shrink-0 items-center gap-1 text-[11px] font-medium text-success"
        >
          <span class="size-1.5 rounded-full bg-success" />
          {{ scoreValue }}
        </span>
      </div>
      <div
        v-if="customerSinceLabel"
        class="mt-0.5 flex items-center gap-2 text-[13px] text-muted-foreground"
      >
        <span class="truncate">{{ customerSinceLabel }}</span>
      </div>
    </div>
  </div>
</template>
