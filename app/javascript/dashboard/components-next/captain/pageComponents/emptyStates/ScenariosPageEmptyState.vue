<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useBranding } from 'shared/composables/useBranding';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['click', 'loadExample']);

const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const emptySubtitle = computed(() =>
  replaceInstallationName(
    t('CAPTAIN.ASSISTANTS.SCENARIOS.EMPTY_STATE.SUBTITLE')
  )
);

const mockScenarios = [
  {
    title: 'Refund Request Policy',
    description:
      'Guide for handling customer refund requests and eligibility verification.',
    instruction:
      'If a customer requests a refund within 30 days, verify their invoice details and guide them through the self-service refund portal.',
    opacity: 'opacity-40',
  },
  {
    title: 'Technical Escalation',
    description: 'Steps for escalating critical technical bugs to engineering.',
    instruction:
      'When encountering a critical system error, collect browser logs, assign priority label "urgent", and handoff to human support team.',
    opacity: 'opacity-30',
  },
];

const onClick = () => {
  emit('click');
};

const onLoadExample = () => {
  emit('loadExample');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('CAPTAIN.ASSISTANTS.SCENARIOS.EMPTY_STATE.TITLE')"
    :subtitle="emptySubtitle"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div
        v-for="(scenario, index) in mockScenarios"
        :key="`mock-scenario-${index}`"
        class="flex items-start gap-4 rounded-xl border border-border/50 bg-card/40 p-5"
        :class="scenario.opacity"
      >
        <div class="mt-1 size-4 shrink-0 rounded border border-border/50" />
        <div class="min-w-0 flex-1 text-left">
          <h3 class="mb-1 text-[15px] font-medium text-foreground">
            {{ scenario.title }}
          </h3>
          <p class="mb-3 text-[13.5px] text-muted-foreground">
            {{ scenario.description }}
          </p>
          <div
            class="line-clamp-2 rounded-lg border border-border/40 bg-background/40 p-3 text-[13px] text-muted-foreground/80"
          >
            {{ scenario.instruction }}
          </div>
        </div>
      </div>
    </template>
    <template #actions>
      <div class="flex flex-wrap items-center justify-center gap-3">
        <RelayButton
          class="h-9 border-0 px-5 font-medium shadow-sm"
          @click="onClick"
        >
          <span class="i-lucide-plus mr-1.5 size-4" />
          {{ $t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.CREATE') }}
        </RelayButton>
        <RelayButton
          variant="outline"
          class="h-9 border-border/80 bg-background px-4 text-[13px] hover:bg-accent"
          @click="onLoadExample"
        >
          {{ $t('CAPTAIN.ASSISTANTS.SCENARIOS.EMPTY_STATE.LOAD_EXAMPLE') }}
        </RelayButton>
      </div>
    </template>
  </EmptyStateLayout>
</template>
