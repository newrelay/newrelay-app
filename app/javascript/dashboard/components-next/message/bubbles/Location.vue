<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});

const lat = computed(() => {
  return attachment.value.coordinatesLat;
});
const long = computed(() => {
  return attachment.value.coordinatesLong;
});

const title = computed(() => {
  return attachment.value.fallbackTitle ?? attachment.value.fallback_title;
});

const mapUrl = computed(
  () => `https://maps.google.com/?q=${lat.value},${long.value}`
);
</script>

<template>
  <BaseBubble
    class="min-w-[280px] cursor-pointer overflow-hidden !rounded-xl !border !border-border !bg-card !p-3 !text-foreground shadow-xs hover:!bg-muted/50"
    data-bubble-name="location"
  >
    <a
      :href="mapUrl"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="flex min-w-0 items-center gap-4 text-inherit no-underline"
    >
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
      >
        <span class="i-lucide-map-pin size-5" />
      </div>
      <div class="flex min-w-0 flex-1 flex-col">
        <span class="truncate text-sm font-semibold text-foreground">
          {{ title || t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP') }}
        </span>
        <span class="mt-0.5 text-[13px] text-muted-foreground">
          {{ t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP') }}
        </span>
      </div>
    </a>
  </BaseBubble>
</template>
