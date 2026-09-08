<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import SettingsLayout from '../SettingsLayout.vue';
import AgentAssignmentIndexPage from './pages/AgentAssignmentIndexPage.vue';
import AgentCapacityIndexPage from './pages/AgentCapacityIndexPage.vue';

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const accountId = computed(() => Number(route.params.accountId));
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCapacityTab = computed(() => {
  const hasAssignmentV2 = isFeatureEnabledonAccount.value(
    accountId.value,
    'assignment_v2'
  );
  const hasAdvancedAssignment = isFeatureEnabledonAccount.value(
    accountId.value,
    'advanced_assignment'
  );
  return hasAssignmentV2 && hasAdvancedAssignment;
});

const activeTab = computed(() =>
  route.name === 'agent_capacity_policy_index' ? 'capacity' : 'assignment'
);

const tabs = computed(() => {
  const items = [
    {
      key: 'assignment',
      label: t('ASSIGNMENT_POLICY.INDEX.TABS.ASSIGNMENT'),
      routeName: 'agent_assignment_policy_index',
    },
  ];
  if (showCapacityTab.value) {
    items.push({
      key: 'capacity',
      label: t('ASSIGNMENT_POLICY.INDEX.TABS.CAPACITY'),
      routeName: 'agent_capacity_policy_index',
    });
  }
  return items;
});

const selectTab = routeName => {
  if (route.name === routeName) return;
  router.push({ name: routeName });
};

watch(showCapacityTab, enabled => {
  if (!enabled && activeTab.value === 'capacity') {
    router.replace({ name: 'agent_assignment_policy_index' });
  }
});
</script>

<template>
  <SettingsLayout :no-records-found="false">
    <template #body>
      <div class="mx-auto max-w-5xl">
        <div class="mb-8">
          <h2 class="text-base font-medium text-foreground">
            {{ $t('ASSIGNMENT_POLICY.INDEX.HEADER.TITLE') }}
          </h2>
          <p class="mt-1 text-sm text-muted-foreground">
            {{ $t('ASSIGNMENT_POLICY.INDEX.HEADER.DESCRIPTION') }}
          </p>
        </div>

        <div class="mb-6 flex items-center gap-1 border-b border-border/60">
          <button
            v-for="tab in tabs"
            :key="tab.key"
            type="button"
            class="relative px-4 py-2.5 text-[14px] font-medium transition-colors"
            :class="
              activeTab === tab.key
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            "
            @click="selectTab(tab.routeName)"
          >
            {{ tab.label }}
            <div
              v-if="activeTab === tab.key"
              class="absolute bottom-0 left-0 right-0 h-0.5 rounded-t-full bg-primary"
            />
          </button>
        </div>

        <AgentAssignmentIndexPage v-if="activeTab === 'assignment'" />
        <AgentCapacityIndexPage v-else-if="showCapacityTab" />
      </div>
    </template>
  </SettingsLayout>
</template>
