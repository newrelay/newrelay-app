<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelaySwitch,
  RelayCheckbox,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { useAlert } from 'dashboard/composables';

const { t } = useI18n();

const defaultSettings = ref({ comments: true, dms: true });
const selectedChannel = ref('Instagram');
const channels = ['Instagram', 'Facebook', 'TikTok', 'WhatsApp Business'];

const searchQuery = ref('');
const activeFilter = ref('All');
const filterTabs = computed(() => [
  { id: 'All', label: t('AUTORESPONDER.RESPONSE_CONTROLS.FILTER_ALL') },
  { id: 'Active', label: t('AUTORESPONDER.RESPONSE_CONTROLS.FILTER_ACTIVE') },
  { id: 'Paused', label: t('AUTORESPONDER.RESPONSE_CONTROLS.FILTER_PAUSED') },
  { id: 'Posts', label: t('AUTORESPONDER.RESPONSE_CONTROLS.FILTER_POSTS') },
  {
    id: 'Direct Messages',
    label: t('AUTORESPONDER.RESPONSE_CONTROLS.FILTER_DMS'),
  },
]);

const items = ref([
  {
    id: 1,
    title: 'Summer Sale 2026 - Up to 40% Off',
    type: 'Post',
    publishedAt: 'Aug 28, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: false,
      automation: 'Summer Sale Comment Auto-DM',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Lead Qualification Bot',
    },
    stats: { commentsSent: 342, dmsSent: 289 },
    selected: false,
  },
  {
    id: 2,
    title: 'Product Launch: NextGen Smartwatch Pro',
    type: 'Reel',
    publishedAt: 'Aug 25, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1508057198894-247b23fe5ade?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: false,
      overridden: true,
      automation: 'General Comment Acknowledgement',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Product Inquiries Autoresponder',
    },
    stats: { commentsSent: 0, dmsSent: 412 },
    selected: false,
  },
  {
    id: 3,
    title: 'Giveaway: Win AirPods Max & Store Credit',
    type: 'Carousel',
    publishedAt: 'Aug 20, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: true,
      automation: 'Giveaway Entry Validator',
    },
    dms: {
      enabled: false,
      overridden: true,
      automation: 'Standard Welcome Flow',
    },
    stats: { commentsSent: 1240, dmsSent: 0 },
    selected: false,
  },
  {
    id: 4,
    title: 'Behind The Scenes: How We Design Our Interfaces',
    type: 'Story',
    publishedAt: 'Aug 18, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: false,
      automation: 'Story Reply Capture',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Story Mentions Auto-Reply',
    },
    stats: { commentsSent: 88, dmsSent: 120 },
    selected: false,
  },
  {
    id: 5,
    title: 'Customer Spotlight: How BrandX Scaled 500%',
    type: 'Post',
    publishedAt: 'Aug 12, 2026',
    thumbnail:
      'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=300&auto=format&fit=crop&q=80',
    comments: {
      enabled: true,
      overridden: false,
      automation: 'Case Study Request Reply',
    },
    dms: {
      enabled: true,
      overridden: false,
      automation: 'Enterprise Lead Route',
    },
    stats: { commentsSent: 215, dmsSent: 198 },
    selected: false,
  },
]);

const dmControls = ref([
  {
    id: 'general_dm',
    name: 'General Inbound DMs',
    description: 'Auto-reply to incoming customer questions in Direct Messages',
    enabled: true,
    overridden: false,
    automation: 'Relay AI Smart Concierge',
    stats: '1,420 replies sent this month',
  },
  {
    id: 'new_followers',
    name: 'New Follower Welcome DM',
    description:
      'Send automated welcome message when a new user follows your profile',
    enabled: true,
    overridden: true,
    automation: 'New Follower Onboarding',
    stats: '680 DMs dispatched',
  },
  {
    id: 'story_mentions',
    name: 'Story Mentions & Tags',
    description:
      'Instantly respond in DM when someone mentions your account in their Story',
    enabled: true,
    overridden: false,
    automation: 'Story Mention Acknowledgement',
    stats: '312 DMs dispatched',
  },
  {
    id: 'message_requests',
    name: 'Hidden / Message Requests Filter',
    description:
      'Auto-screen and respond to pending message requests from non-followers',
    enabled: false,
    overridden: true,
    automation: 'Spam Prevention & Filter',
    stats: '0 replies (Paused)',
  },
]);

