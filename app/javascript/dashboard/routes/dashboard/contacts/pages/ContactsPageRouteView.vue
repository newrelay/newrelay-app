<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
const route = useRoute();
const { t } = useI18n();
const accountId = computed(() => route.params.accountId);

const tabs = computed(() => [
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.CONTACTS'),
    routeName: 'contacts_dashboard_index',
    path: `/app/accounts/${accountId.value}/contacts`,
  },
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.BULK_ACTIONS'),
    routeName: 'contacts_dashboard_bulk_actions',
    path: `/app/accounts/${accountId.value}/contacts/bulk-actions`,
  },
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.TASKS'),
    routeName: 'contacts_dashboard_tasks',
    path: `/app/accounts/${accountId.value}/contacts/tasks`,
  },
]);
const isActive = tab => {
  if (route.name === tab.routeName) return true;
  if (tab.routeName === 'contacts_dashboard_index') {
    return [
      'contacts_dashboard_segments_index',
      'contacts_dashboard_labels_index',
      'contacts_dashboard_active',
    ].includes(route.name);
  }
  return false;
};
</script>

<template>
  <div class="m-0 flex h-full flex-1 flex-col overflow-hidden bg-background">
    <header class="flex shrink-0 flex-col border-b border-border px-6">
      <nav
        class="flex items-center gap-6 overflow-x-auto no-scrollbar"
        role="tablist"
      >
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="tab.path"
          role="tab"
          :aria-selected="isActive(tab)"
          class="relative -mb-px shrink-0 border-b-2 px-1 pb-3 pt-2 text-sm transition-colors"
          :class="
            isActive(tab)
              ? 'border-primary text-foreground font-medium'
              : 'border-transparent text-muted-foreground hover:text-foreground'
          "
        >
          {{ tab.name }}
        </router-link>
      </nav>
    </header>

    <div class="flex min-h-0 flex-1 flex-col overflow-hidden">
      <router-view v-slot="{ Component }">
        <keep-alive>
          <component :is="Component" />
        </keep-alive>
      </router-view>
    </div>
  </div>
</template>
