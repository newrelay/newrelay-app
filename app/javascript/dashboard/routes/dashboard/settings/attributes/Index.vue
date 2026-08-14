<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

import {
  RelayButton,
  RelayConfirmModal,
  RelayInput,
} from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import AttributeRow from './AttributeRow.vue';
import SettingsLayout from '../SettingsLayout.vue';

defineOptions({
  name: 'CustomAttributeSettings',
});

const { t } = useI18n();
const getters = useStoreGetters();
const store = useStore();
const { currentAccount } = useAccount();
const inboxes = useMapGetter('inboxes/getInboxes');

const selectedTabIndex = ref(0);
const searchQuery = ref('');
const selectedAttribute = ref({});
const showAddModal = ref(false);
const showEditModal = ref(false);
const showDeleteConfirmationPopup = ref(false);
const loading = ref({});

const attributeModels = ['conversation_attribute', 'contact_attribute'];
const uiFlags = computed(() => getters['attributes/getUIFlags'].value);

const tabs = computed(() => [
  {
    key: 0,
    name: t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
  },
  {
    key: 1,
    name: t('ATTRIBUTES_MGMT.TABS.CONTACT'),
  },
]);

const attributeModel = computed(
  () => attributeModels[selectedTabIndex.value] || 'conversation_attribute'
);

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(attributeModel.value)
);

const requiredAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const hasPreChatBadge = attribute =>
  (inboxes.value || []).some(inbox => {
    const fields =
      inbox?.pre_chat_form_options?.pre_chat_fields ||
      inbox?.channel?.pre_chat_form_options?.pre_chat_fields ||
      [];
    return fields.some(field => field.name === attribute.attribute_key);
  });

const buildBadges = attribute => {
  const badges = [];
  if (hasPreChatBadge(attribute)) {
    badges.push({ type: 'pre-chat' });
  }
  if (
    attribute.attribute_model === 'conversation_attribute' &&
    requiredAttributeKeys.value.includes(attribute.attribute_key)
  ) {
    badges.push({ type: 'resolution' });
  }
  return badges;
};

const derivedAttributes = computed(() =>
  attributes.value.map(attribute => ({
    ...attribute,
    label: attribute.attribute_display_name,
    type: attribute.attribute_display_type,
    value: attribute.attribute_key,
    badges: buildBadges(attribute),
  }))
);

const filteredAttributes = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return derivedAttributes.value;
  return picoSearch(derivedAttributes.value, query, [
    'attribute_display_name',
    'attribute_key',
    'attribute_description',
  ]);
});

const selectedAttributeName = computed(
  () => selectedAttribute.value?.attribute_display_name || ''
);

const deleteConfirmText = computed(
  () =>
    `${t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')}${selectedAttributeName.value}`
);

const deleteRejectText = computed(() => t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO'));

onMounted(() => {
  store.dispatch('attributes/get');
});

const onClickTabChange = key => {
  selectedTabIndex.value = key;
  searchQuery.value = '';
};

const openAddModal = () => {
  showAddModal.value = true;
};

const handleEditAttribute = attribute => {
  selectedAttribute.value = attribute;
  showEditModal.value = true;
};

const hideEditPopup = () => {
  showEditModal.value = false;
  selectedAttribute.value = {};
};

const handleDeleteAttribute = attribute => {
  selectedAttribute.value = attribute;
  showDeleteConfirmationPopup.value = true;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
  selectedAttribute.value = {};
};

const confirmDeleteAttribute = async () => {
  const id = selectedAttribute.value.id;
  loading.value[id] = true;
  closeDeletePopup();
  try {
    await store.dispatch('attributes/delete', id);
    useAlert(t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error?.message || t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div
        class="mb-8 overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div class="border-b border-border/40 p-4 sm:p-6">
          <h3 class="capitalize text-base font-semibold text-foreground">
            {{ $t('ATTRIBUTES_MGMT.HEADER') }}
          </h3>
          <p class="mt-1 max-w-4xl text-sm text-muted-foreground">
            {{ $t('ATTRIBUTES_MGMT.DESCRIPTION') }}
          </p>
        </div>

        <div class="space-y-6 p-4 sm:p-6">
          <div
            class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
          >
            <div class="flex flex-col gap-4 sm:flex-row sm:items-center">
              <div
                class="flex items-center rounded-full border border-border/60 bg-card p-1 shadow-sm"
              >
                <button
                  v-for="tab in tabs"
                  :key="tab.key"
                  type="button"
                  role="tab"
                  :aria-selected="selectedTabIndex === tab.key"
                  class="rounded-full px-4 py-1.5 text-[13.5px] font-medium transition-all"
                  :class="
                    selectedTabIndex === tab.key
                      ? 'bg-primary/10 text-primary'
                      : 'text-muted-foreground hover:text-foreground'
                  "
                  @click="onClickTabChange(tab.key)"
                >
                  {{ tab.name }}
                </button>
              </div>

              <div class="relative w-full max-w-xs">
                <Icon
                  icon="i-lucide-search"
                  class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                />
                <RelayInput
                  v-model="searchQuery"
                  type="search"
                  :placeholder="$t('ATTRIBUTES_MGMT.SEARCH_PLACEHOLDER')"
                  class-name="h-9 w-full border-border/60 bg-card pl-9 text-[13.5px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
                />
              </div>
            </div>

            <RelayButton
              class="h-9 shrink-0 px-5 text-[13px] font-medium shadow-sm"
              @click="openAddModal"
            >
              {{ $t('ATTRIBUTES_MGMT.HEADER_BTN_TXT') }}
            </RelayButton>
          </div>

          <div
            v-if="searchQuery.trim() && !filteredAttributes.length"
            class="flex flex-col items-center justify-center py-32 text-center"
          >
            <p class="text-sm font-medium text-foreground">
              {{ $t('ATTRIBUTES_MGMT.NO_RESULTS') }}
            </p>
          </div>

          <div
            v-else-if="!derivedAttributes.length"
            class="flex flex-col items-center justify-center py-32 text-center"
          >
            <p class="text-sm font-medium text-foreground">
              {{ $t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404') }}
            </p>
          </div>

          <div
            v-else
            class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
          >
            <div class="divide-y divide-border/40">
              <AttributeRow
                v-for="attribute in filteredAttributes"
                :key="attribute.id"
                :attribute="attribute"
                :badges="attribute.badges"
                :loading="loading[attribute.id]"
                @edit="handleEditAttribute"
                @delete="handleDeleteAttribute"
              />
            </div>
          </div>
        </div>
      </div>

      <AddAttribute
        :show="showAddModal"
        :selected-attribute-model-tab="selectedTabIndex"
        @close="showAddModal = false"
      />

      <EditAttribute
        :show="showEditModal"
        :selected-attribute="selectedAttribute"
        @close="hideEditPopup"
      />

      <RelayConfirmModal
        :show="showDeleteConfirmationPopup"
        :title="
          t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
            attributeName: selectedAttributeName,
          })
        "
        :message="t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
        :confirm-text="deleteConfirmText"
        :cancel-text="deleteRejectText"
        @close="closeDeletePopup"
        @confirm="confirmDeleteAttribute"
      />
    </template>
  </SettingsLayout>
</template>
