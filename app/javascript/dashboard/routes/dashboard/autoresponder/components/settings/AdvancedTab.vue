<script setup>
import { useI18n } from 'vue-i18n';
import { RelayInput, RelayButton } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsToggleRow from './SettingsToggleRow.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';
import { useAutoresponderSettings } from '../../composables/useAutoresponderSettings';

const { t } = useI18n();
const { settings } = useAutoresponderSettings();

const processingModeOptions = [
  'Real-time (Recommended)',
  'Batched (every 5 min)',
  'Manual review',
];
const concurrentOptions = ['1', '5', '10', '20'];
const retryIntervalOptions = ['1 minute', '5 minutes', '15 minutes'];
const retentionOptions = ['3 months', '6 months', '12 months', 'Forever'];
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.ADVANCED.AUTOMATION_ENGINE')"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.ADVANCED.PROCESSING_MODE')
            }}</span>
            <SettingsSelect
              v-model="settings.advanced.processingMode"
              :options="processingModeOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.ADVANCED.CONCURRENT_AUTOMATIONS')
            }}</span>
            <SettingsSelect
              v-model="settings.advanced.concurrentAutomations"
              :options="concurrentOptions"
            />
          </div>
        </div>

        <SettingsToggleRow
          v-model="settings.advanced.retryFailedActions"
          :title="t('AUTORESPONDER.SETTINGS.ADVANCED.RETRY_FAILED')"
          :description="t('AUTORESPONDER.SETTINGS.ADVANCED.RETRY_FAILED_DESC')"
        />
        <div
          v-if="settings.advanced.retryFailedActions"
          class="grid grid-cols-2 gap-3"
        >
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.ADVANCED.MAX_RETRIES')
            }}</label>
            <RelayInput
              v-model="settings.advanced.maxRetries"
              type="number"
              class-name="h-9"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.ADVANCED.RETRY_INTERVAL')
            }}</label>
            <SettingsSelect
              v-model="settings.advanced.retryInterval"
              :options="retryIntervalOptions"
            />
          </div>
        </div>
      </SettingsCard>

      <SettingsCard :title="t('AUTORESPONDER.SETTINGS.ADVANCED.DATA_STORAGE')">
        <div class="flex flex-col gap-2 max-w-sm">
          <span class="text-[13.5px] font-medium text-foreground">{{
            t('AUTORESPONDER.SETTINGS.ADVANCED.DATA_RETENTION')
          }}</span>
          <SettingsSelect
            v-model="settings.advanced.dataRetention"
            :options="retentionOptions"
          />
        </div>
        <SettingsToggleRow
          v-model="settings.advanced.storeMessageHistory"
          :title="t('AUTORESPONDER.SETTINGS.ADVANCED.STORE_HISTORY')"
          :description="t('AUTORESPONDER.SETTINGS.ADVANCED.STORE_HISTORY_DESC')"
        />
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.ADVANCED.DEVELOPER_INTEGRATIONS')"
      >
        <SettingsToggleRow
          v-model="settings.advanced.apiAccess"
          :title="t('AUTORESPONDER.SETTINGS.ADVANCED.API_ACCESS')"
          :description="t('AUTORESPONDER.SETTINGS.ADVANCED.API_ACCESS_DESC')"
        />
        <RelayButton variant="outline" class="w-fit gap-2 text-[13px]">
          <span class="i-lucide-code-2 size-4" />
          {{ t('AUTORESPONDER.SETTINGS.ADVANCED.VIEW_API_DOCS') }}
        </RelayButton>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.ADVANCED.SYSTEM_MAINTENANCE')"
      >
        <SettingsToggleRow
          v-model="settings.advanced.maintenanceMode"
          :title="t('AUTORESPONDER.SETTINGS.ADVANCED.MAINTENANCE_MODE')"
          :description="
            t('AUTORESPONDER.SETTINGS.ADVANCED.MAINTENANCE_MODE_DESC')
          "
        />
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.ADVANCED.ABOUT')"
        icon="i-lucide-info"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.ADVANCED.ABOUT_DESC') }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.ADVANCED.SYSTEM_HEALTH')"
        icon="i-lucide-activity"
      >
        <div class="flex flex-col gap-2.5">
          <div
            v-for="item in settings.advanced.systemHealth"
            :key="item.label"
            class="flex items-center justify-between text-xs"
          >
            <span class="text-muted-foreground">{{ item.label }}</span>
            <span class="font-medium text-emerald-600 dark:text-emerald-400">{{
              item.status
            }}</span>
          </div>
        </div>
      </SettingsSidebarCard>
    </div>
  </div>
</template>
