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
import { useAlert } from 'dashboard/composables';
import { CHANNEL_NAMES, CHANNEL_LOGO_URLS } from '../constants/channels';
import TemplatePreviewPanel from '../components/TemplatePreviewPanel.vue';
import CreateTemplateWizard from '../components/CreateTemplateWizard.vue';

const { t } = useI18n();
const searchQuery = ref('');
const activeTab = ref('All');
const channelFilter = ref('All Channels');
const isPreviewOpen = ref(false);
const isCreateWizardOpen = ref(false);
const previewTemplate = ref(null);

const tabs = computed(() => [
  { id: 'All', icon: '', label: t('AUTORESPONDER.TEMPLATES.TAB_ALL') },
  {
    id: 'Message',
    icon: 'i-lucide-message-square',
    label: t('AUTORESPONDER.TEMPLATES.TAB_MESSAGE'),
  },
  {
    id: 'Comment',
    icon: 'i-lucide-message-circle',
    label: t('AUTORESPONDER.TEMPLATES.TAB_COMMENT'),
  },
  {
    id: 'Favorite',
    icon: 'i-lucide-star',
    label: t('AUTORESPONDER.TEMPLATES.TAB_FAVORITE'),
  },
]);

const templates = ref([
  {
    id: 1,
    name: 'Welcome Message',
    description: 'Warm welcome for new followers or new contacts.',
    type: 'Message',
    channels: ['Instagram', 'WhatsApp'],
    usage: 156,
    updated: '2h ago',
    favorite: true,
  },
  {
    id: 2,
    name: 'Pricing Information',
    description: 'Share pricing details when users ask about price.',
    type: 'Message',
    channels: ['Instagram'],
    usage: 98,
    updated: '5h ago',
    favorite: false,
  },
  {
    id: 3,
    name: 'Business Hours Reply',
    description: 'Reply with your business hours.',
    type: 'Message',
    channels: ['Instagram', 'WhatsApp'],
    usage: 72,
    updated: '1d ago',
    favorite: false,
  },
  {
    id: 4,
    name: 'Thank You Comment',
    description: 'Thank users for positive comments.',
    type: 'Comment',
    channels: ['Instagram', 'Facebook'],
    usage: 64,
    updated: '2d ago',
    favorite: true,
  },
  {
    id: 5,
    name: 'FAQ - General',
    description: 'Answer common general questions.',
    type: 'Message',
    channels: ['WhatsApp'],
    usage: 53,
    updated: '3d ago',
    favorite: false,
  },
  {
    id: 6,
    name: 'Out of Office',
    description: "Inform users when you're not available.",
    type: 'Message',
    channels: ['Instagram', 'WhatsApp'],
    usage: 41,
    updated: '4d ago',
    favorite: false,
  },
  {
    id: 7,
    name: 'Product Inquiry Reply',
    description: 'Reply to product related questions.',
    type: 'Message',
    channels: ['Instagram'],
    usage: 36,
    updated: '5d ago',
    favorite: false,
  },
  {
    id: 8,
    name: 'Great Feedback Reply',
    description: 'Reply to positive feedback or reviews.',
    type: 'Comment',
    channels: ['Facebook'],
    usage: 28,
    updated: '6d ago',
    favorite: true,
  },
]);

const filteredTemplates = computed(() => {
  let list = templates.value;
  if (activeTab.value === 'Favorite') {
    list = list.filter(item => item.favorite);
  } else if (activeTab.value !== 'All') {
    list = list.filter(item => item.type === activeTab.value);
  }
  if (channelFilter.value !== 'All Channels') {
    list = list.filter(item => item.channels.includes(channelFilter.value));
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(item => item.name.toLowerCase().includes(q));
  }
  return list;
});

function toggleFavorite(item) {
  item.favorite = !item.favorite;
}

function openPreview(item) {
  previewTemplate.value = item;
  isPreviewOpen.value = true;
}

function duplicateTemplate() {
  useAlert(t('AUTORESPONDER.TEMPLATES.DUPLICATED_TOAST'));
}

function deleteTemplate(item) {
  templates.value = templates.value.filter(tpl => tpl.id !== item.id);
  useAlert(t('AUTORESPONDER.TEMPLATES.DELETED_TOAST'));
}
</script>

