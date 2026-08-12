<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';
import articleContent from 'dashboard/components-next/HelpCenter/EmptyState/Portal/portalEmptyStateContent.js';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  showButton: {
    type: Boolean,
    default: true,
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
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
      <div v-if="showButton">
        <RelayButton class="h-9 shadow-xs" @click="onClick">
          <span class="i-lucide-plus size-4" aria-hidden="true" />
          {{ buttonLabel }}
        </RelayButton>
      </div>
    </template>
  </EmptyStateLayout>
</template>
