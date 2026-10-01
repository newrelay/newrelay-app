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
    <div class="px-6 pt-6 shrink-0">
      <h1 class="text-base font-medium tracking-tight text-foreground mb-1">
        {{ $t('REPORT.REPORTS_TITLE') }}
      </h1>
      <p class="text-[14px] text-muted-foreground mb-4">
        {{ $t('REPORT.REPORTS_SUBTITLE') }}
      </p>
      <div
        class="flex items-center gap-6 border-b border-border/60 text-[14px]"
      >
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="{ name: tab.routeName }"
          class="relative -mb-px whitespace-nowrap pb-3 font-medium transition-colors"
          :class="
            isTabActive(tab)
              ? 'text-foreground'
              : 'text-muted-foreground hover:text-foreground'
          "
        >
          {{ $t(tab.labelKey) }}
          <span
            v-if="isTabActive(tab)"
            class="absolute inset-x-0 bottom-0 z-10 h-px bg-primary"
            aria-hidden="true"
          />
        </router-link>
      </div>
    </div>
    <div class="flex-1 overflow-auto">
      <div class="px-6 pt-6 pb-12">
        <router-view />
      </div>
    </div>
  </div>
</template>
