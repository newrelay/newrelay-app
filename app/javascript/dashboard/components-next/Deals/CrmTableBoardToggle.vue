<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

const route = useRoute();
const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const isBoard = computed(() => route.name === 'pipelines_dashboard_index');

const tabClass = active =>
  [
    'inline-flex h-full items-center gap-1.5 rounded-sm px-3 text-xs font-medium',
    active
      ? 'bg-background text-foreground shadow-sm'
      : 'text-muted-foreground hover:text-foreground',
  ].join(' ');
</script>

<template>
  <div
    class="flex h-9 items-center rounded-md border border-border/50 bg-muted/50 p-1"
    role="tablist"
  >
    <router-link
      :to="accountScopedRoute('deals_dashboard_index')"
      role="tab"
      :aria-selected="!isBoard"
      :class="tabClass(!isBoard)"
    >
      <span class="i-lucide-layout-dashboard size-3.5" />
      {{ t('DEALS.VIEW_TABLE') }}
    </router-link>
    <router-link
      :to="accountScopedRoute('pipelines_dashboard_index')"
      role="tab"
      :aria-selected="isBoard"
      :class="tabClass(isBoard)"
    >
      <span class="i-lucide-layout-dashboard size-3.5 rotate-90" />
      {{ t('DEALS.VIEW_BOARD') }}
    </router-link>
  </div>
</template>
