<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';

import SettingsLayout from '../../SettingsLayout.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import DashboardAppModal from './DashboardAppModal.vue';
import DashboardAppsRow from './DashboardAppsRow.vue';

const store = useStore();
const { t } = useI18n();

const records = useMapGetter('dashboardApps/getRecords');
const uiFlags = useMapGetter('dashboardApps/getUIFlags');

const searchQuery = ref('');
const showDashboardAppPopup = ref(false);
const selectedApp = ref({});
const mode = ref('CREATE');
const loading = ref({});
const deleteDialogRef = ref(null);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['title']);
});

const emptyMessage = computed(() =>
  searchQuery.value.trim()
    ? t('INTEGRATION_SETTINGS.DASHBOARD_APPS.NO_RESULTS')
    : t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.404')
);

const selectedAppName = computed(() => selectedApp.value?.title || '');

onMounted(() => {
  store.dispatch('dashboardApps/get');
});

const openCreatePopup = () => {
  mode.value = 'CREATE';
  selectedApp.value = {};
  showDashboardAppPopup.value = true;
};

const toggleDashboardAppPopup = () => {
  showDashboardAppPopup.value = !showDashboardAppPopup.value;
  selectedApp.value = {};
};

const editApp = app => {
  loading.value[app.id] = true;
  mode.value = 'UPDATE';
  selectedApp.value = app;
  showDashboardAppPopup.value = true;
};

const openDeletePopup = async app => {
  selectedApp.value = app;
  await Promise.resolve();
  deleteDialogRef.value?.open();
};

const deleteApp = async id => {
  try {
    await store.dispatch('dashboardApps/delete', id);
    useAlert(t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.API_SUCCESS'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.API_ERROR'));
  } finally {
    loading.value[id] = false;
    selectedApp.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedApp.value.id] = true;
  deleteApp(selectedApp.value.id);
  deleteDialogRef.value?.close();
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div class="space-y-6">
        <div>
          <h2 class="text-base font-medium text-foreground">
            {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.TITLE') }}
          </h2>
          <p
            class="mt-1.5 max-w-4xl text-[13.5px] leading-relaxed text-muted-foreground"
          >
            {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DESCRIPTION') }}
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
                t('INTEGRATION_SETTINGS.DASHBOARD_APPS.SEARCH_PLACEHOLDER')
              "
              class-name="h-9 border-border/60 bg-card pl-9 text-[13.5px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <RelayButton
            class="h-9 shrink-0 px-5 font-medium shadow-sm"
            @click="openCreatePopup"
          >
            {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.HEADER_BTN_TXT') }}
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
            class="grid grid-cols-[1.2fr_2fr_1fr] gap-4 border-b border-border/40 bg-background/50 p-4"
          >
            <div class="text-[13px] font-semibold text-foreground">
              {{
                t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER.NAME')
              }}
            </div>
            <div class="text-[13px] font-semibold text-foreground">
              {{
                t(
                  'INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER.ENDPOINT'
                )
              }}
            </div>
            <div
              class="pr-2 text-right text-[13px] font-semibold text-foreground"
            >
              {{
                t(
                  'INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER.ACTIONS'
                )
              }}
            </div>
          </div>

          <div class="divide-y divide-border/40">
            <DashboardAppsRow
              v-for="app in filteredRecords"
              :key="app.id"
              :app="app"
              :loading="loading[app.id]"
              @edit="editApp"
              @delete="openDeletePopup"
            />
          </div>
        </div>
      </div>
    </template>

    <DashboardAppModal
      v-if="showDashboardAppPopup"
      :show="showDashboardAppPopup"
      :mode="mode"
      :selected-app-data="selectedApp"
      @close="toggleDashboardAppPopup"
    />

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.TITLE')"
      :description="
        t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.MESSAGE', {
          appName: selectedAppName,
        })
      "
      :confirm-button-label="
        t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.CONFIRM_YES')
      "
      :cancel-button-label="
        t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.CONFIRM_NO')
      "
      @confirm="confirmDeletion"
      @close="selectedApp = {}"
    />
  </SettingsLayout>
</template>
