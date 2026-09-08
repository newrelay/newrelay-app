<script setup>
import { computed } from 'vue';
import { useReportMetrics } from 'dashboard/composables/useReportMetrics';
import { STATUS } from 'dashboard/store/constants';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { formatTime } from '@chatwoot/utils';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  metric: {
    type: Object,
    default: () => ({}),
  },
  accountSummaryKey: {
    type: String,
    default: 'getAccountSummary',
  },
  summaryFetchingKey: {
    type: String,
    default: 'getAccountSummaryFetchingStatus',
  },
  chartData: {
    type: Array,
    default: () => [],
  },
  groupBy: {
    type: Object,
    default: () => ({}),
  },
});

const { calculateTrend, displayMetric, isAverageMetricType, fetchingStatus } =
  useReportMetrics(props.accountSummaryKey, props.summaryFetchingKey);

// Map metric keys to appropriate Lucide icons
const iconMap = {
  conversations_count: 'i-lucide-message-circle',
  incoming_messages_count: 'i-lucide-download',
  outgoing_messages_count: 'i-lucide-send',
  avg_first_response_time: 'i-lucide-clock',
  avg_resolution_time: 'i-lucide-timer',
  resolutions_count: 'i-lucide-circle-check',
  reply_time: 'i-lucide-clock',
  customer_waiting_time: 'i-lucide-hourglass',
};

const metricIcon = computed(() => {
  return iconMap[props.metric.KEY] || 'i-lucide-message-circle';
});

// Format Trend Data
const trendData = computed(() => {
  if (
    fetchingStatus.value !== STATUS.FINISHED ||
    props.metric.trend === undefined ||
    props.metric.trend === null
  ) {
    return null;
  }

  const trendValue = props.metric.trend;
  const isAvg = isAverageMetricType(props.metric.KEY);

  // For average times, lower is better. For counts, higher is better.
  let isUp = trendValue > 0;
  let isGood = isAvg ? !isUp : isUp;

  if (trendValue === 0) {
    return { value: '0%', up: null, good: true };
  }

  return {
    value: `${calculateTrend(props.metric.KEY)}%`,
    up: isUp,
    good: isGood,
  };
});

// Calculate Max Value for the Bar Chart Height percentages
const maxValue = computed(() => {
  if (!props.chartData || props.chartData.length === 0) return 0;
  // chartData is array of { value, timestamp, count (optional) }
  return Math.max(...props.chartData.map(d => Number(d.value) || 0), 0);
});

const formattedChartData = computed(() => {
  if (!props.chartData || props.chartData.length === 0) return [];

  return props.chartData.map(item => {
    const val = Number(item.value) || 0;
    const heightPercent = maxValue.value > 0 ? (val / maxValue.value) * 100 : 0;

    const date = new Date(fromUnixTime(item.timestamp));
    let formattedDate = format(date, 'dd-MMM');

    // Day = 1, Week = 2, Month = 3, Year = 4 (Based on GROUP_BY_FILTER)
    if (props.groupBy?.period === 'week') {
      const first_day = date.getDate() - date.getDay();
      const last_day = first_day + 6;
      const week_first_date = new Date(new Date(date).setDate(first_day));
      const week_last_date = new Date(new Date(date).setDate(last_day));
      formattedDate = `${format(week_first_date, 'dd-MMM')} - ${format(week_last_date, 'dd-MMM')}`;
    } else if (props.groupBy?.period === 'month') {
      formattedDate = format(date, 'MMM-yyyy');
    } else if (props.groupBy?.period === 'year') {
      formattedDate = format(date, 'yyyy');
    }

    let displayValue = val;
    // Format time if it's an average metric type
    if (isAverageMetricType(props.metric.KEY)) {
      displayValue = formatTime(val);
    }

    return {
      raw: val,
      heightPercent,
      date: formattedDate,
      displayValue,
      count: item.count || 0,
    };
  });
});

const xAxisLabels = computed(() => {
  if (formattedChartData.value.length === 0) return [];
  // Take up to 7 evenly spaced labels to fit under the chart nicely
  const data = formattedChartData.value;
  if (data.length <= 7) return data.map(d => d.date);

  const step = Math.ceil(data.length / 7);
  const labels = [];
  for (let i = 0; i < data.length; i += step) {
    labels.push(data[i].date);
  }
  return labels;
});
</script>

