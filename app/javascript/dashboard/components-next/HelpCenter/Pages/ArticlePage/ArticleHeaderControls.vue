<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { OnClickOutside } from '@vueuse/components';
import { useUISettings } from 'dashboard/composables/useUISettings';
import {
  ARTICLE_TABS,
  CATEGORY_ALL,
  ARTICLE_TABS_OPTIONS,
} from 'dashboard/helper/portalHelper';

import { RelayButton } from 'dashboard/components-next/relay';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  categories: {
    type: Array,
    required: true,
  },
  allowedLocales: {
    type: Array,
    required: true,
  },
  meta: {
    type: Object,
    required: true,
  },
  showSelectionControls: {
    type: Boolean,
    default: false,
  },
  allSelected: {
    type: Boolean,
    default: false,
  },
  isAllPublishedSelected: {
    type: Boolean,
    default: false,
  },
  hasSelection: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'tabChange',
  'localeChange',
  'categoryChange',
  'newArticle',
  'selectCurrentView',
  'selectPublished',
  'clearSelection',
]);

const route = useRoute();
const { t } = useI18n();
const { updateUISettings } = useUISettings();

const isCategoryMenuOpen = ref(false);
const isLocaleMenuOpen = ref(false);
const isSelectMenuOpen = ref(false);

const countKey = tab => {
  if (tab.value === 'all') {
    return 'articlesCount';
  }
  // API meta uses published_count → publishedCount (not publishedArticlesCount)
  if (tab.value === 'published') {
    return 'publishedCount';
  }
  return `${tab.value}ArticlesCount`;
};

const tabs = computed(() => {
  return ARTICLE_TABS_OPTIONS.map(tab => ({
    label: t(`HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.TABS.${tab.key}`),
    value: tab.value,
    count: props.meta[countKey(tab)],
  }));
});

const activeTabValue = computed(() => {
  return route.params.tab || ARTICLE_TABS.ALL;
});

const activeCategoryName = computed(() => {
  const activeCategory = props.categories.find(
    category => category.slug === route.params.categorySlug
  );

  if (activeCategory) {
    const { icon, name } = activeCategory;
    return `${icon} ${name}`;
  }

  return t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.CATEGORY.ALL');
});

const activeLocaleName = computed(() => {
  return props.allowedLocales.find(
    locale => locale.code === route.params.locale
  )?.name;
});

const categoryMenuItems = computed(() => {
  const defaultMenuItem = {
    label: t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.CATEGORY.ALL'),
    value: CATEGORY_ALL,
    action: 'filter',
  };

  const categoryItems = props.categories.map(category => ({
    label: category.name,
    value: category.slug,
    action: 'filter',
    emoji: category.icon,
  }));

  const hasCategorySlug = !!route.params.categorySlug;

  return hasCategorySlug ? [defaultMenuItem, ...categoryItems] : categoryItems;
});

const hasCategoryMenuItems = computed(() => {
  return categoryMenuItems.value?.length > 0;
});

const localeMenuItems = computed(() => {
  return props.allowedLocales.map(locale => ({
    label: locale.name,
    value: locale.code,
    action: 'filter',
  }));
});

const selectMenuItems = computed(() => {
  const items = [
    {
      label: props.allSelected
        ? t(
            'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SELECTION.DESELECT_CURRENT_VIEW'
          )
        : t(
            'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SELECTION.SELECT_CURRENT_VIEW'
          ),
      value: 'current',
      action: 'select',
      icon: 'i-lucide-check-square',
    },
    {
      label: t(
        'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SELECTION.SELECT_ALL_PUBLISHED'
      ),
      value: 'published',
      action: 'select',
      icon: props.isAllPublishedSelected ? 'i-lucide-check' : undefined,
    },
  ];

  if (props.hasSelection) {
    items.push({
      label: t(
        'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SELECTION.CLEAR_SELECTION'
      ),
      value: 'clear',
      action: 'select',
    });
  }

  return items;
});

const handleLocaleAction = ({ value }) => {
  emit('localeChange', value);
  isLocaleMenuOpen.value = false;
  updateUISettings({
    last_active_locale_code: value,
  });
};

const handleCategoryAction = ({ value }) => {
  emit('categoryChange', value);
  isCategoryMenuOpen.value = false;
};

const handleSelectAction = ({ value }) => {
  isSelectMenuOpen.value = false;
  if (value === 'current') {
    emit('selectCurrentView');
  } else if (value === 'published') {
    emit('selectPublished');
  } else if (value === 'clear') {
    emit('clearSelection');
  }
};