<template>
  <div class="h-full bg-background flex flex-col min-h-0">
    <div class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
      <div class="w-full h-full">
        <div
          class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8"
        >
          <div>
            <h1 class="text-xl font-semibold tracking-tight text-foreground">
              {{ t('AUTORESPONDER.TEMPLATES.TITLE') }}
            </h1>
            <p class="text-sm text-muted-foreground mt-1">
              {{ t('AUTORESPONDER.TEMPLATES.SUBTITLE') }}
            </p>
          </div>
          <RelayButton
            class="gap-2 font-medium"
            @click="isCreateWizardOpen = true"
          >
            <span class="i-lucide-plus size-4" />
            {{ t('AUTORESPONDER.TEMPLATES.NEW_TEMPLATE') }}
          </RelayButton>
        </div>

        <div class="flex flex-wrap items-center gap-3 mb-6">
          <div class="relative w-full sm:w-[280px]">
            <span
              class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
            />
            <RelayInput
              v-model="searchQuery"
              :placeholder="t('AUTORESPONDER.TEMPLATES.SEARCH_PLACEHOLDER')"
              class-name="pl-9 bg-background text-[13.5px]"
            />
          </div>

          <RelayDropdownMenu>
            <RelayDropdownMenuTrigger as-child>
              <RelayButton
                variant="outline"
                class="gap-2 text-[13.5px] font-normal h-9"
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

          <RelayButton
            variant="outline"
            class="gap-2 text-[13.5px] font-normal h-9 text-muted-foreground"
          >
            <span
              class="font-mono text-[11px] font-bold bg-muted px-1 py-0.5 rounded mr-1"
            >
              {{ '{}' }}
            </span>
            {{ t('AUTORESPONDER.TEMPLATES.VARIABLES') }}
          </RelayButton>
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
              <span v-if="tab.icon" :class="tab.icon" class="size-4" />
              {{ tab.label }}
              <div
                v-if="activeTab === tab.id"
                class="absolute -bottom-[1px] left-0 right-0 h-[2px] bg-primary rounded-full z-10"
              />
            </button>
          </div>
        </div>

        <div
          class="flex flex-col lg:flex-row gap-6 items-start w-full relative"
        >
          <div
            class="bg-card border border-border rounded-xl shadow-sm overflow-hidden flex flex-col flex-1 min-w-0 transition-all duration-300"
          >
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse min-w-[900px]">
                <thead>
                  <tr class="border-b border-border bg-muted/20">
                    <th
                      class="px-5 py-3.5 text-sm font-medium text-muted-foreground"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.TABLE_TEMPLATE') }}
                    </th>
                    <th
                      class="px-5 py-3.5 text-sm font-medium text-muted-foreground w-28"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.TABLE_TYPE') }}
                    </th>
                    <th
                      class="px-5 py-3.5 text-sm font-medium text-muted-foreground w-32"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.TABLE_CHANNEL') }}
                    </th>
                    <th
                      class="px-5 py-3.5 text-sm font-medium text-muted-foreground w-28"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.TABLE_USAGE') }}
                    </th>
                    <th
                      class="px-5 py-3.5 text-sm font-medium text-muted-foreground w-32"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.TABLE_UPDATED') }}
                    </th>
                    <th
                      class="px-5 py-3.5 text-sm font-medium text-muted-foreground w-28 text-center"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.TABLE_ACTIONS') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border">
                  <tr
                    v-for="item in filteredTemplates"
                    :key="item.id"
                    class="hover:bg-muted/30 transition-colors group cursor-pointer"
                    @click="openPreview(item)"
                  >
                    <td class="px-4 py-4">
                      <div class="flex flex-col gap-1">
                        <div class="flex items-center gap-2">
                          <span class="text-sm font-semibold text-foreground">{{
                            item.name
                          }}</span>
                          <button
                            type="button"
                            @click.stop="toggleFavorite(item)"
                          >
                            <span
                              class="i-lucide-star size-4 cursor-pointer transition-colors"
                              :class="
                                item.favorite
                                  ? 'text-amber-400 fill-amber-400'
                                  : 'text-muted-foreground/30 hover:text-muted-foreground'
                              "
                            />
                          </button>
                        </div>
                        <span
                          class="text-[13px] text-muted-foreground line-clamp-1"
                        >
                          {{ item.description }}
                        </span>
                      </div>
                    </td>
                    <td class="px-4 py-4">
                      <RelayBadge
                        variant="secondary"
                        class="bg-primary/10 text-primary border-none font-medium px-2 py-0.5 rounded-md"
                      >
                        {{
                          item.type === 'Message'
                            ? t('AUTORESPONDER.COMMON.TYPE_MESSAGE')
                            : t('AUTORESPONDER.COMMON.TYPE_COMMENT')
                        }}
                      </RelayBadge>
                    </td>
                    <td class="px-4 py-4">
                      <div class="flex items-center gap-1.5">
                        <img
                          v-for="ch in item.channels"
                          :key="ch"
                          :src="CHANNEL_LOGO_URLS[ch]"
                          class="size-5 rounded"
                          :title="ch"
                        />
                      </div>
                    </td>
                    <td class="px-4 py-4">
                      <span class="text-[13.5px] font-medium text-foreground">
                        {{
                          t('AUTORESPONDER.TEMPLATES.USAGE_TIMES', {
                            count: item.usage,
                          })
                        }}
                      </span>
                    </td>
                    <td class="px-4 py-4">
                      <span class="text-[13.5px] text-muted-foreground">{{
                        item.updated
                      }}</span>
                    </td>
                    <td class="px-4 py-4 text-center" @click.stop>
                      <div
                        class="flex items-center justify-center gap-1.5 text-muted-foreground"
                      >
                        <button
                          type="button"
                          class="p-1.5 rounded-md hover:bg-muted hover:text-foreground transition-colors"
                          :title="t('AUTORESPONDER.COMMON.COPY')"
                          @click="duplicateTemplate"
                        >
                          <span class="i-lucide-copy size-4" />
                        </button>
                        <button
                          type="button"
                          class="p-1.5 rounded-md hover:bg-muted hover:text-foreground transition-colors"
                          :title="t('AUTORESPONDER.COMMON.EDIT')"
                          @click="openPreview(item)"
                        >
                          <span class="i-lucide-pencil size-4" />
                        </button>
                        <RelayDropdownMenu>
                          <RelayDropdownMenuTrigger as-child>
                            <button
                              type="button"
                              class="p-1.5 rounded-md hover:bg-muted hover:text-foreground transition-colors"
                            >
                              <span class="i-lucide-more-vertical size-4" />
                            </button>
                          </RelayDropdownMenuTrigger>
                          <RelayDropdownMenuContent align="end" class="w-40">
                            <RelayDropdownMenuItem @click="openPreview(item)">
                              {{ t('AUTORESPONDER.TEMPLATES.PREVIEW') }}
                            </RelayDropdownMenuItem>
                            <RelayDropdownMenuItem @click="duplicateTemplate">
                              {{ t('AUTORESPONDER.COMMON.DUPLICATE') }}
                            </RelayDropdownMenuItem>
                            <RelayDropdownMenuItem
                              destructive
                              @click="deleteTemplate(item)"
                            >
                              {{ t('AUTORESPONDER.COMMON.DELETE') }}
                            </RelayDropdownMenuItem>
                          </RelayDropdownMenuContent>
                        </RelayDropdownMenu>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="filteredTemplates.length === 0">
                    <td
                      colspan="6"
                      class="px-4 py-16 text-center text-sm text-muted-foreground"
                    >
                      {{ t('AUTORESPONDER.TEMPLATES.EMPTY_STATE') }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div
              class="border-t border-border bg-muted/10 px-4 py-3 flex flex-col sm:flex-row items-center justify-between gap-4"
            >
              <div class="text-[13px] text-muted-foreground">
                {{
                  t('AUTORESPONDER.TEMPLATES.SHOWING_COUNT', {
                    count: filteredTemplates.length,
                    total: templates.length,
                  })
                }}
              </div>
            </div>
          </div>

          <TemplatePreviewPanel
            v-model:open="isPreviewOpen"
            :template="previewTemplate"
          />
        </div>
      </div>

      <CreateTemplateWizard v-model:open="isCreateWizardOpen" />
    </div>
  </div>
</template>
