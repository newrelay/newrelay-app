<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    required: true,
  },
  isComingSoon: {
    type: Boolean,
    default: false,
  },
  isBeta: {
    type: Boolean,
    default: false,
  },
  hasVoiceBadge: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
</script>

<template>
  <button
    type="button"
    class="group relative flex flex-col items-start rounded-[20px] border border-border/60 bg-background p-6 text-left transition-all duration-200"
    :class="{
      'hover:border-border hover:shadow-md enabled:cursor-pointer disabled:cursor-not-allowed disabled:opacity-60':
        !isComingSoon,
      'cursor-not-allowed disabled:opacity-80': isComingSoon,
    }"
  >
    <div class="relative mb-5">
      <div
        class="flex size-11 items-center justify-center rounded-[12px] border border-border/40 bg-card shadow-xs transition-transform group-hover:scale-105"
      >
        <Icon
          :icon="icon"
          class="size-5 text-muted-foreground transition-colors group-hover:text-primary"
        />
      </div>
      <div
        v-if="hasVoiceBadge"
        class="absolute -top-1 flex size-4 items-center justify-center rounded-full border-2 border-background bg-muted ltr:-right-1 rtl:-left-1"
      >
        <Icon
          icon="i-lucide-audio-lines"
          class="size-2.5 text-muted-foreground"
        />
      </div>
    </div>

    <div class="mb-1.5 flex w-full items-center gap-2">
      <h3 class="text-[15px] font-semibold capitalize text-foreground">
        {{ title }}
      </h3>
      <span
        v-if="isBeta && !isComingSoon"
        v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
        class="ml-auto rounded px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wider bg-primary/10 text-primary"
      >
        {{ t('GENERAL.BETA') }}
      </span>
    </div>
    <p class="text-[13px] leading-relaxed text-muted-foreground">
      {{ description }}
    </p>

    <div
      v-if="isComingSoon"
      class="absolute inset-0 flex cursor-not-allowed items-center justify-center rounded-[20px] bg-gradient-to-br from-background/90 via-background/70 to-background/95 backdrop-blur-[2px]"
    >
      <span class="text-sm font-medium text-foreground">
        {{ t('CHANNEL_SELECTOR.COMING_SOON') }}
      </span>
    </div>
  </button>
</template>
