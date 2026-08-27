<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsLayout from '../SettingsLayout.vue';
import SamlSettings from './components/SamlSettings.vue';
import SamlPaywall from './components/SamlPaywall.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

import { usePolicy } from 'dashboard/composables/usePolicy';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import {
  generateTranslationPayload,
  generateLogActionKey,
} from 'dashboard/helper/auditlogHelper';

const { t } = useI18n();
const { shouldShow, shouldShowPaywall } = usePolicy();
const store = useStore();
const getters = useStoreGetters();

const allowedLoginMethods = computed(
  () => window.newrelayConfig.allowedLoginMethods || ['email']
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

const records = computed(() => getters['auditlogs/getAuditLogs'].value || []);
const uiFlags = computed(() => getters['auditlogs/getUIFlags'].value || {});
const agentList = computed(() => getters['agents/getAgents'].value || []);

const generateLogText = auditLogItem => {
  try {
    const payload = generateTranslationPayload(auditLogItem, agentList.value);
    const translationKey = generateLogActionKey(auditLogItem);
    const joinIfArray = value =>
      Array.isArray(value) ? value.join(', ') : value;
    const mergedPayload = {
      ...payload,
      attributes: joinIfArray(payload.attributes),
      values: joinIfArray(payload.values),
    };
    return t(translationKey, mergedPayload);
  } catch (e) {
    return auditLogItem?.auditable_type || 'Updated configuration';
  }
};

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('auditlogs/fetch', { page: 1 });
});
</script>

<template>
  <SettingsLayout>
    <template #body>
      <div class="mt-2 space-y-8">
        <div>
          <h2 class="capitalize text-base font-medium text-foreground">
            {{ t('SECURITY_SETTINGS.TITLE') }}
          </h2>
          <p class="mt-0.5 text-[13px] text-muted-foreground">
            {{ t('SECURITY_SETTINGS.DESCRIPTION') }}
          </p>
        </div>

        <SamlPaywall v-if="showPaywall" />
        <SamlSettings v-else-if="shouldShowSaml" />

        <!-- Audit Logs Section -->
        <div class="pt-6 border-t border-border/40 space-y-4">
          <div>
            <h3 class="text-base font-semibold text-foreground">Audit Logs</h3>
            <p class="text-sm text-muted-foreground mt-1">
              Audit Logs maintain a record of activities in your account,
              allowing you to track and audit your account, team, or services.
            </p>
          </div>

          <div
            class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
          >
            <div
              v-if="!records.length"
              class="flex flex-col items-center justify-center bg-muted/10 py-14"
            >
              <div
                class="mb-4 flex size-14 items-center justify-center rounded-full border border-border/50 bg-muted/50 shadow-xs"
              >
                <Icon
                  icon="i-lucide-file-check"
                  class="size-7 text-muted-foreground/60"
                />
              </div>
              <h4 class="capitalize text-base font-medium text-foreground mb-1">
                {{ $t('AUDIT_LOGS.LIST.EMPTY_TITLE') }}
              </h4>
              <p
                class="max-w-sm text-center text-[13.5px] text-muted-foreground"
              >
                {{ $t('AUDIT_LOGS.LIST.404') }}
              </p>
            </div>

            <div v-else class="overflow-x-auto">
              <table class="w-full border-collapse text-left">
                <thead>
                  <tr class="border-b border-border/40">
                    <th
                      class="bg-transparent px-6 py-4 text-sm font-medium text-foreground"
                    >
                      {{ $t('AUDIT_LOGS.LIST.TABLE_HEADER.ACTIVITY') }}
                    </th>
                    <th
                      class="w-48 bg-transparent px-6 py-4 text-sm font-medium text-foreground"
                    >
                      {{ $t('AUDIT_LOGS.LIST.TABLE_HEADER.TIME') }}
                    </th>
                    <th
                      class="w-48 bg-transparent px-6 py-4 text-sm font-medium text-foreground"
                    >
                      {{ $t('AUDIT_LOGS.LIST.TABLE_HEADER.IP_ADDRESS') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border/40">
                  <tr
                    v-for="auditLogItem in records"
                    :key="auditLogItem.id"
                    class="transition-colors hover:bg-muted/10"
                  >
                    <td class="px-6 py-4 text-sm text-foreground">
                      {{ generateLogText(auditLogItem) }}
                    </td>
                    <td
                      class="whitespace-nowrap px-6 py-4 text-sm text-muted-foreground"
                    >
                      {{
                        messageTimestamp(
                          auditLogItem.created_at,
                          'MMM dd, yyyy hh:mm a'
                        )
                      }}
                    </td>
                    <td
                      class="whitespace-nowrap px-6 py-4 text-sm text-muted-foreground"
                    >
                      {{ auditLogItem.remote_address || '—' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
