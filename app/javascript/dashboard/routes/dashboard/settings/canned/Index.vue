<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import CannedModal from './component/CannedModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import {
  RelayButton,
  RelayConfirmModal,
} from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineOptions({
  name: 'CannedResponseSettings',
});

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

const loading = ref({});
const showCannedModal = ref(false);
const cannedModalMode = ref('add');
const showDeleteConfirmationPopup = ref(false);
const selectedResponse = ref({});

const sortOrder = ref('asc');
const searchQuery = ref('');

const records = computed(() =>
  getters.getSortedCannedResponses.value(sortOrder.value)
);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, [
    { name: 'short_code', weight: 4 },
    'content',
  ]);
});

const uiFlags = computed(() => getters.getUIFlags.value);

const deleteConfirmText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.YES')} ${selectedResponse.value.short_code}`
);

const deleteRejectText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.NO')} ${selectedResponse.value.short_code}`
);

const deleteMessage = computed(() => {
  return ` ${selectedResponse.value.short_code} ? `;
});

const toggleSort = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

const fetchCannedResponses = async () => {
  try {
    await store.dispatch('getCannedResponse');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
  fetchCannedResponses();
});

const openAddPopup = () => {
  cannedModalMode.value = 'add';
  selectedResponse.value = {};
  showCannedModal.value = true;
};

const hideCannedModal = () => {
  showCannedModal.value = false;
};

const openEditPopup = response => {
  cannedModalMode.value = 'edit';
  selectedResponse.value = response;
  showCannedModal.value = true;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCannedResponse = async id => {
  try {
    await store.dispatch('deleteCannedResponse', id);
    useAlert(t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedResponse.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedResponse.value.id] = true;
  closeDeletePopup();
  deleteCannedResponse(selectedResponse.value.id);
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('CANNED_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('CANNED_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('CANNED_MGMT.HEADER')"
        :description="$t('CANNED_MGMT.DESCRIPTION')"
        :search-placeholder="$t('CANNED_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="canned_responses"
      >
        <template v-if="records?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('CANNED_MGMT.COUNT', { n: filteredRecords.length }) }}
          </span>
        </template>
        <template #actions>
          <RelayButton size="sm" @click="openAddPopup">
            {{ $t('CANNED_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div
        class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div v-if="!filteredRecords.length && searchQuery" class="py-20">
          <p class="text-center text-sm text-muted-foreground">
            {{ $t('CANNED_MGMT.NO_RESULTS') }}
          </p>
        </div>
        <div
          v-else-if="!filteredRecords.length"
          class="flex flex-col items-center justify-center py-20"
        >
          <div
            class="mb-5 flex size-16 items-center justify-center rounded-full border border-border bg-muted/50"
          >
            <Icon
              icon="i-lucide-message-square"
              class="size-6 text-muted-foreground/70"
            />
          </div>
          <h3 class="text-base font-semibold text-foreground">
            {{ $t('CANNED_MGMT.LIST.404') }}
          </h3>
        </div>
        <div v-else class="overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b border-border/40 bg-background">
                <th
                  class="w-52 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 hover:text-foreground"
                    @click="toggleSort"
                  >
                    {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.SHORT_CODE') }}
                    <Icon icon="i-lucide-arrow-up-down" class="size-3.5" />
                  </button>
                </th>
                <th
                  class="px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.CONTENT') }}
                </th>
                <th
                  class="w-32 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border/40">
              <tr
                v-for="cannedItem in filteredRecords"
                :key="cannedItem.id || cannedItem.short_code"
                class="group bg-card transition-colors hover:bg-muted/10"
              >
                <td class="px-6 py-4">
                  <div
                    class="inline-flex items-center gap-1.5 rounded-lg border border-primary/20 bg-primary/10 px-2.5 py-1 font-mono text-xs font-medium text-primary"
                  >
                    <Icon
                      icon="i-lucide-terminal-square"
                      class="size-3.5 text-muted-foreground"
                    />
                    {{ cannedItem.short_code }}
                  </div>
                </td>
                <td class="px-6 py-4">
                  <p class="line-clamp-2 text-[14px] text-foreground">
                    {{ getPlainText(cannedItem.content) }}
                  </p>
                </td>
                <td class="px-6 py-4">
                  <div
                    class="flex items-center gap-1.5 opacity-0 transition-opacity group-hover:opacity-100"
                  >
                    <RelayButton
                      v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
                      variant="ghost"
                      size="icon"
                      class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
                      :disabled="loading[cannedItem.id]"
                      @click="openEditPopup(cannedItem)"
                    >
                      <Icon icon="i-lucide-pencil" class="size-3.5" />
                    </RelayButton>
                    <RelayButton
                      v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
                      variant="ghost"
                      size="icon"
                      class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-destructive/20 hover:bg-destructive/10 hover:text-destructive"
                      :disabled="loading[cannedItem.id]"
                      @click="openDeletePopup(cannedItem)"
                    >
                      <Icon icon="i-lucide-trash-2" class="size-3.5" />
                    </RelayButton>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>

    <CannedModal
      :show="showCannedModal"
      :mode="cannedModalMode"
      :selected-response="selectedResponse"
      @close="hideCannedModal"
    />

    <RelayConfirmModal
      :show="showDeleteConfirmationPopup"
      :title="$t('CANNED_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CANNED_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :cancel-text="deleteRejectText"
      @close="closeDeletePopup"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
