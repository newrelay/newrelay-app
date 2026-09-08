<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useMessageContext } from '../provider.js';

const { content, createdAt } = useMessageContext();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);
</script>

<template>
  <RelayTooltip :content="readableTime" side="top">
    <div class="relative flex w-full items-center justify-center">
      <div class="absolute inset-0 flex items-center">
        <div class="w-full border-t border-border" />
      </div>
      <span
        v-dompurify-html="content"
        :title="content"
        class="relative max-w-[90%] bg-muted/10 px-4 text-center text-sm font-medium text-muted-foreground dark:bg-background"
      />
    </div>
  </RelayTooltip>
</template>
