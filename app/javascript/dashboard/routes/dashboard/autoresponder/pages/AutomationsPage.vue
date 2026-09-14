<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import {
  RelayButton,
  RelayInput,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { AUTORESPONDER_CHANNELS } from '../constants/channels';
import CreateAutomationModal from '../components/CreateAutomationModal.vue';
import AccountSwitcher from '../components/AccountSwitcher.vue';
import { useAutoresponderAccount } from '../composables/useAutoresponderAccount';

const { t } = useI18n();
const store = useStore();
const { matchesActiveInbox } = useAutoresponderAccount();

const isCreateModalOpen = ref(false);
const searchQuery = ref('');
const activeTab = ref('All');
const channelFilter = ref('All Channels');
const statusFilter = ref('All Status');

onMounted(() => {
  store.dispatch('commentAutomationCampaigns/get');
});

const campaigns = useMapGetter('commentAutomationCampaigns/getCampaigns');

const channelName = channelType =>
  AUTORESPONDER_CHANNELS.find(c => c.type === channelType)?.name || channelType;

const tabs = computed(() => [
  { id: 'All', label: t('AUTORESPONDER.AUTOMATIONS.TAB_ALL') },
  { id: 'Active', label: t('AUTORESPONDER.AUTOMATIONS.TAB_ACTIVE') },
  { id: 'Paused', label: t('AUTORESPONDER.AUTOMATIONS.TAB_PAUSED') },
]);

const filteredAutomations = computed(() => {
  let list = campaigns.value.filter(c => matchesActiveInbox(c.inbox));
  if (activeTab.value === 'Active') list = list.filter(c => c.is_active);
  if (activeTab.value === 'Paused') list = list.filter(c => !c.is_active);
  if (channelFilter.value !== 'All Channels') {
    list = list.filter(
      c => channelName(c.inbox.channel_type) === channelFilter.value
    );
  }
  if (statusFilter.value !== 'All Status') {
    const wantActive = statusFilter.value === 'Active';
    list = list.filter(c => c.is_active === wantActive);
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(c => c.name.toLowerCase().includes(q));
  }
  return list;
});

function clearFilters() {
  searchQuery.value = '';
  activeTab.value = 'All';
  channelFilter.value = 'All Channels';
  statusFilter.value = 'All Status';
}

function toggleActive(campaign) {
  store.dispatch('commentAutomationCampaigns/update', {
    id: campaign.id,
    campaign: { is_active: !campaign.is_active },
  });
}

function deleteCampaign(campaign) {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('AUTORESPONDER.AUTOMATIONS.DELETE_CONFIRM'))) return;
  store.dispatch('commentAutomationCampaigns/delete', campaign.id);
}
</script>

