<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import SettingsFlowShell from '../../components/SettingsFlowShell.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const steps = computed(() => [
  {
    title: t('TEAMS_SETTINGS.EDIT_FLOW.EDIT_WIZARD_DETAILS.TITLE'),
    body: t('TEAMS_SETTINGS.EDIT_FLOW.EDIT_WIZARD_DETAILS.BODY'),
    route: 'settings_teams_edit',
  },
  {
    title: t('TEAMS_SETTINGS.EDIT_FLOW.EDIT_WIZARD_AGENTS.TITLE'),
    body: t('TEAMS_SETTINGS.EDIT_FLOW.EDIT_WIZARD_AGENTS.BODY'),
    route: 'settings_teams_edit_members',
  },
  {
    title: t('TEAMS_SETTINGS.EDIT_FLOW.EDIT_WIZARD_FINISH.TITLE'),
    body: t('TEAMS_SETTINGS.EDIT_FLOW.EDIT_WIZARD_FINISH.BODY'),
    route: 'settings_teams_edit_finish',
  },
]);

const activeIndex = computed(() => {
  const index = steps.value.findIndex(item => item.route === route.name);
  return index === -1 ? 0 : index;
});

const stepLabel = computed(() =>
  t('TEAMS_SETTINGS.FLOW.STEP', {
    current: activeIndex.value + 1,
    total: steps.value.length,
  })
);

const goBack = () => {
  if (activeIndex.value === 0) {
    router.push(accountScopedRoute('settings_teams_list'));
    return;
  }
  router.back();
};
</script>

<template>
  <SettingsFlowShell
    :title="t('TEAMS_SETTINGS.HEADER')"
    :steps="steps"
    :active-index="activeIndex"
    :back-label="t('GENERAL_SETTINGS.BACK')"
    :step-label="stepLabel"
    @back="goBack"
  >
    <router-view />
  </SettingsFlowShell>
</template>
