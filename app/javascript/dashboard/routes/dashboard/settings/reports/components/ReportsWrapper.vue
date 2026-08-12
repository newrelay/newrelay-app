<script setup>
import { useRoute } from 'vue-router';

const route = useRoute();

const tabs = [
  {
    labelKey: 'SIDEBAR.REPORTS_OVERVIEW',
    routeName: 'account_overview_reports',
    activeOn: [],
  },
  {
    labelKey: 'SIDEBAR.REPORTS_CONVERSATION',
    routeName: 'conversation_reports',
    activeOn: [],
  },
  {
    labelKey: 'SIDEBAR.REPORTS_AGENT',
    routeName: 'agent_reports_index',
    activeOn: ['agent_reports_show'],
  },
  {
    labelKey: 'SIDEBAR.REPORTS_LABEL',
    routeName: 'label_reports_index',
    activeOn: ['label_reports_show'],
  },
  {
    labelKey: 'SIDEBAR.REPORTS_INBOX',
    routeName: 'inbox_reports_index',
    activeOn: ['inbox_reports_show'],
  },
  {
    labelKey: 'SIDEBAR.REPORTS_TEAM',
    routeName: 'team_reports_index',
    activeOn: ['team_reports_show'],
  },
  { labelKey: 'SIDEBAR.CSAT', routeName: 'csat_reports', activeOn: [] },
  { labelKey: 'SIDEBAR.REPORTS_SLA', routeName: 'sla_reports', activeOn: [] },
  { labelKey: 'SIDEBAR.REPORTS_BOT', routeName: 'bot_reports', activeOn: [] },
];

const isTabActive = tab =>
  route.name === tab.routeName || tab.activeOn.includes(route.name);
</script>

<template>
  <div class="flex flex-col h-full w-full overflow-hidden bg-background">
    <div class="px-8 pt-6 shrink-0">
      <h1 class="text-xl font-semibold tracking-tight text-foreground mb-1">
        {{ $t('REPORT.REPORTS_TITLE') }}
      </h1>
      <p class="text-sm text-muted-foreground mb-4">
        {{ $t('REPORT.REPORTS_SUBTITLE') }}
      </p>
      <div
        class="flex items-center gap-6 text-[14px] border-b border-border/60 overflow-x-auto"
      >
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="{ name: tab.routeName }"
          class="pb-3 font-medium whitespace-nowrap border-b-2 -mb-px transition-colors"
          :class="
            isTabActive(tab)
              ? 'border-primary text-primary'
              : 'border-transparent text-muted-foreground hover:text-foreground'
          "
        >
          {{ $t(tab.labelKey) }}
        </router-link>
      </div>
    </div>
    <div class="flex-1 overflow-auto">
      <div class="px-8 pt-6 pb-12">
        <router-view />
      </div>
    </div>
  </div>
</template>
