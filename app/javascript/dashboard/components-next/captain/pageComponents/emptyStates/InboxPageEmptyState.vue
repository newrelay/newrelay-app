<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['click']);

const mockInboxes = [
  { name: 'Email Support (support@company.com)', icon: 'i-lucide-mail' },
  { name: 'Website Chat', icon: 'i-lucide-message-square' },
  { name: 'Facebook Support', icon: 'i-lucide-message-square' },
  { name: 'SMS Service (MGxxxxxx)', icon: 'i-lucide-phone' },
];

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('CAPTAIN.INBOXES.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.INBOXES.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div
        v-for="(inbox, index) in mockInboxes"
        :key="`mock-inbox-${index}`"
        class="flex items-center justify-between rounded-xl border border-border bg-card p-4 opacity-20"
      >
        <div class="flex items-center gap-3">
          <span class="size-4 text-muted-foreground" :class="[inbox.icon]" />
          <span class="text-[14px] font-medium text-foreground">
            {{ inbox.name }}
          </span>
        </div>
        <span class="i-lucide-ellipsis-vertical size-4 text-muted-foreground" />
      </div>
    </template>
    <template #actions>
      <RelayButton
        size="lg"
        class="shadow-md transition-all hover:shadow-lg"
        @click="onClick"
      >
        <span class="i-lucide-plus mr-1.5 size-4" />
        {{ $t('CAPTAIN.INBOXES.ADD_NEW') }}
      </RelayButton>
    </template>
  </EmptyStateLayout>
</template>