const automationOptions = [
  'Summer Sale Comment Auto-DM',
  'Lead Qualification Bot',
  'Giveaway Entry Validator',
  'Product Inquiries Autoresponder',
  'Relay AI Smart Concierge',
  'Story Mention Acknowledgement',
];

const isDrawerOpen = ref(false);
const selectedItem = ref(null);
const drawerForm = ref({
  commentsEnabled: true,
  commentsOverridden: false,
  commentsAutomation: '',
  dmsEnabled: true,
  dmsOverridden: false,
  dmsAutomation: '',
});

function openManageDrawer(item) {
  selectedItem.value = item;
  drawerForm.value = {
    commentsEnabled: item.comments.enabled,
    commentsOverridden: item.comments.overridden,
    commentsAutomation: item.comments.automation,
    dmsEnabled: item.dms.enabled,
    dmsOverridden: item.dms.overridden,
    dmsAutomation: item.dms.automation,
  };
  isDrawerOpen.value = true;
}

function saveDrawerChanges() {
  if (selectedItem.value) {
    selectedItem.value.comments.enabled = drawerForm.value.commentsEnabled;
    selectedItem.value.comments.overridden =
      drawerForm.value.commentsOverridden;
    selectedItem.value.comments.automation =
      drawerForm.value.commentsAutomation;
    selectedItem.value.dms.enabled = drawerForm.value.dmsEnabled;
    selectedItem.value.dms.overridden = drawerForm.value.dmsOverridden;
    selectedItem.value.dms.automation = drawerForm.value.dmsAutomation;
  }
  isDrawerOpen.value = false;
  useAlert(t('AUTORESPONDER.RESPONSE_CONTROLS.SAVED_TOAST'));
}

function resetCommentsToInherited() {
  drawerForm.value.commentsEnabled = defaultSettings.value.comments;
  drawerForm.value.commentsOverridden = false;
}

function resetDmsToInherited() {
  drawerForm.value.dmsEnabled = defaultSettings.value.dms;
  drawerForm.value.dmsOverridden = false;
}

function toggleItemComments(item) {
  item.comments.enabled = !item.comments.enabled;
  item.comments.overridden = true;
}

function toggleItemDms(item) {
  item.dms.enabled = !item.dms.enabled;
  item.dms.overridden = true;
}

const selectedItems = computed(() => items.value.filter(i => i.selected));
const isAllSelected = computed(
  () => items.value.length > 0 && items.value.every(i => i.selected)
);

function toggleSelectAll() {
  const target = !isAllSelected.value;
  items.value.forEach(i => {
    i.selected = target;
  });
}

function bulkEnableComments() {
  selectedItems.value.forEach(i => {
    i.comments.enabled = true;
    i.comments.overridden = true;
  });
}
function bulkDisableComments() {
  selectedItems.value.forEach(i => {
    i.comments.enabled = false;
    i.comments.overridden = true;
  });
}
function bulkEnableDms() {
  selectedItems.value.forEach(i => {
    i.dms.enabled = true;
    i.dms.overridden = true;
  });
}
function bulkDisableDms() {
  selectedItems.value.forEach(i => {
    i.dms.enabled = false;
    i.dms.overridden = true;
  });
}
function bulkResetInherited() {
  selectedItems.value.forEach(i => {
    i.comments.enabled = defaultSettings.value.comments;
    i.comments.overridden = false;
    i.dms.enabled = defaultSettings.value.dms;
    i.dms.overridden = false;
  });
}
function clearSelection() {
  items.value.forEach(i => {
    i.selected = false;
  });
}

const filteredItems = computed(() => {
  let list = items.value;
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(
      i =>
        i.title.toLowerCase().includes(q) ||
        i.comments.automation.toLowerCase().includes(q) ||
        i.dms.automation.toLowerCase().includes(q)
    );
  }
  if (activeFilter.value === 'Active') {
    list = list.filter(i => i.comments.enabled || i.dms.enabled);
  } else if (activeFilter.value === 'Paused') {
    list = list.filter(i => !i.comments.enabled && !i.dms.enabled);
  } else if (activeFilter.value === 'Posts') {
    list = list.filter(i => ['Post', 'Reel', 'Carousel'].includes(i.type));
  }
  return list;
});
</script>

