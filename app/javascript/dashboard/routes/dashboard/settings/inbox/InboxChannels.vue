<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useBranding } from 'shared/composables/useBranding';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { replaceInstallationName } = useBranding();

const createFlowSteps = computed(() => {
  const steps = ['CHANNEL', 'INBOX', 'AGENT', 'FINISH'];

  const routes = {
    CHANNEL: 'settings_inbox_new',
    INBOX: 'settings_inboxes_page_channel',
    AGENT: 'settings_inboxes_add_agents',
    FINISH: 'settings_inbox_finish',
  };

  return steps.map((step, index) => {
    return {
      number: index + 1,
      title: t(`INBOX_MGMT.CREATE_FLOW.${step}.TITLE`),
      body: replaceInstallationName(t(`INBOX_MGMT.CREATE_FLOW.${step}.BODY`)),
      route: routes[step],
    };
  });
});

const activeIndex = computed(() => {
  const index = createFlowSteps.value.findIndex(
    item => item.route === route.name
  );
  return index === -1 ? 0 : index;
});

const goBack = () => {
  if (activeIndex.value === 0) {
    router.push(accountScopedRoute('settings_inbox_list'));
    return;
  }
  router.back();
};
</script>

<template>
  <div
    class="flex h-[calc(100vh-8rem)] w-full flex-col overflow-hidden rounded-xl border border-border/80 bg-background shadow-xs lg:h-[calc(100vh-6rem)]"
  >
    <div
      class="flex shrink-0 items-center gap-3 border-b border-border/40 bg-card px-6 py-4"
    >
      <button
        type="button"
        class="group flex items-center text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
        @click="goBack"
      >
        <Icon
          icon="i-lucide-chevron-left"
          class="mr-1 size-4 transition-transform group-hover:-translate-x-0.5"
        />
        {{ t('GENERAL_SETTINGS.BACK') }}
      </button>
      <div class="mx-2 h-4 w-px bg-border/80" />
      <h2 class="text-base font-semibold text-foreground">
        {{ t('INBOX_MGMT.HEADER') }}
      </h2>
    </div>

    <div
      class="relative w-full shrink-0 border-b border-border/40 bg-background p-6 lg:p-8"
    >
      <div class="relative mx-auto flex max-w-4xl items-start justify-between">
        <div
          class="absolute left-[5%] right-[5%] top-4 z-0 hidden h-px bg-border/60 sm:block"
        />

        <div
          v-for="(step, index) in createFlowSteps"
          :key="step.route"
          class="relative z-10 flex flex-1 flex-col items-center gap-3"
        >
          <div
            class="relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full border text-[13px] font-medium transition-colors duration-200"
            :class="[
              index < activeIndex
                ? 'border-primary bg-primary text-primary-foreground'
                : index === activeIndex
                  ? 'border-primary bg-background text-primary'
                  : 'border-border/80 bg-background text-muted-foreground',
            ]"
          >
            <div
              v-if="index === activeIndex"
              class="absolute inset-0 rounded-full bg-primary/10"
            />
            <Icon
              v-if="index < activeIndex"
              icon="i-lucide-check"
              class="relative z-10 size-4"
            />
            <span v-else class="relative z-10">{{ step.number }}</span>
          </div>

          <div class="flex flex-col text-center">
            <h4
              class="text-[14px] font-medium transition-colors duration-200"
              :class="
                index === activeIndex
                  ? 'text-primary'
                  : index < activeIndex
                    ? 'text-foreground'
                    : 'text-muted-foreground'
              "
            >
              {{ step.title }}
            </h4>
            <p
              class="mx-auto mt-1.5 hidden max-w-[150px] text-[13px] leading-relaxed sm:block"
              :class="
                index === activeIndex ? 'text-primary' : 'text-muted-foreground'
              "
            >
              {{ step.body }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div
      class="relative mx-auto flex w-full max-w-5xl flex-1 flex-col overflow-y-auto bg-background p-6 lg:p-10"
    >
      <router-view />
    </div>
  </div>
</template>
