<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import {
  RelayInput,
  RelayBadge,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import {
  AUTORESPONDER_CHANNELS,
  CHANNEL_NAME_BY_TYPE,
} from '../constants/channels';
import ActivityDetailsPanel from '../components/ActivityDetailsPanel.vue';

const { t } = useI18n();
const store = useStore();

const searchQuery = ref('');
const activeTab = ref('All');
const channelFilter = ref('All Channels');
const isPreviewOpen = ref(false);
const selectedActivity = ref(null);

onMounted(() => {
  store.dispatch('commentAutomationMessageLogs/get');
});

const logs = useMapGetter('commentAutomationMessageLogs/getMessageLogs');

const STATUS_BADGE_CLASS = {
  pending: 'bg-muted text-muted-foreground',
  public_replied: 'bg-blue-500/10 text-blue-600 dark:text-blue-400',
  dm_sent: 'bg-primary/10 text-primary',
  dm_failed: 'bg-destructive/10 text-destructive',
  engaged: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
};

const statusLabel = status =>
  t(`AUTORESPONDER.ACTIVITY.STATUS_${status.toUpperCase()}`);

const tabs = computed(() => [
  {
    id: 'All',
    count: logs.value.length,
    label: t('AUTORESPONDER.ACTIVITY.TAB_ALL'),
  },
  {
    id: 'Engaged',
    count: logs.value.filter(l => l.status === 'engaged').length,
    label: t('AUTORESPONDER.ACTIVITY.TAB_ENGAGED'),
  },
  {
    id: 'Failed',
    count: logs.value.filter(l => l.status === 'dm_failed').length,
    label: t('AUTORESPONDER.ACTIVITY.TAB_FAILED'),
  },
]);

const filteredActivities = computed(() => {
  let result = logs.value;
  if (activeTab.value === 'Engaged') {
    result = result.filter(l => l.status === 'engaged');
  } else if (activeTab.value === 'Failed') {
    result = result.filter(l => l.status === 'dm_failed');
  }
  if (channelFilter.value !== 'All Channels') {
    result = result.filter(
      l => CHANNEL_NAME_BY_TYPE[l.inbox.channel_type] === channelFilter.value
    );
  }
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      l =>
        l.campaign.name.toLowerCase().includes(query) ||
        l.comment_id.toLowerCase().includes(query) ||
        (l.contact?.name || '').toLowerCase().includes(query)
    );
  }
  return result;
});

function openPreview(item) {
  selectedActivity.value = item;
  isPreviewOpen.value = true;
}
</script>

