<script setup>
import CompanyHeader from './CompaniesHeader/CompanyHeader.vue';

defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
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
  isEmptyState: { type: Boolean, default: false },
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
</script>

<template>
  <section
    class="relative flex h-full w-full overflow-hidden bg-muted/10 dark:bg-background"
  >
    <div
      class="flex min-h-0 flex-1 flex-col overflow-y-auto"
      :class="isEmptyState ? 'px-4' : 'p-6 lg:px-10'"
    >
      <div
        class="mx-auto flex w-full flex-1 flex-col"
        :class="
          isEmptyState
            ? 'm-auto max-w-5xl'
            : 'max-w-7xl space-y-6 animate-in fade-in duration-500'
        "
      >
        <CompanyHeader
          v-if="!isEmptyState"
          :search-value="searchValue"
          :header-title="headerTitle"
          :header-subtitle="headerSubtitle"
          :visible-columns="visibleColumns"
          :active-filters="activeFilters"
          :show-toolbar="showToolbar"
          @search="emit('search', $event)"
          @create="emit('create')"
          @import="emit('import')"
          @filter="emit('filter')"
          @clear-filters="emit('clearFilters')"
          @remove-filter="emit('removeFilter', $event)"
          @update:visible-columns="emit('update:visibleColumns', $event)"
        />
        <slot />
      </div>
    </div>
  </section>
</template>
