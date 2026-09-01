<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import {
  RelayButton,
  RelaySwitch,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS } from '../constants/channels';
import CreateAutomationModal from '../components/CreateAutomationModal.vue';

const { t } = useI18n();
const router = useRouter();
const isCreateModalOpen = ref(false);
const dateRange = ref(t('AUTORESPONDER.OVERVIEW.DATE_RANGE_7_DAYS'));

// Demo/mock data — this whole module is a UI-only pre-backend port.
const metrics = [
  {
    key: 'total',
    icon: 'i-lucide-zap',
    label: t('AUTORESPONDER.OVERVIEW.METRIC_TOTAL'),
    value: '12',
    helper: t('AUTORESPONDER.OVERVIEW.METRIC_TOTAL_HELPER'),
    bars: [40, 55, 45, 65, 50, 75, 90],
  },
  {
    key: 'active',
    icon: 'i-lucide-play',
    label: t('AUTORESPONDER.OVERVIEW.METRIC_ACTIVE'),
    value: '8',
    helper: t('AUTORESPONDER.OVERVIEW.METRIC_ACTIVE_HELPER'),
    bars: [35, 50, 45, 60, 70, 65, 85],
  },
  {
    key: 'responses',
    icon: 'i-lucide-message-square',
    label: t('AUTORESPONDER.OVERVIEW.METRIC_RESPONSES'),
    value: '1,284',
    helper: t('AUTORESPONDER.OVERVIEW.METRIC_RESPONSES_HELPER'),
    bars: [45, 60, 55, 70, 65, 80, 95],
  },
  {
    key: 'contacts',
    icon: 'i-lucide-users',
    label: t('AUTORESPONDER.OVERVIEW.METRIC_CONTACTS'),
    value: '892',
    helper: t('AUTORESPONDER.OVERVIEW.METRIC_CONTACTS_HELPER'),
    bars: [40, 45, 42, 50, 48, 55, 65],
  },
];

const topAutomations = ref([
  {
    id: 1,
    name: 'Instagram Comment Reply',
    description: 'Reply to comments containing pricing keywords',
    channel: 'Instagram',
    tags: ['Instagram', 'Comment Reply'],
    status: 'Active',
    responses: 342,
    active: true,
  },
  {
    id: 2,
    name: 'Welcome Message',
    description: 'Send welcome message to new followers',
    channel: 'Instagram',
    tags: ['Instagram', 'Auto Message'],
    status: 'Active',
    responses: 287,
    active: true,
  },
  {
    id: 3,
    name: 'WhatsApp Quick Reply',
    description: 'Auto-reply to common questions',
    channel: 'WhatsApp',
    tags: ['WhatsApp', 'Auto Message'],
    status: 'Active',
    responses: 198,
    active: true,
  },
  {
    id: 4,
    name: 'Facebook Page Comment',
    description: 'Reply to comments on Facebook page',
    channel: 'Facebook',
    tags: ['Facebook', 'Comment Reply'],
    status: 'Active',
    responses: 142,
    active: true,
  },
]);

const responseChartBars = [
  { label: 'May 20', value: 45 },
  { label: 'May 21', value: 60 },
  { label: 'May 22', value: 68 },
  { label: 'May 23', value: 90 },
  { label: 'May 24', value: 72 },
  { label: 'May 25', value: 58 },
  { label: 'May 26', value: 74 },
];

const channelDistribution = [
  {
    name: 'Instagram',
    logo: CHANNEL_LOGO_URLS.Instagram,
    count: 812,
    pct: 63.2,
  },
  { name: 'WhatsApp', logo: CHANNEL_LOGO_URLS.WhatsApp, count: 298, pct: 23.2 },
  { name: 'Facebook', logo: CHANNEL_LOGO_URLS.Facebook, count: 134, pct: 10.4 },
];

const totalResponses = '1,284';
const responsesGrowthPct = '18.6%';

const dateRangeOptions = [
  { key: 'today', label: t('AUTORESPONDER.OVERVIEW.DATE_RANGE_TODAY') },
  { key: '7d', label: t('AUTORESPONDER.OVERVIEW.DATE_RANGE_7_DAYS') },
  { key: '30d', label: t('AUTORESPONDER.OVERVIEW.DATE_RANGE_30_DAYS') },
];