<template>
  <div
    class="h-[calc(100vh-80px)] overflow-y-auto bg-muted/20 p-6 md:p-8 hide-scrollbar flex flex-col"
  >
    <div class="max-w-[1600px] w-full mx-auto flex-1 flex flex-col min-h-0">
      <div class="mb-6">
        <h1 class="text-xl font-semibold tracking-tight text-foreground">
          {{ t('AUTORESPONDER.ACTIVITY.TITLE') }}
        </h1>
        <p class="text-sm text-muted-foreground mt-1">
          {{ t('AUTORESPONDER.ACTIVITY.SUBTITLE') }}
        </p>
      </div>

      <div class="flex flex-wrap items-center gap-3 mb-6">
        <div class="relative w-full sm:w-[240px]">
          <span
            class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            :placeholder="t('AUTORESPONDER.ACTIVITY.SEARCH_PLACEHOLDER')"
            class-name="pl-9 bg-background h-9"
          />
        </div>

        <RelayDropdownMenu>
          <RelayDropdownMenuTrigger as-child>
            <button
              type="button"
              class="h-9 px-3 flex items-center gap-2 text-[13.5px] font-normal rounded-md border border-border bg-background"
            >
              {{ channelFilter }}
              <span
                class="i-lucide-chevron-down size-4 text-muted-foreground"
              />
            </button>
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
      </div>

      <div class="relative border-b border-border w-full mb-6">
        <div class="flex items-center gap-6 overflow-x-auto hide-scrollbar">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            class="relative flex items-center gap-2 pb-3.5 text-[13.5px] font-medium transition-colors whitespace-nowrap"
            :class="
              activeTab === tab.id
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            "
            @click="activeTab = tab.id"
          >
            {{ tab.label }}
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
            <div
              v-if="activeTab === tab.id"
              class="absolute -bottom-[1px] left-0 right-0 h-[2px] bg-primary rounded-full z-10"
            />
          </button>
        </div>
      </div>

      <div
        class="flex flex-col lg:flex-row gap-6 items-start w-full relative h-full min-h-0 pb-10"
      >
        <div
          class="bg-card border border-border rounded-xl shadow-sm overflow-hidden flex flex-col flex-1 min-w-0 transition-all duration-300"
        >
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse min-w-[1000px]">
              <thead>
                <tr class="border-b border-border bg-muted/20">
                  <th
                    class="px-6 py-3.5 text-sm font-medium text-muted-foreground w-32"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_TIME') }}
                  </th>
                  <th
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground w-28"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_CHANNEL') }}
                  </th>
                  <th
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground min-w-[140px]"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_CONTACT') }}
                  </th>
                  <th
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground min-w-[160px]"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_AUTOMATION') }}
                  </th>
                  <th
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground min-w-[160px]"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_COMMENT') }}
                  </th>
                  <th
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground w-32"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_STATUS') }}
                  </th>
                  <th
                    class="px-6 py-3.5 text-sm font-medium text-muted-foreground w-20 text-center"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_DETAILS') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-border">
                <tr
                  v-for="item in filteredActivities"
                  :key="item.id"
                  class="hover:bg-muted/30 transition-colors group cursor-pointer"
                  :class="
                    selectedActivity && selectedActivity.id === item.id
                      ? 'bg-primary/5'
                      : ''
                  "
                  @click="openPreview(item)"
                >
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-[13px] text-foreground font-medium">
                      {{ dynamicTime(item.sent_at || item.created_at) }}
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="flex items-center gap-2">
                      <span
                        :class="getInboxIconByType(item.inbox.channel_type)"
                        class="size-4 text-foreground"
                      />
                      <span class="text-[13px] text-foreground font-medium">{{
                        CHANNEL_NAME_BY_TYPE[item.inbox.channel_type]
                      }}</span>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div v-if="item.contact" class="flex items-center gap-2.5">
                      <img
                        :src="item.contact.avatar_url"
                        class="size-7 rounded-full object-cover bg-muted"
                      />
                      <span class="text-[13px] font-medium text-foreground">{{
                        item.contact.name
                      }}</span>
                    </div>
                    <div v-else class="flex items-center gap-2.5">
                      <div
                        class="size-7 rounded-full bg-muted flex items-center justify-center shrink-0"
                      >
                        <span
                          class="i-lucide-user size-3.5 text-muted-foreground"
                        />
                      </div>
                      <div class="flex flex-col">
                        <span class="text-[13px] font-medium text-foreground">{{
                          t('AUTORESPONDER.ACTIVITY.UNKNOWN_CONTACT')
                        }}</span>
                        <span class="text-xs text-muted-foreground">{{
                          item.commenter_id
                        }}</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="flex flex-col gap-0.5">
                      <span class="text-[13px] font-medium text-foreground">{{
                        item.campaign.name
                      }}</span>
                      <span class="text-xs text-muted-foreground">{{
                        t('AUTORESPONDER.ACTIVITY.KEYWORD_LABEL', {
                          keyword: item.trigger.keyword,
                        })
                      }}</span>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <span class="text-[13px] text-muted-foreground break-all">{{
                      item.comment_id
                    }}</span>
                  </td>
                  <td class="px-4 py-4">
                    <RelayBadge
                      variant="secondary"
                      class="border-none font-medium px-2.5 py-0.5 rounded-md"
                      :class="STATUS_BADGE_CLASS[item.status]"
                    >
                      {{ statusLabel(item.status) }}
                    </RelayBadge>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <button
                      type="button"
                      class="h-7 text-xs px-3 font-medium rounded-md border border-border hover:bg-muted transition-colors"
                      @click.stop="openPreview(item)"
                    >
                      {{ t('AUTORESPONDER.ACTIVITY.VIEW') }}
                    </button>
                  </td>
                </tr>
                <tr v-if="filteredActivities.length === 0">
                  <td
                    colspan="7"
                    class="px-4 py-16 text-center text-sm text-muted-foreground"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.EMPTY_STATE') }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div
            class="border-t border-border bg-muted/10 px-6 py-3 flex flex-col sm:flex-row items-center justify-between gap-4"
          >
            <div class="text-[13px] text-muted-foreground">
              {{
                t('AUTORESPONDER.ACTIVITY.SHOWING_COUNT', {
                  count: filteredActivities.length,
                  total: logs.length,
                })
              }}
            </div>
          </div>
        </div>

        <ActivityDetailsPanel
          v-model:open="isPreviewOpen"
          :activity="selectedActivity"
        />
      </div>
    </div>
  </div>
</template>
