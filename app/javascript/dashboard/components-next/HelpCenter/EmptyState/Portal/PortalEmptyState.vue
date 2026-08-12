<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';
import articleContent from './portalEmptyStateContent';
import CreatePortalDialog from 'dashboard/components-next/HelpCenter/PortalSwitcher/CreatePortalDialog.vue';

const createPortalDialogRef = ref(null);
const openDialog = () => {
  createPortalDialogRef.value.dialogRef.open();
};

const router = useRouter();

const onPortalCreate = ({ slug: portalSlug, locale }) => {
  router.push({
    name: 'portals_articles_index',
    params: { portalSlug, locale },
  });
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('HELP_CENTER.TITLE')"
    :subtitle="$t('HELP_CENTER.NEW_PAGE.DESCRIPTION')"
    class="bg-background"
  >
    <template #empty-state-item>
      <div class="flex flex-col gap-3 overflow-hidden p-px">
        <ArticleCard
          v-for="(article, index) in articleContent.slice(0, 3)"
          :id="article.id"
          :key="`article-${index}`"
          :title="article.title"
          :status="article.status"
          :updated-at="article.updatedAt"
          :author="article.author"
          :category="article.category"
          :views="article.views"
        />
      </div>
    </template>
    <template #actions>
      <RelayButton class="h-9 shadow-xs" @click="openDialog">
        <span class="i-lucide-plus size-4" aria-hidden="true" />
        {{ $t('HELP_CENTER.NEW_PAGE.CREATE_PORTAL_BUTTON') }}
      </RelayButton>
      <CreatePortalDialog
        ref="createPortalDialogRef"
        @create="onPortalCreate"
      />
    </template>
  </EmptyStateLayout>
</template>
