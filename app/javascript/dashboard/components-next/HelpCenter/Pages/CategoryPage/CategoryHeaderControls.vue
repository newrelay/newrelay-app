<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useStoreGetters } from 'dashboard/composables/store.js';

import { RelayButton } from 'dashboard/components-next/relay';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import CategoryDialog from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryDialog.vue';

const props = defineProps({
  categories: {
    type: Array,
    default: () => [],
  },
  allowedLocales: {
    type: Array,
    default: () => [],
  },
  hasSelectedCategory: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['localeChange', 'newArticle']);

const route = useRoute();
const router = useRouter();
const getters = useStoreGetters();
const { t } = useI18n();

const isLocaleMenuOpen = ref(false);
const isCreateCategoryDialogOpen = ref(false);
const isEditCategoryDialogOpen = ref(false);

const currentPortalSlug = computed(() => {
  return route.params.portalSlug;
});

const currentPortal = computed(() => {
  const slug = currentPortalSlug.value;
  if (slug) return getters['portals/portalBySlug'].value(slug);

  return getters['portals/allPortals'].value[0];
});

const currentPortalName = computed(() => {
  return currentPortal.value?.name;
});

const activeLocale = computed(() => {
  return props.allowedLocales.find(
    locale => locale.code === route.params.locale
  );
});

const activeLocaleName = computed(() => activeLocale.value?.name ?? '');
const activeLocaleCode = computed(() => activeLocale.value?.code ?? '');

const localeMenuItems = computed(() => {
  return props.allowedLocales.map(locale => ({
    label: locale.name,
    value: locale.code,
    action: 'filter',
  }));
});

const selectedCategory = computed(() =>
  props.categories.find(category => category.slug === route.params.categorySlug)
);

const selectedCategoryName = computed(() => {
  return selectedCategory.value?.name;
});

const selectedCategoryCount = computed(
  () => selectedCategory.value?.meta?.articles_count || 0
);

const selectedCategoryEmoji = computed(() => {
  return selectedCategory.value?.icon;
});

const categoriesCount = computed(() => props.categories?.length);

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t(
        'HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.BREADCRUMB.CATEGORY_LOCALE',
        { localeCode: activeLocaleCode.value }
      ),
      link: '#',
    },
  ];
  if (selectedCategory.value) {
    items.push({
      label: t(
        'HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.BREADCRUMB.ACTIVE_CATEGORY',
        {
          categoryName: selectedCategoryName.value,
          categoryCount: selectedCategoryCount.value,
        }
      ),
      emoji: selectedCategoryEmoji.value,
    });
  }
  return items;
});

const handleLocaleAction = ({ value }) => {
  emit('localeChange', value);
  isLocaleMenuOpen.value = false;
};

const handleBreadcrumbClick = () => {
  const { categorySlug, ...otherParams } = route.params;
  router.push({
    name: 'portals_categories_index',
    params: otherParams,
  });
};
</script>

<template>
  <div class="flex w-full items-center justify-between gap-4">
    <div v-if="!hasSelectedCategory" class="flex flex-wrap items-center gap-2">
      <div class="relative">
        <OnClickOutside @trigger="isLocaleMenuOpen = false">
          <RelayButton
            variant="ghost"
            class="h-9 border border-border px-3 text-[13px] hover:border-transparent"
            @click="isLocaleMenuOpen = !isLocaleMenuOpen"
          >
            {{ activeLocaleName }}
            <span
              class="i-lucide-chevron-down size-4 opacity-50"
              aria-hidden="true"
            />
          </RelayButton>
          <DropdownMenu
            v-if="isLocaleMenuOpen"
            :menu-items="localeMenuItems"
            show-search
            class="left-0 top-full mt-2 max-h-60 w-40 xl:right-0"
            @action="handleLocaleAction"
          />
        </OnClickOutside>
      </div>
      <div class="hidden h-4 w-px bg-border sm:block" />
      <span class="min-w-0 truncate text-[13px] text-muted-foreground">
        {{
          t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.CATEGORIES_COUNT', {
            n: categoriesCount,
          })
        }}
      </span>
    </div>
    <Breadcrumb
      v-else
      :items="breadcrumbItems"
      @click="handleBreadcrumbClick"
    />
    <div v-if="!hasSelectedCategory" class="relative shrink-0">
      <OnClickOutside @trigger="isCreateCategoryDialogOpen = false">
        <RelayButton
          class="h-9 shadow-xs"
          @click="isCreateCategoryDialogOpen = !isCreateCategoryDialogOpen"
        >
          <span class="i-lucide-plus size-4" aria-hidden="true" />
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.NEW_CATEGORY') }}
        </RelayButton>
        <CategoryDialog
          v-if="isCreateCategoryDialogOpen"
          mode="create"
          :portal-name="currentPortalName"
          :active-locale-name="activeLocaleName"
          :active-locale-code="activeLocaleCode"
          @close="isCreateCategoryDialogOpen = false"
        />
      </OnClickOutside>
    </div>
    <div v-else class="relative flex shrink-0 items-center gap-2">
      <OnClickOutside @trigger="isEditCategoryDialogOpen = false">
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8"
          @click="isEditCategoryDialogOpen = !isEditCategoryDialogOpen"
        >
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.EDIT_CATEGORY') }}
        </RelayButton>
        <CategoryDialog
          v-if="isEditCategoryDialogOpen"
          :selected-category="selectedCategory"
          :portal-name="currentPortalName"
          :active-locale-name="activeLocaleName"
          :active-locale-code="activeLocaleCode"
          @close="isEditCategoryDialogOpen = false"
        />
      </OnClickOutside>
      <RelayButton class="h-9 shadow-xs" @click="emit('newArticle')">
        <span class="i-lucide-plus size-4" aria-hidden="true" />
        {{ t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.NEW_ARTICLE') }}
      </RelayButton>
    </div>
  </div>
</template>
