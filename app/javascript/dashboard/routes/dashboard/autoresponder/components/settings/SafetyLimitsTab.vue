<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsToggleRow from './SettingsToggleRow.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';
import { useAutoresponderSettings } from '../../composables/useAutoresponderSettings';

const { t } = useI18n();
const { settings } = useAutoresponderSettings();

const maxResponsesOptions = ['1 per person', '3 per person', 'Unlimited'];
const cooldownOptions = ['1 hour', '24 hours', '7 days'];
const dailyLimitOptions = ['0', '100', '500', '1000'];

const whySafetyMatters = computed(() =>
  t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.WHY_MATTERS_DESC')
);
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.AUTOMATION_SAFETY')"
      >
        <SettingsToggleRow
          v-model="settings.safety.safeMode"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.SAFE_MODE')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.SAFE_MODE_DESC')
          "
        />
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.AUTOMATION_LIMITS')"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.MAX_RESPONSES')
            }}</span>
            <SettingsSelect
              v-model="settings.safety.maxResponses"
              :options="maxResponsesOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.COOLDOWN_PERIOD')
            }}</span>
            <SettingsSelect
              v-model="settings.safety.cooldownPeriod"
              :options="cooldownOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.DAILY_LIMIT')
            }}</span>
            <SettingsSelect
              v-model="settings.safety.dailyLimit"
              :options="dailyLimitOptions"
            />
          </div>
        </div>
        <SettingsToggleRow
          v-model="settings.safety.respectLimits"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.RESPECT_LIMITS')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.RESPECT_LIMITS_DESC')
          "
        />
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.DUPLICATE_PREVENTION')"
      >
        <SettingsToggleRow
          v-model="settings.safety.preventDuplicatesSafe"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.PREVENT_DUPLICATES')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.PREVENT_DUPLICATES_DESC')
          "
        />
        <SettingsToggleRow
          v-model="settings.safety.checkSimilar"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.CHECK_SIMILAR')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.CHECK_SIMILAR_DESC')
          "
        />
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.PLATFORM_RESTRICTIONS')"
      >
        <SettingsToggleRow
          v-model="settings.safety.allowAllChannels"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.ALLOW_ALL_CHANNELS')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.ALLOW_ALL_CHANNELS_DESC')
          "
        />
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.SPAM_PROTECTION')"
      >
        <SettingsToggleRow
          v-model="settings.safety.keywordFiltering"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.KEYWORD_FILTERING')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.KEYWORD_FILTERING_DESC')
          "
        />
        <SettingsToggleRow
          v-model="settings.safety.autoFlag"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.AUTO_FLAG')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.AUTO_FLAG_DESC')
          "
        />
        <SettingsToggleRow
          v-model="settings.safety.blockUnknown"
          :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.BLOCK_UNKNOWN')"
          :description="
            t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.BLOCK_UNKNOWN_DESC')
          "
        />
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.WHY_MATTERS')"
        icon="i-lucide-shield"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ whySafetyMatters }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.RATE_LIMITS')"
        icon="i-lucide-gauge"
      >
        <div class="flex flex-col gap-2.5">
          <div
            v-for="rl in settings.safety.rateLimits"
            :key="rl.platform"
            class="flex items-center justify-between text-xs"
          >
            <span class="text-muted-foreground">{{ rl.platform }}</span>
            <span class="font-medium text-foreground">{{ rl.limit }}</span>
          </div>
        </div>
      </SettingsSidebarCard>

      <div
        class="bg-amber-500/10 border border-amber-500/20 rounded-xl p-4 flex gap-3"
      >
        <span
          class="i-lucide-alert-triangle size-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5"
        />
        <p class="text-xs text-amber-700 dark:text-amber-300 leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.SAFETY_LIMITS.IMPORTANT_ALERT') }}
        </p>
      </div>
    </div>
  </div>
</template>
