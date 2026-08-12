<script setup>
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import AddAutomationRule from './AddAutomationRule.vue';
import EditAutomationRule from './EditAutomationRule.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { picoSearch } from '@scmmishra/pico-search';
import AutomationRuleRow from './AutomationRuleRow.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const confirmDialog = ref(null);

const loading = ref({});
const addDialogRef = ref(null);
const editDialogRef = ref(null);
const showDeleteConfirmationPopup = ref(false);
const selectedAutomation = ref({});
const searchQuery = ref('');
const toggleModalTitle = ref(t('AUTOMATION.TOGGLE.ACTIVATION_TITLE'));
const toggleModalDescription = ref(
  t('AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION')
);

const records = computed(() => getters['automations/getAutomations'].value);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name', 'description']);
});
const uiFlags = computed(() => getters['automations/getUIFlags'].value);
const accountId = computed(() => getters.getCurrentAccountId.value);

const deleteConfirmText = computed(
  () => `${t('AUTOMATION.DELETE.CONFIRM.YES')} ${selectedAutomation.value.name}`
);

const deleteRejectText = computed(
  () => `${t('AUTOMATION.DELETE.CONFIRM.NO')} ${selectedAutomation.value.name}`
);

const deleteMessage = computed(() => ` ${selectedAutomation.value.name}?`);

const isSLAEnabled = computed(() =>
  getters['accounts/isFeatureEnabledonAccount'].value(accountId.value, 'sla')
);

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('contacts/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  store.dispatch('campaigns/get');
  store.dispatch('automations/get');
  if (isSLAEnabled.value) {
    store.dispatch('sla/get');
  }
});

const openAddPopup = () => {
  addDialogRef.value?.open();
};
const hideAddPopup = () => {
  addDialogRef.value?.close();
};

