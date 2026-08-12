<script setup>
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useConfig } from 'dashboard/composables/useConfig';
import { ARTICLE_TABS, CATEGORY_ALL } from 'dashboard/helper/portalHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAlert } from 'dashboard/composables';
import articlesAPI from 'dashboard/api/helpCenter/articles';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';
import ArticleHeaderControls from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleHeaderControls.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ArticleEmptyState from 'dashboard/components-next/HelpCenter/EmptyState/Article/ArticleEmptyState.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import BulkTranslateDialog from './BulkTranslateDialog.vue';

const props = defineProps({
  articles: {
    type: Array,
    required: true,
  },
  categories: {
    type: Array,
    required: true,
  },
  allowedLocales: {
    type: Array,
    required: true,
  },
  portalName: {
    type: String,
    required: true,
  },
  meta: {
    type: Object,
    required: true,
  },
  isCategoryArticles: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['pageChange', 'fetchPortal', 'refreshArticles']);

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isFetching = useMapGetter('articles/isFetching');
const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const selectedArticleIds = ref(new Set());
const deleteConfirmDialogRef = ref(null);
const isCategoryMenuOpen = ref(false);

const { isEnterprise } = useConfig();

const isTranslationAvailable = computed(
  () =>
    isEnterprise &&
    isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CAPTAIN_TASKS
    )
);

const allItems = computed(() => props.articles.map(a => ({ id: a.id })));
const visibleArticleIds = computed(() => props.articles.map(a => a.id));

const selectAllLabel = computed(() => {
  if (!visibleArticleIds.value.length) return '';
  return t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.SELECT_ALL', {
    count: visibleArticleIds.value.length,
  });
});

const selectedCountLabel = computed(() =>
  t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.SELECTED_COUNT', {
    count: selectedArticleIds.value.size,
  })
);

const allSelected = computed(
  () =>
    visibleArticleIds.value.length > 0 &&
    visibleArticleIds.value.every(id => selectedArticleIds.value.has(id))
);

const publishedArticleIds = computed(() =>
  props.articles.filter(a => a.status === 'published').map(a => a.id)
);

const isAllPublishedSelected = computed(
  () =>
    publishedArticleIds.value.length > 0 &&
    publishedArticleIds.value.every(id => selectedArticleIds.value.has(id))
);

const bulkTranslateDialogRef = ref(null);

const hasNoArticles = computed(
  () => !isFetching.value && !props.articles.length
);

const isLoading = computed(() => isFetching.value || isSwitchingPortal.value);

const showSelectionControls = computed(
  () => !isLoading.value && props.articles.length > 0
);

const totalArticlesCount = computed(() => props.meta.allArticlesCount);

const hasNoArticlesInPortal = computed(
  () => totalArticlesCount.value === 0 && !props.isCategoryArticles
);

const shouldShowPaginationFooter = computed(() => {
  return !(isFetching.value || isSwitchingPortal.value || hasNoArticles.value);
});

const updateRoute = newParams => {
  const { portalSlug, locale, tab, categorySlug } = route.params;
  router.push({
    name: 'portals_articles_index',
    params: {
      portalSlug,
      locale: newParams.locale ?? locale,
      tab: newParams.tab ?? tab,
      categorySlug: newParams.categorySlug ?? categorySlug,
      ...newParams,
    },
  });
};

const articlesCount = computed(() => {
  const { tab } = route.params;
  const { meta } = props;
  const countMap = {
    '': meta.articlesCount,
    mine: meta.mineArticlesCount,
    published: meta.publishedCount,
    draft: meta.draftArticlesCount,
    archived: meta.archivedArticlesCount,
  };
  return Number(countMap[tab] || countMap['']);
});

const showArticleHeaderControls = computed(
  () => !props.isCategoryArticles && !isSwitchingPortal.value
);

const showCategoryHeaderControls = computed(
  () => props.isCategoryArticles && !isSwitchingPortal.value
);

const getEmptyStateText = type => {
  if (props.isCategoryArticles) {
    return t(`HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.CATEGORY.${type}`);
  }
  const tabName = route.params.tab?.toUpperCase() || 'ALL';
  return t(`HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.${tabName}.${type}`);
};

const getEmptyStateTitle = computed(() => getEmptyStateText('TITLE'));
const getEmptyStateSubtitle = computed(() => getEmptyStateText('SUBTITLE'));

const handleTabChange = tab =>
  updateRoute({ tab: tab.value === ARTICLE_TABS.ALL ? '' : tab.value });

const handleCategoryAction = value =>
  updateRoute({ categorySlug: value === CATEGORY_ALL ? '' : value });

const handleLocaleAction = value => {
  updateRoute({ locale: value, categorySlug: '' });
  emit('fetchPortal', value);
};
const handlePageChange = page => emit('pageChange', page);

