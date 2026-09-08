<script setup>
import { ref } from 'vue';
import ReportHeader from './components/ReportHeader.vue';
import SummaryReports from './components/SummaryReports.vue';
import RelayButton from 'dashboard/components-next/relay/button/Button.vue';

const summarReportsRef = ref(null);

const onDownloadClick = () => {
  summarReportsRef.value.downloadReports();
};
</script>

<template>
  <ReportHeader
    :header-title="$t('INBOX_REPORTS.HEADER')"
    :header-description="$t('INBOX_REPORTS.DESCRIPTION')"
  >
    <RelayButton @click="onDownloadClick">
      <span class="i-lucide-download size-4" />
      {{ $t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS') }}
    </RelayButton>
  </ReportHeader>

  <SummaryReports
    ref="summarReportsRef"
    action-key="summaryReports/fetchInboxSummaryReports"
    getter-key="inboxes/getInboxes"
    fetch-items-key="inboxes/get"
    summary-key="summaryReports/getInboxSummaryReports"
    type="inbox"
  />
</template>
