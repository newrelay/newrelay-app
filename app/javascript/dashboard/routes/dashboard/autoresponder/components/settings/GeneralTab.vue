<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelaySwitch, RelayInput } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';
import { useAutoresponderSettings } from '../../composables/useAutoresponderSettings';
import { useAutoresponderAccount } from '../../composables/useAutoresponderAccount';

const UNASSIGNED = 'Unassigned';
const LEGACY_ASSIGN_TO = new Set(['Round robin', 'Least busy agent']);

const { t } = useI18n();
const { settings } = useAutoresponderSettings();
const { teamMembers } = useAutoresponderAccount();

const responseTypeOptions = ['Reply in thread', 'Send as DM', 'Reply + DM'];
const responseTimeOptions = ['No delay', '1 minute', '5 minutes', '15 minutes'];
const lookbackOptions = ['1 hour', '24 hours', '7 days'];
const tagOptions = ['No tag selected', 'automated', 'needs-review', 'vip'];
const languageOptions = ['English (US)', 'Spanish', 'French'];

const assignToOptions = computed(() => [
  {
    value: UNASSIGNED,
    label: t('AUTORESPONDER.SETTINGS.GENERAL.ASSIGN_TO_UNASSIGNED'),
  },
  ...[...teamMembers.value]
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(member => ({
      value: `agent:${member.id}`,
      label: member.name,
      searchText: member.email || '',
    })),
]);

const assignTo = computed({
  get() {
    const value = settings.value.general.assignTo;
    if (!value || LEGACY_ASSIGN_TO.has(value)) return UNASSIGNED;
    if (assignToOptions.value.some(option => option.value === value)) {
      return value;
    }
    const member = teamMembers.value.find(item => item.name === value);
    return member ? `agent:${member.id}` : UNASSIGNED;
  },
  set(value) {
    settings.value.general.assignTo = value;
  },
});

const quickTips = computed(() => [
  t('AUTORESPONDER.SETTINGS.GENERAL.TIP_1'),
  t('AUTORESPONDER.SETTINGS.GENERAL.TIP_2'),
  t('AUTORESPONDER.SETTINGS.GENERAL.TIP_3'),
]);
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.GLOBAL_AUTOMATION')"
      >
        <template #header-action>
          <div class="flex flex-col items-end gap-2">
            <RelaySwitch v-model="settings.general.globalAutomation" />
            <span
              class="text-xs font-medium"
              :class="
                settings.general.globalAutomation
                  ? 'text-primary'
                  : 'text-muted-foreground'
              "
            >
              {{
                settings.general.globalAutomation
                  ? t('AUTORESPONDER.SETTINGS.GENERAL.AUTOMATIONS_ACTIVE')
                  : t('AUTORESPONDER.SETTINGS.GENERAL.AUTOMATIONS_PAUSED')
              }}
            </span>
          </div>
        </template>
        <p class="text-xs text-muted-foreground max-w-[400px] -mt-4">
          {{ t('AUTORESPONDER.SETTINGS.GENERAL.GLOBAL_AUTOMATION_DESC') }}
        </p>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.DEFAULT_RESPONSE_SETTINGS')"
        :description="
          t('AUTORESPONDER.SETTINGS.GENERAL.DEFAULT_RESPONSE_SETTINGS_DESC')
        "
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.RESPONSE_TYPE')
            }}</span>
            <SettingsSelect
              v-model="settings.general.defaultResponseType"
              :options="responseTypeOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.RESPONSE_TIME')
            }}</span>
            <SettingsSelect
              v-model="settings.general.defaultResponseTime"
              :options="responseTimeOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.LOOKBACK_WINDOW')
            }}</span>
            <SettingsSelect
              v-model="settings.general.lookbackWindow"
              :options="lookbackOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.DEFAULT_LANGUAGE')
            }}</span>
            <SettingsSelect
              v-model="settings.general.defaultLanguage"
              :options="languageOptions"
            />
          </div>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.DUPLICATE_PREVENTION')"
        :description="
          t('AUTORESPONDER.SETTINGS.GENERAL.DUPLICATE_PREVENTION_DESC')
        "
      >
        <div class="flex flex-col gap-4">
          <label class="flex items-center gap-3 cursor-pointer">
            <RelaySwitch v-model="settings.general.preventDuplicate" />
            <span class="text-[13.5px] font-medium text-foreground">
              {{
                t('AUTORESPONDER.SETTINGS.GENERAL.PREVENT_DUPLICATE_REPLIES')
              }}
            </span>
          </label>
          <label class="flex items-center gap-3 cursor-pointer">
            <RelaySwitch v-model="settings.general.ignoreBots" />
            <span class="text-[13.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.SETTINGS.GENERAL.IGNORE_BOT_ACCOUNTS') }}
            </span>
          </label>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.AUTO_ASSIGNMENT')"
        :description="t('AUTORESPONDER.SETTINGS.GENERAL.AUTO_ASSIGNMENT_DESC')"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.ASSIGN_TO')
            }}</span>
            <SettingsSelect
              v-model="assignTo"
              :options="assignToOptions"
              searchable
              :search-placeholder="
                t('AUTORESPONDER.SETTINGS.GENERAL.ASSIGN_TO_SEARCH')
              "
            />
          </div>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.TAGS_LABELS')"
        :description="t('AUTORESPONDER.SETTINGS.GENERAL.TAGS_LABELS_DESC')"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.AUTO_APPLY_TAG')
            }}</span>
            <SettingsSelect
              v-model="settings.general.autoApplyTag"
              :options="tagOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.CUSTOM_TAG')
            }}</span>
            <RelayInput
              :placeholder="
                t('AUTORESPONDER.SETTINGS.GENERAL.CUSTOM_TAG_PLACEHOLDER')
              "
            />
          </div>
        </div>
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.AUTOMATION_SAFETY')"
        icon="i-lucide-shield"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.GENERAL.AUTOMATION_SAFETY_DESC') }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.GENERAL.QUICK_TIPS')"
        icon="i-lucide-sparkles"
      >
        <ul class="flex flex-col gap-2.5">
          <li
            v-for="tip in quickTips"
            :key="tip"
            class="text-xs text-muted-foreground flex items-start gap-2"
          >
            <span
              class="i-lucide-check-circle-2 size-3.5 text-primary shrink-0 mt-0.5"
            />
            {{ tip }}
          </li>
        </ul>
      </SettingsSidebarCard>
    </div>
  </div>
</template>
