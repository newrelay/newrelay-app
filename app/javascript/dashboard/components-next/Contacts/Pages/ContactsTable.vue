<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
  visibleColumns: {
    type: Array,
    default: () => [
      'email',
      'phoneNumber',
      'company',
      'createdAt',
      'lastActivity',
      'tags',
    ],
  },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
  isPreview: { type: Boolean, default: false },
  emptyMode: { type: String, default: '' },
  emptyTitle: { type: String, default: '' },
  emptySubtitle: { type: String, default: '' },
});

const emit = defineEmits([
  'toggleContact',
  'toggleAll',
  'update:sort',
  'clearSearch',
  'addContact',
  'clearFilters',
]);

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const customAttributes = useMapGetter('attributes/getContactAttributes');

// Backend-supported sort keys (Api::V1::Accounts::ContactsController)
const SORTABLE_COLUMNS = {
  name: 'name',
  email: 'email',
  phoneNumber: 'phone_number',
  company: 'company_name',
  createdAt: 'created_at',
  lastActivity: 'last_activity_at',
};

const selectedIdsSet = computed(() => new Set(props.selectedContactIds || []));

const isAllSelected = computed(() => {
  if (!props.contacts.length) return false;
  return props.contacts.every(c => selectedIdsSet.value.has(c.id));
});

const isSomeSelected = computed(() => {
  if (!props.contacts.length) return false;
  return (
    props.contacts.some(c => selectedIdsSet.value.has(c.id)) &&
    !isAllSelected.value
  );
});

const handleSelectAll = checked => {
  emit('toggleAll', checked);
};

const handleSelectRow = (id, checked) => {
  emit('toggleContact', { id, value: checked });
};

const isSelected = id => selectedIdsSet.value.has(id);

const parseDateString = dateString => {
  if (!dateString) return null;
  const isUnixTimestamp =
    typeof dateString === 'number' ||
    (!Number.isNaN(Number(dateString)) &&
      !String(dateString).includes('-') &&
      !String(dateString).includes('T'));
  return new Date(isUnixTimestamp ? Number(dateString) * 1000 : dateString);
};

