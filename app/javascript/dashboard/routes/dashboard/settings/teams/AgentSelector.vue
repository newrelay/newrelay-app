<script setup>
import { computed } from 'vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';
import Avatar from 'next/avatar/Avatar.vue';
import BaseTable from 'dashboard/components-next/table/BaseTable.vue';
import BaseTableRow from 'dashboard/components-next/table/BaseTableRow.vue';
import BaseTableCell from 'dashboard/components-next/table/BaseTableCell.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  agentList: {
    type: Array,
    default: () => [],
  },
  selectedAgents: {
    type: Array,
    default: () => [],
  },
  updateSelectedAgents: {
    type: Function,
    default: () => {},
  },
  isWorking: {
    type: Boolean,
    default: false,
  },
  submitButtonText: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const selectedAgentCount = computed(() => props.selectedAgents.length);

const allAgentsSelected = computed(
  () =>
    props.selectedAgents.length === props.agentList.length &&
    props.agentList.length > 0
);

const someAgentsSelected = computed(
  () => props.selectedAgents.length > 0 && !allAgentsSelected.value
);

const disableSubmitButton = computed(() => selectedAgentCount.value === 0);

const isAgentSelected = agentId => {
  return props.selectedAgents.includes(agentId);
};

const handleSelectAgent = agentId => {
  const shouldRemove = isAgentSelected(agentId);

  let result = [];
  if (shouldRemove) {
    result = props.selectedAgents.filter(item => item !== agentId);
  } else {
    result = [...props.selectedAgents, agentId];
  }

  props.updateSelectedAgents(result);
};

const toggleSelectAll = () => {
  if (allAgentsSelected.value) {
    props.updateSelectedAgents([]);
  } else {
    const result = props.agentList.map(item => item.id);
    props.updateSelectedAgents(result);
  }
};

const headers = computed(() => [
  '',
  t('TEAMS_SETTINGS.AGENTS.AGENT'),
  t('TEAMS_SETTINGS.AGENTS.EMAIL'),
]);
</script>

<template>
  <div class="space-y-4">
    <BaseTable :headers="headers" :items="agentList">
      <template #header-0>
        <div class="flex items-center">
          <RelayCheckbox
            :model-value="allAgentsSelected"
            :indeterminate="someAgentsSelected"
            :title="$t('TEAMS_SETTINGS.AGENTS.SELECT_ALL')"
            @change="toggleSelectAll"
          />
        </div>
      </template>

      <template #row="{ items }">
        <BaseTableRow v-for="agent in items" :key="agent.id" :item="agent">
          <template #default>
            <BaseTableCell class="w-5">
              <div class="flex items-center">
                <RelayCheckbox
                  :model-value="isAgentSelected(agent.id)"
                  @change="() => handleSelectAgent(agent.id)"
                />
              </div>
            </BaseTableCell>

            <BaseTableCell class="min-w-0 max-w-40">
              <div class="flex min-w-0 items-center gap-2.5">
                <Avatar
                  :src="agent.thumbnail"
                  :name="agent.name"
                  :status="agent.availability_status"
                  :size="24"
                  hide-offline-status
                  rounded-full
                  class="flex-shrink-0"
                />
                <h4 class="mb-0 truncate text-sm font-medium text-foreground">
                  {{ agent.name }}
                </h4>
              </div>
            </BaseTableCell>

            <BaseTableCell class="min-w-0">
              <span class="block truncate text-xs text-muted-foreground">
                {{ agent.email || '---' }}
              </span>
            </BaseTableCell>
          </template>
        </BaseTableRow>
      </template>
    </BaseTable>

    <div
      class="sticky bottom-0 z-20 -mx-8 flex items-center justify-between border-t border-border/40 bg-card px-8 py-4 shadow-xs"
    >
      <p class="mb-0 text-sm font-medium text-muted-foreground">
        {{
          $t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT', {
            selected: selectedAgents.length,
            total: agentList.length,
          })
        }}
      </p>
      <RelayButton
        type="submit"
        class="h-10 px-6 font-semibold shadow-sm"
        :disabled="disableSubmitButton || isWorking"
      >
        {{ submitButtonText }}
      </RelayButton>
    </div>
  </div>
</template>
