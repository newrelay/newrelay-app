<script setup>
import ReportsShell from './components/ReportsShell.vue';
</script>

<template>
  <ReportsShell
    key="inbox-reports"
    type="inbox"
    getter-key="inboxes/getInboxes"
    action-key="inboxes/get"
    :download-button-label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
    :report-title="$t('INBOX_REPORTS.HEADER')"
  />
</template>
