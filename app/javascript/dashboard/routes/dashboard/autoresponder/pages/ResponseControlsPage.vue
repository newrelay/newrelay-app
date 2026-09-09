<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelaySwitch,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { RELAY_MODAL_CLOSE_BUTTON_CLASS } from 'dashboard/components-next/relay/modal/constants';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import CommentAutomationResponseControlsAPI from 'dashboard/api/commentAutomationResponseControls';
import AccountSwitcher from '../components/AccountSwitcher.vue';
import { useAutoresponderAccount } from '../composables/useAutoresponderAccount';

const { t } = useI18n();
const { accountScopedRoute } = useAccount();
const { activeAccount, matchesActiveInbox } = useAutoresponderAccount();

const defaultSettings = ref({ comments: true, dms: true });
const items = ref([]);
const dmControls = ref([]);
const automationOptions = ref([]);

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

onMounted(async () => {
  try {
    const { data } = await CommentAutomationResponseControlsAPI.get();
    const payload = data.payload || {};
    items.value = payload.posts || [];
    dmControls.value = payload.dms || [];
    defaultSettings.value = payload.defaults || { comments: true, dms: true };
    automationOptions.value = payload.automations || [];
  } catch {
    items.value = [];
    dmControls.value = [];
  }
});

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

function persistControl(id, payload) {
  return CommentAutomationResponseControlsAPI.update(id, payload);
}

function persistDefaults() {
  persistControl('defaults', defaultSettings.value);
}

function persistItem(item) {
  persistControl(item.id, { comments: item.comments, dms: item.dms });
}

function persistDm(dm) {
  dm.overridden = true;
  persistControl(dm.id, {
    enabled: dm.enabled,
    overridden: dm.overridden,
    automation: dm.automation,
  });
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
    persistItem(selectedItem.value);
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
  persistItem(item);
}

function toggleItemDms(item) {
  item.dms.enabled = !item.dms.enabled;
  item.dms.overridden = true;
  persistItem(item);
}

const filteredItems = computed(() => {
  let list = items.value.filter(i => matchesActiveInbox(i.inboxId));
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
  <div
    class="flex-1 overflow-y-auto w-full bg-background p-4 sm:p-6 lg:p-8 space-y-6 relative"
  >
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
        <AccountSwitcher />

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
              activeAccount.handle
            }}</span>
            <span class="text-[11.5px] text-muted-foreground font-normal">{{
              t('AUTORESPONDER.RESPONSE_CONTROLS.ACCOUNT_PLATFORM', {
                platform: activeAccount.platform,
              })
            }}</span>
          </div>
          <p class="text-[13px] text-muted-foreground mt-0.5">
            {{
              t('AUTORESPONDER.RESPONSE_CONTROLS.DEFAULT_BEHAVIOR_DESC', {
                handle: activeAccount.handle,
              })
            }}
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
          <RelaySwitch
            v-model="defaultSettings.comments"
            @update:model-value="persistDefaults"
          />
        </div>
        <div class="h-4 w-px bg-border" />
        <div class="flex items-center gap-2 text-[13px]">
          <span class="text-muted-foreground">{{
            t('AUTORESPONDER.RESPONSE_CONTROLS.DEFAULT_DMS')
          }}</span>
          <RelaySwitch
            v-model="defaultSettings.dms"
            @update:model-value="persistDefaults"
          />
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
          class="relative pb-3 text-[13.5px] font-medium transition-colors whitespace-nowrap"
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
    </div>

    <div v-if="activeFilter !== 'Direct Messages'" class="space-y-4">
      <div v-if="filteredItems.length > 0" class="space-y-3">
        <div
          v-for="item in filteredItems"
          :key="item.id"
          class="p-4 sm:p-5 rounded-xl bg-card border border-border/60 shadow-xs hover:border-primary/30 transition-all flex flex-col md:flex-row md:items-center justify-between gap-5"
        >
          <div class="flex items-start gap-4 min-w-0 flex-1">
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
            class="text-[12px] font-medium px-2.5 py-1 rounded-md bg-primary/10 text-primary self-start sm:self-auto font-mono"
          >
            {{ activeAccount.handle }}
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
                @update:model-value="persistDm(dm)"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="isDrawerOpen && selectedItem"
      class="fixed inset-0 z-[100] bg-background/80 backdrop-blur-[8px] flex justify-end"
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
            :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
            @click="isDrawerOpen = false"
          >
            <span class="i-lucide-x size-4" />
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
            <h3 class="text-[13.5px] font-semibold text-foreground">
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
            <router-link
              :to="accountScopedRoute('autoresponder_automations')"
              class="text-[12.5px] text-primary hover:underline flex items-center gap-1 font-medium"
            >
              {{ t('AUTORESPONDER.RESPONSE_CONTROLS.MANAGE_IN_BUILDER') }}
              <span class="i-lucide-external-link size-3" />
            </router-link>
          </div>

          <div class="space-y-3 pt-3 border-t border-border/40">
            <h3 class="text-[13.5px] font-semibold text-foreground">
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
            <router-link
              :to="accountScopedRoute('autoresponder_automations')"
              class="text-[12.5px] text-primary hover:underline flex items-center gap-1 font-medium"
            >
              {{ t('AUTORESPONDER.RESPONSE_CONTROLS.MANAGE_IN_BUILDER') }}
              <span class="i-lucide-external-link size-3" />
            </router-link>
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
