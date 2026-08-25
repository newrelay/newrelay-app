<script setup>
import ReportsShell from './components/ReportsShell.vue';
</script>

<template>
  <ReportsShell
    key="label-reports"
    type="label"
    getter-key="labels/getLabels"
    action-key="labels/get"
    :download-button-label="$t('LABEL_REPORTS.DOWNLOAD_LABEL_REPORTS')"
    :report-title="$t('LABEL_REPORTS.HEADER')"
  />
</template>
