<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import CannedModal from './component/CannedModal.vue';
import SettingsLayout from '../SettingsLayout.vue';
import {
  RelayButton,
  RelayConfirmModal,
  RelayInput,
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
    :no-records-found="false"
  >
    <template #body>
      <div
        class="mb-8 overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div
          class="flex flex-col justify-between gap-4 border-b border-border/40 p-4 sm:flex-row sm:items-center sm:p-6"
        >
          <div>
            <h3 class="text-base font-medium text-foreground">
              {{ $t('CANNED_MGMT.HEADER') }}
            </h3>
            <p class="mt-1 max-w-3xl text-sm text-muted-foreground">
              {{ $t('CANNED_MGMT.DESCRIPTION') }}
            </p>
          </div>
          <RelayButton
            class="h-9 shrink-0 px-4 text-[13px] font-medium shadow-sm"
            @click="openAddPopup"
          >
            {{ $t('CANNED_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </div>

        <div class="space-y-6 p-4 sm:p-6">
          <div
            class="flex items-center justify-between rounded-xl border border-border/60 bg-card p-2 shadow-xs"
          >
            <div class="relative w-full max-w-md">
              <Icon
                icon="i-lucide-search"
                class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <RelayInput
                v-model="searchQuery"
                type="search"
                :placeholder="$t('CANNED_MGMT.SEARCH_PLACEHOLDER')"
                class-name="h-9 w-full border-border/40 bg-background/50 pl-9 text-[13.5px] shadow-none focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/20"
              />
            </div>
            <div
              class="shrink-0 border-l border-border/40 px-4 text-[13px] font-medium text-muted-foreground"
            >
              {{ $t('CANNED_MGMT.COUNT', { n: filteredRecords.length }) }}
            </div>
          </div>

          <div
            class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
          >
            <div
              v-if="searchQuery && !filteredRecords.length"
              class="flex flex-col items-center justify-center p-16 text-center"
            >
              <p class="text-sm text-muted-foreground">
                {{ $t('CANNED_MGMT.NO_RESULTS') }}
              </p>
            </div>

            <div
              v-else-if="!records.length"
              class="flex flex-col items-center justify-center p-16 text-center"
            >
              <div
                class="mb-5 flex size-14 items-center justify-center rounded-full bg-muted"
              >
                <Icon
                  icon="i-lucide-message-square"
                  class="size-6 text-muted-foreground"
                />
              </div>
              <h3 class="text-base font-medium text-foreground">
                {{ $t('CANNED_MGMT.LIST.404') }}
              </h3>
              <p class="mt-1 text-[13.5px] text-muted-foreground">
                {{ $t('CANNED_MGMT.LIST.DESC') }}
              </p>
            </div>

            <div v-else class="min-w-full">
              <div
                class="grid grid-cols-[200px_1fr_120px] items-center border-b border-border/40 bg-muted/30 px-6 py-3.5"
              >
                <div class="text-[14px] font-medium text-muted-foreground">
                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 hover:text-foreground"
                    @click="toggleSort"
                  >
                    {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.SHORT_CODE') }}
                    <Icon icon="i-lucide-arrow-up-down" class="size-3.5" />
                  </button>
                </div>
                <div class="text-[14px] font-medium text-muted-foreground">
                  {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.CONTENT') }}
                </div>
                <div
                  class="text-right text-[14px] font-medium text-muted-foreground"
                >
                  {{ $t('CANNED_MGMT.LIST.TABLE_HEADER.ACTIONS') }}
                </div>
              </div>

              <div class="divide-y divide-border/40">
                <div
                  v-for="cannedItem in filteredRecords"
                  :key="cannedItem.id || cannedItem.short_code"
                  class="group grid grid-cols-[200px_1fr_120px] items-center px-6 py-4 transition-colors hover:bg-muted/20"
                >
                  <div class="flex items-center gap-3 pr-4">
                    <div
                      class="inline-flex items-center gap-1.5 rounded-md border border-primary/20 bg-primary/10 px-2.5 py-1 font-mono text-[13px] font-medium text-primary"
                    >
                      <Icon
                        icon="i-lucide-terminal-square"
                        class="size-3.5 opacity-70"
                      />
                      {{ cannedItem.short_code }}
                    </div>
                  </div>

                  <div
                    class="truncate pr-6 text-[14px] leading-relaxed text-foreground"
                  >
                    {{ getPlainText(cannedItem.content) }}
                  </div>

                  <div
                    class="flex items-center justify-end gap-2 opacity-0 transition-opacity group-hover:opacity-100"
                  >
                    <RelayTooltip
                      :content="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
                      side="top"
                    >
                      <RelayButton
                        variant="ghost"
                        size="icon"
                        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground border border-border hover:border-transparent"
                        :disabled="loading[cannedItem.id]"
                        @click="openEditPopup(cannedItem)"
                      >
                        <Icon icon="i-lucide-pencil" class="size-3.5" />
                      </RelayButton>
                    </RelayTooltip>
                    <RelayTooltip
                      :content="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
                      side="top"
                    >
                      <RelayButton
                        variant="ghost"
                        size="icon"
                        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-destructive/20 hover:bg-destructive/10 hover:text-destructive border border-border hover:border-transparent"
                        :disabled="loading[cannedItem.id]"
                        @click="openDeletePopup(cannedItem)"
                      >
                        <Icon icon="i-lucide-trash-2" class="size-3.5" />
                      </RelayButton>
                    </RelayTooltip>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

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
    </template>
  </SettingsLayout>
</template>
