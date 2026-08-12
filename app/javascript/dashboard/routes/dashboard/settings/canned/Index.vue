<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SettingsListCard from '../components/SettingsListCard.vue';
import SettingsListRow from '../components/SettingsListRow.vue';
import {
  RelayButton,
  RelayModal,
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

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const cannedResponseAPI = ref({ message: '' });

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
    `${t('CANNED_MGMT.DELETE.CONFIRM.YES')} ${activeResponse.value.short_code}`
);

const deleteRejectText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.NO')} ${activeResponse.value.short_code}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.short_code} ? `;
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

const showAlertMessage = message => {
  loading.value[activeResponse.value.id] = false;
  activeResponse.value = {};
  cannedResponseAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  activeResponse.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  activeResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCannedResponse = async id => {
  try {
    await store.dispatch('deleteCannedResponse', id);
    showAlertMessage(t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  loading.value[activeResponse.value.id] = true;
  closeDeletePopup();
  deleteCannedResponse(activeResponse.value.id);
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('CANNED_MGMT.LOADING')"
    :no-records-found="false"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('CANNED_MGMT.HEADER')"
        :description="$t('CANNED_MGMT.DESCRIPTION')"
        :search-placeholder="$t('CANNED_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="canned_responses"
      >
        <template #count>
          <span class="text-sm text-muted-foreground">
            {{ filteredRecords.length }}
            {{ $t('CANNED_MGMT.COUNT_SUFFIX') }}
          </span>
        </template>
        <template #actions>
          <RelayButton
            v-tooltip.top="$t('CANNED_MGMT.LIST.TABLE_HEADER.SHORT_CODE')"
            variant="ghost"
            size="icon"
            class="size-9 border border-border text-muted-foreground shadow-xs hover:border-transparent hover:bg-muted/50 hover:text-foreground"
            @click="toggleSort"
          >
            <Icon icon="i-lucide-arrow-up-down" class="size-4" />
          </RelayButton>
          <RelayButton size="sm" @click="openAddPopup">
            {{ $t('CANNED_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <SettingsListCard
        :details-label="$t('CANNED_MGMT.LIST.TABLE_HEADER.CONTENT')"
        :actions-label="$t('CANNED_MGMT.LIST.TABLE_HEADER.ACTIONS')"
        :show-column-headers="!!filteredRecords.length"
      >
        <template v-if="!filteredRecords.length" #empty>
          <div
            v-if="searchQuery"
            class="px-6 text-center text-sm text-muted-foreground"
          >
            {{ $t('CANNED_MGMT.NO_RESULTS') }}
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center bg-muted/10 px-6 py-4"
          >
            <div
              class="mb-5 flex size-16 items-center justify-center rounded-full border border-border bg-muted/50"
            >
              <Icon
                icon="i-lucide-message-square-off"
                class="size-7 text-muted-foreground/70"
              />
            </div>
            <h3 class="mb-1.5 text-base font-semibold text-foreground">
              {{ $t('CANNED_MGMT.LIST.404') }}
            </h3>
          </div>
        </template>

        <SettingsListRow
          v-for="cannedItem in filteredRecords"
          :key="cannedItem.id || cannedItem.short_code"
        >
          <template #leading>
            <div
              class="inline-flex items-center gap-1.5 rounded-lg border border-primary/20 bg-primary/10 px-2.5 py-1 font-mono text-xs font-medium text-primary"
            >
              <Icon icon="i-lucide-terminal" class="size-3 opacity-70" />
              {{ cannedItem.short_code }}
            </div>
          </template>
          <p class="line-clamp-3 text-sm text-foreground">
            {{ getPlainText(cannedItem.content) }}
          </p>
          <template #actions>
            <RelayButton
              v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
              variant="ghost"
              size="icon"
              class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
              @click="openEditPopup(cannedItem)"
            >
              <Icon icon="i-lucide-pencil" class="size-3.5" />
            </RelayButton>
            <RelayButton
              v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
              variant="ghost"
              size="icon"
              class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
              :disabled="loading[cannedItem.id]"
              @click="openDeletePopup(cannedItem)"
            >
              <Icon icon="i-lucide-trash-2" class="size-3.5" />
            </RelayButton>
          </template>
        </SettingsListRow>
      </SettingsListCard>
    </template>

    <RelayModal
      :show="showAddPopup"
      :title="$t('CANNED_MGMT.ADD.TITLE')"
      :description="$t('CANNED_MGMT.ADD.DESC')"
      size="lg"
      @close="hideAddPopup"
    >
      <AddCanned :on-close="hideAddPopup" />
    </RelayModal>

    <RelayModal
      :show="showEditPopup"
      :title="`${$t('CANNED_MGMT.EDIT.TITLE')} - ${activeResponse.short_code}`"
      size="lg"
      @close="hideEditPopup"
    >
      <EditCanned
        v-if="showEditPopup"
        :id="activeResponse.id"
        :edshort-code="activeResponse.short_code"
        :edcontent="activeResponse.content"
        :on-close="hideEditPopup"
      />
    </RelayModal>

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
