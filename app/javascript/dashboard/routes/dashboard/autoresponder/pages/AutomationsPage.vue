<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS, CHANNEL_NAMES } from '../constants/channels';
import CreateAutomationModal from '../components/CreateAutomationModal.vue';

const { t } = useI18n();
const isCreateModalOpen = ref(false);
const searchQuery = ref('');
const activeTab = ref('All');
const channelFilter = ref('All Channels');
const typeFilter = ref('All Types');
const statusFilter = ref('All Status');

const tabs = computed(() => [
  { id: 'All', count: 12 },
  { id: 'Active', count: 8 },
  { id: 'Paused', count: 2 },
  { id: 'Draft', count: 1 },
  { id: 'Disabled', count: 1 },
]);

const automations = ref([
  {
    id: 1,
    name: 'Instagram Comment Reply',
    type: 'Comment',
    description: 'Reply to comments containing pricing keywords',
    triggerName: 'When someone comments',
    triggerDesc: 'Contains "price"',
    channel: 'Instagram',
    status: 'Active',
    responses: 342,
    updated: '2h ago',
  },
  {
    id: 2,
    name: 'Welcome Message',
    type: 'Message',
    description: 'Send welcome message to new followers',
    triggerName: 'When someone sends a message',
    triggerDesc: 'Any message',
    channel: 'Instagram',
    status: 'Active',
    responses: 287,
    updated: '5h ago',
  },
  {
    id: 3,
    name: 'WhatsApp Quick Reply',
    type: 'Message',
    description: 'Auto-reply to common questions',
    triggerName: 'When someone sends a message',
    triggerDesc: 'Contains keywords',
    channel: 'WhatsApp',
    status: 'Active',
    responses: 198,
    updated: '1d ago',
  },
  {
    id: 4,
    name: 'Facebook Page Comment',
    type: 'Comment',
    description: 'Reply to comments on Facebook page',
    triggerName: 'When someone comments',
    triggerDesc: 'Any comment',
    channel: 'Facebook',
    status: 'Active',
    responses: 142,
    updated: '1d ago',
  },
  {
    id: 5,
    name: 'Story Mention Reply',
    type: 'Message',
    description: 'Reply when mentioned in story',
    triggerName: 'When someone mentions your story',
    triggerDesc: 'Any mention',
    channel: 'Instagram',
    status: 'Paused',
    responses: 64,
    updated: '2d ago',
  },
  {
    id: 6,
    name: 'Out of Hours Reply',
    type: 'Message',
    description: 'Auto-reply outside business hours',
    triggerName: 'When someone sends a message',
    triggerDesc: 'Outside business hours',
    channel: 'Instagram',
    status: 'Paused',
    responses: 38,
    updated: '3d ago',
  },
  {
    id: 7,
    name: 'Support Fallback',
    type: 'Message',
    description: 'Fallback reply when no match found',
    triggerName: 'When no other rule matches',
    triggerDesc: 'Any message',
    channel: 'WhatsApp',
    status: 'Draft',
    responses: 0,
    updated: '3d ago',
  },
  {
    id: 8,
    name: 'Promotions Comment',
    type: 'Comment',
    description: 'Reply to promo related comments',
    triggerName: 'When someone comments',
    triggerDesc: 'Contains "offer"',
    channel: 'Instagram',
    status: 'Disabled',
    responses: 0,
    updated: '5d ago',
  },
]);

const filteredAutomations = computed(() => {
  let list = automations.value;
  if (activeTab.value !== 'All') {
    list = list.filter(item => item.status === activeTab.value);
  }
  if (channelFilter.value !== 'All Channels') {
    list = list.filter(item => item.channel === channelFilter.value);
  }
  if (typeFilter.value !== 'All Types') {
    list = list.filter(item => item.type === typeFilter.value);
  }
  if (statusFilter.value !== 'All Status') {
    list = list.filter(item => item.status === statusFilter.value);
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(item => item.name.toLowerCase().includes(q));
  }
  return list;
});

