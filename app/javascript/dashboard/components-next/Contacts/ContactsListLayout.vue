<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';

import ContactListHeaderWrapper from 'dashboard/components-next/Contacts/ContactsHeader/ContactListHeaderWrapper.vue';
import ContactsActiveFiltersPreview from 'dashboard/components-next/Contacts/ContactsHeader/components/ContactsActiveFiltersPreview.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import ContactsLoadMore from 'dashboard/components-next/Contacts/ContactsLoadMore.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 100 },
  itemsPerPage: { type: Number, default: 15 },
  activeSegment: { type: Object, default: null },
  segmentsId: { type: [String, Number], default: 0 },
  hasAppliedFilters: { type: Boolean, default: false },
  isFetchingList: { type: Boolean, default: false },
  useInfiniteScroll: { type: Boolean, default: false },
  hasMore: { type: Boolean, default: false },
  isLoadingMore: { type: Boolean, default: false },
  showToolbar: { type: Boolean, default: true },
});

const emit = defineEmits([
  'update:currentPage',
  'search',
  'applyFilter',
  'clearFilters',
  'loadMore',
]);

const route = useRoute();

const contactListHeaderWrapper = ref(null);

const isNotSegmentView = computed(() => {
  return route.name !== 'contacts_dashboard_segments_index';
});

const isActiveView = computed(() => {
  return route.name === 'contacts_dashboard_active';
});

const isLabelView = computed(
  () => route.name === 'contacts_dashboard_labels_index'
);

const showActiveFiltersPreview = computed(() => {
  return (
    (props.hasAppliedFilters || !isNotSegmentView.value) &&
    !props.isFetchingList &&
    !isLabelView.value &&
    !isActiveView.value
  );
});

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};

const openFilter = () => {
  contactListHeaderWrapper.value?.onToggleFilters();
};

const showLoadMore = computed(() => {
  return props.useInfiniteScroll && props.hasMore;
});

const showPagination = computed(() => {
  return !props.useInfiniteScroll && props.showPaginationFooter;
});
</script>

<template>
  <section class="flex h-full w-full overflow-hidden bg-muted/10">
    <div class="flex h-full w-full flex-col transition-all duration-300">
      <ContactListHeaderWrapper
        v-if="showToolbar"
        ref="contactListHeaderWrapper"
        :show-search="isNotSegmentView && !isActiveView"
        :search-value="searchValue"
        :header-title="headerTitle"
        :active-segment="activeSegment"
        :segments-id="segmentsId"
        :has-applied-filters="hasAppliedFilters"
        :is-label-view="isLabelView"
        :is-active-view="isActiveView"
        @search="emit('search', $event)"
        @apply-filter="emit('applyFilter', $event)"
        @clear-filters="emit('clearFilters')"
      >
        <template #columns>
          <slot name="columns" />
        </template>
      </ContactListHeaderWrapper>

      <ContactsActiveFiltersPreview
        v-if="showActiveFiltersPreview"
        :active-segment="activeSegment"
        @clear-filters="emit('clearFilters')"
        @open-filter="openFilter"
      />

      <main class="flex-1 overflow-y-auto">
        <div class="flex h-full w-full flex-col px-6 py-6">
          <slot name="default" />
          <ContactsLoadMore
            v-if="showLoadMore"
            :is-loading="isLoadingMore"
            @load-more="emit('loadMore')"
          />
        </div>
      </main>

      <footer v-if="showPagination" class="sticky bottom-0 z-0">
        <PaginationFooter
          current-page-info="CONTACTS_LAYOUT.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