const navigateToNewArticlePage = () => {
  const { categorySlug, locale } = route.params;
  router.push({
    name: props.isCategoryArticles
      ? 'portals_categories_articles_new'
      : 'portals_articles_new',
    params: { categorySlug, locale },
  });
};

const handleToggleSelect = articleId => {
  const newSet = new Set(selectedArticleIds.value);
  if (newSet.has(articleId)) {
    newSet.delete(articleId);
  } else {
    newSet.add(articleId);
  }
  selectedArticleIds.value = newSet;
};

const clearSelection = () => {
  selectedArticleIds.value = new Set();
};

const toggleSelectCurrentView = () => {
  if (allSelected.value) {
    clearSelection();
    return;
  }
  selectedArticleIds.value = new Set(visibleArticleIds.value);
};

const selectAllPublished = () => {
  if (isAllPublishedSelected.value) {
    const next = new Set(selectedArticleIds.value);
    publishedArticleIds.value.forEach(id => next.delete(id));
    selectedArticleIds.value = next;
    return;
  }
  selectedArticleIds.value = new Set([
    ...selectedArticleIds.value,
    ...publishedArticleIds.value,
  ]);
};

const handleTranslateArticle = articleId => {
  selectedArticleIds.value = new Set([articleId]);
  bulkTranslateDialogRef.value?.dialogRef?.open();
};

const openTranslateDialog = () => {
  bulkTranslateDialogRef.value?.dialogRef?.open();
};

const onBulkActionSuccess = message => {
  useAlert(message);
  clearSelection();
  emit('refreshArticles');
};

const bulkUpdateStatus = async status => {
  try {
    await articlesAPI.bulkUpdateStatus({
      portalSlug: route.params.portalSlug,
      articleIds: [...selectedArticleIds.value],
      status,
    });
    onBulkActionSuccess(
      t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.STATUS_SUCCESS')
    );
  } catch (error) {
    useAlert(
      error?.message || t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.STATUS_ERROR')
    );
  }
};

const categoryMenuItems = computed(() =>
  props.categories.map(category => ({
    label: category.name,
    value: category.id,
    action: 'move',
    emoji: category.icon,
  }))
);

const handleBulkUpdateCategory = async ({ value }) => {
  isCategoryMenuOpen.value = false;
  try {
    await articlesAPI.bulkUpdateCategory({
      portalSlug: route.params.portalSlug,
      articleIds: [...selectedArticleIds.value],
      categoryId: value,
    });
    onBulkActionSuccess(
      t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.CATEGORY_SUCCESS')
    );
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.CATEGORY_ERROR')
    );
  }
};

const confirmBulkDelete = () => {
  deleteConfirmDialogRef.value?.open();
};

const bulkDelete = async () => {
  try {
    await articlesAPI.bulkDelete({
      portalSlug: route.params.portalSlug,
      articleIds: [...selectedArticleIds.value],
    });
    deleteConfirmDialogRef.value?.close();
    onBulkActionSuccess(
      t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_SUCCESS')
    );
  } catch (error) {
    deleteConfirmDialogRef.value?.close();
    useAlert(
      error?.message || t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_ERROR')
    );
  }
};

// Clear selection when articles change (page change, filter change)
watch(
  () => props.articles,
  () => clearSelection()
);
</script>

