<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { usePolicy } from 'dashboard/composables/usePolicy';
const route = useRoute();
const { t } = useI18n();
const { checkPermissions } = usePolicy();

const accountId = computed(() => route.params.accountId);
const canManageContacts = computed(() =>
  checkPermissions(['administrator', 'contact_manage'])
);

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
    <header
      class="flex shrink-0 flex-col border-b border-border/40 px-6 pb-0 pt-6"
    >
      <!-- Main tabs: absolute bar for consistency with button tabs (border-b-2 fails on buttons) -->
      <nav class="flex items-center gap-6 overflow-x-auto" role="tablist">
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="tab.path"
          role="tab"
          :aria-selected="isActive(tab)"
          class="relative -mb-px shrink-0 px-1 pb-3 pt-2 text-sm font-medium transition-colors"
          :class="
            isActive(tab)
              ? 'text-foreground'
              : 'text-muted-foreground hover:text-foreground'
          "
        >
          {{ tab.name }}
          <span
            v-if="isActive(tab)"
            class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
            aria-hidden="true"
          />
        </router-link>
      </nav>
    </header>

    <div class="flex-1 overflow-auto">
      <router-view v-slot="{ Component }">
        <keep-alive>
          <component :is="Component" />
        </keep-alive>
      </router-view>
    </div>
  </div>
</template>
