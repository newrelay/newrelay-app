<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import IntegrationItem from './IntegrationItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const FILTERS = {
  ALL: 'all',
  CONNECTED: 'connected',
  DISCONNECTED: 'disconnected',
};

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();

const searchQuery = ref('');
const activeFilter = ref(FILTERS.ALL);
const selectedIntegration = ref(null);
const dialogRef = ref(null);
const uiFlags = getters['integrations/getUIFlags'];

const integrationList = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const filterTabs = computed(() => [
  {
    key: FILTERS.ALL,
    label: t('INTEGRATION_SETTINGS.FILTERS.ALL'),
  },
  {
    key: FILTERS.CONNECTED,
    label: t('INTEGRATION_SETTINGS.FILTERS.CONNECTED'),
  },
  {
    key: FILTERS.DISCONNECTED,
    label: t('INTEGRATION_SETTINGS.FILTERS.DISCONNECTED'),
  },
]);

const filteredByStatus = computed(() => {
  if (activeFilter.value === FILTERS.CONNECTED) {
    return integrationList.value.filter(item => item.enabled);
  }
  if (activeFilter.value === FILTERS.DISCONNECTED) {
    return integrationList.value.filter(item => !item.enabled);
  }
  return integrationList.value;
});

const filteredIntegrationList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return filteredByStatus.value;
  return picoSearch(filteredByStatus.value, query, ['name', 'description']);
});

const hasActiveQuery = computed(
  () => !!searchQuery.value.trim() || activeFilter.value !== FILTERS.ALL
);

onMounted(() => {
  store.dispatch('integrations/get');
});

const openDeletePopup = async integration => {
  selectedIntegration.value = integration;
  await nextTick();
  dialogRef.value?.open();
};

const closeDeletePopup = () => {
  dialogRef.value?.close();
  selectedIntegration.value = null;
};

const confirmDeletion = async () => {
  if (!selectedIntegration.value) return;
  const integrationId = selectedIntegration.value.id;
  closeDeletePopup();
  try {
    await store.dispatch('integrations/deleteIntegration', integrationId);
    useAlert(t('INTEGRATION_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INTEGRATION_SETTINGS.LOADING')"
  >
    <template #body>
      <div class="flex flex-col space-y-10">
        <div
          class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
        >
          <div
            class="scrollbar-hide flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0"
          >
            <RelayButton
              v-for="tab in filterTabs"
              :key="tab.key"
              :variant="activeFilter === tab.key ? 'outline' : 'ghost'"
              size="sm"
              class="h-9 shrink-0 px-4"
              :class="
                activeFilter === tab.key
                  ? 'border-border bg-accent/50 font-semibold text-foreground shadow-sm'
                  : 'font-medium text-muted-foreground hover:text-foreground'
              "
              @click="activeFilter = tab.key"
            >
              {{ tab.label }}
            </RelayButton>
          </div>
          <div class="relative w-full shrink-0 sm:w-72">
            <Icon
              icon="i-lucide-search"
              class="pointer-events-none absolute top-1/2 size-4 -translate-y-1/2 text-muted-foreground ltr:left-3 rtl:right-3"
            />
            <RelayInput
              v-model="searchQuery"
              type="search"
              :placeholder="$t('INTEGRATION_SETTINGS.SEARCH_PLACEHOLDER')"
              class-name="h-9 w-full bg-card shadow-sm text-[13px] ltr:pl-9 rtl:pr-9"
            />
          </div>
        </div>

        <div
          v-if="!filteredIntegrationList.length && hasActiveQuery"
          class="flex flex-1 items-center justify-center py-20 text-center text-sm text-muted-foreground"
        >
          {{ $t('INTEGRATION_SETTINGS.NO_RESULTS') }}
        </div>
        <div v-else class="grid grid-cols-1 gap-5 xl:grid-cols-2">
          <IntegrationItem
            v-for="item in filteredIntegrationList"
            :id="item.id"
            :key="item.id"
            :name="item.name"
            :description="item.description"
            :enabled="item.enabled"
            @disconnect="openDeletePopup(item)"
          />
        </div>
      </div>
    </template>

    <Dialog
      ref="dialogRef"
      type="alert"
      :title="$t('INTEGRATION_SETTINGS.DELETE.CONFIRM.TITLE')"
      :description="
        $t('INTEGRATION_SETTINGS.DELETE.CONFIRM.MESSAGE', {
          integrationName: selectedIntegration?.name,
        })
      "
      :confirm-button-label="$t('INTEGRATION_SETTINGS.DELETE.CONFIRM.YES')"
      :cancel-button-label="$t('INTEGRATION_SETTINGS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
      @close="selectedIntegration = null"
    />
  </SettingsLayout>
</template>