const openEditPopup = response => {
  selectedAutomation.value = { ...response };
  editDialogRef.value?.open();
};
const hideEditPopup = () => {
  editDialogRef.value?.close();
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedAutomation.value = response;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteAutomation = async id => {
  try {
    await store.dispatch('automations/delete', id);
    useAlert(t('AUTOMATION.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AUTOMATION.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[selectedAutomation.value.id] = false;
  }
};
const confirmDeletion = () => {
  loading.value[selectedAutomation.value.id] = true;
  closeDeletePopup();
  deleteAutomation(selectedAutomation.value.id);
};
const cloneAutomation = async ({ id }) => {
  try {
    await store.dispatch('automations/clone', id);
    useAlert(t('AUTOMATION.CLONE.API.SUCCESS_MESSAGE'));
    store.dispatch('automations/get');
  } catch (error) {
    useAlert(t('AUTOMATION.CLONE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[selectedAutomation.value.id] = false;
  }
};

const submitAutomation = async (payload, mode) => {
  try {
    const action =
      mode === 'edit' ? 'automations/update' : 'automations/create';
    const successMessage =
      mode === 'edit'
        ? t('AUTOMATION.EDIT.API.SUCCESS_MESSAGE')
        : t('AUTOMATION.ADD.API.SUCCESS_MESSAGE');
    await store.dispatch(action, payload);
    useAlert(successMessage);
    hideAddPopup();
    hideEditPopup();
  } catch (error) {
    if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
      return;
    }

    const errorMessage =
      mode === 'edit'
        ? t('AUTOMATION.EDIT.API.ERROR_MESSAGE')
        : t('AUTOMATION.ADD.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};
const toggleAutomation = async ({ id, name, status }) => {
  try {
    if (status) {
      toggleModalTitle.value = t('AUTOMATION.TOGGLE.DEACTIVATION_TITLE');
      toggleModalDescription.value = t(
        'AUTOMATION.TOGGLE.DEACTIVATION_DESCRIPTION',
        {
          automationName: name,
        }
      );
    } else {
      toggleModalTitle.value = t('AUTOMATION.TOGGLE.ACTIVATION_TITLE');
      toggleModalDescription.value = t(
        'AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION',
        {
          automationName: name,
        }
      );
    }

    const ok = await confirmDialog.value.showConfirmation();
    if (ok) {
      await store.dispatch('automations/update', {
        id: id,
        active: !status,
      });
      const message = status
        ? t('AUTOMATION.TOGGLE.DEACTIVATION_SUCCESFUL')
        : t('AUTOMATION.TOGGLE.ACTIVATION_SUCCESFUL');
      useAlert(message);
    }
  } catch (error) {
    useAlert(t('AUTOMATION.EDIT.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('AUTOMATION.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div class="space-y-6">
        <div
          class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
        >
          <div>
            <h2 class="text-base font-medium text-foreground">
              {{ $t('AUTOMATION.HEADER') }}
            </h2>
            <p
              class="mt-1 max-w-3xl text-sm leading-relaxed text-muted-foreground"
            >
              {{ $t('AUTOMATION.DESCRIPTION') }}
            </p>
          </div>
          <RelayButton
            class="h-10 w-full shrink-0 whitespace-nowrap shadow-sm sm:w-auto"
            @click="openAddPopup"
          >
            {{ $t('AUTOMATION.HEADER_BTN_TXT') }}
          </RelayButton>
        </div>

        <div
          class="flex items-center justify-between gap-3 rounded-xl border border-border/60 bg-card p-2 shadow-xs"
        >
          <div class="relative w-full max-w-md">
            <Icon
              icon="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            />
            <RelayInput
              v-model="searchQuery"
              type="search"
              :placeholder="$t('AUTOMATION.SEARCH_PLACEHOLDER')"
              class-name="h-9 border-transparent bg-background/50 pl-9 text-[13.5px] shadow-none focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/20"
            />
          </div>
          <div
            class="shrink-0 border-l border-border/40 px-4 text-[13px] font-medium text-muted-foreground"
          >
            {{ $t('AUTOMATION.COUNT', { n: filteredRecords.length }) }}
          </div>
        </div>

        <div
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <div
            v-if="!records.length"
            class="flex flex-col items-center justify-center p-16 text-center"
          >
            <div
              class="mb-5 flex size-14 items-center justify-center rounded-full bg-muted"
            >
              <Icon icon="i-lucide-zap" class="size-6 text-muted-foreground" />
            </div>
            <h3 class="text-base font-medium text-foreground">
              {{ $t('AUTOMATION.LIST.EMPTY_TITLE') }}
            </h3>
            <p class="mt-1 text-[13.5px] text-muted-foreground">
              {{ $t('AUTOMATION.LIST.EMPTY_DESC') }}
            </p>
            <RelayButton class="mt-6 h-9 shadow-sm" @click="openAddPopup">
              <Icon icon="i-lucide-plus" class="size-4" />
              {{ $t('AUTOMATION.HEADER_BTN_TXT') }}
            </RelayButton>
          </div>

          <div
            v-else-if="!filteredRecords.length"
            class="px-6 py-16 text-center text-sm text-muted-foreground"
          >
            {{ $t('AUTOMATION.NO_RESULTS') }}
          </div>

          <div v-else class="min-w-full overflow-x-auto">
            <div
              class="grid grid-cols-[1.5fr_100px_1fr_120px] items-center border-b border-border/40 bg-muted/30 px-6 py-3.5"
            >
              <div
                class="text-[12px] font-medium uppercase tracking-wider text-muted-foreground"
              >
                {{ $t('AUTOMATION.LIST.TABLE_HEADER.NAME') }}
              </div>
              <div
                class="text-[12px] font-medium uppercase tracking-wider text-muted-foreground"
              >
                {{ $t('AUTOMATION.LIST.TABLE_HEADER.ACTIVE') }}
              </div>
              <div
                class="text-[12px] font-medium uppercase tracking-wider text-muted-foreground"
              >
                {{ $t('AUTOMATION.LIST.TABLE_HEADER.CREATED_ON') }}
              </div>
              <div
                class="text-right text-[12px] font-medium uppercase tracking-wider text-muted-foreground"
              >
                {{ $t('AUTOMATION.LIST.TABLE_HEADER.ACTIONS') }}
              </div>
            </div>

            <div class="divide-y divide-border/40">
              <AutomationRuleRow
                v-for="automation in filteredRecords"
                :key="automation.id"
                :automation="automation"
                :loading="loading[automation.id]"
                @clone="cloneAutomation"
                @toggle="toggleAutomation"
                @edit="openEditPopup"
                @delete="openDeletePopup"
              />
            </div>
          </div>
        </div>
      </div>
    </template>

    <AddAutomationRule ref="addDialogRef" @save-automation="submitAutomation" />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('AUTOMATION.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />

    <EditAutomationRule
      ref="editDialogRef"
      :selected-response="selectedAutomation"
      @save-automation="submitAutomation"
    />
    <woot-confirm-modal
      ref="confirmDialog"
      :title="toggleModalTitle"
      :description="toggleModalDescription"
    />
  </SettingsLayout>
</template>
