<script setup>
import { computed, onMounted, ref } from 'vue';
import { useToggle } from '@vueuse/core';

import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const agentStatus = useMapGetter('agents/getAgentStatus');
const accountConversationMetric = useMapGetter('getAccountConversationMetric');
const store = useStore();

const accounti18nKey = 'OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS';
const teams = useMapGetter('teams/getTeams');

const teamMenuList = computed(() => [
  { label: t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.ALL_TEAMS'), value: null },
  ...teams.value.map(team => ({ label: team.name, value: team.id })),
]);

const conversationCards = computed(() => [
  {
    key: 'open',
    icon: 'i-lucide-message-circle',
    label: t(`${accounti18nKey}.OPEN`),
    value: accountConversationMetric.value.open ?? 0,
  },
  {
    key: 'unattended',
    icon: 'i-lucide-circle-alert',
    label: t(`${accounti18nKey}.UNATTENDED`),
    value: accountConversationMetric.value.unattended ?? 0,
  },
  {
    key: 'unassigned',
    icon: 'i-lucide-user-x',
    label: t(`${accounti18nKey}.UNASSIGNED`),
    value: accountConversationMetric.value.unassigned ?? 0,
  },
  {
    key: 'pending',
    icon: 'i-lucide-hourglass',
    label: t(`${accounti18nKey}.PENDING`),
    value: accountConversationMetric.value.pending ?? 0,
  },
]);

const agentStatusRows = computed(() => [
  {
    key: 'online',
    dotClass: 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]',
    label: t('OVERVIEW_REPORTS.AGENT_STATUS.ONLINE'),
    value: agentStatus.value.online ?? 0,
  },
  {
    key: 'busy',
    dotClass: 'bg-orange-500 shadow-[0_0_8px_rgba(249,115,22,0.5)]',
    label: t('OVERVIEW_REPORTS.AGENT_STATUS.BUSY'),
    value: agentStatus.value.busy ?? 0,
  },
  {
    key: 'offline',
    dotClass: 'bg-slate-400',
    label: t('OVERVIEW_REPORTS.AGENT_STATUS.OFFLINE'),
    value: agentStatus.value.offline ?? 0,
  },
]);

const selectedTeam = ref(null);
const selectedTeamLabel = computed(
  () =>
    teamMenuList.value.find(item => item.value === selectedTeam.value)?.label
);

const fetchData = () => {
  const params = {};
  if (selectedTeam.value) params.team_id = selectedTeam.value;
  store.dispatch('fetchAccountConversationMetric', params);
};

const { startRefetching } = useLiveRefresh(fetchData);
const [showDropdown, toggleDropdown] = useToggle();

const handleAction = ({ value }) => {
  toggleDropdown(false);
  selectedTeam.value = value;
  fetchData();
};

onMounted(() => {
  fetchData();
  startRefetching();
});
</script>

<template>
  <div class="flex flex-col xl:flex-row gap-6">
    <!-- Conversation metrics column -->
    <div class="flex-1 flex flex-col gap-4">
      <div class="flex items-center justify-between h-8">
        <div class="flex items-center gap-3">
          <h3 class="text-base font-medium text-foreground tracking-tight">
            {{ $t(`${accounti18nKey}.HEADER`) }}
          </h3>
          <div
            class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 text-[12px] font-medium border border-emerald-500/20"
          >
            <span
              class="size-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"
            />
            Live
          </div>
        </div>
        <div
          v-if="teams.length"
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative"
        >
          <Button
            sm
            slate
            faded
            :label="selectedTeamLabel"
            class="capitalize rounded-md"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showDropdown"
            :menu-items="teamMenuList"
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            label-class="capitalize"
            @action="handleAction($event)"
          />
        </div>
      </div>
      <div class="grid grid-cols-2 xl:grid-cols-4 gap-4">
        <div
          v-for="card in conversationCards"
          :key="card.key"
          class="group flex flex-col justify-between bg-card border border-border/60 rounded-xl shadow-sm p-5 transition-colors hover:border-primary/20"
        >
          <div>
            <div class="flex items-center gap-2 mb-4">
              <span
                class="size-6 rounded-md bg-primary/10 text-primary grid place-content-center shrink-0"
              >
                <span :class="card.icon" class="size-3.5" />
              </span>
              <h3
                class="text-[13px] font-medium text-muted-foreground transition-colors group-hover:text-foreground"
              >
                {{ card.label }}
              </h3>
            </div>
            <div class="mb-1">
              <span
                class="text-[28px] leading-none font-semibold text-foreground tracking-tight"
              >
                {{ card.value }}
              </span>
            </div>
            <div class="flex items-center gap-1.5 text-[12px]">
              <span class="font-medium text-muted-foreground">
                {{ $t('REPORT.DATA_PENDING') }}
              </span>
              <span class="text-muted-foreground">
                {{ $t('REPORT.VS_LAST_PERIOD') }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Agent status column -->
    <div class="flex flex-col gap-4 w-full xl:w-[320px] shrink-0">
      <div class="flex items-center gap-3 h-8">
        <h3 class="text-base font-medium text-foreground tracking-tight">
          {{ $t('OVERVIEW_REPORTS.AGENT_STATUS.HEADER') }}
        </h3>
        <div
          class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 text-[12px] font-medium border border-emerald-500/20"
        >
          <span
            class="size-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"
          />
          Live
        </div>
      </div>
      <div
        class="w-full bg-card border border-border/60 rounded-xl shadow-sm p-1.5 flex flex-col"
      >
        <div
          v-for="row in agentStatusRows"
          :key="row.key"
          class="flex items-center justify-between px-3 py-2.5 rounded-lg transition-colors hover:bg-muted"
        >
          <div class="flex items-center gap-3">
            <span :class="row.dotClass" class="size-2 rounded-full shrink-0" />
            <span class="text-[14px] font-medium text-foreground">{{
              row.label
            }}</span>
          </div>
          <div class="flex items-center gap-4">
            <span class="text-[12px] font-medium text-muted-foreground">
              {{ $t('REPORT.DATA_PENDING') }}
            </span>
            <span
              class="text-[14px] font-medium text-foreground w-6 text-right"
            >
              {{ row.value }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
