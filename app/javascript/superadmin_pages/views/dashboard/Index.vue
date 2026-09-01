<script setup>
/* eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text */
import { computed } from 'vue';
import LineChart from 'shared/components/charts/LineChart.vue';

const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const rawValues = computed(() =>
  (props.componentData.chartData || []).map(item => item[1])
);

const formatChartLabel = value => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const prepareData = sourceData => {
  const labels = [];
  const data = [];
  (sourceData || []).forEach(item => {
    labels.push(formatChartLabel(item[0]));
    data.push(item[1]);
  });
  return {
    labels,
    datasets: [
      {
        label: 'Conversations',
        data,
        fill: true,
        tension: 0.4,
        borderWidth: 2.2,
        pointRadius: 0,
        pointHoverRadius: 5,
        pointBorderWidth: 2,
        pointHoverBorderWidth: 2,
        backgroundColor: ctx => {
          const chart = ctx.chart;
          const { chartArea } = chart;
          const primary =
            getComputedStyle(document.documentElement)
              .getPropertyValue('--primary')
              .trim() || '#4f46e5';
          if (!chartArea) return `${primary}26`;
          const gradient = chart.ctx.createLinearGradient(
            0,
            chartArea.top,
            0,
            chartArea.bottom
          );
          gradient.addColorStop(0, `${primary}40`);
          gradient.addColorStop(1, `${primary}00`);
          return gradient;
        },
      },
    ],
  };
};

const chartData = computed(() => prepareData(props.componentData.chartData));

const totalConversations = computed(() =>
  rawValues.value.reduce((sum, v) => sum + v, 0)
);

const peakConversations = computed(() => Math.max(...rawValues.value, 0));

const avgConversations = computed(() => {
  const len = rawValues.value.length;
  return len ? Math.round(totalConversations.value / len) : 0;
});

const trendPercent = computed(() => {
  const vals = rawValues.value;
  if (vals.length < 2) return null;
  const half = Math.floor(vals.length / 2);
  const first = vals.slice(0, half).reduce((s, v) => s + v, 0);
  const second = vals.slice(half).reduce((s, v) => s + v, 0);
  if (!first) return null;
  return Math.round(((second - first) / first) * 100);
});

const { accountsCount, usersCount, inboxesCount, conversationsCount } =
  props.componentData;

const stats = [
  { label: 'Accounts', value: accountsCount, icon: 'i-lucide-building' },
  { label: 'Users', value: usersCount, icon: 'i-lucide-users' },
  { label: 'Inboxes', value: inboxesCount, icon: 'i-lucide-inbox' },
  {
    label: 'Conversations',
    value: conversationsCount,
    icon: 'i-lucide-message-square',
  },
];
</script>

<template>
  <div class="space-y-6">
    <h1 class="page-title">Admin Dashboard</h1>

    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <div v-for="stat in stats" :key="stat.label" class="stat-card">
        <div class="stat-card-inner">
          <div class="stat-card-icon-wrap">
            <svg
              v-if="stat.label === 'Accounts'"
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide lucide-building-2 text-primary"
            >
              <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z" />
              <path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2" />
              <path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2" />
              <path d="M10 6h4" />
              <path d="M10 10h4" />
              <path d="M10 14h4" />
              <path d="M10 18h4" />
            </svg>
            <svg
              v-else-if="stat.label === 'Users'"
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide lucide-users text-primary"
            >
              <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
              <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
              <path d="M16 3.13a4 4 0 0 1 0 7.75" />
            </svg>
            <svg
              v-else-if="stat.label === 'Inboxes'"
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide lucide-inbox text-primary"
            >
              <polyline points="22 12 16 12 14 15 10 15 8 12 2 12" />
              <path
                d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"
              />
            </svg>
            <svg
              v-else
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide lucide-message-square text-primary"
            >
              <path
                d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"
              />
            </svg>
          </div>
          <div class="stat-card-body">
            <div class="stat-card-val">
              {{ stat.value }}
            </div>
            <div class="stat-card-label">
              {{ stat.label }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      class="activity-card rounded-xl border border-border bg-card shadow-xs"
    >
      <div
        class="px-6 pt-5 pb-4 border-b border-border flex items-start justify-between gap-6 flex-wrap"
      >
        <div>
          <h2 class="text-base font-medium text-foreground">
            Conversation Activity
          </h2>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">
            Volume of conversations over time
          </p>
        </div>

        <div class="flex items-center gap-8">
          <div class="text-right">
            <div
              class="text-[11px] font-medium text-muted-foreground uppercase tracking-wide"
            >
              Total
            </div>
            <div
              class="text-xl font-semibold text-foreground tabular-nums mt-0.5"
            >
              {{ totalConversations.toLocaleString() }}
            </div>
          </div>
          <div class="text-right">
            <div
              class="text-[11px] font-medium text-muted-foreground uppercase tracking-wide"
            >
              Peak
            </div>
            <div
              class="text-xl font-semibold text-foreground tabular-nums mt-0.5"
            >
              {{ peakConversations.toLocaleString() }}
            </div>
          </div>
          <div class="text-right">
            <div
              class="text-[11px] font-medium text-muted-foreground uppercase tracking-wide"
            >
              Avg / period
            </div>
            <div
              class="text-xl font-semibold text-foreground tabular-nums mt-0.5"
            >
              {{ avgConversations.toLocaleString() }}
            </div>
          </div>
          <div v-if="trendPercent !== null" class="text-right">
            <div
              class="text-[11px] font-medium text-muted-foreground uppercase tracking-wide"
            >
              Trend
            </div>
            <div
              class="inline-flex items-center gap-1 text-base font-semibold tabular-nums mt-0.5 text-destructive"
            >
              <span
                :class="
                  trendPercent >= 0
                    ? 'i-lucide-trending-up'
                    : 'i-lucide-trending-down'
                "
                class="size-4 shrink-0"
                aria-hidden="true"
              />
              {{ Math.abs(trendPercent) }}%
            </div>
          </div>
        </div>
      </div>

      <div class="h-[320px] w-full px-4 pt-4 pb-2">
        <LineChart class="h-full w-full" :collection="chartData" />
      </div>
    </div>
  </div>
</template>
