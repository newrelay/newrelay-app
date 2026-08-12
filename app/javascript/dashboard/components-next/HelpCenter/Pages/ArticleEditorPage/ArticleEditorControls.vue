<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { OnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';

import { RelayButton } from 'dashboard/components-next/relay';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ArticleEditorProperties from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorProperties.vue';

const props = defineProps({
  article: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['saveArticle', 'setAuthor', 'setCategory']);

const { t } = useI18n();
const route = useRoute();

const openAgentsList = ref(false);
const openCategoryList = ref(false);
const openProperties = ref(false);
const selectedAuthorId = ref(null);
const selectedCategoryId = ref(null);

const agents = useMapGetter('agents/getAgents');
const categories = useMapGetter('categories/allCategories');
const currentUserId = useMapGetter('getCurrentUserID');

const isNewArticle = computed(() => !props.article?.id);

const currentUser = computed(() =>
  agents.value.find(agent => agent.id === currentUserId.value)
);

const categorySlugFromRoute = computed(() => route.params.categorySlug);

const author = computed(() => {
  if (isNewArticle.value) {
    return selectedAuthorId.value
      ? agents.value.find(agent => agent.id === selectedAuthorId.value)
      : currentUser.value;
  }
  return props.article?.author || null;
});

const authorName = computed(
  () => author.value?.name || author.value?.available_name || ''
);
const authorThumbnailSrc = computed(() => author.value?.thumbnail);

const agentList = computed(() => {
  return (
    agents.value
      ?.map(({ name, id, thumbnail }) => ({
        label: name,
        value: id,
        thumbnail: { name, src: thumbnail },
        isSelected: props.article?.author?.id
          ? id === props.article.author.id
          : id === (selectedAuthorId.value || currentUserId.value),
        action: 'assignAuthor',
      }))
      // Sort the list by isSelected first, then by name(label)
      .toSorted((a, b) => {
        if (a.isSelected !== b.isSelected) {
          return Number(b.isSelected) - Number(a.isSelected);
        }
        return a.label.localeCompare(b.label);
      }) ?? []
  );
});

const hasAgentList = computed(() => {
  return agents.value?.length > 1;
});

const findCategoryFromSlug = slug => {
  return categories.value?.find(category => category.slug === slug);
};

const selectedCategory = computed(() => {
  if (isNewArticle.value) {
    if (selectedCategoryId.value) {
      return (
        categories.value?.find(c => c.id === selectedCategoryId.value) || null
      );
    }
    if (categorySlugFromRoute.value) {
      const categoryFromSlug = findCategoryFromSlug(
        categorySlugFromRoute.value
      );
      if (categoryFromSlug) return categoryFromSlug;
    }
    return categories.value?.[0] || null;
  }
  return categories.value.find(
    category => category.id === props.article?.category?.id
  );
});

const categoryList = computed(() => {
  return (
    categories.value
      .map(({ name, id, icon }) => ({
        label: name,
        value: id,
        emoji: icon,
        isSelected: isNewArticle.value
          ? id === (selectedCategoryId.value || selectedCategory.value?.id)
          : id === props.article?.category?.id,
        action: 'assignCategory',
      }))
      // Sort categories by isSelected
      .toSorted((a, b) => Number(b.isSelected) - Number(a.isSelected))
  );
});

const hasCategoryMenuItems = computed(() => {
  return categoryList.value?.length > 0;
});

const handleArticleAction = ({ action, value }) => {
  const actions = {
    assignAuthor: () => {
      if (isNewArticle.value) {
        selectedAuthorId.value = value;
        emit('setAuthor', value);
      } else {
        emit('saveArticle', { author_id: value });
      }
      openAgentsList.value = false;
    },
    assignCategory: () => {
      if (isNewArticle.value) {
        selectedCategoryId.value = value;
        emit('setCategory', value);
      } else {
        emit('saveArticle', { category_id: value });
      }
      openCategoryList.value = false;
    },
  };

  actions[action]?.();
};

const updateMeta = meta => {
  emit('saveArticle', { meta });
};

onMounted(() => {
  if (categorySlugFromRoute.value && isNewArticle.value) {
    // Assign category from slug if there is one
    const categoryFromSlug = findCategoryFromSlug(categorySlugFromRoute.value);
    if (categoryFromSlug) {
      handleArticleAction({
        action: 'assignCategory',
        value: categoryFromSlug?.id,
      });
    }
  }
});
</script>

<template>
  <div class="mb-6 flex flex-wrap items-center gap-3">
    <div class="relative">
      <OnClickOutside @trigger="openAgentsList = false">
        <RelayButton
          variant="ghost"
          class="h-8 border border-transparent px-2 text-[13px] font-normal text-muted-foreground hover:bg-transparent hover:text-foreground"
          @click="openAgentsList = !openAgentsList"
        >
          <Avatar
            :name="authorName"
            :src="authorThumbnailSrc"
            :size="16"
            rounded-full
          />
          <span>{{ authorName || '-' }}</span>
        </RelayButton>
        <DropdownMenu
          v-if="openAgentsList && hasAgentList"
          :menu-items="agentList"
          show-search
          class="z-[100] mt-2 max-h-60 w-48 top-full ltr:left-0 rtl:right-0"
          @action="handleArticleAction"
        />
      </OnClickOutside>
    </div>

    <div class="h-4 w-px bg-border/60" />

    <div class="relative">
      <OnClickOutside @trigger="openCategoryList = false">
        <RelayButton
          variant="ghost"
          class="h-8 border border-transparent px-2 text-[13px] font-normal text-muted-foreground hover:bg-transparent hover:text-foreground"
          @click="openCategoryList = !openCategoryList"
        >
          <span
            v-if="!selectedCategory?.icon"
            class="i-lucide-layout-grid size-3.5"
            aria-hidden="true"
          />
          <span>
            {{
              selectedCategory
                ? `${selectedCategory.icon || ''} ${selectedCategory.name || t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.UNCATEGORIZED')}`
                : t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.UNCATEGORIZED')
            }}
          </span>
        </RelayButton>
        <DropdownMenu
          v-if="openCategoryList && hasCategoryMenuItems"
          :menu-items="categoryList"
          show-search
          class="left-0 top-full z-[100] mt-2 max-h-60 w-48"
          @action="handleArticleAction"
        />
      </OnClickOutside>
    </div>

    <div class="h-4 w-px bg-border/60" />

    <div class="relative">
      <OnClickOutside @trigger="openProperties = false">
        <RelayButton
          variant="ghost"
          :disabled="isNewArticle"
          class="h-8 border border-transparent px-2 text-[13px] font-normal text-muted-foreground hover:bg-transparent hover:text-foreground"
          @click="openProperties = !openProperties"
        >
          <span class="i-lucide-plus size-3.5" aria-hidden="true" />
          {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.MORE_PROPERTIES') }}
        </RelayButton>
        <ArticleEditorProperties
          v-if="openProperties"
          :article="article"
          class="right-0 top-full z-[100] mt-2 xl:left-0"
          @save-article="updateMeta"
          @close="openProperties = false"
        />
      </OnClickOutside>
    </div>
  </div>
</template>
