<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { RelayCheckbox } from 'dashboard/components-next/relay';
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
});

const emit = defineEmits(['toggleContact', 'toggleAll', 'update:sort']);

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
  if (!isColumnActive(sortKey)) return 'i-lucide-chevrons-up-down opacity-40';
  return props.activeOrdering === '-'
    ? 'i-lucide-chevron-down'
    : 'i-lucide-chevron-up';
};

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
</script>

<template>
  <div
    class="w-full overflow-hidden rounded-xl border border-border/50 bg-card shadow-sm"
  >
    <div class="w-full overflow-x-auto">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-border/50 bg-muted/30">
          <tr>
            <th class="w-12 px-4 py-3 align-middle">
              <RelayCheckbox
                :model-value="isAllSelected"
                :indeterminate="isSomeSelected"
                class="border-muted-foreground/30"
                @update:model-value="handleSelectAll"
              />
            </th>
            <th
              class="whitespace-nowrap px-4 py-3 font-medium text-muted-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.name)"
            >
              <button
                type="button"
                class="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                @click="handleColumnSort(SORTABLE_COLUMNS.name)"
              >
                {{ t('CONTACTS_LAYOUT.FILTER.NAME') }}
                <span
                  class="size-3.5 shrink-0"
                  :class="sortIconClass(SORTABLE_COLUMNS.name)"
                />
              </button>
            </th>
            <th
              v-if="visibleColumns.includes('email')"
              class="whitespace-nowrap px-4 py-3 font-medium text-muted-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.email)"
            >
              <button
                type="button"
                class="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                @click="handleColumnSort(SORTABLE_COLUMNS.email)"
              >
                {{ t('CONTACTS_LAYOUT.FILTER.EMAIL') }}
                <span
                  class="size-3.5 shrink-0"
                  :class="sortIconClass(SORTABLE_COLUMNS.email)"
                />
              </button>
            </th>
            <th
              v-if="visibleColumns.includes('phoneNumber')"
              class="whitespace-nowrap px-4 py-3 font-medium text-muted-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.phoneNumber)"
            >
              <button
                type="button"
                class="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                @click="handleColumnSort(SORTABLE_COLUMNS.phoneNumber)"
              >
                {{ t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER') }}
                <span
                  class="size-3.5 shrink-0"
                  :class="sortIconClass(SORTABLE_COLUMNS.phoneNumber)"
                />
              </button>
            </th>
            <th
              v-if="visibleColumns.includes('company')"
              class="whitespace-nowrap px-4 py-3 font-medium text-muted-foreground"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.company)"
            >
              <button
                type="button"
                class="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                @click="handleColumnSort(SORTABLE_COLUMNS.company)"
              >
                {{ t('CONTACTS_LAYOUT.FILTER.COMPANY') }}
                <span
                  class="size-3.5 shrink-0"
                  :class="sortIconClass(SORTABLE_COLUMNS.company)"
                />
              </button>
            </th>
            <th
              v-if="visibleColumns.includes('createdAt')"
              class="hidden whitespace-nowrap px-4 py-3 font-medium text-muted-foreground lg:table-cell"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.createdAt)"
            >
              <button
                type="button"
                class="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                @click="handleColumnSort(SORTABLE_COLUMNS.createdAt)"
              >
                {{ t('CONTACTS_LAYOUT.FILTER.CREATED_AT') }}
                <span
                  class="size-3.5 shrink-0"
                  :class="sortIconClass(SORTABLE_COLUMNS.createdAt)"
                />
              </button>
            </th>
            <th
              v-if="visibleColumns.includes('lastActivity')"
              class="hidden whitespace-nowrap px-4 py-3 font-medium text-muted-foreground lg:table-cell"
              :aria-sort="sortAriaValue(SORTABLE_COLUMNS.lastActivity)"
            >
              <button
                type="button"
                class="inline-flex items-center gap-1 transition-colors hover:text-foreground"
                @click="handleColumnSort(SORTABLE_COLUMNS.lastActivity)"
              >
                {{ t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY') }}
                <span
                  class="size-3.5 shrink-0"
                  :class="sortIconClass(SORTABLE_COLUMNS.lastActivity)"
                />
              </button>
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
                class="border-muted-foreground/30"
                @update:model-value="
                  checked => handleSelectRow(contact.id, checked)
                "
              />
            </td>

            <td class="min-w-[200px] px-4 py-4 align-middle">
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
              <span v-else class="text-sm text-muted-foreground">—</span>
            </td>

            <td
              v-if="visibleColumns.includes('phoneNumber')"
              class="whitespace-nowrap px-4 py-4 align-middle text-sm text-muted-foreground"
            >
              {{ contact.phoneNumber || '—' }}
            </td>

            <td
              v-if="visibleColumns.includes('company')"
              class="px-4 py-4 align-middle text-sm text-foreground"
            >
              {{ contact.additionalAttributes?.companyName || '—' }}
            </td>

            <td
              v-if="visibleColumns.includes('createdAt')"
              class="hidden whitespace-nowrap px-4 py-4 align-middle text-sm text-muted-foreground lg:table-cell"
            >
              {{ formatDate(contact.createdAt) || '—' }}
            </td>

            <td
              v-if="visibleColumns.includes('lastActivity')"
              class="hidden whitespace-nowrap px-4 py-4 align-middle text-sm text-muted-foreground lg:table-cell"
            >
              {{ getRelativeTime(contact.lastActivityAt) || '—' }}
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
              class="px-4 py-4 align-middle text-sm text-muted-foreground"
            >
              {{ contact.customAttributes?.[col.attributeKey] || '—' }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
