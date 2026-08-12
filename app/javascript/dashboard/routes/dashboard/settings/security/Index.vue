<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsLayout from '../SettingsLayout.vue';
import SamlSettings from './components/SamlSettings.vue';
import SamlPaywall from './components/SamlPaywall.vue';

import { usePolicy } from 'dashboard/composables/usePolicy';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const { t } = useI18n();
const { shouldShow, shouldShowPaywall } = usePolicy();

const allowedLoginMethods = computed(
  () => window.chatwootConfig.allowedLoginMethods || ['email']
);

const isSamlSsoEnabled = computed(() =>
  allowedLoginMethods.value.includes('saml')
);

const shouldShowSaml = computed(() => {
  const hasPermission = shouldShow(
    FEATURE_FLAGS.SAML,
    ['administrator'],
    [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE]
  );
  return hasPermission && isSamlSsoEnabled.value;
});

const showPaywall = computed(() => shouldShowPaywall('saml'));
</script>

<template>
  <SettingsLayout>
    <template #body>
      <div class="mt-2 space-y-6">
        <div>
          <h2 class="text-base font-medium text-foreground">
            {{ t('SECURITY_SETTINGS.TITLE') }}
          </h2>
          <p class="mt-0.5 text-[13px] text-muted-foreground">
            {{ t('SECURITY_SETTINGS.DESCRIPTION') }}
          </p>
        </div>

        <SamlPaywall v-if="showPaywall" />
        <SamlSettings v-else-if="shouldShowSaml" />
        <p v-else class="text-sm text-muted-foreground">
          {{ t('SECURITY_SETTINGS.SAML_DISABLED_MESSAGE') }}
        </p>
      </div>
    </template>
  </SettingsLayout>
</template>
