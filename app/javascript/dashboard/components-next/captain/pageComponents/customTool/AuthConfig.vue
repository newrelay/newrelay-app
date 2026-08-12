<script setup>
import { watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';

const props = defineProps({
  authType: {
    type: String,
    required: true,
    validator: value => ['none', 'bearer', 'basic', 'api_key'].includes(value),
  },
});

const { t } = useI18n();

const authConfig = defineModel('authConfig', {
  type: Object,
  default: () => ({}),
});

watch(
  () => props.authType,
  () => {
    authConfig.value = {};
  }
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <div v-if="authType === 'bearer'" class="flex flex-col gap-2">
      <RelayLabel html-for="captain-tool-bearer-token">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.BEARER_TOKEN') }}
      </RelayLabel>
      <RelayInput
        id="captain-tool-bearer-token"
        v-model="authConfig.token"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.BEARER_TOKEN_PLACEHOLDER')
        "
      />
    </div>
    <template v-else-if="authType === 'basic'">
      <div class="flex flex-col gap-2">
        <RelayLabel html-for="captain-tool-basic-username">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.USERNAME') }}
        </RelayLabel>
        <RelayInput
          id="captain-tool-basic-username"
          v-model="authConfig.username"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.USERNAME_PLACEHOLDER')
          "
        />
      </div>
      <div class="flex flex-col gap-2">
        <RelayLabel html-for="captain-tool-basic-password">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.PASSWORD') }}
        </RelayLabel>
        <RelayInput
          id="captain-tool-basic-password"
          v-model="authConfig.password"
          type="password"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.PASSWORD_PLACEHOLDER')
          "
        />
      </div>
    </template>
    <template v-else-if="authType === 'api_key'">
      <div class="flex flex-col gap-2">
        <RelayLabel html-for="captain-tool-api-key">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_KEY') }}
        </RelayLabel>
        <RelayInput
          id="captain-tool-api-key"
          v-model="authConfig.name"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_KEY_PLACEHOLDER')
          "
        />
      </div>
      <div class="flex flex-col gap-2">
        <RelayLabel html-for="captain-tool-api-value">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_VALUE') }}
        </RelayLabel>
        <RelayInput
          id="captain-tool-api-value"
          v-model="authConfig.key"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_VALUE_PLACEHOLDER')
          "
        />
      </div>
    </template>
  </div>
</template>
