<script setup>
import ReportsShell from './components/ReportsShell.vue';
</script>

<template>
  <ReportsShell
    key="team-reports"
    type="team"
    getter-key="teams/getTeams"
    action-key="teams/get"
    :download-button-label="$t('TEAM_REPORTS.DOWNLOAD_TEAM_REPORTS')"
    :report-title="$t('TEAM_REPORTS.HEADER')"
  />
</template>
