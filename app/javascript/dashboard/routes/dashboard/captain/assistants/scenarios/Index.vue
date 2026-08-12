<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { picoSearch } from '@scmmishra/pico-search';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import ScenariosCard from 'dashboard/components-next/captain/assistant/ScenariosCard.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import AddNewScenariosDialog from 'dashboard/components-next/captain/assistant/AddNewScenariosDialog.vue';
import ScenariosPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/ScenariosPageEmptyState.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const assistantId = computed(() => Number(route.params.assistantId));

const uiFlags = useMapGetter('captainScenarios/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);
const scenarios = useMapGetter('captainScenarios/getRecords');

const searchQuery = ref('');
const isCreating = ref(false);
const bulkSelectedIds = ref(new Set());

const scenariosExample = [
  {
    id: 1,
    title: 'Prospective Buyer',
    description:
      'Handle customers who are showing interest in purchasing a license',
    instruction:
      'If someone is interested in purchasing a license, ask them for following:\n\n1. How many licenses are they willing to purchase?\n2. Are they migrating from another platform?\n. Once these details are collected, do the following steps\n1. add a private note to with the information you collected using [Add Private Note](tool://add_private_note)\n2. Add label "sales" to the contact using [Add Label to Conversation](tool://add_label_to_conversation)\n3. Reply saying "one of us will reach out soon" and provide an estimated timeline for the response and [Handoff to Human](tool://handoff)',
    tools: ['add_private_note', 'add_label_to_conversation', 'handoff'],
  },
];

const filteredScenarios = computed(() => {
  const query = searchQuery.value.trim();
  const source = scenarios.value;
  if (!query) return source;
  return picoSearch(source, query, ['title', 'description', 'instruction']);
});

const isEmpty = computed(
  () => !scenarios.value.length && !isCreating.value && !searchQuery.value
);

const handleRuleSelect = id => {
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const buildSelectedCountLabel = computed(() => {
  const count = scenarios.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.UNSELECT_ALL', { count })
    : t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.SELECT_ALL', { count });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const getToolsFromInstruction = instruction => [
  ...new Set(
    [...(instruction?.matchAll(/\(tool:\/\/([^)]+)\)/g) ?? [])].map(m => m[1])
  ),
];

const startCreate = () => {
  isCreating.value = true;
  bulkSelectedIds.value = new Set();
};

const cancelCreate = () => {
  isCreating.value = false;
};

const updateScenario = async scenario => {
  try {
    await store.dispatch('captainScenarios/update', {
      id: scenario.id,
      assistantId: assistantId.value,
      ...scenario,
      tools: getToolsFromInstruction(scenario.instruction),
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const deleteScenario = async id => {
  try {
    await store.dispatch('captainScenarios/delete', {
      id,
      assistantId: assistantId.value,
    });
    bulkSelectedIds.value = new Set(
      [...bulkSelectedIds.value].filter(selectedId => selectedId !== id)
    );
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

const bulkDeleteScenarios = async ids => {
  const idsArray = ids || Array.from(bulkSelectedIds.value);
  try {
    await Promise.all(
      idsArray.map(id =>
        store.dispatch('captainScenarios/delete', {
          id,
          assistantId: assistantId.value,
        })
      )
    );
    bulkSelectedIds.value = new Set();
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

const addScenario = async scenario => {
  try {
    await store.dispatch('captainScenarios/create', {
      assistantId: assistantId.value,
      ...scenario,
      tools: getToolsFromInstruction(scenario.instruction),
    });
    isCreating.value = false;
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

const addAllExampleScenarios = async () => {
  try {
    await Promise.all(
      scenariosExample.map(scenario =>
        store.dispatch('captainScenarios/create', {
          assistantId: assistantId.value,
          ...scenario,
        })
      )
    );
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  store.dispatch('captainScenarios/get', {
    assistantId: assistantId.value,
  });
  store.dispatch('captainTools/getTools');
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.SCENARIOS.TITLE')"
    :is-fetching="isFetching"
    :is-empty="isEmpty"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #subHeader>
      <BulkSelectBar
        v-if="bulkSelectedIds.size > 0 && !isCreating"
        v-model="bulkSelectedIds"
        :all-items="scenarios"
        :select-all-label="buildSelectedCountLabel"
        :selected-count-label="selectedCountLabel"
        :delete-label="
          $t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.BULK_DELETE_BUTTON')
        "
        @bulk-delete="bulkDeleteScenarios"
      />
      <div
        v-else-if="scenarios.length > 0 || isCreating"
        class="mb-6 flex items-center justify-between gap-4"
      >
        <RelayButton
          v-if="!isCreating"
          variant="outline"
          class="shrink-0 border-border/80 bg-background shadow-sm"
          @click="startCreate"
        >
          <span class="i-lucide-plus mr-1.5 size-4" />
          {{ $t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.CREATE') }}
        </RelayButton>
        <div v-else class="flex-1" />

        <div class="relative w-full sm:w-64">
          <span
            class="i-lucide-search pointer-events-none absolute left-2.5 top-2.5 size-4 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.LIST.SEARCH_PLACEHOLDER')
            "
            type="search"
            class-name="h-9 bg-background pl-9"
          />
        </div>
      </div>
    </template>

    <template #emptyState>
      <ScenariosPageEmptyState
        @click="startCreate"
        @load-example="addAllExampleScenarios"
      />
    </template>

    <template #body>
      <AddNewScenariosDialog
        :open="isCreating"
        @update:open="isCreating = $event"
        @add="addScenario"
        @cancel="cancelCreate"
      />

      <div
        v-if="
          scenarios.length > 0 && !isCreating && filteredScenarios.length === 0
        "
        class="mb-2 mt-1"
      >
        <span class="text-sm text-muted-foreground">
          {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.SEARCH_EMPTY_MESSAGE') }}
        </span>
      </div>

      <div v-else-if="scenarios.length > 0 && !isCreating" class="space-y-4">
        <ScenariosCard
          v-for="scenario in filteredScenarios"
          :id="scenario.id"
          :key="scenario.id"
          :title="scenario.title"
          :description="scenario.description"
          :instruction="scenario.instruction"
          :tools="scenario.tools"
          :is-selected="bulkSelectedIds.has(scenario.id)"
          selectable
          @select="handleRuleSelect"
          @delete="deleteScenario(scenario.id)"
          @update="updateScenario"
        />
      </div>
    </template>
  </PageLayout>
</template>