<template>
  <HelpCenterLayout
    :current-page="Number(meta.currentPage)"
    :total-items="articlesCount"
    :items-per-page="25"
    :header="portalName"
    :show-pagination-footer="shouldShowPaginationFooter"
    @update:current-page="handlePageChange"
  >
    <template #header-actions>
      <ArticleHeaderControls
        v-if="showArticleHeaderControls"
        :categories="categories"
        :allowed-locales="allowedLocales"
        :meta="meta"
        :show-selection-controls="showSelectionControls"
        :all-selected="allSelected"
        :is-all-published-selected="isAllPublishedSelected"
        :has-selection="selectedArticleIds.size > 0"
        @tab-change="handleTabChange"
        @locale-change="handleLocaleAction"
        @category-change="handleCategoryAction"
        @new-article="navigateToNewArticlePage"
        @select-current-view="toggleSelectCurrentView"
        @select-published="selectAllPublished"
        @clear-selection="clearSelection"
      />
      <CategoryHeaderControls
        v-else-if="showCategoryHeaderControls"
        :categories="categories"
        :allowed-locales="allowedLocales"
        :has-selected-category="isCategoryArticles"
        @new-article="navigateToNewArticlePage"
      />
    </template>
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 text-muted-foreground"
      >
        <Spinner />
      </div>
      <template v-else-if="!hasNoArticles">
        <div
          v-if="selectedArticleIds.size > 0"
          class="sticky top-0 z-[5] bg-gradient-to-b from-background from-90% to-transparent pb-2 pt-1"
        >
          <BulkSelectBar
            v-model="selectedArticleIds"
            :all-items="allItems"
            :select-all-label="selectAllLabel"
            :selected-count-label="selectedCountLabel"
            class="mb-3 justify-between rounded-xl border-primary/30 bg-primary/5 p-3 shadow-md ltr:!pr-3 rtl:!pl-3"
          >
            <template #secondaryActions>
              <RelayButton
                variant="ghost"
                size="sm"
                class="h-8 text-[12.5px] text-muted-foreground"
                @click="clearSelection"
              >
                {{
                  t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.CLEAR_SELECTION')
                }}
              </RelayButton>
            </template>
            <template #actions>
              <div class="ml-auto flex flex-wrap items-center gap-2">
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 text-[12.5px]"
                  @click="bulkUpdateStatus('published')"
                >
                  <span class="i-lucide-check size-3.5 text-primary" />
                  <span class="hidden sm:inline">{{
                    t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.PUBLISH')
                  }}</span>
                </RelayButton>
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 text-[12.5px]"
                  @click="bulkUpdateStatus('draft')"
                >
                  <span class="i-lucide-pencil-line size-3.5 opacity-70" />
                  <span class="hidden sm:inline">{{
                    t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DRAFT')
                  }}</span>
                </RelayButton>
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 text-[12.5px]"
                  @click="bulkUpdateStatus('archived')"
                >
                  <span class="i-lucide-archive size-3.5 opacity-70" />
                  <span class="hidden sm:inline">{{
                    t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.ARCHIVE')
                  }}</span>
                </RelayButton>
                <div v-if="categoryMenuItems.length" class="relative">
                  <OnClickOutside @trigger="isCategoryMenuOpen = false">
                    <RelayButton
                      variant="outline"
                      size="sm"
                      class="h-8 text-[12.5px]"
                      @click="isCategoryMenuOpen = !isCategoryMenuOpen"
                    >
                      <span class="i-lucide-folder-input size-3.5 opacity-70" />
                      <span class="hidden sm:inline">{{
                        t(
                          'HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.MOVE_TO_CATEGORY'
                        )
                      }}</span>
                    </RelayButton>
                    <DropdownMenu
                      v-if="isCategoryMenuOpen"
                      :menu-items="categoryMenuItems"
                      show-search
                      class="right-0 top-full mt-2 max-h-60 w-48"
                      @action="handleBulkUpdateCategory"
                    />
                  </OnClickOutside>
                </div>
                <RelayButton
                  v-if="isTranslationAvailable"
                  variant="outline"
                  size="sm"
                  class="h-8 text-[12.5px]"
                  @click="openTranslateDialog"
                >
                  <span class="i-lucide-languages size-3.5 opacity-70" />
                  <span class="hidden sm:inline">{{
                    t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.TRANSLATE')
                  }}</span>
                </RelayButton>
                <RelayButton
                  variant="destructive"
                  size="sm"
                  class="h-8 text-[12.5px]"
                  @click="confirmBulkDelete"
                >
                  <span class="i-lucide-trash-2 size-3.5" />
                  <span class="hidden sm:inline">{{
                    t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE')
                  }}</span>
                </RelayButton>
              </div>
            </template>
          </BulkSelectBar>
        </div>
        <ArticleList
          :articles="articles"
          :is-category-articles="isCategoryArticles"
          :selected-article-ids="selectedArticleIds"
          class="relative z-0"
          @translate-article="handleTranslateArticle"
          @toggle-select="handleToggleSelect"
        />
      </template>
      <ArticleEmptyState
        v-else
        :title="getEmptyStateTitle"
        :subtitle="getEmptyStateSubtitle"
        :show-button="hasNoArticlesInPortal"
        :button-label="
          t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.ALL.BUTTON_LABEL')
        "
        @click="navigateToNewArticlePage"
      />
    </template>
    <BulkTranslateDialog
      ref="bulkTranslateDialogRef"
      :selected-article-ids="[...selectedArticleIds]"
      :allowed-locales="allowedLocales"
      @translate-started="clearSelection"
    />
    <Dialog
      ref="deleteConfirmDialogRef"
      type="alert"
      :title="
        t(
          'HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_CONFIRM_TITLE',
          selectedArticleIds.size
        )
      "
      :description="
        t(
          'HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_CONFIRM_DESCRIPTION',
          selectedArticleIds.size
        )
      "
      :confirm-button-label="
        t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_CONFIRM')
      "
      @confirm="bulkDelete"
    />
  </HelpCenterLayout>
</template>
