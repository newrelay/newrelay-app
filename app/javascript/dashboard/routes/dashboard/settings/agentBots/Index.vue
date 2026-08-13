<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';

import SettingsLayout from '../SettingsLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import AgentBotModal from './components/AgentBotModal.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayConfirmModal,
  RelayInput,
} from 'dashboard/components-next/relay';

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const { t } = useI18n();

const agentBots = useMapGetter('agentBots/getBots');
const uiFlags = useMapGetter('agentBots/getUIFlags');

const selectedBot = ref({});
const searchQuery = ref('');
const loading = ref({});
const modalType = ref(MODAL_TYPES.CREATE);
const showAgentBotModal = ref(false);
const showDeleteConfirmationPopup = ref(false);

const deleteMessage = computed(() =>
  t('AGENT_BOTS.DELETE.CONFIRM.MESSAGE', {
    name: selectedBot.value?.name || '',
  })
);

const filteredAgentBots = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return agentBots.value;
  return picoSearch(agentBots.value, query, ['name', 'description']);
});

const emptyMessage = computed(() =>
  searchQuery.value.trim()
    ? t('AGENT_BOTS.NO_RESULTS')
    : t('AGENT_BOTS.LIST.404')
);

const openAddModal = () => {
  modalType.value = MODAL_TYPES.CREATE;
  selectedBot.value = {};
  showAgentBotModal.value = true;
};

const hideAgentBotModal = () => {
  showAgentBotModal.value = false;
};

const openEditModal = bot => {
  modalType.value = MODAL_TYPES.EDIT;
  selectedBot.value = bot;
  showAgentBotModal.value = true;
};

const openDeletePopup = bot => {
  selectedBot.value = bot;
  showDeleteConfirmationPopup.value = true;
};

const deleteAgentBot = async id => {
  try {
    await store.dispatch('agentBots/delete', id);
    useAlert(t('AGENT_BOTS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_BOTS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedBot.value = {};
  }
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = () => {
  loading.value[selectedBot.value.id] = true;
  closeDeletePopup();
  deleteAgentBot(selectedBot.value.id);
};

const botWebhookUrl = bot => bot.outgoing_url || bot.bot_config?.webhook_url;

onMounted(() => {
  store.dispatch('agentBots/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('AGENT_BOTS.LIST.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div
        class="mb-8 overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div class="border-b border-border/40 p-4 sm:p-6">
          <h3 class="text-base font-medium text-foreground">
            {{ t('AGENT_BOTS.HEADER') }}
          </h3>
          <p class="mt-1 max-w-4xl text-sm text-muted-foreground">
            {{ t('AGENT_BOTS.DESCRIPTION') }}
          </p>
        </div>

        <div class="space-y-6 p-4 sm:p-6">
          <div class="flex items-center justify-between gap-4">
          <div class="relative w-full max-w-sm">
            <Icon
              icon="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            />
            <RelayInput
              v-model="searchQuery"
              type="search"
              :placeholder="t('AGENT_BOTS.SEARCH_PLACEHOLDER')"
              class-name="h-9 border-border/60 bg-card pl-9 text-[13.5px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <RelayButton
            class="h-9 shrink-0 px-5 font-medium shadow-sm"
            @click="openAddModal"
          >
            {{ t('AGENT_BOTS.ADD.TITLE') }}
          </RelayButton>
        </div>

        <div
          v-if="!filteredAgentBots.length"
          class="flex flex-col items-center justify-center py-32 text-center"
        >
          <p class="text-[14px] font-medium text-foreground">
            {{ emptyMessage }}
          </p>
        </div>

        <div
          v-else
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <div
            class="grid grid-cols-[2fr_2fr_1fr] gap-4 border-b border-border/40 bg-background/50 p-4"
          >
            <div class="text-[13px] font-semibold text-foreground">
              {{ t('AGENT_BOTS.LIST.TABLE_HEADER.DETAILS') }}
            </div>
            <div class="text-[13px] font-semibold text-foreground">
              {{ t('AGENT_BOTS.LIST.TABLE_HEADER.URL') }}
            </div>
            <div
              class="pr-2 text-right text-[13px] font-semibold text-foreground"
            >
              {{ t('AGENT_BOTS.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>

          <div class="divide-y divide-border/40">
            <div
              v-for="bot in filteredAgentBots"
              :key="bot.id"
              class="group grid grid-cols-[2fr_2fr_1fr] items-center gap-4 p-4 transition-colors hover:bg-muted/10"
            >
              <div class="flex min-w-0 items-center gap-4">
                <Avatar
                  v-if="bot.thumbnail"
                  :name="bot.name"
                  :src="bot.thumbnail"
                  :size="40"
                  class="flex-shrink-0"
                />
                <div
                  v-else
                  class="flex size-10 shrink-0 items-center justify-center rounded-xl border border-border/40 bg-warning/10 shadow-xs"
                >
                  <Icon icon="i-lucide-bot" class="size-5 text-warning" />
                </div>
                <div class="flex min-w-0 flex-col">
                  <div class="flex min-w-0 items-center gap-2">
                    <h4
                      class="truncate text-[14px] font-medium text-foreground"
                    >
                      {{ bot.name }}
                    </h4>
                    <span
                      v-if="bot.system_bot"
                      class="flex-shrink-0 rounded-md bg-muted px-1 py-0.5 text-xs text-foreground"
                    >
                      {{ t('AGENT_BOTS.GLOBAL_BOT_BADGE') }}
                    </span>
                  </div>
                  <p
                    v-if="bot.description"
                    class="mt-0.5 truncate text-[13px] text-muted-foreground"
                  >
                    {{ bot.description }}
                  </p>
                </div>
              </div>

              <div class="truncate pr-4 text-[13px] text-muted-foreground">
                {{ botWebhookUrl(bot) }}
              </div>

              <div class="flex items-center justify-end gap-1 pr-2 opacity-0 transition-opacity group-hover:opacity-100">
                <RelayButton
                  v-if="!bot.system_bot"
                  v-tooltip.top="t('AGENT_BOTS.EDIT.BUTTON_TEXT')"
                  variant="ghost"
                  size="icon"
                  class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
                  :disabled="loading[bot.id]"
                  @click="openEditModal(bot)"
                >
                  <Icon icon="i-lucide-pencil" class="size-3.5" />
                </RelayButton>
                <RelayButton
                  v-if="!bot.system_bot"
                  v-tooltip.top="t('AGENT_BOTS.DELETE.BUTTON_TEXT')"
                  variant="ghost"
                  size="icon"
                  class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-destructive/20 hover:bg-destructive/10 hover:text-destructive"
                  :disabled="loading[bot.id]"
                  @click="openDeletePopup(bot)"
                >
                  <Icon icon="i-lucide-trash-2" class="size-3.5" />
                </RelayButton>
              </div>
            </div>
          </div>
        </div>
        </div>
      </div>
    </template>

    <AgentBotModal
      :show="showAgentBotModal"
      :type="modalType"
      :selected-bot="selectedBot"
      @close="hideAgentBotModal"
    />

    <RelayConfirmModal
      :show="showDeleteConfirmationPopup"
      :title="t('AGENT_BOTS.DELETE.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="t('AGENT_BOTS.DELETE.CONFIRM.YES')"
      :cancel-text="t('AGENT_BOTS.DELETE.CONFIRM.NO')"
      @close="closeDeletePopup"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
