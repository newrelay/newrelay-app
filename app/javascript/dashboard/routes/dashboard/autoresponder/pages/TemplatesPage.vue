<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  RelayButton,
  RelayInput,
  RelayBadge,
} from 'dashboard/components-next/relay';
import { useAlert } from 'dashboard/composables';
import TemplatePreviewPanel from '../components/TemplatePreviewPanel.vue';
import CreateTemplateWizard from '../components/CreateTemplateWizard.vue';
import CreateAutomationModal from '../components/CreateAutomationModal.vue';
import AccountSwitcher from '../components/AccountSwitcher.vue';

const { t } = useI18n();
const store = useStore();

const searchQuery = ref('');
const activeTab = ref('All');
const isPreviewOpen = ref(false);
const isWizardOpen = ref(false);
const previewTemplate = ref(null);
const editingTemplate = ref(null);
const isCreateAutomationOpen = ref(false);
const automationTemplate = ref(null);

onMounted(() => {
  store.dispatch('commentAutomationTemplates/get');
});

const templates = useMapGetter('commentAutomationTemplates/getTemplates');

const tabs = computed(() => [
  { id: 'All', icon: '', label: t('AUTORESPONDER.TEMPLATES.TAB_ALL') },
  {
    id: 'message',
    icon: 'i-lucide-message-square',
    label: t('AUTORESPONDER.TEMPLATES.TAB_MESSAGE'),
  },
  {
    id: 'comment',
    icon: 'i-lucide-message-circle',
    label: t('AUTORESPONDER.TEMPLATES.TAB_COMMENT'),
  },
  {
    id: 'Favorite',
    icon: 'i-lucide-star',
    label: t('AUTORESPONDER.TEMPLATES.TAB_FAVORITE'),
  },
]);

const filteredTemplates = computed(() => {
  let list = templates.value;
  if (activeTab.value === 'Favorite') {
    list = list.filter(item => item.favorite);
  } else if (activeTab.value !== 'All') {
    list = list.filter(item => item.template_type === activeTab.value);
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(item => item.name.toLowerCase().includes(q));
  }
  return list;
});

function toggleFavorite(item) {
  store.dispatch('commentAutomationTemplates/update', {
    id: item.id,
    template: { favorite: !item.favorite },
  });
}

function openPreview(item) {
  previewTemplate.value = item;
  isPreviewOpen.value = true;
}

function openCreateWizard() {
  editingTemplate.value = null;
  isWizardOpen.value = true;
}

function openEditWizard(item) {
  editingTemplate.value = item;
  isWizardOpen.value = true;
}

function duplicateTemplate(item) {
  store.dispatch('commentAutomationTemplates/create', {
    template: {
      name: t('AUTORESPONDER.TEMPLATES.COPY_NAME', { name: item.name }),
      template_type: item.template_type,
      public_replies: item.public_replies,
      dm_text_body: item.dm_text_body,
      favorite: false,
    },
  });
  useAlert(t('AUTORESPONDER.TEMPLATES.DUPLICATED_TOAST'));
}

function deleteTemplate(item) {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('AUTORESPONDER.TEMPLATES.DELETE_CONFIRM'))) return;
  store.dispatch('commentAutomationTemplates/delete', item.id);
  useAlert(t('AUTORESPONDER.TEMPLATES.DELETED_TOAST'));
}

function useInAutomation(template) {
  automationTemplate.value = template;
  isCreateAutomationOpen.value = true;
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
            <h1 class="text-[16px] font-medium tracking-tight text-foreground">
              {{ t('AUTORESPONDER.TEMPLATES.TITLE') }}
            </h1>
            <p class="text-[13.5px] text-muted-foreground mt-1">
              {{ t('AUTORESPONDER.TEMPLATES.SUBTITLE') }}
            </p>
          </div>
          <div class="flex items-center gap-3">
            <AccountSwitcher />
            <RelayButton class="gap-2 font-medium" @click="openCreateWizard">
              <span class="i-lucide-plus size-4" />
              {{ t('AUTORESPONDER.TEMPLATES.NEW_TEMPLATE') }}
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
              :placeholder="t('AUTORESPONDER.TEMPLATES.SEARCH_PLACEHOLDER')"
              class-name="pl-9 bg-background text-[13.5px]"
            />
          </div>
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
              <table class="w-full text-left border-collapse min-w-[760px]">
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
                          {{ item.dm_text_body }}
                        </span>
                      </div>
                    </td>
                    <td class="px-4 py-4">
                      <RelayBadge
                        variant="secondary"
                        class="bg-primary/10 text-primary border-none font-medium px-2 py-0.5 rounded-md"
                      >
                        {{
                          item.template_type === 'message'
                            ? t('AUTORESPONDER.COMMON.TYPE_MESSAGE')
                            : t('AUTORESPONDER.COMMON.TYPE_COMMENT')
                        }}
                      </RelayBadge>
                    </td>
                    <td class="px-4 py-4">
                      <span class="text-[13.5px] font-medium text-foreground">
                        {{
                          t('AUTORESPONDER.TEMPLATES.USAGE_TIMES', {
                            count: item.usage_count,
                          })
                        }}
                      </span>
                    </td>
                    <td class="px-4 py-4">
                      <span class="text-[13.5px] text-muted-foreground">{{
                        dynamicTime(item.updated_at)
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
                          @click="duplicateTemplate(item)"
                        >
                          <span class="i-lucide-copy size-4" />
                        </button>
                        <button
                          type="button"
                          class="p-1.5 rounded-md hover:bg-muted hover:text-foreground transition-colors"
                          :title="t('AUTORESPONDER.COMMON.EDIT')"
                          @click="openEditWizard(item)"
                        >
                          <span class="i-lucide-pencil size-4" />
                        </button>
                        <button
                          type="button"
                          class="p-1.5 rounded-md hover:bg-muted hover:text-destructive transition-colors"
                          :title="t('AUTORESPONDER.COMMON.DELETE')"
                          @click="deleteTemplate(item)"
                        >
                          <span class="i-lucide-trash-2 size-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="filteredTemplates.length === 0">
                    <td
                      colspan="5"
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
            @use-in-automation="useInAutomation"
          />
        </div>
      </div>

      <CreateTemplateWizard
        v-model:open="isWizardOpen"
        :template="editingTemplate"
      />
      <CreateAutomationModal
        v-model:open="isCreateAutomationOpen"
        :template="automationTemplate"
      />
    </div>
  </div>
</template>
