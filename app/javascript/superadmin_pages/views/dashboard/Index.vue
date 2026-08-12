<script setup>
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

const prepareData = sourceData => {
  const labels = [];
  const data = [];
  sourceData.forEach(item => {
    labels.push(item[0]);
    data.push(item[1]);
  });
  return {
    labels,
    datasets: [
      {
        label: 'Conversations',
        data,
        borderColor: 'rgba(91, 91, 214, 1)',
        backgroundColor: ctx => {
          const chart = ctx.chart;
          const { chartArea } = chart;
          if (!chartArea) return 'rgba(91, 91, 214, 0.15)';
          const gradient = chart.ctx.createLinearGradient(
            0,
            chartArea.top,
            0,
            chartArea.bottom
          );
          gradient.addColorStop(0, 'rgba(91, 91, 214, 0.25)');
          gradient.addColorStop(1, 'rgba(91, 91, 214, 0)');
          return gradient;
        },
        fill: true,
        tension: 0.4,
        borderWidth: 2,
        pointRadius: 3,
        pointHoverRadius: 6,
        pointBackgroundColor: 'rgba(91, 91, 214, 1)',
        pointBorderColor: '#fff',
        pointBorderWidth: 2,
        pointHoverBackgroundColor: 'rgba(91, 91, 214, 1)',
        pointHoverBorderColor: '#fff',
        pointHoverBorderWidth: 2,
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
    <header
      class="flex items-center justify-between pb-4 border-b border-border/40"
    >
      <h1 class="text-2xl font-semibold tracking-tight text-foreground">
        Dashboard
      </h1>
    </header>

    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="stat in stats"
        :key="stat.label"
        class="rounded-xl border border-border bg-card p-5 shadow-xs"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-medium text-muted-foreground">{{
            stat.label
          }}</span>
          <span
            class="size-4 text-muted-foreground"
            :class="[stat.icon]"
            aria-hidden="true"
          />
        </div>
        <div class="text-3xl font-bold text-foreground tabular-nums">
          {{ stat.value }}
        </div>
      </div>
    </div>

    <div
      class="rounded-xl border border-border bg-card shadow-xs overflow-hidden"
    >
      <div
        class="px-6 pt-5 pb-4 border-b border-border/40 flex items-start justify-between gap-6 flex-wrap"
      >
        <div>
          <h2 class="text-base font-semibold text-foreground">
            Conversation Activity
          </h2>
          <p class="text-sm text-muted-foreground mt-0.5">
            Volume of conversations over time
          </p>
        </div>

        <div class="flex items-center divide-x divide-border/60">
          <div class="pr-5 text-right">
            <div
              class="text-xs font-medium text-muted-foreground uppercase tracking-wide"
            >
              Total
            </div>
            <div class="text-xl font-bold text-foreground tabular-nums mt-0.5">
              {{ totalConversations.toLocaleString() }}
            </div>
          </div>
          <div class="px-5 text-right">
            <div
              class="text-xs font-medium text-muted-foreground uppercase tracking-wide"
            >
              Peak
            </div>
            <div class="text-xl font-bold text-foreground tabular-nums mt-0.5">
              {{ peakConversations.toLocaleString() }}
            </div>
          </div>
          <div class="pl-5 text-right">
            <div
              class="text-xs font-medium text-muted-foreground uppercase tracking-wide"
            >
              Avg / period
            </div>
            <div class="text-xl font-bold text-foreground tabular-nums mt-0.5">
              {{ avgConversations.toLocaleString() }}
            </div>
          </div>
          <div v-if="trendPercent !== null" class="pl-5 text-right">
            <div
              class="text-xs font-medium text-muted-foreground uppercase tracking-wide"
            >
              Trend
            </div>
            <div
              class="inline-flex items-center gap-1 text-base font-bold tabular-nums mt-0.5"
              :class="trendPercent >= 0 ? 'text-success' : 'text-destructive'"
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

      <!-- eslint-disable-next-line vue/no-static-inline-styles -->
      <LineChart
        class="px-4 pt-4 pb-2 w-full"
        :collection="chartData"
        style="max-height: 360px"
      />
    </div>
  </div>
</template>
