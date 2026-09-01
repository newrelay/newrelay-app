<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { Line } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  LineElement,
  PointElement,
  CategoryScale,
  LinearScale,
  Filler,
} from 'chart.js';

const props = defineProps({
  collection: {
    type: Object,
    default: () => ({}),
  },
  chartOptions: {
    type: Object,
    default: () => ({}),
  },
});

ChartJS.register(
  Title,
  Tooltip,
  LineElement,
  PointElement,
  CategoryScale,
  LinearScale,
  Filler
);

const fontFamily =
  'Geist,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

const themeTick = ref(0);

const cssVar = (name, fallback) => {
  if (typeof document === 'undefined') return fallback;
  return (
    getComputedStyle(document.documentElement).getPropertyValue(name).trim() ||
    fallback
  );
};

const chartTheme = computed(() => ({
  primary: cssVar('--primary', '#4f46e5'),
  muted: cssVar('--muted-foreground', '#6c727e'),
  border: cssVar('--border', '#e4e7ee'),
  popover: cssVar('--popover', '#ffffff'),
  popoverFg: cssVar('--popover-foreground', '#141822'),
  card: cssVar('--card', '#ffffff'),
  revision: themeTick.value,
}));

const themedCollection = computed(() => {
  const { primary, card } = chartTheme.value;
  const source = props.collection || {};
  const datasets = (source.datasets || []).map(dataset => ({
    ...dataset,
    borderColor: primary,
    pointBackgroundColor: primary,
    pointHoverBackgroundColor: primary,
    pointBorderColor: card,
    pointHoverBorderColor: card,
    clip: false,
  }));
  return { ...source, datasets };
});

const defaultChartOptions = computed(() => {
  const { muted, border, popover, popoverFg, primary } = chartTheme.value;
  return {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 400 },
    interaction: { mode: 'index', intersect: false },
    layout: {
      padding: { top: 16, right: 8, bottom: 12, left: 4 },
    },
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: popover,
        titleColor: muted,
        bodyColor: popoverFg,
        borderColor: border,
        borderWidth: 1,
        padding: 10,
        cornerRadius: 8,
        displayColors: true,
        boxPadding: 4,
        titleFont: { family: fontFamily, size: 12, weight: '500' },
        bodyFont: { family: fontFamily, size: 13, weight: '600' },
        callbacks: {
          label: context => `Conversations: ${context.parsed.y}`,
        },
      },
    },
    scales: {
      x: {
        ticks: {
          font: { family: fontFamily, size: 11 },
          color: muted,
          maxRotation: 0,
          minRotation: 0,
          autoSkip: true,
          maxTicksLimit: 10,
          padding: 8,
        },
        grid: { display: false },
        border: { display: false },
      },
      y: {
        type: 'linear',
        position: 'left',
        beginAtZero: true,
        ticks: {
          font: { family: fontFamily, size: 11 },
          color: muted,
          stepSize: 1,
          padding: 6,
        },
        grid: { color: border },
        border: { display: false },
      },
    },
    elements: {
      point: {
        hoverBorderColor: primary,
      },
    },
  };
});

const options = computed(() => ({
  ...defaultChartOptions.value,
  ...props.chartOptions,
}));

const onThemeChange = () => {
  themeTick.value += 1;
};

onMounted(() => {
  window.addEventListener('nr-theme-changed', onThemeChange);
});

onUnmounted(() => {
  window.removeEventListener('nr-theme-changed', onThemeChange);
});
</script>

<template>
  <Line :data="themedCollection" :options="options" />
</template>