function goToAutomations() {
  router.push({ name: 'autoresponder_automations' });
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full bg-background p-6 lg:p-8">
    <div class="max-w-7xl mx-auto flex flex-col gap-8">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4"
      >
        <div>
          <h1 class="text-xl font-semibold tracking-tight text-foreground">
            {{ t('AUTORESPONDER.OVERVIEW.TITLE') }}
          </h1>
          <p class="text-sm text-muted-foreground mt-1">
            {{ t('AUTORESPONDER.OVERVIEW.SUBTITLE') }}
          </p>
        </div>
        <RelayButton class="gap-2" @click="isCreateModalOpen = true">
          <span class="i-lucide-plus size-4" />
          {{ t('AUTORESPONDER.OVERVIEW.CREATE_AUTOMATION') }}
        </RelayButton>
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
          <div class="mt-4 flex items-end justify-between">
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
            <div class="flex items-end gap-0.5 h-10 w-[70px]">
              <div
                v-for="(bar, idx) in metric.bars"
                :key="idx"
                class="flex-1 bg-primary/30 rounded-sm"
                :style="{ height: `${bar}%` }"
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
              <h3 class="text-base font-semibold text-foreground">
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

          <div class="p-5 flex flex-col gap-3">
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
                  <img
                    :src="CHANNEL_LOGO_URLS[item.channel]"
                    class="size-5 opacity-90 dark:opacity-80"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-sm text-foreground truncate">
                    {{ item.name }}
                  </div>
                  <div
                    class="text-[13px] text-muted-foreground truncate mt-0.5"
                  >
                    {{ item.description }}
                  </div>
                  <div class="flex items-center gap-2 mt-2">
                    <span
                      v-for="tag in item.tags"
                      :key="tag"
                      class="px-2 py-0.5 rounded-md bg-primary/10 text-primary text-[11px] font-medium"
                    >
                      {{ tag }}
                    </span>
                  </div>
                </div>
              </div>

              <div
                class="flex items-center justify-between sm:justify-end w-full sm:w-auto gap-6 sm:gap-8 shrink-0"
              >
                <div class="flex flex-col items-start sm:items-end">
                  <div class="flex items-center gap-1.5">
                    <div class="size-1.5 rounded-full bg-primary" />
                    <span class="text-xs font-medium text-foreground">{{
                      item.status
                    }}</span>
                  </div>
                  <div class="text-sm font-semibold text-foreground mt-0.5">
                    {{ item.responses }}
                  </div>
                  <div class="text-[11px] text-muted-foreground">
                    {{ t('AUTORESPONDER.OVERVIEW.RESPONSES_LABEL') }}
                  </div>
                </div>
                <div class="flex items-center gap-3">
                  <RelaySwitch v-model="item.active" />
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
                      <RelayDropdownMenuItem>
                        {{ t('AUTORESPONDER.COMMON.DUPLICATE') }}
                      </RelayDropdownMenuItem>
                      <RelayDropdownMenuItem destructive>
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
            <h3 class="text-base font-semibold text-foreground">
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
                  @click="dateRange = opt.label"
                >
                  {{ opt.label }}
                </RelayDropdownMenuItem>
              </RelayDropdownMenuContent>
            </RelayDropdownMenu>
          </div>

          <div class="mb-6">
            <div class="flex items-baseline gap-3">
              <span
                class="text-3xl font-semibold tracking-tight text-foreground"
                >{{ totalResponses }}</span
              >
              <div
                class="flex items-center text-[13px] font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-md gap-0.5"
              >
                <span class="i-lucide-arrow-up size-3" />
                {{ responsesGrowthPct }}
              </div>
              <span class="text-[13px] text-muted-foreground">
                {{ t('AUTORESPONDER.OVERVIEW.VS_PREVIOUS_7_DAYS') }}
              </span>
            </div>
          </div>

          <div
            class="flex-1 min-h-[240px] flex items-end justify-between gap-3 pt-2"
          >
            <div
              v-for="bar in responseChartBars"
              :key="bar.label"
              class="flex-1 flex flex-col items-center gap-2 group cursor-pointer"
            >
              <div class="w-full h-[190px] relative flex items-end">
                <div
                  class="w-full bg-primary group-hover:bg-primary/90 rounded-t-md transition-all"
                  :style="{ height: `${bar.value}%` }"
                />
              </div>
              <span
                class="text-xs font-medium text-muted-foreground group-hover:text-foreground transition-colors"
              >
                {{ bar.label }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div
        class="bg-card text-card-foreground rounded-xl border border-border shadow-sm p-6"
      >
        <div class="flex flex-col lg:flex-row lg:items-center gap-6">
          <div class="lg:w-1/4 shrink-0">
            <h3 class="text-base font-semibold text-foreground">
              {{ t('AUTORESPONDER.OVERVIEW.CHANNEL_DISTRIBUTION') }}
            </h3>
            <p class="text-sm text-muted-foreground mt-0.5">
              {{ t('AUTORESPONDER.OVERVIEW.CHANNEL_DISTRIBUTION_SUBTITLE') }}
            </p>
          </div>

          <div
            class="flex-1 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4"
          >
            <div
              v-for="channel in channelDistribution"
              :key="channel.name"
              class="flex flex-col gap-2 p-4 rounded-lg border border-border bg-background"
            >
              <div class="flex items-center gap-2">
                <div
                  class="size-8 rounded-md border border-border bg-card shadow-xs flex items-center justify-center"
                >
                  <img
                    :src="channel.logo"
                    class="size-4 opacity-90 dark:opacity-80"
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
