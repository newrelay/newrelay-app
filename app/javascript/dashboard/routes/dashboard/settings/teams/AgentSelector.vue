<script setup>
import { computed } from 'vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';
import Avatar from 'next/avatar/Avatar.vue';
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
</script>

<template>
  <div
    class="overflow-hidden rounded-xl border border-border/70 bg-card shadow-xs"
  >
    <div
      class="grid grid-cols-[1.5fr_1.5fr_1fr] gap-4 border-b border-border/50 bg-muted/25 px-5 py-3.5 capitalize"
    >
      <div class="flex items-center gap-3">
        <RelayCheckbox
          :model-value="allAgentsSelected"
          :indeterminate="someAgentsSelected"
          :title="$t('TEAMS_SETTINGS.AGENTS.SELECT_ALL')"
          @change="toggleSelectAll"
        />
        <span class="text-[14px] font-semibold text-muted-foreground">
          {{ t('TEAMS_SETTINGS.AGENTS.AGENT') }}
        </span>
      </div>
      <div class="text-[14px] font-semibold text-muted-foreground">
        {{ t('TEAMS_SETTINGS.AGENTS.EMAIL') }}
      </div>
      <div class="text-[14px] font-semibold text-muted-foreground">
        {{ t('TEAMS_SETTINGS.AGENTS.ROLE') }}
      </div>
    </div>

    <div class="max-h-[340px] divide-y divide-border/40 overflow-y-auto">
      <button
        v-for="agent in agentList"
        :key="agent.id"
        type="button"
        class="grid w-full cursor-pointer grid-cols-[1.5fr_1.5fr_1fr] items-center gap-4 px-5 py-3 text-left transition-colors hover:bg-muted/15"
        :class="isAgentSelected(agent.id) ? 'bg-primary/[0.02]' : ''"
        @click="handleSelectAgent(agent.id)"
      >
        <div class="flex items-center gap-3">
          <RelayCheckbox
            class="pointer-events-none"
            :model-value="isAgentSelected(agent.id)"
          />
          <div class="flex min-w-0 items-center gap-2.5">
            <Avatar
              :src="agent.thumbnail"
              :name="agent.name"
              :status="agent.availability_status"
              :size="28"
              hide-offline-status
              rounded-full
              class="shrink-0"
            />
            <span class="truncate text-[13.5px] font-medium text-foreground">
              {{ agent.name }}
            </span>
          </div>
        </div>
        <div class="truncate text-[13.5px] text-muted-foreground">
          {{ agent.email || '---' }}
        </div>
        <div>
          <span
            class="inline-flex rounded bg-muted px-2 py-0.5 text-[11.5px] font-medium capitalize text-muted-foreground"
          >
            {{ agent.role || '---' }}
          </span>
        </div>
      </button>
    </div>

    <div
      class="flex items-center justify-between border-t border-border/40 bg-muted/10 px-5 py-3.5"
    >
      <span class="text-[13px] text-muted-foreground">
        <strong class="font-medium text-foreground">
          {{ selectedAgentCount }}
        </strong>
        {{
          t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT_SHORT', {
            total: agentList.length,
          })
        }}
      </span>
      <RelayButton
        type="submit"
        class="h-9 rounded-lg px-5 text-[13.5px] font-medium shadow-xs"
        :disabled="disableSubmitButton || isWorking"
      >
        {{ submitButtonText }}
      </RelayButton>
    </div>
  </div>
</template>
