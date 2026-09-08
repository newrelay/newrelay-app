<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { subDays, startOfDay, isSameDay, format } from 'date-fns';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import {
  RelayButton,
  RelaySwitch,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import LineChart from 'shared/components/charts/LineChart.vue';
import { CHANNEL_NAME_BY_TYPE } from '../constants/channels';
import CreateAutomationModal from '../components/CreateAutomationModal.vue';
import AccountSwitcher from '../components/AccountSwitcher.vue';
import { useAutoresponderAccount } from '../composables/useAutoresponderAccount';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { matchesActiveInbox } = useAutoresponderAccount();

const isCreateModalOpen = ref(false);
const dateRangeKey = ref('7d');

onMounted(() => {
  store.dispatch('commentAutomationCampaigns/get');
  store.dispatch('commentAutomationMessageLogs/get');
});

const campaigns = useMapGetter('commentAutomationCampaigns/getCampaigns');
const logs = useMapGetter('commentAutomationMessageLogs/getMessageLogs');
const scopedCampaigns = computed(() =>
  campaigns.value.filter(c => matchesActiveInbox(c.inbox))
);
const scopedLogs = computed(() =>
  logs.value.filter(l => matchesActiveInbox(l.inbox))
);

const SPARKLINE_DAYS = 7;
const sparklineOptions = {
  layout: { padding: 0 },
  plugins: { legend: { display: false }, tooltip: { enabled: false } },
  scales: {
    x: { display: false, grid: { display: false }, border: { display: false } },
    y: {
      display: false,
      beginAtZero: true,
      grid: { display: false },
      border: { display: false },
    },
  },
};

const logTime = log => new Date((log.sent_at || log.created_at) * 1000);
const campaignTime = campaign => new Date((campaign.created_at || 0) * 1000);

function daysInRange(count) {
  const days = [];
  for (let i = count - 1; i >= 0; i -= 1) {
    days.push(startOfDay(subDays(new Date(), i)));
  }
  return days;
}

function sparklineCollection(data) {
  return {
    labels: data.map((_, index) => String(index)),
    datasets: [
      {
        data,
        fill: false,
        tension: 0.4,
        borderWidth: 2,
        pointRadius: 0,
        pointHoverRadius: 0,
      },
    ],
  };
}

const sparklineSeries = computed(() => {
  const days = daysInRange(SPARKLINE_DAYS);
  return {
    total: days.map(
      day =>
        scopedCampaigns.value.filter(c => startOfDay(campaignTime(c)) <= day)
          .length
    ),
    active: days.map(
      day =>
        scopedCampaigns.value.filter(
          c => c.is_active && startOfDay(campaignTime(c)) <= day
        ).length
    ),
    responses: days.map(
      day =>
        scopedLogs.value.filter(
          l => l.status !== 'pending' && isSameDay(logTime(l), day)
        ).length
    ),
    contacts: days.map(day => {
      const ids = new Set(
        scopedLogs.value
          .filter(l => l.contact && isSameDay(logTime(l), day))
          .map(l => l.contact.id)
      );
      return ids.size;
    }),
  };
});

const metrics = computed(() => {
  const respondedLogs = scopedLogs.value.filter(l => l.status !== 'pending');
  const uniqueContacts = new Set(
    scopedLogs.value.filter(l => l.contact).map(l => l.contact.id)
  );
  const series = sparklineSeries.value;
  return [
    {
      key: 'total',
      icon: 'i-lucide-zap',
      label: t('AUTORESPONDER.OVERVIEW.METRIC_TOTAL'),
      value: scopedCampaigns.value.length,
      helper: t('AUTORESPONDER.OVERVIEW.METRIC_TOTAL_HELPER'),
      sparkline: sparklineCollection(series.total),
    },
    {
      key: 'active',
      icon: 'i-lucide-play',
      label: t('AUTORESPONDER.OVERVIEW.METRIC_ACTIVE'),
      value: scopedCampaigns.value.filter(c => c.is_active).length,
      helper: t('AUTORESPONDER.OVERVIEW.METRIC_ACTIVE_HELPER'),
      sparkline: sparklineCollection(series.active),
    },
    {
      key: 'responses',
      icon: 'i-lucide-message-square',
      label: t('AUTORESPONDER.OVERVIEW.METRIC_RESPONSES'),
      value: respondedLogs.length,
      helper: t('AUTORESPONDER.OVERVIEW.METRIC_RESPONSES_HELPER'),
      sparkline: sparklineCollection(series.responses),
    },
    {
      key: 'contacts',
      icon: 'i-lucide-users',
      label: t('AUTORESPONDER.OVERVIEW.METRIC_CONTACTS'),
      value: uniqueContacts.size,
      helper: t('AUTORESPONDER.OVERVIEW.METRIC_CONTACTS_HELPER'),
      sparkline: sparklineCollection(series.contacts),
    },
  ];
});

const topAutomations = computed(() =>
  [...scopedCampaigns.value]
    .sort((a, b) => b.responses_count - a.responses_count)
    .slice(0, 4)
);

const dateRangeOptions = [
  {
    key: 'today',
    days: 1,
    label: t('AUTORESPONDER.OVERVIEW.DATE_RANGE_TODAY'),
  },
  { key: '7d', days: 7, label: t('AUTORESPONDER.OVERVIEW.DATE_RANGE_7_DAYS') },
  {
    key: '30d',
    days: 30,
    label: t('AUTORESPONDER.OVERVIEW.DATE_RANGE_30_DAYS'),
  },
];
const dateRange = computed(
  () => dateRangeOptions.find(o => o.key === dateRangeKey.value).label
);
const dateRangeDays = computed(
  () => dateRangeOptions.find(o => o.key === dateRangeKey.value).days
);

const responseChartBars = computed(() =>
  daysInRange(dateRangeDays.value).map(day => ({
    label: format(day, 'MMM d'),
    value: scopedLogs.value.filter(l => isSameDay(logTime(l), day)).length,
  }))
);

const totalResponsesInRange = computed(() =>
  responseChartBars.value.reduce((sum, bar) => sum + bar.value, 0)
);

const previousResponsesInRange = computed(() => {
  const days = dateRangeDays.value;
  const currentStart = startOfDay(subDays(new Date(), days - 1));
  const previousStart = startOfDay(subDays(new Date(), days * 2 - 1));
  return scopedLogs.value.filter(l => {
    const day = startOfDay(logTime(l));
    return day >= previousStart && day < currentStart;
  }).length;
});

const responsesDeltaPct = computed(() => {
  const previous = previousResponsesInRange.value;
  if (!previous) return null;
  return Math.round(
    ((totalResponsesInRange.value - previous) / previous) * 100
  );
});

const responseChartCollection = computed(() => ({
  labels: responseChartBars.value.map(bar => bar.label),
  datasets: [
    {
      label: t('AUTORESPONDER.OVERVIEW.RESPONSES_OVER_TIME'),
      data: responseChartBars.value.map(bar => bar.value),
      fill: true,
      tension: 0.4,
      borderWidth: 2.2,
      pointRadius: 0,
      pointHoverRadius: 5,
    },
  ],
}));

const channelDistribution = computed(() => {
  const total = scopedLogs.value.length;
  const counts = scopedLogs.value.reduce((acc, log) => {
    const type = log.inbox.channel_type;
    acc[type] = (acc[type] || 0) + 1;
    return acc;
  }, {});
  return Object.entries(counts)
    .map(([type, count]) => ({
      type,
      name: CHANNEL_NAME_BY_TYPE[type] || type,
      count,
      pct: total ? Math.round((count / total) * 1000) / 10 : 0,
    }))
    .sort((a, b) => b.count - a.count);
});

function goToAutomations() {
  router.push({ name: 'autoresponder_automations' });
}

function toggleActive(campaign) {
  store.dispatch('commentAutomationCampaigns/update', {
    id: campaign.id,
    campaign: { is_active: !campaign.is_active },
  });
}

function deleteCampaign(campaign) {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('AUTORESPONDER.AUTOMATIONS.DELETE_CONFIRM'))) return;
  store.dispatch('commentAutomationCampaigns/delete', campaign.id);
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full bg-background p-6 lg:p-8">
    <div class="max-w-7xl mx-auto flex flex-col gap-8">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4"
      >
        <div>
          <h1 class="text-[16px] font-medium tracking-tight text-foreground">
            {{ t('AUTORESPONDER.OVERVIEW.TITLE') }}
          </h1>
          <p class="text-[13.5px] text-muted-foreground mt-1">
            {{ t('AUTORESPONDER.OVERVIEW.SUBTITLE') }}
          </p>
        </div>
        <div class="flex items-center gap-3">
          <AccountSwitcher />
          <RelayButton class="gap-2" @click="isCreateModalOpen = true">
            <span class="i-lucide-plus size-4" />
            {{ t('AUTORESPONDER.OVERVIEW.CREATE_AUTOMATION') }}
          </RelayButton>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          v-for="metric in metrics"
          :key="metric.key"
          class="bg-card text-card-foreground rounded-xl border border-border shadow-sm p-5 flex flex-col justify-between"
        >
          <div class="flex items-center gap-3">
            <div
              class="size-10 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0"
            >
              <span :class="metric.icon" class="size-5" />
            </div>
            <span class="text-sm font-medium text-foreground">{{
              metric.label
            }}</span>
          </div>
          <div class="mt-4 flex items-end justify-between gap-3">
            <div>
              <div
                class="text-3xl font-semibold tracking-tight text-foreground"
              >
                {{ metric.value }}
              </div>
              <div class="text-xs text-muted-foreground mt-1">
                {{ metric.helper }}
              </div>
            </div>
            <div class="h-10 w-20 shrink-0">
              <LineChart
                :collection="metric.sparkline"
                :chart-options="sparklineOptions"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div
          class="bg-card text-card-foreground rounded-xl border border-border shadow-sm flex flex-col"
        >
          <div class="p-5 pb-0 flex items-center justify-between">
            <div>
              <h3 class="text-base font-medium text-foreground">
                {{ t('AUTORESPONDER.OVERVIEW.ACTIVE_AUTOMATIONS_TITLE') }}
              </h3>
              <p class="text-sm text-muted-foreground mt-0.5">
                {{ t('AUTORESPONDER.OVERVIEW.ACTIVE_AUTOMATIONS_SUBTITLE') }}
              </p>
            </div>
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 px-3 text-xs"
              @click="goToAutomations"
            >
              {{ t('AUTORESPONDER.OVERVIEW.VIEW_ALL') }}
            </RelayButton>
          </div>

          <div
            v-if="!topAutomations.length"
            class="p-5 text-sm text-muted-foreground"
          >
            {{ t('AUTORESPONDER.AUTOMATIONS.EMPTY_STATE') }}
          </div>
          <div v-else class="p-5 flex flex-col gap-3">
            <div
              v-for="item in topAutomations"
              :key="item.id"
              class="flex flex-col sm:flex-row sm:items-center justify-between p-3 rounded-lg border border-border bg-background hover:bg-muted/30 transition-colors gap-4 sm:gap-2"
            >
              <div
                class="flex items-start sm:items-center gap-4 flex-1 min-w-0"
              >
                <div
                  class="size-10 rounded-lg border border-border bg-card shadow-xs flex items-center justify-center shrink-0"
                >
                  <span
                    :class="getInboxIconByType(item.inbox.channel_type)"
                    class="size-5 text-foreground"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-sm text-foreground truncate">
                    {{ item.name }}
                  </div>
                  <div
                    class="text-[13px] text-muted-foreground truncate mt-0.5"
                  >
                    {{
                      t('AUTORESPONDER.ACTIVITY.KEYWORD_LABEL', {
                        keyword: item.trigger?.keyword,
                      })
                    }}
                  </div>
                </div>
              </div>

              <div
                class="flex items-center justify-between sm:justify-end w-full sm:w-auto gap-6 sm:gap-8 shrink-0"
              >
                <div class="flex flex-col items-start sm:items-end">
                  <div class="flex items-center gap-1.5">
                    <div
                      class="size-1.5 rounded-full"
                      :class="
                        item.is_active ? 'bg-primary' : 'bg-muted-foreground'
                      "
                    />
                    <span class="text-xs font-medium text-foreground">{{
                      item.is_active
                        ? t('AUTORESPONDER.AUTOMATIONS.STATUS_ACTIVE')
                        : t('AUTORESPONDER.AUTOMATIONS.STATUS_PAUSED')
                    }}</span>
                  </div>
                  <div class="text-sm font-semibold text-foreground mt-0.5">
                    {{ item.responses_count }}
                  </div>
                  <div class="text-[11px] text-muted-foreground">
                    {{ t('AUTORESPONDER.OVERVIEW.RESPONSES_LABEL') }}
                  </div>
                </div>
                <div class="flex items-center gap-3">
                  <RelaySwitch
                    :model-value="item.is_active"
                    @update:model-value="toggleActive(item)"
                  />
                  <RelayDropdownMenu>
                    <RelayDropdownMenuTrigger as-child>
                      <button
                        type="button"
                        class="p-1.5 text-muted-foreground hover:bg-muted rounded-md transition-colors outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                      >
                        <span class="i-lucide-more-horizontal size-4" />
                      </button>
                    </RelayDropdownMenuTrigger>
                    <RelayDropdownMenuContent align="end" class="w-40">
                      <RelayDropdownMenuItem @click="goToAutomations">
                        {{ t('AUTORESPONDER.COMMON.EDIT_AUTOMATION') }}
                      </RelayDropdownMenuItem>
                      <RelayDropdownMenuItem
                        destructive
                        @click="deleteCampaign(item)"
                      >
                        {{ t('AUTORESPONDER.COMMON.DELETE') }}
                      </RelayDropdownMenuItem>
                    </RelayDropdownMenuContent>
                  </RelayDropdownMenu>
                </div>
              </div>
            </div>
          </div>

          <div class="p-4 border-t border-border mt-auto">
            <button
              type="button"
              class="w-full text-center text-[13.5px] font-medium text-primary hover:underline flex items-center justify-center gap-1.5"
              @click="goToAutomations"
            >
              {{ t('AUTORESPONDER.OVERVIEW.VIEW_ALL_AUTOMATIONS') }}
              <span class="i-lucide-chevron-down size-4 -rotate-90" />
            </button>
          </div>
        </div>

        <div
          class="bg-card text-card-foreground rounded-xl border border-border shadow-sm p-6 flex flex-col"
        >
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-base font-medium text-foreground">
              {{ t('AUTORESPONDER.OVERVIEW.RESPONSES_OVER_TIME') }}
            </h3>
            <RelayDropdownMenu>
              <RelayDropdownMenuTrigger as-child>
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 px-3 text-xs gap-1"
                >
                  {{ dateRange }}
                  <span class="i-lucide-chevron-down size-3.5 opacity-70" />
                </RelayButton>
              </RelayDropdownMenuTrigger>
              <RelayDropdownMenuContent align="end" class="w-40">
                <RelayDropdownMenuItem
                  v-for="opt in dateRangeOptions"
                  :key="opt.key"
                  @click="dateRangeKey = opt.key"
                >
                  {{ opt.label }}
                </RelayDropdownMenuItem>
              </RelayDropdownMenuContent>
            </RelayDropdownMenu>
          </div>

          <div class="mb-6">
            <div class="flex items-baseline gap-3 flex-wrap">
              <span
                class="text-3xl font-semibold tracking-tight text-foreground"
                >{{ totalResponsesInRange }}</span
              >
              <span
                v-if="responsesDeltaPct !== null"
                class="inline-flex items-center text-[13px] font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-md gap-0.5"
              >
                <span
                  :class="
                    responsesDeltaPct >= 0
                      ? 'i-lucide-arrow-up'
                      : 'i-lucide-arrow-down'
                  "
                  class="size-3"
                />
                {{
                  t('AUTORESPONDER.OVERVIEW.DELTA_PCT', {
                    pct: Math.abs(responsesDeltaPct),
                  })
                }}
              </span>
              <span class="text-[13px] text-muted-foreground">
                {{ t('AUTORESPONDER.OVERVIEW.VS_PREVIOUS') }}
              </span>
            </div>
          </div>

          <div class="flex-1 min-h-[240px] h-60">
            <LineChart :collection="responseChartCollection" />
          </div>
        </div>
      </div>

      <div
        class="bg-card text-card-foreground rounded-xl border border-border shadow-sm p-6"
      >
        <div class="flex flex-col lg:flex-row lg:items-center gap-6">
          <div class="lg:w-1/4 shrink-0">
            <h3 class="text-base font-medium text-foreground">
              {{ t('AUTORESPONDER.OVERVIEW.CHANNEL_DISTRIBUTION') }}
            </h3>
            <p class="text-sm text-muted-foreground mt-0.5">
              {{ t('AUTORESPONDER.OVERVIEW.CHANNEL_DISTRIBUTION_SUBTITLE') }}
            </p>
          </div>

          <div
            v-if="!channelDistribution.length"
            class="flex-1 text-sm text-muted-foreground"
          >
            {{ t('AUTORESPONDER.ACTIVITY.EMPTY_STATE') }}
          </div>
          <div
            v-else
            class="flex-1 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4"
          >
            <div
              v-for="channel in channelDistribution"
              :key="channel.type"
              class="flex flex-col gap-2 p-4 rounded-lg border border-border bg-background"
            >
              <div class="flex items-center gap-2">
                <div
                  class="size-8 rounded-md border border-border bg-card shadow-xs flex items-center justify-center"
                >
                  <span
                    :class="getInboxIconByType(channel.type)"
                    class="size-4 text-foreground"
                  />
                </div>
                <span class="text-[13.5px] font-medium text-foreground">{{
                  channel.name
                }}</span>
              </div>
              <div class="flex items-end justify-between mt-1">
                <span
                  class="text-xl font-semibold tracking-tight text-foreground"
                >
                  {{ channel.count }}
                </span>
                <span class="text-xs font-medium text-muted-foreground">
                  {{ channel.pct }}%
                </span>
              </div>
              <div
                class="h-1.5 w-full bg-muted rounded-full overflow-hidden mt-1"
              >
                <div
                  class="h-full bg-primary rounded-full"
                  :style="{ width: `${channel.pct}%` }"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <CreateAutomationModal v-model:open="isCreateModalOpen" />
  </div>
</template>
