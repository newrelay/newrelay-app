<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useMessageContext } from '../provider.js';
import {
  highlightSearchHtml,
  useConversationMessageSearch,
} from 'dashboard/composables/useConversationMessageSearch';

const { content, createdAt } = useMessageContext();
const { query } = useConversationMessageSearch();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);

const shortTime = computed(() => messageTimestamp(createdAt.value, 'h:mm a'));

const timeSuffix = computed(() =>
  shortTime.value ? `\u2022 ${shortTime.value}` : ''
);

const plainContent = computed(() =>
  String(content.value || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase()
);

const activityIcon = computed(() => {
  const text = plainContent.value;
  if (text.includes('reopen')) return 'i-lucide-rotate-ccw';
  if (text.includes('resolv')) return 'i-lucide-check-circle-2';
  if (text.includes('pending')) return 'i-lucide-hourglass';
  if (text.includes('snooze')) return 'i-lucide-clock';
  if (text.includes('assign')) return 'i-lucide-user';
  if (text.includes('label') || text.includes('tag')) return 'i-lucide-tag';
  if (text.includes('archiv')) return 'i-lucide-archive';
  if (text.includes('block') || text.includes('ban')) return 'i-lucide-ban';
  return 'i-lucide-info';
});

const highlightedContent = computed(() =>
  highlightSearchHtml(content.value, query.value)
);

const activityIconClass = computed(() => {
  const text = plainContent.value;
  if (text.includes('reopen')) return 'text-primary';
  if (text.includes('resolv')) return 'text-success';
  if (text.includes('pending') || text.includes('snooze'))
    return 'text-warning';
  if (text.includes('block') || text.includes('ban')) return 'text-destructive';
  if (text.includes('assign') || text.includes('label') || text.includes('tag'))
    return 'text-primary';
  return 'text-primary';
});
</script>

<template>
  <RelayTooltip :content="readableTime" side="top">
    <div
      class="my-1 flex w-full items-center justify-center"
      data-bubble-name="activity"
    >
      <div
        class="inline-flex max-w-full items-center gap-1.5 rounded-full border border-border/70 bg-muted/60 px-3 py-1 text-[11.5px] font-medium text-muted-foreground shadow-2xs backdrop-blur-xs dark:bg-card"
      >
        <span
          class="size-3.5 shrink-0"
          :class="[activityIcon, activityIconClass]"
        />
        <span
          v-dompurify-html="highlightedContent"
          class="min-w-0 truncate [&_a]:inline [&_a]:font-medium [&_a]:text-muted-foreground [&_b]:inline [&_b]:font-medium [&_p]:m-0 [&_p]:inline [&_strong]:inline [&_strong]:font-medium"
        />
        <span
          v-if="shortTime"
          class="ml-0.5 shrink-0 text-[10.5px] text-muted-foreground/60"
        >
          {{ timeSuffix }}
        </span>
      </div>
    </div>
  </RelayTooltip>
</template>