<template>
  <div class="flex-1 p-4 sm:p-8 max-w-7xl mx-auto space-y-6 relative">
    <div
      class="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-2 border-b border-border/40"
    >
      <div>
        <h1 class="text-base font-medium text-foreground">
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.TITLE') }}
        </h1>
        <p class="text-[13.5px] text-muted-foreground mt-0.5 leading-relaxed">
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.SUBTITLE') }}
        </p>
      </div>

      <div class="flex items-center gap-3 shrink-0">
        <RelayDropdownMenu>
          <RelayDropdownMenuTrigger as-child>
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg text-[13.5px] font-medium bg-card border border-border shadow-xs px-3 hover:border-transparent"
            >
              <span class="i-lucide-instagram size-4 text-rose-500" />
              <span>{{ selectedChannel }}</span>
              <span class="i-lucide-chevron-down size-3.5 opacity-50 ml-1" />
            </RelayButton>
          </RelayDropdownMenuTrigger>
          <RelayDropdownMenuContent align="end" class="w-48">
            <RelayDropdownMenuItem
              v-for="c in channels"
              :key="c"
              class="gap-2"
              @click="selectedChannel = c"
            >
              <span>{{ c }}</span>
              <span
                v-if="selectedChannel === c"
                class="i-lucide-check size-3.5 text-primary ml-auto"
              />
            </RelayDropdownMenuItem>
          </RelayDropdownMenuContent>
        </RelayDropdownMenu>

        <div class="relative w-56 sm:w-64">
          <span
            class="i-lucide-search size-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            :placeholder="
              t('AUTORESPONDER.RESPONSE_CONTROLS.SEARCH_PLACEHOLDER')
            "
            class-name="pl-9 h-9 rounded-lg bg-background border border-border shadow-xs"
          />
        </div>
      </div>
    </div>

    <div
      class="p-4 rounded-xl bg-card border border-border/60 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4"
    >
      <div class="flex items-start gap-3">
        <div
          class="size-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0 mt-0.5"
        >
          <span class="i-lucide-zap size-4" />
        </div>
        <div>
          <div
            class="text-[13.5px] font-medium text-foreground flex items-center gap-2"
          >
            {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DEFAULT_BEHAVIOR') }}
            <span class="text-primary font-semibold">{{
              selectedChannel
            }}</span>
          </div>
          <p class="text-[13px] text-muted-foreground mt-0.5">
            {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DEFAULT_BEHAVIOR_DESC') }}
            <span class="text-foreground font-medium">
              {{
                t('AUTORESPONDER.RESPONSE_CONTROLS.COMMENTS_STATE', {
                  state: defaultSettings.comments ? 'ON' : 'OFF',
                })
              }}
            </span>
            &bull;
            <span class="text-foreground font-medium">
              {{
                t('AUTORESPONDER.RESPONSE_CONTROLS.DMS_STATE', {
                  state: defaultSettings.dms ? 'ON' : 'OFF',
                })
              }}
            </span>
          </p>
        </div>
      </div>

      <div class="flex items-center gap-4 shrink-0 self-end sm:self-auto">
        <div class="flex items-center gap-2 text-[13px]">
          <span class="text-muted-foreground">{{
            t('AUTORESPONDER.RESPONSE_CONTROLS.DEFAULT_COMMENTS')
          }}</span>
          <RelaySwitch v-model="defaultSettings.comments" />
        </div>
        <div class="h-4 w-px bg-border" />
        <div class="flex items-center gap-2 text-[13px]">
          <span class="text-muted-foreground">{{
            t('AUTORESPONDER.RESPONSE_CONTROLS.DEFAULT_DMS')
          }}</span>
          <RelaySwitch v-model="defaultSettings.dms" />
        </div>
      </div>
    </div>

    <div
      class="relative border-b border-border w-full flex items-center justify-between"
    >
      <div class="flex items-center gap-8 overflow-x-auto hide-scrollbar">
        <button
          v-for="tItem in filterTabs"
          :key="tItem.id"
          type="button"
          class="relative pb-3 text-sm font-medium transition-colors whitespace-nowrap"
          :class="
            activeFilter === tItem.id
              ? 'text-primary'
              : 'text-muted-foreground hover:text-foreground'
          "
          @click="activeFilter = tItem.id"
        >
          {{ tItem.label }}
          <div
            v-if="activeFilter === tItem.id"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-primary rounded-full"
          />
        </button>
      </div>

      <div
        v-if="activeFilter !== 'Direct Messages' && filteredItems.length > 0"
        class="flex items-center gap-2 pb-3 text-[13px] text-muted-foreground"
      >
        <RelayCheckbox
          id="select-all"
          v-model="isAllSelected"
          @click="toggleSelectAll"
        />
        <label for="select-all" class="cursor-pointer font-medium select-none">
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.SELECT_ALL') }}
        </label>
      </div>
    </div>

    <div v-if="activeFilter !== 'Direct Messages'" class="space-y-4">
      <div v-if="filteredItems.length > 0" class="space-y-3">
        <div
          v-for="item in filteredItems"
          :key="item.id"
          class="p-4 sm:p-5 rounded-xl bg-card border border-border/60 shadow-xs hover:border-primary/30 transition-all flex flex-col md:flex-row md:items-center justify-between gap-5"
          :class="{ 'border-primary/40': item.selected }"
        >
          <div class="flex items-start gap-4 min-w-0 flex-1">
            <div class="pt-2 shrink-0">
              <RelayCheckbox v-model="item.selected" />
            </div>

            <div
              class="relative size-16 sm:size-20 rounded-lg overflow-hidden bg-muted border border-border shrink-0 shadow-2xs"
            >
              <img
                :src="item.thumbnail"
                :alt="item.title"
                class="size-full object-cover"
              />
              <div
                class="absolute bottom-1 right-1 px-1.5 py-0.5 rounded bg-black/70 backdrop-blur-sm text-[10px] font-semibold text-white uppercase tracking-wider"
              >
                {{ item.type }}
              </div>
            </div>

            <div class="min-w-0 space-y-1">
              <div class="flex items-center gap-2 flex-wrap">
                <h2
                  class="text-sm font-semibold text-foreground truncate max-w-md"
                >
                  {{ item.title }}
                </h2>
                <span
                  class="text-[11.5px] font-medium px-2 py-0.5 rounded-full flex items-center gap-1 shrink-0"
                  :class="
                    item.comments.enabled || item.dms.enabled
                      ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                      : 'bg-muted text-muted-foreground'
                  "
                >
                  <span
                    class="size-1.5 rounded-full"
                    :class="
                      item.comments.enabled || item.dms.enabled
                        ? 'bg-emerald-500'
                        : 'bg-muted-foreground'
                    "
                  />
                  {{
                    item.comments.enabled || item.dms.enabled
                      ? t('AUTORESPONDER.RESPONSE_CONTROLS.ACTIVE')
                      : t('AUTORESPONDER.RESPONSE_CONTROLS.PAUSED')
                  }}
                </span>
              </div>

              <div
                class="text-[12.5px] text-muted-foreground flex items-center gap-2"
              >
                <span>{{
                  t('AUTORESPONDER.RESPONSE_CONTROLS.PUBLISHED', {
                    date: item.publishedAt,
                  })
                }}</span>
                <span>&bull;</span>
                <span>{{
                  t('AUTORESPONDER.RESPONSE_CONTROLS.STATS', {
                    comments: item.stats.commentsSent,
                    dms: item.stats.dmsSent,
                  })
                }}</span>
              </div>

              <div
                class="text-xs text-muted-foreground/80 flex items-center gap-3 pt-0.5"
              >
                <span class="flex items-center gap-1 truncate">
                  <span
                    class="i-lucide-message-square size-3 text-muted-foreground"
                  />
                  {{ item.comments.automation }}
                </span>
                <span>&bull;</span>
                <span class="flex items-center gap-1 truncate">
                  <span class="i-lucide-send size-3 text-muted-foreground" />
                  {{ item.dms.automation }}
                </span>
              </div>
            </div>
          </div>

          <div
            class="flex items-center gap-6 sm:gap-8 shrink-0 self-end md:self-auto border-t md:border-t-0 border-border/40 pt-3 md:pt-0 w-full md:w-auto justify-between md:justify-end"
          >
            <div class="flex flex-col items-start gap-1">
              <div class="flex items-center gap-2.5">
                <span
                  class="text-[13.5px] font-medium text-foreground flex items-center gap-1"
                >
                  <span
                    class="i-lucide-message-square size-3.5 text-muted-foreground"
                  />
                  {{ t('AUTORESPONDER.RESPONSE_CONTROLS.COMMENTS') }}
                </span>
                <RelaySwitch
                  :model-value="item.comments.enabled"
                  @update:model-value="toggleItemComments(item)"
                />
              </div>
              <span
                class="text-[11px] font-medium"
                :class="
                  item.comments.overridden
                    ? 'text-amber-600 dark:text-amber-400'
                    : 'text-muted-foreground'
                "
              >
                {{
                  item.comments.overridden
                    ? t('AUTORESPONDER.RESPONSE_CONTROLS.OVERRIDDEN')
                    : t('AUTORESPONDER.RESPONSE_CONTROLS.INHERITED')
                }}
                &bull; {{ item.comments.enabled ? 'ON' : 'OFF' }}
              </span>
            </div>

            <div class="flex flex-col items-start gap-1">
              <div class="flex items-center gap-2.5">
                <span
                  class="text-[13.5px] font-medium text-foreground flex items-center gap-1"
                >
                  <span class="i-lucide-send size-3.5 text-muted-foreground" />
                  {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DIRECT_MESSAGES') }}
                </span>
                <RelaySwitch
                  :model-value="item.dms.enabled"
                  @update:model-value="toggleItemDms(item)"
                />
              </div>
              <span
                class="text-[11px] font-medium"
                :class="
                  item.dms.overridden
                    ? 'text-amber-600 dark:text-amber-400'
                    : 'text-muted-foreground'
                "
              >
                {{
                  item.dms.overridden
                    ? t('AUTORESPONDER.RESPONSE_CONTROLS.OVERRIDDEN')
                    : t('AUTORESPONDER.RESPONSE_CONTROLS.INHERITED')
                }}
                &bull; {{ item.dms.enabled ? 'ON' : 'OFF' }}
              </span>
            </div>

            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 px-3 gap-1.5 rounded-lg text-[13px] font-medium shadow-xs"
              @click="openManageDrawer(item)"
            >
              <span>{{ t('AUTORESPONDER.RESPONSE_CONTROLS.MANAGE') }}</span>
              <span class="i-lucide-arrow-right size-3.5" />
            </RelayButton>
          </div>
        </div>
      </div>

      <div
        v-else
        class="flex flex-col items-center justify-center py-24 text-center bg-card border border-dashed border-border rounded-xl"
      >
        <div
          class="size-12 rounded-full bg-muted flex items-center justify-center mb-3"
        >
          <span class="i-lucide-search size-6 text-muted-foreground" />
        </div>
        <h3 class="text-base font-semibold text-foreground">
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.EMPTY_TITLE') }}
        </h3>
        <p class="text-[13.5px] text-muted-foreground mt-1 max-w-sm">
          {{
            t('AUTORESPONDER.RESPONSE_CONTROLS.EMPTY_DESC', {
              query: searchQuery,
            })
          }}
        </p>
      </div>
    </div>

    <div
      v-if="activeFilter === 'Direct Messages' || activeFilter === 'All'"
      class="space-y-4 pt-2"
    >
      <div
        class="border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden"
      >
        <div
          class="p-4 sm:p-6 border-b border-border/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
        >
          <div>
            <h2 class="text-base font-semibold text-foreground">
              {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DM_CONTROLS_TITLE') }}
            </h2>
            <p class="text-[13.5px] text-muted-foreground mt-0.5">
              {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DM_CONTROLS_DESC') }}
            </p>
          </div>
          <span
            class="text-xs font-medium px-2.5 py-1 rounded-md bg-primary/10 text-primary self-start sm:self-auto"
          >
            {{
              t('AUTORESPONDER.RESPONSE_CONTROLS.CHANNEL_LABEL', {
                channel: selectedChannel,
              })
            }}
          </span>
        </div>

        <div class="divide-y divide-border/40">
          <div
            v-for="dm in dmControls"
            :key="dm.id"
            class="p-4 sm:p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-muted/20 transition-colors"
          >
            <div class="space-y-1 max-w-xl">
              <div class="flex items-center gap-2.5">
                <h3 class="text-sm font-semibold text-foreground">
                  {{ dm.name }}
                </h3>
                <span
                  class="text-[11px] font-medium px-2 py-0.5 rounded-full"
                  :class="
                    dm.enabled
                      ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                      : 'bg-muted text-muted-foreground'
                  "
                >
                  {{
                    dm.enabled
                      ? t('AUTORESPONDER.RESPONSE_CONTROLS.ACTIVE')
                      : t('AUTORESPONDER.RESPONSE_CONTROLS.PAUSED')
                  }}
                </span>
              </div>
              <p class="text-[13px] text-muted-foreground leading-relaxed">
                {{ dm.description }}
              </p>
              <div
                class="text-xs text-muted-foreground/80 flex items-center gap-2 pt-0.5"
              >
                <span class="font-medium text-foreground">{{
                  t('AUTORESPONDER.RESPONSE_CONTROLS.FLOW', {
                    flow: dm.automation,
                  })
                }}</span>
                <span>&bull;</span>
                <span>{{ dm.stats }}</span>
              </div>
            </div>

            <div class="flex items-center gap-4 shrink-0 self-end md:self-auto">
              <div class="text-right hidden sm:block">
                <div class="text-[12.5px] font-medium text-foreground">
                  {{
                    dm.enabled
                      ? t('AUTORESPONDER.RESPONSE_CONTROLS.RESPONDING')
                      : t('AUTORESPONDER.RESPONSE_CONTROLS.SILENT')
                  }}
                </div>
                <div class="text-[11px] text-muted-foreground">
                  {{
                    dm.overridden
                      ? t('AUTORESPONDER.RESPONSE_CONTROLS.OVERRIDDEN')
                      : t('AUTORESPONDER.RESPONSE_CONTROLS.INHERITED')
                  }}
                </div>
              </div>
              <RelaySwitch
                v-model="dm.enabled"
                @update:model-value="dm.overridden = true"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="selectedItems.length > 0"
      class="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 px-4 py-2.5 bg-card/95 text-foreground backdrop-blur-md border border-border/80 rounded-xl shadow-2xl"
    >
      <div class="text-[13px] font-medium px-2 border-r border-border/80">
        {{
          t('AUTORESPONDER.RESPONSE_CONTROLS.SELECTED_COUNT', {
            count: selectedItems.length,
          })
        }}
      </div>

      <div class="flex items-center gap-2">
        <RelayButton
          size="sm"
          variant="ghost"
          class="h-8 px-2.5 text-[12.5px]"
          @click="bulkEnableComments"
        >
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.BULK_ENABLE_COMMENTS') }}
        </RelayButton>
        <RelayButton
          size="sm"
          variant="ghost"
          class="h-8 px-2.5 text-[12.5px]"
          @click="bulkDisableComments"
        >
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.BULK_DISABLE_COMMENTS') }}
        </RelayButton>
        <RelayButton
          size="sm"
          variant="ghost"
          class="h-8 px-2.5 text-[12.5px]"
          @click="bulkEnableDms"
        >
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.BULK_ENABLE_DMS') }}
        </RelayButton>
        <RelayButton
          size="sm"
          variant="ghost"
          class="h-8 px-2.5 text-[12.5px]"
          @click="bulkDisableDms"
        >
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.BULK_DISABLE_DMS') }}
        </RelayButton>
        <RelayButton
          size="sm"
          variant="ghost"
          class="h-8 px-2.5 text-[12.5px]"
          @click="bulkResetInherited"
        >
          {{ t('AUTORESPONDER.RESPONSE_CONTROLS.BULK_RESET') }}
        </RelayButton>
      </div>

      <button
        type="button"
        class="size-7 rounded-lg hover:bg-muted flex items-center justify-center text-muted-foreground hover:text-foreground ml-1"
        @click="clearSelection"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>

    <div
      v-if="isDrawerOpen && selectedItem"
      class="fixed inset-0 z-[100] bg-background/60 backdrop-blur-xs flex justify-end"
      @click="isDrawerOpen = false"
    >
      <div
        class="w-full max-w-[460px] h-full bg-card border-l border-border shadow-2xl flex flex-col"
        @click.stop
      >
        <div
          class="p-5 border-b border-border flex items-start justify-between gap-4"
        >
          <div class="flex items-center gap-3.5 min-w-0">
            <img
              :src="selectedItem.thumbnail"
              :alt="selectedItem.title"
              class="size-12 rounded-lg object-cover border border-border shrink-0"
            />
            <div class="min-w-0">
              <h2 class="text-[15px] font-semibold text-foreground truncate">
                {{ selectedItem.title }}
              </h2>
              <p class="text-[12.5px] text-muted-foreground">
                {{ selectedItem.type }} &bull; {{ selectedItem.publishedAt }}
              </p>
            </div>
          </div>
          <button
            type="button"
            class="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors shrink-0"
            @click="isDrawerOpen = false"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-5 space-y-6">
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <span
                class="text-[13px] font-semibold uppercase tracking-wider text-muted-foreground"
              >
                {{ t('AUTORESPONDER.RESPONSE_CONTROLS.RESPONSE_STATUS') }}
              </span>
              <span
                class="text-[11.5px] font-medium px-2 py-0.5 rounded-full"
                :class="
                  drawerForm.commentsEnabled || drawerForm.dmsEnabled
                    ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                    : 'bg-muted text-muted-foreground'
                "
              >
                {{
                  drawerForm.commentsEnabled || drawerForm.dmsEnabled
                    ? t('AUTORESPONDER.RESPONSE_CONTROLS.ACTIVE')
                    : t('AUTORESPONDER.RESPONSE_CONTROLS.PAUSED')
                }}
              </span>
            </div>

            <div
              class="p-3.5 rounded-xl bg-muted/40 border border-border space-y-2"
            >
              <div class="flex items-center justify-between">
                <div>
                  <div class="text-[13.5px] font-medium text-foreground">
                    {{
                      t('AUTORESPONDER.RESPONSE_CONTROLS.COMMENTS_AUTO_REPLY')
                    }}
                  </div>
                  <p class="text-[12.5px] text-muted-foreground">
                    {{
                      t(
                        'AUTORESPONDER.RESPONSE_CONTROLS.COMMENTS_AUTO_REPLY_DESC'
                      )
                    }}
                  </p>
                </div>
                <RelaySwitch
                  v-model="drawerForm.commentsEnabled"
                  @update:model-value="drawerForm.commentsOverridden = true"
                />
              </div>
              <div
                class="flex items-center justify-between text-[11.5px] pt-1 border-t border-border/40"
              >
                <span
                  :class="
                    drawerForm.commentsOverridden
                      ? 'text-amber-600 dark:text-amber-400 font-medium'
                      : 'text-muted-foreground'
                  "
                >
                  {{
                    drawerForm.commentsOverridden
                      ? t('AUTORESPONDER.RESPONSE_CONTROLS.STATUS_OVERRIDDEN')
                      : t('AUTORESPONDER.RESPONSE_CONTROLS.STATUS_INHERITED')
                  }}
                </span>
                <button
                  v-if="drawerForm.commentsOverridden"
                  type="button"
                  class="text-primary hover:underline"
                  @click="resetCommentsToInherited"
                >
                  {{ t('AUTORESPONDER.RESPONSE_CONTROLS.RESET_TO_INHERITED') }}
                </button>
              </div>
            </div>

            <div
              class="p-3.5 rounded-xl bg-muted/40 border border-border space-y-2"
            >
              <div class="flex items-center justify-between">
                <div>
                  <div class="text-[13.5px] font-medium text-foreground">
                    {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DM_INQUIRIES') }}
                  </div>
                  <p class="text-[12.5px] text-muted-foreground">
                    {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DM_INQUIRIES_DESC') }}
                  </p>
                </div>
                <RelaySwitch
                  v-model="drawerForm.dmsEnabled"
                  @update:model-value="drawerForm.dmsOverridden = true"
                />
              </div>
              <div
                class="flex items-center justify-between text-[11.5px] pt-1 border-t border-border/40"
              >
                <span
                  :class="
                    drawerForm.dmsOverridden
                      ? 'text-amber-600 dark:text-amber-400 font-medium'
                      : 'text-muted-foreground'
                  "
                >
                  {{
                    drawerForm.dmsOverridden
                      ? t('AUTORESPONDER.RESPONSE_CONTROLS.STATUS_OVERRIDDEN')
                      : t('AUTORESPONDER.RESPONSE_CONTROLS.STATUS_INHERITED')
                  }}
                </span>
                <button
                  v-if="drawerForm.dmsOverridden"
                  type="button"
                  class="text-primary hover:underline"
                  @click="resetDmsToInherited"
                >
                  {{ t('AUTORESPONDER.RESPONSE_CONTROLS.RESET_TO_INHERITED') }}
                </button>
              </div>
            </div>
          </div>

          <div class="space-y-3 pt-3 border-t border-border/40">
            <h3
              class="text-[13.5px] font-semibold text-foreground flex items-center gap-2"
            >
              <span class="i-lucide-message-square size-4 text-primary" />
              {{ t('AUTORESPONDER.RESPONSE_CONTROLS.COMMENT_FLOW') }}
            </h3>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('AUTORESPONDER.RESPONSE_CONTROLS.ACTIVE_AUTOMATION') }}
              </label>
              <RelayDropdownMenu>
                <RelayDropdownMenuTrigger as-child>
                  <RelayButton
                    variant="outline"
                    class="h-9 justify-between rounded-lg text-[13.5px] font-normal bg-background px-3 text-left w-full"
                  >
                    <span class="truncate">{{
                      drawerForm.commentsAutomation ||
                      t('AUTORESPONDER.RESPONSE_CONTROLS.SELECT_AUTOMATION')
                    }}</span>
                    <span
                      class="i-lucide-chevron-down size-3.5 opacity-50 ml-2 shrink-0"
                    />
                  </RelayButton>
                </RelayDropdownMenuTrigger>
                <RelayDropdownMenuContent align="start" class="w-80">
                  <RelayDropdownMenuItem
                    v-for="opt in automationOptions"
                    :key="opt"
                    class="text-[13px]"
                    @click="drawerForm.commentsAutomation = opt"
                  >
                    <span>{{ opt }}</span>
                    <span
                      v-if="drawerForm.commentsAutomation === opt"
                      class="i-lucide-check size-3.5 text-primary ml-auto"
                    />
                  </RelayDropdownMenuItem>
                </RelayDropdownMenuContent>
              </RelayDropdownMenu>
            </div>
          </div>

          <div class="space-y-3 pt-3 border-t border-border/40">
            <h3
              class="text-[13.5px] font-semibold text-foreground flex items-center gap-2"
            >
              <span class="i-lucide-send size-4 text-primary" />
              {{ t('AUTORESPONDER.RESPONSE_CONTROLS.DM_FLOW') }}
            </h3>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('AUTORESPONDER.RESPONSE_CONTROLS.ACTIVE_AUTOMATION') }}
              </label>
              <RelayDropdownMenu>
                <RelayDropdownMenuTrigger as-child>
                  <RelayButton
                    variant="outline"
                    class="h-9 justify-between rounded-lg text-[13.5px] font-normal bg-background px-3 text-left w-full"
                  >
                    <span class="truncate">{{
                      drawerForm.dmsAutomation ||
                      t('AUTORESPONDER.RESPONSE_CONTROLS.SELECT_AUTOMATION')
                    }}</span>
                    <span
                      class="i-lucide-chevron-down size-3.5 opacity-50 ml-2 shrink-0"
                    />
                  </RelayButton>
                </RelayDropdownMenuTrigger>
                <RelayDropdownMenuContent align="start" class="w-80">
                  <RelayDropdownMenuItem
                    v-for="opt in automationOptions"
                    :key="opt"
                    class="text-[13px]"
                    @click="drawerForm.dmsAutomation = opt"
                  >
                    <span>{{ opt }}</span>
                    <span
                      v-if="drawerForm.dmsAutomation === opt"
                      class="i-lucide-check size-3.5 text-primary ml-auto"
                    />
                  </RelayDropdownMenuItem>
                </RelayDropdownMenuContent>
              </RelayDropdownMenu>
            </div>
          </div>
        </div>

        <div
          class="p-4 border-t border-border flex items-center justify-end gap-3 bg-muted/20"
        >
          <RelayButton
            variant="outline"
            class="h-9 px-4 rounded-lg text-[13.5px]"
            @click="isDrawerOpen = false"
          >
            {{ t('AUTORESPONDER.COMMON.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="h-9 px-5 rounded-lg shadow-xs text-[13.5px]"
            @click="saveDrawerChanges"
          >
            {{ t('AUTORESPONDER.COMMON.SAVE_CHANGES') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
