<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { formatInstallationDisplayName } from 'shared/helpers/installationNameHelper';

const store = useStore();
const { t } = useI18n();

const globalConfig = computed(() => store.getters['globalConfig/get']);

const displayName = computed(() =>
  formatInstallationDisplayName(globalConfig.value.installationName)
);

const installationInitial = computed(() =>
  displayName.value.charAt(0).toUpperCase()
);

const features = computed(() => [
  {
    icon: 'i-lucide-message-circle',
    title: t('LOGIN.MARKETING.FEATURES.OMNICHANNEL.TITLE'),
    description: t('LOGIN.MARKETING.FEATURES.OMNICHANNEL.DESCRIPTION'),
  },
  {
    icon: 'i-lucide-zap',
    title: t('LOGIN.MARKETING.FEATURES.AUTOMATION.TITLE'),
    description: t('LOGIN.MARKETING.FEATURES.AUTOMATION.DESCRIPTION'),
  },
  {
    icon: 'i-lucide-bar-chart-3',
    title: t('LOGIN.MARKETING.FEATURES.ANALYTICS.TITLE'),
    description: t('LOGIN.MARKETING.FEATURES.ANALYTICS.DESCRIPTION'),
  },
]);
</script>

<template>
  <div
    class="w-full md:w-[45%] bg-gradient-to-br from-auth-marketing-from via-auth-marketing-via to-auth-marketing-to p-10 flex flex-col relative overflow-hidden"
  >
    <div
      class="absolute top-0 right-0 w-[300px] h-[300px] bg-primary/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none"
    />

    <div class="flex items-center gap-2 mb-10 relative z-10">
      <div
        class="size-8 rounded-lg bg-primary text-primary-foreground flex items-center justify-center font-bold text-lg"
      >
        {{ installationInitial }}
      </div>
      <span class="text-xl font-bold text-foreground">{{ displayName }}</span>
    </div>

    <h1
      class="text-[28px] font-bold text-foreground leading-[1.2] mb-4 relative z-10 pr-4"
    >
      {{ t('LOGIN.MARKETING.HEADLINE_START') }}
      <span class="text-primary">{{
        t('LOGIN.MARKETING.HEADLINE_HIGHLIGHT')
      }}</span>
    </h1>

    <p class="text-[14px] text-muted-foreground mb-10 relative z-10 pr-8">
      {{ t('LOGIN.MARKETING.SUBTITLE') }}
    </p>

    <div class="flex flex-col gap-6 relative z-10">
      <div
        v-for="feature in features"
        :key="feature.icon"
        class="flex items-start gap-4"
      >
        <div
          class="size-10 rounded-[10px] bg-primary/10 flex items-center justify-center shrink-0"
        >
          <span :class="feature.icon" class="size-5 text-primary" />
        </div>
        <div>
          <h3 class="text-[14px] font-semibold text-foreground mb-0.5">
            {{ feature.title }}
          </h3>
          <p class="text-[13px] text-muted-foreground leading-relaxed">
            {{ feature.description }}
          </p>
        </div>
      </div>
    </div>

    <!-- Glassmorphic floating graphic -->
    <div
      class="absolute -bottom-24 left-4 sm:left-10 w-[280px] h-[220px] bg-auth-mock-panel/40 backdrop-blur-md border border-auth-mock-border/60 rounded-3xl shadow-xl p-4 flex flex-col gap-3 -rotate-2 transform-gpu"
    >
      <div
        class="w-24 h-12 bg-primary/80 rounded-2xl rounded-bl-sm self-end shadow-lg flex items-center justify-center gap-1.5 backdrop-blur-sm -mt-6 mr-4 relative z-20"
      >
        <div class="size-1.5 rounded-full bg-white/80 animate-pulse" />
        <div class="size-1.5 rounded-full bg-white/80 animate-pulse delay-75" />
        <div
          class="size-1.5 rounded-full bg-white/80 animate-pulse delay-150"
        />
      </div>
      <div class="flex items-center gap-3 bg-auth-mock-row/60 p-2 rounded-xl">
        <div class="size-8 rounded-full bg-auth-mock-avatar-blue/20" />
        <div class="flex-1 flex flex-col gap-1.5">
          <div class="h-2 w-3/4 bg-auth-mock-skeleton rounded-full" />
          <div class="h-2 w-1/2 bg-auth-mock-skeleton rounded-full" />
        </div>
      </div>
      <div class="flex items-center gap-3 bg-auth-mock-row/60 p-2 rounded-xl">
        <div class="size-8 rounded-full bg-auth-mock-avatar-purple/20" />
        <div class="flex-1 flex flex-col gap-1.5">
          <div class="h-2 w-2/3 bg-auth-mock-skeleton rounded-full" />
          <div class="h-2 w-1/3 bg-auth-mock-skeleton rounded-full" />
        </div>
      </div>
      <div
        class="absolute bottom-6 -right-12 w-[160px] h-[90px] bg-auth-mock-panel/90 rounded-xl shadow-lg border border-auth-mock-border/50 p-3 z-30 flex items-center justify-center"
      >
        <svg
          viewBox="0 0 100 40"
          class="w-full h-full text-auth-mock-chart"
          fill="none"
          stroke="currentColor"
          stroke-width="3"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M5 30 Q 20 10 35 25 T 65 15 T 95 5" />
        </svg>
        <div class="absolute top-2 left-2 flex gap-1">
          <div class="size-1.5 rounded-full bg-auth-mock-skeleton" />
          <div class="size-1.5 rounded-full bg-auth-mock-skeleton" />
        </div>
      </div>
    </div>
  </div>
</template>
