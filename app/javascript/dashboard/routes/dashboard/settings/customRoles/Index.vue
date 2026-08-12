<script setup>
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import CustomRoleModal from './component/CustomRoleModal.vue';
import CustomRolePaywall from './component/CustomRolePaywall.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { picoSearch } from '@scmmishra/pico-search';
import { getI18nKey } from 'dashboard/routes/dashboard/settings/helper/settingsHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayConfirmModal,
} from 'dashboard/components-next/relay';

const store = useStore();
const { t } = useI18n();

const showCustomRoleModal = ref(false);
const customRoleModalMode = ref('add');
const selectedRole = ref(null);
const loading = ref({});
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const searchQuery = ref('');

const records = useMapGetter('customRole/getCustomRoles');

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name', 'description']);
});
const uiFlags = useMapGetter('customRole/getUIFlags');

const deleteConfirmText = computed(
  () => `${t('CUSTOM_ROLE.DELETE.CONFIRM.YES')} ${activeResponse.value.name}`
);

const deleteRejectText = computed(
  () => `${t('CUSTOM_ROLE.DELETE.CONFIRM.NO')} ${activeResponse.value.name}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.name} ? `;
});

const isFeatureEnabledOnAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const currentAccountId = useMapGetter('getCurrentAccountId');

const isBehindAPaywall = computed(() => {
  return !isFeatureEnabledOnAccount.value(
    currentAccountId.value,
    'custom_roles'
  );
});

const getFormattedPermissions = role => {
  return role.permissions
    .map(event => t(getI18nKey('CUSTOM_ROLE.PERMISSIONS', event)))
    .join(', ');
};

const fetchCustomRoles = async () => {
  try {
    await store.dispatch('customRole/getCustomRole');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
  fetchCustomRoles();
});

const showAlertMessage = message => {
  loading.value[activeResponse.value.id] = false;
  activeResponse.value = {};
  useAlert(message);
};

const openAddModal = () => {
  if (isBehindAPaywall.value) return;
  customRoleModalMode.value = 'add';
  selectedRole.value = null;
  showCustomRoleModal.value = true;
};

const openEditModal = role => {
  customRoleModalMode.value = 'edit';
  selectedRole.value = role;
  showCustomRoleModal.value = true;
};

