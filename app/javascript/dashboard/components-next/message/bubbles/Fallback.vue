<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import FormattedContent from './Text/FormattedContent.vue';
import { useMessageContext } from '../provider.js';

const { attachments, content } = useMessageContext();

const attachment = computed(() => attachments.value?.[0] || {});
const url = computed(
  () => attachment.value.dataUrl || attachment.value.data_url
);
const title = computed(
  () =>
    attachment.value.fallbackTitle ||
    attachment.value.fallback_title ||
    url.value
);
</script>

<template>
  <BaseBubble
    class="min-w-[280px] overflow-hidden !rounded-xl !border !border-border !bg-card !p-3 !text-foreground shadow-xs"
    data-bubble-name="fallback"
  >
    <FormattedContent v-if="content" :content="content" class="mb-2" />
    <a
      v-if="url"
      :href="url"
      target="_blank"
      rel="noopener noreferrer"
      class="flex min-w-0 items-center gap-4 text-inherit no-underline"
    >
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
      >
        <span class="i-lucide-link size-5" />
      </div>
      <span class="truncate text-sm font-semibold text-foreground">
        {{ title }}
      </span>
    </a>
    <span v-else class="text-sm text-muted-foreground">
      {{ title }}
    </span>
  </BaseBubble>
</template>
