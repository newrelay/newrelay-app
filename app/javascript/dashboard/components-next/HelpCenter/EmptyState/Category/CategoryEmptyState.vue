<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import CategoryCard from 'dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue';
import categoryContent from 'dashboard/components-next/HelpCenter/EmptyState/Category/categoryEmptyStateContent.js';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="flex flex-col gap-3 overflow-hidden p-px">
        <CategoryCard
          v-for="category in categoryContent.slice(0, 3)"
          :id="category.id"
          :key="category.id"
          :title="category.name"
          :icon="category.icon"
          :description="category.description"
          :articles-count="category.meta.articles_count || 0"
          :slug="category.slug"
        />
      </div>
    </template>
  </EmptyStateLayout>
</template>