<template>
  <div
    class="p-6 rounded-xl border border-border bg-card shadow-sm flex flex-col relative overflow-hidden group h-full"
  >
    <!-- Highlight bar on top -->
    <div
      class="absolute top-0 left-0 w-full h-1 bg-primary/0 group-hover:bg-primary/10 transition-colors"
    />

    <div class="flex items-start gap-4 mb-10">
      <div
        class="size-10 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0"
      >
        <span class="size-5" :class="[metricIcon]" />
      </div>
      <div class="flex flex-col">
        <h3 class="text-[14px] font-medium text-muted-foreground">
          {{ metric.NAME }}
        </h3>

        <div v-if="fetchingStatus === STATUS.FETCHING" class="mt-2">
          <Spinner size="sm" />
        </div>
        <div
          v-else-if="fetchingStatus === STATUS.FAILED"
          class="text-destructive text-[13px] mt-1"
        >
          {{ $t('REPORT.SUMMARY_FETCHING_FAILED') }}
        </div>
        <div
          v-else-if="fetchingStatus === STATUS.FINISHED"
          class="flex items-end gap-3 mt-1"
        >
          <span
            class="text-[28px] leading-none font-medium text-foreground tracking-tight"
          >
            {{ displayMetric(metric.KEY) }}
          </span>

          <div
            v-if="trendData"
            class="flex items-center gap-1 text-[14px] font-medium pb-1"
            :class="trendData.good ? 'text-emerald-600' : 'text-destructive'"
          >
            <span
              v-if="trendData.up === true"
              class="i-lucide-trending-up size-3.5"
            />
            <span
              v-else-if="trendData.up === false"
              class="i-lucide-trending-down size-3.5"
            />
            <span v-else class="i-lucide-minus size-3.5" />
            {{ trendData.value }}
          </div>
        </div>
      </div>
    </div>

    <!-- Mini CSS Bar Chart -->
    <div
      v-if="formattedChartData.length > 0"
      class="mt-auto h-28 flex items-end gap-2 border-b border-border/50 pb-2 relative ml-4"
    >
      <div
        class="absolute -left-4 top-0 text-[10px] text-muted-foreground/50 font-medium whitespace-nowrap"
      >
        {{ isAverageMetricType(metric.KEY) ? formatTime(maxValue) : maxValue }}
      </div>
      <div
        class="absolute -left-4 bottom-1 text-[10px] text-muted-foreground/50 font-medium"
      >
        {{ 0 }}
      </div>

      <div
        v-for="(item, i) in formattedChartData"
        :key="i"
        class="flex-1 flex flex-col justify-end h-full relative group/bar"
      >
        <div
          class="w-full transition-all duration-300 rounded-t-sm bg-primary/90 group-hover/bar:bg-primary"
          :style="{
            height: `${item.heightPercent}%`,
            minHeight: item.raw > 0 ? '3px' : '1px',
            opacity: item.raw === 0 ? '0.05' : '1',
          }"
        />

        <!-- Tooltip -->
        <div
          class="absolute -top-[60px] left-1/2 -translate-x-1/2 bg-slate-900 text-white px-3 py-2 rounded-md shadow-xl opacity-0 group-hover/bar:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-10 flex flex-col gap-1 min-w-max"
        >
          <span class="font-bold text-[11px] leading-none">{{
            item.date
          }}</span>
          <div class="flex items-center gap-1.5 mt-0.5">
            <div class="size-2 bg-primary rounded-sm" />
            <span class="text-[11px] leading-none text-white/90"
              >{{ metric.NAME }}: {{ item.displayValue }}</span
            >
          </div>
          <div
            v-if="item.count > 0 && isAverageMetricType(metric.KEY)"
            class="flex items-center gap-1.5 mt-0.5"
          >
            <div class="size-2 bg-white/20 rounded-sm" />
            <span class="text-[11px] leading-none text-white/70"
              >{{ $t('REPORT.CONVERSATION_COUNT') }}: {{ item.count }}</span
            >
          </div>
          <!-- Tooltip Arrow -->
          <div
            class="absolute -bottom-1 left-1/2 -translate-x-1/2 size-2.5 bg-slate-900 rotate-45"
          />
        </div>
      </div>
    </div>

    <div
      v-else-if="
        fetchingStatus === STATUS.FINISHED && formattedChartData.length === 0
      "
      class="mt-auto h-28 flex items-center justify-center border-b border-border/50 text-sm text-muted-foreground"
    >
      {{ $t('REPORT.NO_ENOUGH_DATA') }}
    </div>

    <!-- X Axis -->
    <div v-if="xAxisLabels.length > 0" class="flex gap-2 mt-2 ml-4">
      <div
        v-for="day in xAxisLabels"
        :key="day"
        class="flex-1 text-center text-[10px] text-muted-foreground font-medium truncate"
      >
        {{ day }}
      </div>
    </div>
  </div>
</template>