const hideCustomRoleModal = () => {
  selectedRole.value = null;
  showCustomRoleModal.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  activeResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCustomRole = async id => {
  try {
    await store.dispatch('customRole/deleteCustomRole', id);
    showAlertMessage(t('CUSTOM_ROLE.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CUSTOM_ROLE.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  loading.value[activeResponse.value.id] = true;
  closeDeletePopup();
  deleteCustomRole(activeResponse.value.id);
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('CUSTOM_ROLE.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <CustomRolePaywall v-if="isBehindAPaywall" />
      <div v-else class="max-w-5xl">
        <div
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <div class="border-b border-border/40 p-4 sm:p-6">
            <h3 class="text-base font-semibold text-foreground">
              {{ $t('CUSTOM_ROLE.HEADER') }}
            </h3>
            <p class="mt-1 max-w-3xl text-sm text-muted-foreground">
              {{ $t('CUSTOM_ROLE.LIST.DESC') }}
            </p>
          </div>

          <div class="space-y-6 p-4 sm:p-6">
            <div
              class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
              <div class="relative w-full sm:max-w-xs">
                <Icon
                  icon="i-lucide-search"
                  class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                />
                <RelayInput
                  v-model="searchQuery"
                  type="search"
                  :placeholder="$t('CUSTOM_ROLE.SEARCH_PLACEHOLDER')"
                  class-name="h-10 bg-background pl-9 shadow-sm"
                />
              </div>
              <div class="flex shrink-0 items-center gap-4">
                <span class="text-[13px] font-medium text-muted-foreground">
                  {{ $t('CUSTOM_ROLE.COUNT', { n: records.length }) }}
                </span>
                <RelayButton
                  class="h-9 w-full whitespace-nowrap shadow-sm sm:w-auto"
                  @click="openAddModal"
                >
                  {{ $t('CUSTOM_ROLE.HEADER_BTN_TXT') }}
                </RelayButton>
              </div>
            </div>

            <div
              v-if="!records.length"
              class="flex flex-col items-center justify-center p-16 text-center"
            >
              <div
                class="mb-5 flex size-14 items-center justify-center rounded-full border border-border/40 bg-muted/50"
              >
                <Icon
                  icon="i-lucide-shield"
                  class="size-6 text-muted-foreground"
                />
              </div>
              <h3 class="mb-2 text-[16px] font-semibold text-foreground">
                {{ $t('CUSTOM_ROLE.LIST.EMPTY_TITLE') }}
              </h3>
              <p
                class="mx-auto mb-6 max-w-sm text-[13.5px] leading-relaxed text-muted-foreground"
              >
                {{ $t('CUSTOM_ROLE.LIST.EMPTY_DESC') }}
              </p>
              <RelayButton class="h-9 shadow-sm" @click="openAddModal">
                {{ $t('CUSTOM_ROLE.HEADER_BTN_TXT') }}
              </RelayButton>
            </div>

            <div
              v-else-if="!filteredRecords.length"
              class="px-2 py-12 text-center text-sm text-muted-foreground"
            >
              {{ $t('CUSTOM_ROLE.NO_RESULTS') }}
            </div>

            <div v-else class="overflow-x-auto">
              <table class="w-full text-left">
                <thead>
                  <tr
                    class="border-b border-border/40 text-[12px] font-medium text-foreground"
                  >
                    <th class="py-4 pr-4 align-bottom font-semibold">
                      {{ $t('CUSTOM_ROLE.LIST.TABLE_HEADER.NAME') }}
                    </th>
                    <th class="px-4 py-4 align-bottom font-semibold">
                      {{ $t('CUSTOM_ROLE.LIST.TABLE_HEADER.DESCRIPTION') }}
                    </th>
                    <th class="px-4 py-4 align-bottom font-semibold">
                      {{ $t('CUSTOM_ROLE.LIST.TABLE_HEADER.PERMISSIONS') }}
                    </th>
                    <th
                      class="w-[100px] py-4 pl-4 text-center align-bottom font-semibold"
                    >
                      {{ $t('CUSTOM_ROLE.LIST.TABLE_HEADER.ACTIONS') }}
                    </th>
                  </tr>
                </thead>
                <tbody
                  class="divide-y divide-border/40 text-[13px] text-muted-foreground"
                >
                  <tr
                    v-for="role in filteredRecords"
                    :key="role.id"
                    class="group transition-colors hover:bg-muted/10"
                  >
                    <td
                      class="w-[120px] py-4 pr-4 align-top font-medium text-foreground"
                    >
                      {{ role.name }}
                    </td>
                    <td class="w-[140px] px-4 py-4 align-top">
                      {{ role.description }}
                    </td>
                    <td class="px-4 py-4 pr-8 align-top leading-relaxed">
                      {{ getFormattedPermissions(role) }}
                    </td>
                    <td class="py-4 pl-4 align-top">
                      <div class="flex items-center justify-center gap-2">
                        <RelayButton
                          v-tooltip.top="$t('CUSTOM_ROLE.EDIT.BUTTON_TEXT')"
                          variant="outline"
                          size="icon"
                          class="size-8 border-border/60 bg-background text-muted-foreground shadow-none hover:bg-muted/50 hover:text-foreground"
                          @click="openEditModal(role)"
                        >
                          <Icon icon="i-lucide-pencil" class="size-3.5" />
                        </RelayButton>
                        <RelayButton
                          v-tooltip.top="$t('CUSTOM_ROLE.DELETE.BUTTON_TEXT')"
                          variant="outline"
                          size="icon"
                          class="size-8 border-border/60 bg-background text-muted-foreground shadow-none hover:bg-destructive/10 hover:text-destructive"
                          :disabled="loading[role.id]"
                          @click="openDeletePopup(role)"
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
        </div>
      </div>
    </template>

    <CustomRoleModal
      :show="showCustomRoleModal"
      :mode="customRoleModalMode"
      :selected-role="selectedRole"
      @close="hideCustomRoleModal"
    />

    <RelayConfirmModal
      :show="showDeleteConfirmationPopup"
      :title="$t('CUSTOM_ROLE.DELETE.CONFIRM.TITLE')"
      :message="$t('CUSTOM_ROLE.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :cancel-text="deleteRejectText"
      @close="closeDeletePopup"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