function clearFilters() {
  searchQuery.value = '';
  activeTab.value = 'All';
  channelFilter.value = 'All Channels';
  typeFilter.value = 'All Types';
  statusFilter.value = 'All Status';
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full bg-background p-6 lg:p-8">
    <div class="max-w-7xl mx-auto flex flex-col min-h-[calc(100vh-8rem)]">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6"
      >
        <div>
          <h1 class="text-xl font-semibold tracking-tight text-foreground">
            {{ t('AUTORESPONDER.AUTOMATIONS.TITLE') }}
          </h1>
          <p class="text-sm text-muted-foreground mt-1">
            {{ t('AUTORESPONDER.AUTOMATIONS.SUBTITLE') }}
          </p>
        </div>
        <RelayButton class="gap-2" @click="isCreateModalOpen = true">
          <span class="i-lucide-plus size-4" />
          {{ t('AUTORESPONDER.AUTOMATIONS.CREATE_AUTOMATION') }}
        </RelayButton>
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
              v-for="c in CHANNEL_NAMES"
              :key="c"
              @click="channelFilter = c"
            >
              {{ c }}
            </RelayDropdownMenuItem>
          </RelayDropdownMenuContent>
        </RelayDropdownMenu>

        <RelayDropdownMenu>
          <RelayDropdownMenuTrigger as-child>
            <RelayButton
              variant="outline"
              class="gap-2 text-[13.5px] font-normal"
            >
              {{ typeFilter }}
              <span
                class="i-lucide-chevron-down size-4 text-muted-foreground"
              />
            </RelayButton>
          </RelayDropdownMenuTrigger>
          <RelayDropdownMenuContent align="start" class="w-40">
            <RelayDropdownMenuItem @click="typeFilter = 'All Types'">
              {{ t('AUTORESPONDER.COMMON.ALL_TYPES') }}
            </RelayDropdownMenuItem>
            <RelayDropdownMenuItem @click="typeFilter = 'Comment'">
              {{ t('AUTORESPONDER.COMMON.TYPE_COMMENT') }}
            </RelayDropdownMenuItem>
            <RelayDropdownMenuItem @click="typeFilter = 'Message'">
              {{ t('AUTORESPONDER.COMMON.TYPE_MESSAGE') }}
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
              v-for="s in ['Active', 'Paused', 'Draft', 'Disabled']"
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
        class="flex items-center gap-6 mb-6 border-b border-border w-full overflow-x-auto hide-scrollbar"
      >
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          class="flex items-center gap-2 pb-3 text-[13.5px] transition-colors whitespace-nowrap border-b-2 -mb-[1px] font-medium"
          :class="
            activeTab === tab.id
              ? 'border-primary text-primary'
              : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted-foreground/30'
          "
          @click="activeTab = tab.id"
        >
          {{ tab.id }}
          <span
            class="text-[11px] px-1.5 py-0.5 rounded-sm"
            :class="
              activeTab === tab.id
                ? 'bg-primary/10 text-primary'
                : 'bg-muted text-muted-foreground'
            "
          >
            {{ tab.count }}
          </span>
        </button>
      </div>

      <div
        class="bg-card border border-border rounded-xl shadow-sm overflow-hidden flex flex-col flex-1"
      >
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr class="border-b border-border bg-muted/20">
                <th class="px-4 py-3 text-xs font-medium text-muted-foreground">
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_AUTOMATION') }}
                </th>
                <th
                  class="px-4 py-3 text-xs font-medium text-muted-foreground w-1/4"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_TRIGGER') }}
                </th>
                <th
                  class="px-4 py-3 text-xs font-medium text-muted-foreground w-32"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_CHANNEL') }}
                </th>
                <th
                  class="px-4 py-3 text-xs font-medium text-muted-foreground w-32"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_STATUS') }}
                </th>
                <th
                  class="px-4 py-3 text-xs font-medium text-muted-foreground w-24"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_RESPONSES') }}
                </th>
                <th
                  class="px-4 py-3 text-xs font-medium text-muted-foreground w-28"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_UPDATED') }}
                </th>
                <th
                  class="px-4 py-3 text-xs font-medium text-muted-foreground w-16 text-center"
                >
                  {{ t('AUTORESPONDER.AUTOMATIONS.TABLE_ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border">
              <tr
                v-for="item in filteredAutomations"
                :key="item.id"
                class="hover:bg-muted/30 transition-colors group bg-background"
              >
                <td class="px-4 py-4">
                  <div class="flex items-start gap-3">
                    <div
                      class="size-8 rounded-lg border border-border bg-card shadow-xs flex items-center justify-center shrink-0 mt-0.5"
                    >
                      <img
                        :src="CHANNEL_LOGO_URLS[item.channel]"
                        class="size-4 opacity-90"
                      />
                    </div>
                    <div>
                      <div class="flex items-center gap-2">
                        <span class="text-sm font-medium text-foreground">{{
                          item.name
                        }}</span>
                        <span
                          class="px-1.5 py-0.5 rounded text-[10px] font-medium bg-primary/10 text-primary"
                        >
                          {{ item.type }}
                        </span>
                      </div>
                      <p class="text-[13px] text-muted-foreground mt-0.5">
                        {{ item.description }}
                      </p>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <div class="text-[13.5px] font-medium text-foreground">
                    {{ item.triggerName }}
                  </div>
                  <div class="text-[13px] text-muted-foreground mt-0.5">
                    {{ item.triggerDesc }}
                  </div>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <div class="flex items-center gap-1.5">
                    <img
                      :src="CHANNEL_LOGO_URLS[item.channel]"
                      class="size-3.5 opacity-90"
                    />
                    <span class="text-[13.5px] font-medium text-foreground">{{
                      item.channel
                    }}</span>
                  </div>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <div class="flex items-center gap-1.5">
                    <div
                      class="size-1.5 rounded-full"
                      :class="
                        item.status === 'Active'
                          ? 'bg-primary'
                          : 'bg-muted-foreground'
                      "
                    />
                    <span
                      class="text-[13px] font-medium"
                      :class="
                        item.status === 'Active'
                          ? 'text-primary'
                          : 'text-muted-foreground'
                      "
                    >
                      {{ item.status }}
                    </span>
                  </div>
                </td>
                <td class="px-4 py-4 align-top pt-4">
                  <span class="text-[13.5px] font-semibold text-foreground">{{
                    item.responses
                  }}</span>
                </td>
                <td
                  class="px-4 py-4 align-top pt-4 text-[13px] text-muted-foreground"
                >
                  {{ item.updated }}
                </td>
                <td class="px-4 py-4 align-top pt-4 text-center">
                  <RelayDropdownMenu>
                    <RelayDropdownMenuTrigger as-child>
                      <button
                        type="button"
                        class="p-1.5 text-muted-foreground hover:bg-muted rounded-md transition-colors outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                      >
                        <span class="i-lucide-more-horizontal size-4" />
                      </button>
                    </RelayDropdownMenuTrigger>
                    <RelayDropdownMenuContent align="end" class="w-40">
                      <RelayDropdownMenuItem>
                        {{ t('AUTORESPONDER.COMMON.EDIT_AUTOMATION') }}
                      </RelayDropdownMenuItem>
                      <RelayDropdownMenuItem>
                        {{ t('AUTORESPONDER.COMMON.DUPLICATE') }}
                      </RelayDropdownMenuItem>
                      <RelayDropdownMenuItem>
                        {{ t('AUTORESPONDER.AUTOMATIONS.VIEW_ACTIVITY') }}
                      </RelayDropdownMenuItem>
                      <RelayDropdownMenuItem destructive>
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
                total: automations.length,
              })
            }}
          </div>
        </div>
      </div>
    </div>

    <CreateAutomationModal v-model:open="isCreateModalOpen" />
  </div>
</template>
