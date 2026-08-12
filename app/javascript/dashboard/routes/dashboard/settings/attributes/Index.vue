<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import AttributeRow from './AttributeRow.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SettingsListCard from '../components/SettingsListCard.vue';

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
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const addDialogRef = ref(null);
const editDialogRef = ref(null);
const deleteDialogRef = ref(null);
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

const emptyMessage = computed(() =>
  searchQuery.value.trim()
    ? t('ATTRIBUTES_MGMT.NO_RESULTS')
    : t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404')
);

const selectedAttributeName = computed(
  () => selectedAttribute.value?.attribute_display_name || ''
);

onMounted(() => {
  store.dispatch('attributes/get');
});

const onClickTabChange = key => {
  selectedTabIndex.value = key;
  searchQuery.value = '';
};

const openAddPopup = async () => {
  showAddPopup.value = true;
  await nextTick();
  addDialogRef.value?.open();
};

const hideAddPopup = () => {
  showAddPopup.value = false;
  addDialogRef.value?.close();
};

const handleEditAttribute = async attribute => {
  selectedAttribute.value = attribute;
  showEditPopup.value = true;
  await nextTick();
  editDialogRef.value?.open();
};

const hideEditPopup = () => {
  showEditPopup.value = false;
  selectedAttribute.value = {};
  editDialogRef.value?.close();
};

const handleDeleteAttribute = async attribute => {
  selectedAttribute.value = attribute;
  await nextTick();
  deleteDialogRef.value?.open();
};

const confirmDeleteAttribute = async () => {
  const id = selectedAttribute.value.id;
  loading.value[id] = true;
  try {
    await store.dispatch('attributes/delete', id);
    useAlert(t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error?.message || t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedAttribute.value = {};
    deleteDialogRef.value?.close();
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="false"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('ATTRIBUTES_MGMT.HEADER')"
        :description="$t('ATTRIBUTES_MGMT.DESCRIPTION')"
        :search-placeholder="$t('ATTRIBUTES_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="custom_attributes"
      >
        <template #tabs>
          <div
            class="flex items-center gap-6 overflow-x-auto border-b border-border/60 text-[14px]"
          >
            <button
              v-for="tab in tabs"
              :key="tab.key"
              type="button"
              role="tab"
              :aria-selected="selectedTabIndex === tab.key"
              class="-mb-px whitespace-nowrap border-b-2 pb-3 font-medium transition-colors"
              :class="
                selectedTabIndex === tab.key
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground'
              "
              @click="onClickTabChange(tab.key)"
            >
              {{ tab.name }}
            </button>
          </div>
        </template>
        <template #actions>
          <RelayButton size="sm" @click="openAddPopup">
            {{ $t('ATTRIBUTES_MGMT.HEADER_BTN_TXT') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <SettingsListCard :show-column-headers="false">
        <template v-if="!filteredAttributes.length" #empty>
          <div class="px-6 py-20 text-center text-sm text-muted-foreground">
            {{ emptyMessage }}
          </div>
        </template>
        <div
          v-if="filteredAttributes.length"
          class="flex flex-col gap-3 p-4 sm:p-6"
        >
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
      </SettingsListCard>
    </template>

    <Dialog
      ref="addDialogRef"
      type="edit"
      title=""
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="hideAddPopup"
    >
      <AddAttribute
        v-if="showAddPopup"
        :on-close="hideAddPopup"
        :selected-attribute-model-tab="selectedTabIndex"
      />
    </Dialog>

    <Dialog
      ref="editDialogRef"
      type="edit"
      title=""
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="hideEditPopup"
    >
      <EditAttribute
        v-if="showEditPopup"
        :selected-attribute="selectedAttribute"
        @close="hideEditPopup"
      />
    </Dialog>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="
        t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
          attributeName: selectedAttributeName,
        })
      "
      :description="t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-button-label="`${t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')}${selectedAttributeName}`"
      :cancel-button-label="t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO')"
      :is-loading="uiFlags.isDeleting"
      @confirm="confirmDeleteAttribute"
      @close="selectedAttribute = {}"
    />
  </SettingsLayout>
</template>
