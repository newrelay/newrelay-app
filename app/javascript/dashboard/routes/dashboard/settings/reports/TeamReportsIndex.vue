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
    :header-title="$t('TEAM_REPORTS.HEADER')"
    :header-description="$t('TEAM_REPORTS.DESCRIPTION')"
  >
    <RelayButton @click="onDownloadClick">
      <span class="i-lucide-download size-4" />
      {{ $t('TEAM_REPORTS.DOWNLOAD_TEAM_REPORTS') }}
    </RelayButton>
  </ReportHeader>

  <SummaryReports
    ref="summarReportsRef"
    action-key="summaryReports/fetchTeamSummaryReports"
    getter-key="teams/getTeams"
    fetch-items-key="teams/get"
    summary-key="summaryReports/getTeamSummaryReports"
    type="team"
  />
</template>
