<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { debounce } from '@chatwoot/utils';
import { useCompaniesStore } from 'dashboard/stores/companies';

import CompaniesListLayout from 'dashboard/components-next/Companies/CompaniesListLayout.vue';
import CompaniesTable from 'dashboard/components-next/Companies/CompaniesTable.vue';
import CompanyEmptyState from 'dashboard/components-next/Companies/EmptyState/CompanyEmptyState.vue';
import mockCompanies from 'dashboard/components-next/Companies/EmptyState/companyEmptyStateContent';
import CompanyCreateDialog from 'dashboard/components-next/Companies/CompanyCreateDialog.vue';
import CompanyImportDialog from 'dashboard/components-next/Companies/CompanyImportDialog.vue';
import CompanyFiltersDrawer from 'dashboard/components-next/Companies/CompanyFiltersDrawer.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const DEFAULT_SORT_FIELD = 'name';
const DEBOUNCE_DELAY = 300;
const DEFAULT_VISIBLE_COLUMNS = {
  company: true,
  industry: true,
  phone: true,
  email: true,
  contacts: true,
  website: true,
  owner: true,
};

const companiesStore = useCompaniesStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { updateUISettings, uiSettings } = useUISettings();

const companies = computed(() => companiesStore.getCompaniesList);
const meta = computed(() => companiesStore.getMeta);
const uiFlags = computed(() => companiesStore.getUIFlags);

const searchQuery = computed(() => route.query?.search || '');
const searchValue = ref(searchQuery.value);
const createCompanyDialogRef = ref(null);
const isImportOpen = ref(false);
const isFilterOpen = ref(false);
const activeFilters = ref([]);
const pageNumber = computed(() => Number(route.query?.page) || 1);

const parseSortSettings = (sortString = '') => {
  const hasDescending = sortString.startsWith('-');
  const sortField = hasDescending ? sortString.slice(1) : sortString;
  return {
    sort: sortField || DEFAULT_SORT_FIELD,
    order: hasDescending ? '-' : '',
  };
};

const { companies_sort_by: companySortBy = DEFAULT_SORT_FIELD } =
  uiSettings.value ?? {};
const { sort: initialSort, order: initialOrder } =
  parseSortSettings(companySortBy);

const sortState = reactive({
  activeSort: initialSort,
  activeOrdering: initialOrder,
});

const visibleColumns = computed({
  get: () =>
    uiSettings.value?.companies_visible_columns || {
      ...DEFAULT_VISIBLE_COLUMNS,
    },
  set: val => {
    updateUISettings({ companies_visible_columns: val });
  },
});

const isFetchingList = computed(() => uiFlags.value.fetchingList);
const isCreatingCompany = computed(() => uiFlags.value.creatingItem);
const isImportingCompany = computed(() => uiFlags.value.isImporting);

const buildSortAttr = () =>
  `${sortState.activeOrdering}${sortState.activeSort}`;

const sortParam = computed(() => buildSortAttr());

const showMockCompanies = ref(false);
const hasRealCompanies = computed(() => companies.value.length > 0);
const hasCompanies = computed(
  () => showMockCompanies.value || hasRealCompanies.value
);
const isIndexFirstPage = computed(() => pageNumber.value === 1);
const showEmptyStateLayout = computed(
  () =>
    !searchQuery.value &&
    !activeFilters.value.length &&
    !hasCompanies.value &&
    isIndexFirstPage.value &&
    !isFetchingList.value
);
const showEmptyText = computed(
  () =>
    (searchQuery.value || activeFilters.value.length > 0) &&
    !hasCompanies.value &&
    !isFetchingList.value
);

const companyFieldValue = (company, property) => {
  const attrs = company.additionalAttributes || {};
  switch (property) {
    case 'name':
      return company.name || '';
    case 'industry':
      return attrs.industry || '';
    case 'contacts':
      return String(company.contactsCount || 0);
    case 'phone':
      return attrs.phone || '';
    case 'email':
      return attrs.email || '';
    case 'website':
      return attrs.website || company.domain || '';
    case 'owner':
      return attrs.owner || '';
    default:
      return '';
  }
};

const matchesFilter = (company, filter) => {
  const field = String(companyFieldValue(company, filter.property))
    .toLowerCase()
    .trim();
  const value = String(filter.value || '')
    .toLowerCase()
    .trim();
  if (filter.operator === 'not_equal') return field !== value;
  return field.includes(value) || field === value;
};

const displayedCompanies = computed(() => {
  if (!activeFilters.value.length) return companies.value;
  return companies.value.filter(company =>
    activeFilters.value.every(filter => matchesFilter(company, filter))
  );
});

const listCompanies = computed(() =>
  showMockCompanies.value ? mockCompanies : displayedCompanies.value
);

const updateURLParams = (page, search = '', sort = '') => {
  const query = {
    ...route.query,
    page: page.toString(),
  };

  if (search) {
    query.search = search;
  } else {
    delete query.search;
  }

  if (sort) {
    query.sort = sort;
  } else {
    delete query.sort;
  }

  router.replace({ query });
};

const fetchCompanies = async (page, search, sort) => {
  const currentPage = page ?? pageNumber.value;
  const currentSearch = search ?? searchQuery.value;
  const currentSort = sort ?? sortParam.value;

  if (page !== undefined || search !== undefined || sort !== undefined) {
    updateURLParams(currentPage, currentSearch, currentSort);
  }

  if (currentSearch) {
    await companiesStore.search({
      search: currentSearch,
      page: currentPage,
      sort: currentSort,
    });
  } else {
    await companiesStore.get({
      page: currentPage,
      sort: currentSort,
    });
  }
};