const handleNewArticle = () => {
  emit('newArticle');
};

const handleTabChange = tab => {
  emit('tabChange', tab);
};

const isTabActive = value => activeTabValue.value === value;
</script>

<template>
  <div
    class="flex w-full flex-col justify-between gap-4 sm:flex-row sm:items-center"
  >
    <div class="flex flex-wrap items-center gap-4">
      <div class="flex flex-wrap items-center gap-5 text-[14px]">
        <button
          v-for="tab in tabs"
          :key="tab.value"
          type="button"
          class="transition-colors"
          :class="
            isTabActive(tab.value)
              ? 'font-medium text-primary'
              : 'text-muted-foreground hover:text-foreground'
          "
          @click="handleTabChange(tab)"
        >
          {{ tab.label }}
          <span v-if="tab.count != null">({{ tab.count }})</span>
        </button>
      </div>

      <template v-if="showSelectionControls">
        <div class="hidden h-4 w-px bg-border/60 sm:block" />

        <div class="flex items-center gap-2">
          <div class="relative">
            <OnClickOutside @trigger="isSelectMenuOpen = false">
              <RelayButton
                variant="outline"
                size="sm"
                class="h-8 border-border/80 bg-background px-2.5 text-[13px] font-medium shadow-sm"
                @click="isSelectMenuOpen = !isSelectMenuOpen"
              >
                <span
                  class="i-lucide-check-square size-3.5 opacity-70"
                  aria-hidden="true"
                />
                {{
                  t(
                    'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SELECTION.SELECT'
                  )
                }}
                <span
                  class="i-lucide-chevron-down size-3.5 opacity-50"
                  aria-hidden="true"
                />
              </RelayButton>

              <DropdownMenu
                v-if="isSelectMenuOpen"
                :menu-items="selectMenuItems"
                class="left-0 top-full mt-2 w-52"
                @action="handleSelectAction"
              />
            </OnClickOutside>
          </div>

          <RelayButton
            variant="outline"
            size="sm"
            class="h-8 rounded-md px-2.5 text-[12.5px] font-medium transition-colors"
            :class="
              isAllPublishedSelected
                ? 'border-primary/30 bg-primary/10 text-primary'
                : 'border-border/80 text-muted-foreground hover:text-foreground'
            "
            @click="emit('selectPublished')"
          >
            <span
              v-if="isAllPublishedSelected"
              class="i-lucide-check size-3.5 text-primary"
              aria-hidden="true"
            />
            {{
              t(
                'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SELECTION.SELECT_PUBLISHED'
              )
            }}
          </RelayButton>
        </div>
      </template>

      <div class="hidden h-4 w-px bg-border/60 sm:block" />

      <div class="flex items-center gap-2">
        <div class="relative">
          <OnClickOutside @trigger="isLocaleMenuOpen = false">
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 border-border bg-background px-3 text-[13px] font-normal shadow-sm"
              @click="isLocaleMenuOpen = !isLocaleMenuOpen"
            >
              {{ activeLocaleName }}
              <span
                class="i-lucide-chevron-down size-3.5 opacity-50"
                aria-hidden="true"
              />
            </RelayButton>

            <DropdownMenu
              v-if="isLocaleMenuOpen"
              :menu-items="localeMenuItems"
              show-search
              class="left-0 top-full mt-2 max-h-60 w-40 max-w-[300px] xl:right-0"
              @action="handleLocaleAction"
            />
          </OnClickOutside>
        </div>
        <div v-if="hasCategoryMenuItems" class="relative">
          <OnClickOutside @trigger="isCategoryMenuOpen = false">
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 max-w-48 px-3 text-[13px] font-normal"
              @click="isCategoryMenuOpen = !isCategoryMenuOpen"
            >
              <span class="truncate">{{ activeCategoryName }}</span>
              <span
                class="i-lucide-chevron-down size-3.5 shrink-0 opacity-50"
                aria-hidden="true"
              />
            </RelayButton>

            <DropdownMenu
              v-if="isCategoryMenuOpen"
              :menu-items="categoryMenuItems"
              show-search
              class="left-0 top-full mt-2 max-h-60 w-48 xl:right-0"
              @action="handleCategoryAction"
            />
          </OnClickOutside>
        </div>
      </div>
    </div>

    <RelayButton class="h-9 shrink-0 px-4 shadow-sm" @click="handleNewArticle">
      <span class="i-lucide-plus size-4" aria-hidden="true" />
      {{ t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.NEW_ARTICLE') }}
    </RelayButton>
  </div>
</template>
