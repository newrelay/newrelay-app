<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';

import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['close', 'createAssistant']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const assistants = useMapGetter('captainAssistants/getRecords');

const currentAssistantId = computed(() => route.params.assistantId);

const isAssistantActive = assistant => {
  return assistant.id === Number(currentAssistantId.value);
};

const fetchDataForRoute = async (routeName, assistantId) => {
  const dataFetchMap = {
    captain_assistants_responses_index: async () => {
      await store.dispatch('captainResponses/get', { assistantId });
      await store.dispatch('captainResponses/fetchPendingCount', assistantId);
    },
    captain_assistants_responses_pending: async () => {
      await store.dispatch('captainResponses/get', {
        assistantId,
        status: 'pending',
      });
    },
    captain_assistants_documents_index: async () => {
      await store.dispatch('captainDocuments/get', { assistantId });
    },
    captain_assistants_scenarios_index: async () => {
      await store.dispatch('captainScenarios/get', { assistantId });
    },
    captain_assistants_playground_index: () => {
      // Playground doesn't need pre-fetching, it loads on interaction
    },
    captain_assistants_inboxes_index: async () => {
      await store.dispatch('captainInboxes/get', { assistantId });
    },
    captain_tools_index: async () => {
      await store.dispatch('captainCustomTools/get', { page: 1 });
    },
    captain_assistants_settings_index: async () => {
      await store.dispatch('captainAssistants/show', assistantId);
    },
  };

  const fetchFn = dataFetchMap[routeName];
  if (fetchFn) {
    await fetchFn();
  }
};

const handleAssistantChange = async assistant => {
  if (isAssistantActive(assistant)) return;

  const currentRouteName = route.name;
  const targetRouteName =
    currentRouteName || 'captain_assistants_responses_index';

  await fetchDataForRoute(targetRouteName, assistant.id);

  await router.push({
    name: targetRouteName,
    params: {
      accountId: route.params.accountId,
      assistantId: assistant.id,
    },
  });

  emit('close');
};

const openCreateAssistantDialog = () => {
  emit('createAssistant');
  emit('close');
};
</script>

<template>
  <div
    class="absolute z-[110] my-0.5 flex w-[230px] flex-col overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
  >
    <div
      class="mb-1 flex items-start justify-between gap-2 border-b border-border/40 px-3 py-2"
    >
      <div class="min-w-0 flex-1">
        <p class="text-[13px] font-semibold text-foreground">
          {{ t('CAPTAIN.ASSISTANT_SWITCHER.ASSISTANTS') }}
        </p>
        <p class="mt-0.5 text-[12.5px] leading-snug text-muted-foreground">
          {{ t('CAPTAIN.ASSISTANT_SWITCHER.SWITCH_ASSISTANT') }}
        </p>
      </div>
      <RelayButton
        variant="outline"
        size="sm"
        class="h-7 shrink-0 rounded-full border-border px-3 text-[12px] hover:bg-muted hover:border-border"
        @click="openCreateAssistantDialog"
      >
        <span class="i-lucide-plus mr-1 size-3" />
        {{ t('CAPTAIN.ASSISTANT_SWITCHER.NEW_ASSISTANT') }}
      </RelayButton>
    </div>
    <button
      v-for="assistant in assistants"
      :key="assistant.id"
      type="button"
      class="reset-base flex w-full cursor-pointer items-center rounded-sm px-2 py-2 text-left hover:bg-accent hover:text-accent-foreground"
      @click="handleAssistantChange(assistant)"
    >
      <span
        class="i-lucide-brain-circuit mr-2 size-4 shrink-0"
        :class="
          isAssistantActive(assistant) ? 'text-primary' : 'text-foreground'
        "
      />
      <span class="min-w-0 flex-1 truncate text-[13.5px] text-foreground">
        {{ assistant.name || '' }}
      </span>
      <span
        v-if="isAssistantActive(assistant)"
        class="i-lucide-check ml-auto size-4 shrink-0 text-primary"
      />
    </button>
    <p
      v-if="assistants.length === 0"
      class="px-3 py-2 text-sm text-muted-foreground"
    >
      {{ t('CAPTAIN.ASSISTANT_SWITCHER.EMPTY_LIST') }}
    </p>
  </div>
</template>