const onSearch = debounce(query => {
  searchValue.value = query;
  fetchCompanies(1, query, sortParam.value);
}, DEBOUNCE_DELAY);

const onPageChange = page => {
  fetchCompanies(page, searchValue.value, sortParam.value);
};

const showCompany = companyId => {
  router.push({
    name: 'companies_dashboard_show',
    params: {
      accountId: route.params.accountId,
      companyId,
    },
  });
};

const openCreateCompanyDialog = () => {
  createCompanyDialogRef.value?.dialogRef.open();
};

const openImportDialog = () => {
  isImportOpen.value = true;
};

const importCompanies = async file => {
  try {
    await companiesStore.import(file);
    isImportOpen.value = false;
    useAlert(t('COMPANIES.IMPORT.MESSAGES.SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('COMPANIES.IMPORT.MESSAGES.ERROR'));
  }
};

const openFilters = () => {
  isFilterOpen.value = true;
};

const applyFilters = filters => {
  activeFilters.value = filters;
};

const clearFilters = () => {
  activeFilters.value = [];
};

const clearSearch = () => {
  searchValue.value = '';
  fetchCompanies(1, '', sortParam.value);
};

const removeFilter = index => {
  activeFilters.value = activeFilters.value.filter((_, i) => i !== index);
};

const createCompany = async company => {
  try {
    const newCompany = await companiesStore.create(company);
    createCompanyDialogRef.value?.onSuccess();
    useAlert(t('COMPANIES.CREATE.MESSAGES.SUCCESS'));
    showCompany(newCompany.id);
  } catch {
    useAlert(t('COMPANIES.CREATE.MESSAGES.ERROR'));
  }
};

onMounted(() => {
  searchValue.value = searchQuery.value;

  if (!route.query.sort && sortParam.value !== DEFAULT_SORT_FIELD) {
    updateURLParams(pageNumber.value, searchQuery.value, sortParam.value);
  }

  fetchCompanies();
});
</script>

<template>
  <CompaniesListLayout
    :search-value="searchValue"
    :header-title="t('COMPANIES.HEADER')"
    :header-subtitle="t('COMPANIES.SUBTITLE')"
    :visible-columns="visibleColumns"
    :active-filters="activeFilters"
    :show-toolbar="!showEmptyStateLayout"
    :is-empty-state="showEmptyStateLayout"
    @search="onSearch"
    @create="openCreateCompanyDialog"
    @import="openImportDialog"
    @filter="openFilters"
    @clear-filters="clearFilters"
    @remove-filter="removeFilter"
    @update:visible-columns="visibleColumns = $event"
  >
    <div
      v-if="isFetchingList"
      class="flex items-center justify-center py-16 text-muted-foreground"
    >
      <Spinner />
    </div>

    <CompanyEmptyState
      v-else-if="showEmptyStateLayout"
      @create="openCreateCompanyDialog"
      @import="openImportDialog"
      @load-mock="showMockCompanies = true"
    />

    <div
      v-else-if="showEmptyText"
      class="flex flex-col items-center justify-center space-y-3 py-16 text-center"
    >
      <div
        class="flex size-12 items-center justify-center rounded-full bg-muted"
      >
        <span class="i-lucide-search size-6 text-muted-foreground" />
      </div>
      <h3 class="text-lg font-medium text-foreground">
        {{ t('COMPANIES.EMPTY_STATE.SEARCH_EMPTY_TITLE') }}
      </h3>
      <p v-if="searchQuery" class="max-w-sm text-sm text-muted-foreground">
        {{
          t('COMPANIES.EMPTY_STATE.SEARCH_EMPTY_SUBTITLE', {
            query: searchQuery,
          })
        }}
      </p>
      <div class="mt-4 flex items-center justify-center gap-3">
        <RelayButton v-if="searchQuery" variant="outline" @click="clearSearch">
          {{ t('COMPANIES.EMPTY_STATE.CLEAR_SEARCH') }}
        </RelayButton>
        <RelayButton
          v-else-if="activeFilters.length"
          variant="outline"
          @click="clearFilters"
        >
          {{ t('COMPANIES.FILTERS.CLEAR') }}
        </RelayButton>
        <RelayButton class="gap-2 shadow-sm" @click="openCreateCompanyDialog">
          {{ t('COMPANIES.ACTIONS.CREATE') }}
        </RelayButton>
      </div>
    </div>

    <CompaniesTable
      v-else
      :companies="listCompanies"
      :visible-columns="visibleColumns"
      :current-page="showMockCompanies ? 1 : pageNumber"
      :total-items="
        showMockCompanies ? mockCompanies.length : Number(meta.totalCount || 0)
      "
      :items-per-page="25"
      :is-preview="showMockCompanies"
      @show-company="showCompany"
      @update:current-page="onPageChange"
    />

    <CompanyCreateDialog
      ref="createCompanyDialogRef"
      :is-loading="isCreatingCompany"
      @create="createCompany"
    />
    <CompanyImportDialog
      v-model:open="isImportOpen"
      :is-loading="isImportingCompany"
      @import="importCompanies"
    />
    <CompanyFiltersDrawer
      v-model:open="isFilterOpen"
      :active-filters="activeFilters"
      @apply="applyFilters"
      @clear="clearFilters"
    />
  </CompaniesListLayout>
</template>