<template>
  <div class="min-w-0 flex-1 overflow-y-auto w-full bg-background p-6">
    <div
      class="mx-auto flex min-h-[calc(100vh-8rem)] min-w-0 max-w-7xl flex-col"
    >
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6"
      >
        <div>
          <h1 class="text-[16px] font-medium tracking-tight text-foreground">
            {{ t('AUTORESPONDER.AUTOMATIONS.TITLE') }}
          </h1>
          <p class="text-[13.5px] text-muted-foreground mt-1">
            {{ t('AUTORESPONDER.AUTOMATIONS.SUBTITLE') }}
          </p>
        </div>
        <div class="flex min-w-0 flex-wrap items-center gap-3">
          <AccountSwitcher />
          <RelayButton
            class="w-full gap-2 sm:w-auto"
            @click="isCreateModalOpen = true"
          >
            <span class="i-lucide-plus size-4" />
            {{ t('AUTORESPONDER.AUTOMATIONS.CREATE_AUTOMATION') }}
          </RelayButton>
        </div>
      </div>

      <div class="flex flex-wrap items-center gap-3 mb-6">
        <div class="relative w-full sm:w-[280px]">
          <span
            class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            :placeholder="t('AUTORESPONDER.AUTOMATIONS.SEARCH_PLACEHOLDER')"
            class-name="pl-9 bg-background"
          />
        </div>

        <RelayDropdownMenu>
          <RelayDropdownMenuTrigger as-child>
            <RelayButton
              variant="outline"
              class="gap-2 text-[13.5px] font-normal"
            >
              {{ channelFilter }}
              <span
                class="i-lucide-chevron-down size-4 text-muted-foreground"
              />
            </RelayButton>
          </RelayDropdownMenuTrigger>
          <RelayDropdownMenuContent align="start" class="w-40">
            <RelayDropdownMenuItem @click="channelFilter = 'All Channels'">
              {{ t('AUTORESPONDER.COMMON.ALL_CHANNELS') }}
            </RelayDropdownMenuItem>
            <RelayDropdownMenuItem
              v-for="c in AUTORESPONDER_CHANNELS"
              :key="c.type"
              @click="channelFilter = c.name"
            >
              {{ c.name }}
            </RelayDropdownMenuItem>
          </RelayDropdownMenuContent>
        </RelayDropdownMenu>

        <RelayDropdownMenu>
          <RelayDropdownMenuTrigger as-child>
            <RelayButton
              variant="outline"
              class="gap-2 text-[13.5px] font-normal"
            >
              {{ statusFilter }}
              <span
                class="i-lucide-chevron-down size-4 text-muted-foreground"
              />
            </RelayButton>
          </RelayDropdownMenuTrigger>
          <RelayDropdownMenuContent align="start" class="w-40">
            <RelayDropdownMenuItem @click="statusFilter = 'All Status'">
              {{ t('AUTORESPONDER.COMMON.ALL_STATUS') }}
            </RelayDropdownMenuItem>
            <RelayDropdownMenuItem
              v-for="s in ['Active', 'Paused']"
              :key="s"
              @click="statusFilter = s"
            >
              {{ s }}
            </RelayDropdownMenuItem>
          </RelayDropdownMenuContent>
        </RelayDropdownMenu>

        <button
          type="button"
          class="text-[13.5px] font-medium text-primary hover:underline ml-1"
          @click="clearFilters"
        >
          {{ t('AUTORESPONDER.COMMON.CLEAR_ALL') }}
        </button>
      </div>

      <div
        class="relative border-b border-border w-full flex items-center justify-between mb-6"
      >
        <div class="flex items-center gap-8 overflow-x-auto hide-scrollbar">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            class="relative pb-3 text-[13.5px] font-medium transition-colors whitespace-nowrap"
            :class="
              activeTab === tab.id
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            "
            @click="activeTab = tab.id"
          >
            {{ tab.label }}
            <div
              v-if="activeTab === tab.id"
              class="absolute bottom-0 left-0 right-0 h-0.5 bg-primary rounded-full"
            />
          </button>
        </div>
      </div>

      <div
        class="bg-card border border-border rounded-xl shadow-sm overflow-hidden flex flex-col flex-1 min-w-0"
      >
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr class="border-b border-border bg-muted/20">
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_AUTOMATION') }}
                </th>
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground w-1/4"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_TRIGGER') }}
                </th>
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground w-32"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_CHANNEL') }}
                </th>
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground w-32"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_STATUS') }}
                </th>
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground w-24"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_RESPONSES') }}
                </th>
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground w-28"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_UPDATED') }}
                </th>
                <th
                  class="px-4 py-3 text-[12px] font-medium text-muted-foreground w-16 text-center"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border">
              <tr
                v-for="item in filteredAutomations"
                :key="item.id"
                class="hover:bg-accent transition-colors group bg-background"
              >
                <td class="px-4 py-4">
                  <div class="flex items-start gap-3">
                    <div
                      class="size-8 rounded-lg border border-border bg-card shadow-xs flex items-center justify-center shrink-0 mt-0.5"
                    >
                      <span
                        :class="getInboxIconByType(item.inbox.channel_type)"
                        class="size-4 text-foreground"
                      />
                    </div>
                    <div>
                      <span class="text-sm font-medium text-foreground">{{
                        item.name
                      }}</span>
                      <p class="text-[13px] text-muted-foreground mt-0.5">
                        {{ item.inbox.name }} &bull;
                        {{ t('AUTORESPONDER.AUTOMATIONS.POST_ID_LABEL') }}
                        {{ item.post_id }}
                      </p>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <template v-if="item.trigger">
                    <div class="text-[13.5px] font-medium text-foreground">
                      {{ t('AUTORESPONDER.AUTOMATIONS.WHEN_COMMENT') }}
                    </div>
                    <div class="text-[13px] text-muted-foreground mt-0.5">
                      {{
                        t(
                          item.trigger.match_type === 'exact'
                            ? 'AUTORESPONDER.AUTOMATIONS.KEYWORD_EXACT'
                            : 'AUTORESPONDER.AUTOMATIONS.KEYWORD_CONTAINS',
                          { keyword: item.trigger.keyword }
                        )
                      }}
                    </div>
                  </template>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <div class="flex items-center gap-1.5">
                    <span
                      :class="getInboxIconByType(item.inbox.channel_type)"
                      class="size-3.5 text-muted-foreground"
                    />
                    <span class="text-[13.5px] font-medium text-foreground">{{
                      channelName(item.inbox.channel_type)
                    }}</span>
                  </div>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <button
                    type="button"
                    class="flex items-center gap-1.5"
                    @click="toggleActive(item)"
                  >
                    <div
                      class="size-1.5 rounded-full"
                      :class="
                        item.is_active ? 'bg-primary' : 'bg-muted-foreground'
                      "
                    />
                    <span
                      class="text-[13px] font-medium"
                      :class="
                        item.is_active
                          ? 'text-primary'
                          : 'text-muted-foreground'
                      "
                    >
                      {{
                        item.is_active
                          ? t('AUTORESPONDER.AUTOMATIONS.STATUS_ACTIVE')
                          : t('AUTORESPONDER.AUTOMATIONS.STATUS_PAUSED')
                      }}
                    </span>
                  </button>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <span class="text-[13.5px] font-semibold text-foreground">{{
                    item.responses_count
                  }}</span>
                </td>
                <td
                  class="px-4 py-4 align-top pt-4 text-[13px] text-muted-foreground"
                >
                  {{ dynamicTime(item.updated_at) }}
                </td>
                <td class="px-4 py-4 align-top pt-4 text-center">
                  <RelayDropdownMenu>
                    <RelayDropdownMenuTrigger as-child>
                      <button
                        type="button"
                        class="p-1.5 text-muted-foreground hover:bg-accent rounded-md transition-colors outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                      >
                        <span class="i-lucide-more-horizontal size-4" />
                      </button>
                    </RelayDropdownMenuTrigger>
                    <RelayDropdownMenuContent align="end" class="w-40">
                      <RelayDropdownMenuItem
                        destructive
                        @click="deleteCampaign(item)"
                      >
                        {{ t('AUTORESPONDER.COMMON.DELETE') }}
                      </RelayDropdownMenuItem>
                    </RelayDropdownMenuContent>
                  </RelayDropdownMenu>
                </td>
              </tr>
              <tr v-if="filteredAutomations.length === 0">
                <td
                  colspan="7"
                  class="px-4 py-16 text-center text-sm text-muted-foreground"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.EMPTY_STATE') }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div
          class="border-t border-border p-4 flex items-center justify-between mt-auto bg-card"
        >
          <div class="text-[13px] text-muted-foreground">
            {{
              t('AUTORESPONDER.AUTOMATIONS.SHOWING_COUNT', {
                count: filteredAutomations.length,
                total: campaigns.length,
              })
            }}
          </div>
        </div>
      </div>
    </div>

    <CreateAutomationModal v-model:open="isCreateModalOpen" />
  </div>
</template>
