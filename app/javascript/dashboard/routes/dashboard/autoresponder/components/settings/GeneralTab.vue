<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelaySwitch, RelayInput } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';

const { t } = useI18n();

const globalAutomation = ref(true);
const defaultResponseType = ref('Reply in thread');
const defaultResponseTime = ref('No delay');
const lookbackWindow = ref('24 hours');
const assignTo = ref('Unassigned');
const autoApplyTag = ref('No tag selected');
const defaultLanguage = ref('English (US)');
const preventDuplicate = ref(true);
const ignoreBots = ref(true);

const responseTypeOptions = ['Reply in thread', 'Send as DM', 'Reply + DM'];
const responseTimeOptions = ['No delay', '1 minute', '5 minutes', '15 minutes'];
const lookbackOptions = ['1 hour', '24 hours', '7 days'];
const assignToOptions = ['Unassigned', 'Round robin', 'Least busy agent'];
const tagOptions = ['No tag selected', 'automated', 'needs-review', 'vip'];
const languageOptions = ['English (US)', 'Spanish', 'French'];

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
            <RelaySwitch v-model="globalAutomation" />
            <span
              class="text-xs font-medium"
              :class="
                globalAutomation ? 'text-primary' : 'text-muted-foreground'
              "
            >
              {{
                globalAutomation
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
              v-model="defaultResponseType"
              :options="responseTypeOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.RESPONSE_TIME')
            }}</span>
            <SettingsSelect
              v-model="defaultResponseTime"
              :options="responseTimeOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.LOOKBACK_WINDOW')
            }}</span>
            <SettingsSelect
              v-model="lookbackWindow"
              :options="lookbackOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.GENERAL.DEFAULT_LANGUAGE')
            }}</span>
            <SettingsSelect
              v-model="defaultLanguage"
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
            <RelaySwitch v-model="preventDuplicate" />
            <span class="text-[13.5px] font-medium text-foreground">
              {{
                t('AUTORESPONDER.SETTINGS.GENERAL.PREVENT_DUPLICATE_REPLIES')
              }}
            </span>
          </label>
          <label class="flex items-center gap-3 cursor-pointer">
            <RelaySwitch v-model="ignoreBots" />
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
            <SettingsSelect v-model="assignTo" :options="assignToOptions" />
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
            <SettingsSelect v-model="autoApplyTag" :options="tagOptions" />
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
