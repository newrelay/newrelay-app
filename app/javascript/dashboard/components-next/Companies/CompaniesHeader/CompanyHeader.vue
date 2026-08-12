<script setup>
import { useI18n } from 'vue-i18n';
import {
  RelayBadge,
  RelayButton,
  RelayInput,
} from 'dashboard/components-next/relay';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import CompanyColumnManager from '../CompanyColumnManager.vue';

defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  headerSubtitle: { type: String, default: '' },
  visibleColumns: {
    type: Object,
    default: () => ({
      company: true,
      industry: true,
      phone: true,
      email: true,
      contacts: true,
      website: true,
      owner: true,
    }),
  },
  activeFilters: { type: Array, default: () => [] },
  showToolbar: { type: Boolean, default: true },
});

const emit = defineEmits([
  'search',
  'create',
  'import',
  'filter',
  'clearFilters',
  'removeFilter',
  'update:visibleColumns',
]);

const { t } = useI18n();

const propertyLabel = property => {
  const labels = {
    name: t('COMPANIES.FILTERS.PROPERTIES.NAME'),
    industry: t('COMPANIES.FILTERS.PROPERTIES.INDUSTRY'),
    contacts: t('COMPANIES.FILTERS.PROPERTIES.CONTACTS'),
    phone: t('COMPANIES.FILTERS.PROPERTIES.PHONE'),
    email: t('COMPANIES.FILTERS.PROPERTIES.EMAIL'),
    website: t('COMPANIES.FILTERS.PROPERTIES.WEBSITE'),
    owner: t('COMPANIES.FILTERS.PROPERTIES.OWNER'),
  };
  return labels[property] || labels.name;
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-base font-medium tracking-tight text-foreground">
          {{ headerTitle }}
        </h1>
        <p v-if="headerSubtitle" class="mt-1.5 text-sm text-muted-foreground">
          {{ headerSubtitle }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <RelayButton
          variant="outline"
          class="h-9 gap-2 text-sm font-medium shadow-xs"
          @click="emit('import')"
        >
          <span class="i-lucide-upload size-4 text-muted-foreground" />
          {{ t('COMPANIES.ACTIONS.IMPORT') }}
        </RelayButton>
        <RelayButton
          class="h-9 gap-2 px-5 text-sm font-medium shadow-xs"
          @click="emit('create')"
        >
          <span class="i-lucide-plus size-4" />
          {{ t('COMPANIES.ACTIONS.CREATE') }}
        </RelayButton>
      </div>
    </div>

    <div v-if="showToolbar" class="flex flex-col gap-4">
      <div class="flex items-center justify-between gap-4">
        <div class="relative w-full max-w-sm flex-1">
          <span
            class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            type="search"
            class-name="h-10 w-full rounded-lg border-border/60 bg-card pl-9 text-sm shadow-sm"
            :model-value="searchValue"
            :placeholder="t('COMPANIES.SEARCH_PLACEHOLDER')"
            @update:model-value="emit('search', $event)"
          />
        </div>

        <div class="flex shrink-0 items-center gap-3">
          <Popover align="end">
            <RelayButton
              variant="outline"
              class="h-10 gap-2 rounded-lg border-border/60 bg-card text-sm font-medium shadow-sm"
            >
              <span class="i-lucide-columns-3 size-4" />
              {{ t('COMPANIES.ACTIONS.COLUMNS') }}
              <span class="i-lucide-chevron-down ml-1 size-3 opacity-50" />
            </RelayButton>
            <template #content>
              <CompanyColumnManager
                :visible-columns="visibleColumns"
                @update:visible-columns="emit('update:visibleColumns', $event)"
              />
            </template>
          </Popover>

          <RelayButton
            variant="outline"
            class="h-10 gap-2 rounded-lg border-border/60 bg-card text-sm font-medium shadow-sm"
            @click="emit('filter')"
          >
            <span class="i-lucide-list-filter size-4" />
            {{ t('COMPANIES.ACTIONS.FILTERS') }}
          </RelayButton>
        </div>
      </div>

      <div
        v-show="activeFilters.length > 0"
        class="flex animate-in fade-in items-center justify-between rounded-lg border border-border/40 bg-muted/10 px-4 py-2.5 duration-200"
      >
        <div class="flex flex-wrap items-center gap-2">
          <template v-for="(filter, index) in activeFilters" :key="filter.id">
            <span
              v-if="index > 0"
              class="px-1 text-xs font-medium uppercase text-muted-foreground"
            >
              {{ t('COMPANIES.FILTERS.AND') }}
            </span>
            <RelayBadge
              variant="secondary"
              class="flex h-6.5 items-center gap-1.5 rounded-md border-border/60 bg-background px-2 py-0.5 text-[12px] font-medium shadow-sm hover:bg-background"
            >
              <span class="text-muted-foreground">
                {{ propertyLabel(filter.property) }}
              </span>
              <span class="font-medium text-primary">
                {{
                  filter.operator === 'not_equal'
                    ? t('COMPANIES.FILTERS.OPERATOR_IS_NOT')
                    : t('COMPANIES.FILTERS.OPERATOR_IS')
                }}
              </span>
              <span class="max-w-[150px] truncate font-semibold">
                {{ filter.value }}
              </span>
              <button
                type="button"
                class="ml-1 rounded-full p-0.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus:outline-none"
                @click="emit('removeFilter', index)"
              >
                <span class="i-lucide-x size-3" />
              </button>
            </RelayBadge>
          </template>
        </div>
        <button
          type="button"
          class="text-[13px] font-medium text-primary transition-colors hover:underline"
          @click="emit('clearFilters')"
        >
          {{ t('COMPANIES.FILTERS.CLEAR_ALL') }}
        </button>
      </div>
    </div>
  </div>
</template>
