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
    <div
      class="flex w-full justify-center px-4 py-0.5"
      data-bubble-name="activity"
    >
      <span
        v-dompurify-html="content"
        class="max-w-full text-center text-[13px] font-normal leading-5 text-muted-foreground [&_a]:inline [&_a]:font-medium [&_a]:text-muted-foreground [&_b]:inline [&_b]:font-medium [&_p]:m-0 [&_p]:inline [&_strong]:inline [&_strong]:font-medium"
      />
    </div>
  </RelayTooltip>
</template>