const formatDate = dateString => {
  const date = parseDateString(dateString);
  if (!date) return '';
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

const getRelativeTime = dateString => {
  const date = parseDateString(dateString);
  if (!date) return '';
  const diffMs = new Date() - date;
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}d ago`;
};

const onClickViewDetails = async id => {
  if (props.isPreview) return;
  const routeTypes = {
    contacts_dashboard_segments_index: ['contacts_edit_segment', 'segmentId'],
    contacts_dashboard_labels_index: ['contacts_edit_label', 'label'],
  };
  const [name, paramKey] = routeTypes[route.name] || ['contacts_edit'];
  const params = {
    contactId: id,
    ...(paramKey && { [paramKey]: route.params[paramKey] }),
  };

  await router.push({ name, params, query: route.query });
};

const visibleCustomColumns = computed(() => {
  return props.visibleColumns
    .filter(key => key.startsWith('custom_'))
    .map(key => {
      const attributeKey = key.replace('custom_', '');
      const attr = (customAttributes.value || []).find(
        a => a.attributeKey === attributeKey
      );
      return {
        key,
        attributeKey,
        label: attr
          ? attr.attributeDisplayName || attr.attributeKey
          : attributeKey,
      };
    });
});

const isColumnActive = sortKey => props.activeSort === sortKey;

const sortAriaValue = sortKey => {
  if (!isColumnActive(sortKey)) return 'none';
  return props.activeOrdering === '-' ? 'descending' : 'ascending';
};

const sortIconClass = sortKey => {
  const isActive = isColumnActive(sortKey);
  return [
    'i-lucide-arrow-up-down size-3 shrink-0 transition-opacity',
    isActive ? 'opacity-100 text-primary' : 'opacity-0 group-hover:opacity-50',
  ];
};

const emptyColspan = computed(() => {
  let count = 2;
  [
    'email',
    'phoneNumber',
    'company',
    'createdAt',
    'lastActivity',
    'tags',
  ].forEach(key => {
    if (props.visibleColumns.includes(key)) count += 1;
  });
  return count + visibleCustomColumns.value.length;
});

const handleColumnSort = sortKey => {
  if (isColumnActive(sortKey)) {
    emit('update:sort', {
      sort: sortKey,
      order: props.activeOrdering === '-' ? '' : '-',
    });
    return;
  }
  emit('update:sort', { sort: sortKey, order: '' });
};

const emptyPlaceholderClass = 'text-muted-foreground/50 text-[13px]';

// Prefer the real linked Company record; fall back to the legacy free-text
// attribute for contacts that only have a typed-in company name.
const companyDisplayName = contact =>
  contact.company?.name || contact.additionalAttributes?.companyName || '';
</script>

<template>
  <div
    class="overflow-hidden rounded-xl border border-border/50 bg-card shadow-sm"
  >
    <div class="w-full overflow-x-auto">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-border/50 bg-muted/30">
          <tr>
            <th
              class="w-12 px-4 py-3 align-middle font-medium text-muted-foreground"
            >
              <RelayCheckbox
                :model-value="isAllSelected"
                :indeterminate="isSomeSelected"
                @update:model-value="handleSelectAll"
              />
            </th>
            <th
              class="group cursor-pointer whitespace-nowrap px-4 py-3 font-medium text-muted-foreground transition-colors hover:text-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.name)"
              @click="handleColumnSort(SORTABLE_COLUMNS.name)"
            >
              <div class="flex items-center gap-1">
                {{ t('CONTACTS_LAYOUT.FILTER.NAME') }}
                <span :class="sortIconClass(SORTABLE_COLUMNS.name)" />
              </div>
            </th>
            <th
              v-if="visibleColumns.includes('email')"
              class="group cursor-pointer whitespace-nowrap px-4 py-3 font-medium text-muted-foreground transition-colors hover:text-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.email)"
              @click="handleColumnSort(SORTABLE_COLUMNS.email)"
            >
              <div class="flex items-center gap-1">
                {{ t('CONTACTS_LAYOUT.FILTER.EMAIL') }}
                <span :class="sortIconClass(SORTABLE_COLUMNS.email)" />
              </div>
            </th>
            <th
              v-if="visibleColumns.includes('phoneNumber')"
              class="group cursor-pointer whitespace-nowrap px-4 py-3 font-medium text-muted-foreground transition-colors hover:text-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.phoneNumber)"
              @click="handleColumnSort(SORTABLE_COLUMNS.phoneNumber)"
            >
              <div class="flex items-center gap-1">
                {{ t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER') }}
                <span :class="sortIconClass(SORTABLE_COLUMNS.phoneNumber)" />
              </div>
            </th>
            <th
              v-if="visibleColumns.includes('company')"
              class="group cursor-pointer whitespace-nowrap px-4 py-3 font-medium text-muted-foreground transition-colors hover:text-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.company)"
              @click="handleColumnSort(SORTABLE_COLUMNS.company)"
            >
              <div class="flex items-center gap-1">
                {{ t('CONTACTS_LAYOUT.FILTER.COMPANY') }}
                <span :class="sortIconClass(SORTABLE_COLUMNS.company)" />
              </div>
            </th>
            <th
              v-if="visibleColumns.includes('createdAt')"
              class="group hidden cursor-pointer whitespace-nowrap px-4 py-3 font-medium text-muted-foreground transition-colors hover:text-foreground lg:table-cell"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.createdAt)"
              @click="handleColumnSort(SORTABLE_COLUMNS.createdAt)"
            >
              <div class="flex items-center gap-1">
                {{ t('CONTACTS_LAYOUT.FILTER.CREATED_AT') }}
                <span :class="sortIconClass(SORTABLE_COLUMNS.createdAt)" />
              </div>
            </th>
            <th
              v-if="visibleColumns.includes('lastActivity')"
              class="group hidden cursor-pointer whitespace-nowrap px-4 py-3 font-medium text-muted-foreground transition-colors hover:text-foreground lg:table-cell"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.lastActivity)"
              @click="handleColumnSort(SORTABLE_COLUMNS.lastActivity)"
            >
              <div class="flex items-center gap-1">
                {{ t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY') }}
                <span :class="sortIconClass(SORTABLE_COLUMNS.lastActivity)" />
              </div>
            </th>
            <th
              v-if="visibleColumns.includes('tags')"
              class="whitespace-nowrap px-4 py-3 font-medium text-muted-foreground"
            >
              {{ t('CONTACTS_LAYOUT.FILTER.TAGS') }}
            </th>
            <th
              v-for="col in visibleCustomColumns"
              :key="col.key"
              class="whitespace-nowrap px-4 py-3 font-medium text-muted-foreground"
            >
              {{ col.label }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border/40">
          <tr v-if="emptyMode">
            <td :colspan="emptyColspan" class="px-4 py-16 text-center">
              <div class="flex flex-col items-center justify-center space-y-3">
                <div
                  class="flex size-12 items-center justify-center rounded-full bg-muted"
                >
                  <span class="i-lucide-search size-6 text-muted-foreground" />
                </div>
                <h3 class="text-lg font-medium text-foreground">
                  {{ emptyTitle }}
                </h3>
                <p
                  v-if="emptySubtitle"
                  class="mx-auto max-w-sm text-sm text-muted-foreground"
                >
                  {{ emptySubtitle }}
                </p>
                <div
                  v-if="emptyMode === 'search'"
                  class="mt-4 flex items-center justify-center gap-3"
                >
                  <RelayButton variant="outline" @click="emit('clearSearch')">
                    {{ t('CONTACTS_LAYOUT.EMPTY_STATE.CLEAR_SEARCH') }}
                  </RelayButton>
                  <RelayButton
                    class="gap-2 shadow-sm"
                    @click="emit('addContact')"
                  >
                    <span class="i-lucide-plus size-4" />
                    {{
                      t(
                        'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.ADD_CONTACT'
                      )
                    }}
                  </RelayButton>
                </div>
                <div
                  v-else-if="emptyMode === 'filters'"
                  class="mt-4 flex items-center justify-center gap-3"
                >
                  <RelayButton variant="outline" @click="emit('clearFilters')">
                    {{ t('CONTACTS_LAYOUT.FILTER.BUTTONS.CLEAR_FILTERS') }}
                  </RelayButton>
                </div>
              </div>
            </td>
          </tr>
          <template v-else>
            <tr
              v-for="contact in contacts"
              :key="contact.id"
              class="group cursor-pointer transition-colors hover:bg-muted/30"
              :class="{ 'bg-muted/20': isSelected(contact.id) }"
              @click="onClickViewDetails(contact.id)"
            >
              <td class="px-4 py-4 align-middle" @click.stop>
                <RelayCheckbox
                  :model-value="isSelected(contact.id)"
                  @update:model-value="
                    checked => handleSelectRow(contact.id, checked)
                  "
                />
              </td>

              <td class="min-w-[250px] px-4 py-4 align-middle">
                <div class="flex items-center gap-3">
                  <Avatar
                    :name="contact.name"
                    :src="contact.thumbnail"
                    :size="36"
                    rounded-full
                    hide-offline-status
                    class="shadow-sm ring-1 ring-border/50"
                  />
                  <button
                    type="button"
                    class="truncate text-left font-medium text-foreground hover:underline"
                    @click.stop="onClickViewDetails(contact.id)"
                  >
                    {{
                      contact.name || t('CONTACTS_LAYOUT.CARD.UNNAMED_CONTACT')
                    }}
                  </button>
                </div>
              </td>

              <td
                v-if="visibleColumns.includes('email')"
                class="px-4 py-4 align-middle"
                @click.stop
              >
                <ComposeConversation
                  v-if="contact.email"
                  :initial-contact="contact"
                  align="start"
                >
                  <template #trigger>
                    <span
                      class="cursor-pointer truncate text-sm text-foreground hover:text-primary hover:underline"
                    >
                      {{ contact.email }}
                    </span>
                  </template>
                </ComposeConversation>
                <span v-else :class="emptyPlaceholderClass">—</span>
              </td>

              <td
                v-if="visibleColumns.includes('phoneNumber')"
                class="whitespace-nowrap px-4 py-4 align-middle"
              >
                <span
                  :class="
                    contact.phoneNumber
                      ? 'text-sm text-muted-foreground'
                      : emptyPlaceholderClass
                  "
                >
                  {{ contact.phoneNumber || '—' }}
                </span>
              </td>

              <td
                v-if="visibleColumns.includes('company')"
                class="px-4 py-4 align-middle"
              >
                <span
                  :class="
                    companyDisplayName(contact)
                      ? 'text-sm text-foreground'
                      : emptyPlaceholderClass
                  "
                >
                  {{ companyDisplayName(contact) || '—' }}
                </span>
              </td>

              <td
                v-if="visibleColumns.includes('createdAt')"
                class="hidden whitespace-nowrap px-4 py-4 align-middle lg:table-cell"
              >
                <span
                  :class="
                    formatDate(contact.createdAt)
                      ? 'text-sm text-muted-foreground'
                      : emptyPlaceholderClass
                  "
                >
                  {{ formatDate(contact.createdAt) || '—' }}
                </span>
              </td>

              <td
                v-if="visibleColumns.includes('lastActivity')"
                class="hidden whitespace-nowrap px-4 py-4 align-middle lg:table-cell"
              >
                <span
                  :class="
                    getRelativeTime(contact.lastActivityAt)
                      ? 'text-sm text-muted-foreground'
                      : emptyPlaceholderClass
                  "
                >
                  {{ getRelativeTime(contact.lastActivityAt) || '—' }}
                </span>
              </td>

              <td
                v-if="visibleColumns.includes('tags')"
                class="px-4 py-4 align-middle"
              >
                <div class="flex flex-wrap gap-1.5">
                  <span
                    v-for="label in (contact.labels || []).slice(0, 3)"
                    :key="label"
                    class="inline-flex items-center rounded-md border border-border/50 bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground"
                  >
                    {{ label }}
                  </span>
                  <span
                    v-if="(contact.labels || []).length > 3"
                    class="inline-flex items-center rounded-md border border-border/50 bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground"
                  >
                    +{{ contact.labels.length - 3 }}
                  </span>
                </div>
              </td>

              <td
                v-for="col in visibleCustomColumns"
                :key="col.key"
                class="px-4 py-4 align-middle"
              >
                <span
                  :class="
                    contact.customAttributes?.[col.attributeKey]
                      ? 'text-sm text-muted-foreground'
                      : emptyPlaceholderClass
                  "
                >
                  {{ contact.customAttributes?.[col.attributeKey] || '—' }}
                </span>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>
