<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelayBadge,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS, CHANNEL_NAMES } from '../constants/channels';
import ActivityDetailsPanel from '../components/ActivityDetailsPanel.vue';

const { t } = useI18n();
const searchQuery = ref('');
const activeTab = ref('All');
const channelFilter = ref('All Channels');
const isPreviewOpen = ref(false);
const selectedActivity = ref(null);

const tabs = computed(() => [
  { id: 'All', count: '1,284', label: t('AUTORESPONDER.ACTIVITY.TAB_ALL') },
  {
    id: 'Successful',
    count: '1,266',
    label: t('AUTORESPONDER.ACTIVITY.TAB_SUCCESSFUL'),
  },
  { id: 'Failed', count: '12', label: t('AUTORESPONDER.ACTIVITY.TAB_FAILED') },
  { id: 'Skipped', count: '6', label: t('AUTORESPONDER.ACTIVITY.TAB_SKIPPED') },
]);

const activities = ref([
  {
    id: 'ACT-2024-05-26-103012',
    time: 'May 26, 2024\n10:30 AM',
    channel: 'Instagram',
    channelType: 'Comment',
    contact: {
      name: 'John Smith',
      handle: '@john.smith',
      avatar: 'https://i.pravatar.cc/150?u=1',
    },
    automation: 'Pricing Response',
    automationType: 'Comment Reply',
    action: 'Replied to comment',
    actionSnippet: '"How much does this cost?"',
    status: 'Successful',
  },
  {
    id: 'ACT-2024-05-26-102812',
    time: 'May 26, 2024\n10:28 AM',
    channel: 'Instagram',
    channelType: 'DM',
    contact: {
      name: 'Sarah Johnson',
      handle: '@sarah.j',
      avatar: 'https://i.pravatar.cc/150?u=2',
    },
    automation: 'Welcome Message',
    automationType: 'Auto Responder',
    action: 'Sent message',
    actionSnippet: 'Welcome! How can we...',
    status: 'Successful',
  },
  {
    id: 'ACT-2024-05-26-102212',
    time: 'May 26, 2024\n10:22 AM',
    channel: 'WhatsApp',
    channelType: 'Message',
    contact: {
      name: 'Michael Brown',
      handle: '+1 (555) 123-4567',
      avatar: 'https://i.pravatar.cc/150?u=3',
    },
    automation: 'WhatsApp Quick Reply',
    automationType: 'Auto Responder',
    action: 'Sent message',
    actionSnippet: 'Thanks for reaching out...',
    status: 'Successful',
  },
  {
    id: 'ACT-2024-05-26-101812',
    time: 'May 26, 2024\n10:18 AM',
    channel: 'Facebook',
    channelType: 'Comment',
    contact: {
      name: 'Emily Davis',
      handle: '@emily.d',
      avatar: 'https://i.pravatar.cc/150?u=4',
    },
    automation: 'Thank You Comment',
    automationType: 'Comment Reply',
    action: 'Replied to comment',
    actionSnippet: 'Great service!',
    status: 'Successful',
  },
  {
    id: 'ACT-2024-05-26-101212',
    time: 'May 26, 2024\n10:12 AM',
    channel: 'Instagram',
    channelType: 'Comment',
    contact: {
      name: 'David Wilson',
      handle: '@david.w',
      avatar: 'https://i.pravatar.cc/150?u=5',
    },
    automation: 'Out of Hours Reply',
    automationType: 'Comment Reply',
    action: 'Replied to comment',
    actionSnippet: 'Are you open now?',
    status: 'Skipped',
  },
  {
    id: 'ACT-2024-05-26-100812',
    time: 'May 26, 2024\n10:08 AM',
    channel: 'Instagram',
    channelType: 'DM',
    contact: {
      name: 'Jessica Lee',
      handle: '@jessica.lee',
      avatar: 'https://i.pravatar.cc/150?u=6',
    },
    automation: 'Product Inquiry',
    automationType: 'Auto Responder',
    action: 'Failed to send message',
    actionSnippet: 'Network error',
    status: 'Failed',
  },
  {
    id: 'ACT-2024-05-26-100112',
    time: 'May 26, 2024\n10:01 AM',
    channel: 'WhatsApp',
    channelType: 'Message',
    contact: {
      name: 'Chris Taylor',
      handle: '+1 (555) 987-6543',
      avatar: 'https://i.pravatar.cc/150?u=7',
    },
    automation: 'Business Hours Reply',
    automationType: 'Auto Responder',
    action: 'Sent message',
    actionSnippet: 'We are available from...',
    status: 'Successful',
  },
  {
    id: 'ACT-2024-05-26-095812',
    time: 'May 26, 2024\n09:58 AM',
    channel: 'Facebook',
    channelType: 'Comment',
    contact: {
      name: 'Amanda White',
      handle: '@amanda.w',
      avatar: 'https://i.pravatar.cc/150?u=8',
    },
    automation: 'FAQ - General',
    automationType: 'Comment Reply',
    action: 'Replied to comment',
    actionSnippet: 'Do you offer delivery?',
    status: 'Successful',
  },
]);

