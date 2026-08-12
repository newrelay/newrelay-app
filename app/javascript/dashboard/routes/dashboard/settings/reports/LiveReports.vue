<script setup>
import ConversationHeatmapContainer from './components/heatmaps/ConversationHeatmapContainer.vue';
import ResolutionHeatmapContainer from './components/heatmaps/ResolutionHeatmapContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
import TeamLiveReportContainer from './components/TeamLiveReportContainer.vue';
import StatsLiveReportsContainer from './components/StatsLiveReportsContainer.vue';
</script>

<template>
  <div class="flex flex-col gap-6 pb-6">
    <StatsLiveReportsContainer />
    <ConversationHeatmapContainer />
    <ResolutionHeatmapContainer />
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <AgentLiveReportContainer />
      <TeamLiveReportContainer />
    </div>
  </div>
</template>
