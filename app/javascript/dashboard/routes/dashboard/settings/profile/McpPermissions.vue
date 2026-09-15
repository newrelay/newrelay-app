<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import McpPermissionsForm from './McpPermissionsForm.vue';

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const { isCloudFeatureEnabled } = useAccount();

const isMcpEnabled = computed(() => isCloudFeatureEnabled('mcp_integration'));
const scopes = computed(() => currentUser.value.access_token_scopes || []);

const handleSave = async newScopes => {
  const success = await store.dispatch('updateAccessTokenScopes', {
    scopes: newScopes,
  });
  useAlert(
    success ? t('MCP_SETTINGS.SAVE_SUCCESS') : t('MCP_SETTINGS.SAVE_ERROR')
  );
};
</script>

<template>
  <div class="grid w-full">
    <BaseSettingsHeader
      :title="t('MCP_SETTINGS.TITLE')"
      :description="t('MCP_SETTINGS.SUBTITLE')"
      :back-button-label="t('PROFILE_SETTINGS.TITLE')"
    />

    <div class="mt-4 max-w-2xl">
      <p v-if="!isMcpEnabled" class="text-sm text-muted-foreground">
        {{ t('MCP_SETTINGS.DISABLED_MESSAGE') }}
      </p>
      <template v-else>
        <McpPermissionsForm :initial-scopes="scopes" @save="handleSave" />
        <router-link
          :to="{ name: 'profile_settings_index' }"
          class="mt-6 inline-block text-sm font-medium text-primary hover:underline"
        >
          {{ t('MCP_SETTINGS.ACCESS_TOKEN_LINK') }}
        </router-link>
      </template>
    </div>
  </div>
</template>
