<script setup>
import { computed } from 'vue';
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
  'Inter,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

const defaultChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  animation: { duration: 400 },
  interaction: { mode: 'index', intersect: false },
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: 'rgba(0,0,0,0.75)',
      padding: 10,
      cornerRadius: 8,
      titleFont: { family: fontFamily, size: 12 },
      bodyFont: { family: fontFamily, size: 13, weight: 'bold' },
    },
  },
  scales: {
    x: {
      ticks: { font: { family: fontFamily, size: 11 }, color: '#9ca3af' },
      grid: { display: false },
      border: { display: false },
    },
    y: {
      type: 'linear',
      position: 'left',
      beginAtZero: true,
      ticks: {
        font: { family: fontFamily, size: 11 },
        color: '#9ca3af',
        stepSize: 1,
      },
      grid: { color: 'rgba(0,0,0,0.06)' },
      border: { display: false },
    },
  },
};

const options = computed(() => ({
  ...defaultChartOptions,
  ...props.chartOptions,
}));
</script>

<template>
  <Line :data="collection" :options="options" />
</template>