const filteredActivities = computed(() => {
  let result = activities.value;
  if (activeTab.value !== 'All') {
    result = result.filter(item => item.status === activeTab.value);
  }
  if (channelFilter.value !== 'All Channels') {
    result = result.filter(item => item.channel === channelFilter.value);
  }
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      item =>
        item.contact.name.toLowerCase().includes(query) ||
        item.automation.toLowerCase().includes(query)
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
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6"
      >
        <div>
          <h1 class="text-xl font-semibold tracking-tight text-foreground">
            {{ t('AUTORESPONDER.ACTIVITY.TITLE') }}
          </h1>
          <p class="text-sm text-muted-foreground mt-1">
            {{ t('AUTORESPONDER.ACTIVITY.SUBTITLE') }}
          </p>
        </div>
        <RelayButton variant="outline" class="gap-2">
          <span class="i-lucide-download size-4" />
          {{ t('AUTORESPONDER.ACTIVITY.EXPORT') }}
        </RelayButton>
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
            <RelayButton
              variant="outline"
              class="gap-2 text-[13.5px] font-normal h-9 bg-background"
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
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground min-w-[200px]"
                  >
                    {{ t('AUTORESPONDER.ACTIVITY.TABLE_ACTION') }}
                  </th>
                  <th
                    class="px-4 py-3.5 text-sm font-medium text-muted-foreground w-24"
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
                      {{ item.time.replace('\n', ' ') }}
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="flex items-center gap-2">
                      <img
                        :src="CHANNEL_LOGO_URLS[item.channel]"
                        class="size-4 rounded-sm"
                      />
                      <div class="flex flex-col">
                        <span class="text-[13px] text-foreground font-medium">{{
                          item.channel
                        }}</span>
                        <span class="text-xs text-muted-foreground">{{
                          item.channelType
                        }}</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="flex items-center gap-2.5">
                      <img
                        :src="item.contact.avatar"
                        class="size-7 rounded-full object-cover"
                      />
                      <div class="flex flex-col">
                        <span class="text-[13px] font-medium text-foreground">{{
                          item.contact.name
                        }}</span>
                        <span class="text-xs text-primary">{{
                          item.contact.handle
                        }}</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="flex flex-col gap-0.5">
                      <span class="text-[13px] font-medium text-foreground">{{
                        item.automation
                      }}</span>
                      <span class="text-xs text-muted-foreground">{{
                        item.automationType
                      }}</span>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="flex flex-col gap-0.5">
                      <span class="text-[13px] font-medium text-foreground">{{
                        item.action
                      }}</span>
                      <span class="text-xs text-muted-foreground line-clamp-1">
                        {{ item.actionSnippet }}
                      </span>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <RelayBadge
                      variant="secondary"
                      class="bg-primary/10 text-primary border-none font-medium px-2.5 py-0.5 rounded-md"
                    >
                      {{ item.status }}
                    </RelayBadge>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <RelayButton
                      variant="outline"
                      size="sm"
                      class="h-7 text-xs px-3 font-medium"
                      @click.stop="openPreview(item)"
                    >
                      {{ t('AUTORESPONDER.ACTIVITY.VIEW') }}
                    </RelayButton>
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
                  total: activities.length,
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
