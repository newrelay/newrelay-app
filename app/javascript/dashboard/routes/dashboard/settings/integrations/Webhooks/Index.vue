<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { picoSearch } from '@scmmishra/pico-search';

import SettingsLayout from '../../SettingsLayout.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import NewWebhook from './NewWebHook.vue';
import EditWebhook from './EditWebHook.vue';
import WebhookRow from './WebhookRow.vue';

const store = useStore();
const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const records = useMapGetter('webhooks/getWebhooks');
const uiFlags = useMapGetter('webhooks/getUIFlags');

const searchQuery = ref('');
const selectedWebhook = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const deleteDialogRef = ref(null);
const addDialogRef = ref(null);
const editDialogRef = ref(null);
const loading = ref({});

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name', 'url']);
});

const emptyMessage = computed(() =>
  searchQuery.value.trim()
    ? t('INTEGRATION_SETTINGS.WEBHOOK.NO_RESULTS')
    : t('INTEGRATION_SETTINGS.WEBHOOK.LIST.404')
);

const selectedWebhookUrl = computed(() => selectedWebhook.value?.url || '');

onMounted(() => {
  store.dispatch('integrations/get', 'webhook');
  store.dispatch('webhooks/get');
});

const openAddPopup = async () => {
  showAddPopup.value = true;
  await nextTick();
  addDialogRef.value?.open();
};

const hideAddPopup = () => {
  showAddPopup.value = false;
  addDialogRef.value?.close();
};

const openEditPopup = async webhook => {
  selectedWebhook.value = webhook;
  showEditPopup.value = true;
  await nextTick();
  editDialogRef.value?.open();
};

const hideEditPopup = () => {
  showEditPopup.value = false;
  selectedWebhook.value = {};
  editDialogRef.value?.close();
};

const openDeletePopup = async webhook => {
  selectedWebhook.value = webhook;
  await nextTick();
  deleteDialogRef.value?.open();
};

const deleteWebhook = async id => {
  try {
    await store.dispatch('webhooks/delete', id);
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedWebhook.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedWebhook.value.id] = true;
  deleteWebhook(selectedWebhook.value.id);
  deleteDialogRef.value?.close();
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="t('INTEGRATION_SETTINGS.WEBHOOK.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div class="space-y-6">
        <div>
          <h2 class="text-base font-medium text-foreground">
            {{ t('INTEGRATION_SETTINGS.WEBHOOK.HEADER') }}
          </h2>
          <p
            class="mt-1.5 max-w-4xl text-[13.5px] leading-relaxed text-muted-foreground"
          >
            {{
              replaceInstallationName(
                t('INTEGRATION_SETTINGS.WEBHOOK.DESCRIPTION')
              )
            }}
          </p>
        </div>

        <div class="flex items-center justify-between gap-4">
          <div class="relative w-full max-w-sm">
            <Icon
              icon="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            />
            <RelayInput
              v-model="searchQuery"
              type="search"
              :placeholder="
                t('INTEGRATION_SETTINGS.WEBHOOK.SEARCH_PLACEHOLDER')
              "
              class-name="h-9 border-border/60 bg-card pl-9 text-[13.5px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <RelayButton
            class="h-9 shrink-0 px-5 font-medium shadow-sm"
            @click="openAddPopup"
          >
            {{ t('INTEGRATION_SETTINGS.WEBHOOK.HEADER_BTN_TXT') }}
          </RelayButton>
        </div>

        <div
          v-if="!filteredRecords.length"
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
              {{ t('INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.DETAILS') }}
            </div>
            <div class="text-[13px] font-semibold text-foreground">
              {{ t('INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.URL') }}
            </div>
            <div
              class="pr-2 text-right text-[13px] font-semibold text-foreground"
            >
              {{ t('INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>

          <div class="divide-y divide-border/40">
            <WebhookRow
              v-for="webhook in filteredRecords"
              :key="webhook.id"
              :webhook="webhook"
              :loading="loading[webhook.id]"
              @edit="openEditPopup"
              @delete="openDeletePopup"
            />
          </div>
        </div>
      </div>
    </template>

    <Dialog
      ref="addDialogRef"
      type="edit"
      title=""
      width="xl"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="hideAddPopup"
    >
      <NewWebhook v-if="showAddPopup" :on-close="hideAddPopup" />
    </Dialog>

    <Dialog
      ref="editDialogRef"
      type="edit"
      title=""
      width="xl"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="hideEditPopup"
    >
      <EditWebhook
        v-if="showEditPopup"
        :id="selectedWebhook.id"
        :value="selectedWebhook"
        :on-close="hideEditPopup"
      />
    </Dialog>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')"
      :description="
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE', {
          webhookURL: selectedWebhookUrl,
        })
      "
      :confirm-button-label="
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')
      "
      :cancel-button-label="t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
      @close="selectedWebhook = {}"
    />
  </SettingsLayout>
</template>
