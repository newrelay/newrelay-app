<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import ContactsListingHeaderActions from 'dashboard/components-next/Contacts/ContactsHeader/ContactsListingHeaderActions.vue';

const route = useRoute();
const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const tabs = computed(() => [
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.ALL'),
    routeName: 'contacts_dashboard_index',
    to: accountScopedRoute('contacts_dashboard_index'),
  },
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.BULK_ACTIONS'),
    routeName: 'contacts_dashboard_bulk_actions',
    to: accountScopedRoute('contacts_dashboard_bulk_actions'),
  },
  {
    name: t('CONTACTS_LAYOUT.HEADER.SUB_NAV.TASKS'),
    routeName: 'contacts_dashboard_tasks',
    to: accountScopedRoute('contacts_dashboard_tasks'),
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
    <header class="flex shrink-0 flex-col border-b border-border/40 px-6 pt-6">
      <div class="flex items-start justify-between gap-3">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.TITLE') }}
          </h1>
          <p class="mt-1 text-sm text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.DESCRIPTION') }}
          </p>
        </div>
        <ContactsListingHeaderActions />
      </div>
      <nav
        class="mt-6 flex items-center gap-6 overflow-x-auto no-scrollbar"
        role="tablist"
      >
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="tab.to"
          role="tab"
          :aria-selected="isActive(tab)"
          class="relative -mb-px shrink-0 border-b-2 px-1 pb-3 pt-2 text-sm transition-colors"
          :class="
            isActive(tab)
              ? 'border-primary font-medium text-foreground'
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
