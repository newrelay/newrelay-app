<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import McpPermissionsForm from './McpPermissionsForm.vue';

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const { isCloudFeatureEnabled } = useAccount();

const isMcpEnabled = computed(() => isCloudFeatureEnabled('mcp_integration'));
const scopes = computed(() => currentUser.value.access_token_scopes || []);

const mcpConfig = computed(() =>
  JSON.stringify(
    {
      mcpServers: {
        newrelay: {
          type: 'http',
          url: `${window.location.origin}/mcp/messages`,
          headers: {
            Authorization: `Bearer ${currentUser.value.access_token}`,
          },
        },
      },
    },
    null,
    2
  )
);
const maskedMcpConfig = computed(() =>
  mcpConfig.value.replace(/"Bearer .*"/, '"Bearer ••••••••"')
);

const handleSave = async newScopes => {
  const success = await store.dispatch('updateAccessTokenScopes', {
    scopes: newScopes,
  });
  useAlert(
    success ? t('MCP_SETTINGS.SAVE_SUCCESS') : t('MCP_SETTINGS.SAVE_ERROR')
  );
};

const handleCopyConfig = async () => {
  await copyTextToClipboard(mcpConfig.value);
  useAlert(t('MCP_SETTINGS.CONNECT.COPY_SUCCESS'));
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
        <div class="mb-6 p-4 rounded-xl border border-border/80 bg-muted/40">
          <h3 class="text-[14px] font-semibold text-foreground">
            {{ t('MCP_SETTINGS.CONNECT.TITLE') }}
          </h3>
          <p class="text-[12.5px] text-muted-foreground mt-0.5 mb-3">
            {{ t('MCP_SETTINGS.CONNECT.SUBTITLE') }}
          </p>
          <pre
            class="text-[12px] font-mono bg-background border border-border/80 rounded-lg p-3 overflow-x-auto whitespace-pre-wrap break-all"
            >{{ maskedMcpConfig }}</pre
          >
          <RelayButton
            type="button"
            variant="outline"
            class="h-9 px-3.5 mt-3 bg-background shadow-sm border-border/80 text-foreground"
            @click="handleCopyConfig"
          >
            <Icon icon="i-lucide-copy" class="size-3.5" />
            {{ t('MCP_SETTINGS.CONNECT.COPY_BUTTON') }}
          </RelayButton>
          <p class="text-[12px] text-muted-foreground mt-3">
            {{ t('MCP_SETTINGS.CONNECT.SUPPORTED_CLIENTS') }}
          </p>
          <p class="text-[12px] text-muted-foreground mt-1.5">
            {{ t('MCP_SETTINGS.CONNECT.OAUTH_NOTE') }}
          </p>
        </div>

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
