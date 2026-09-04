<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayCheckbox } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsToggleRow from './SettingsToggleRow.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';
import { useAutoresponderSettings } from '../../composables/useAutoresponderSettings';

const { t } = useI18n();
const { settings } = useAutoresponderSettings();

const timeOptions = [
  '06:00 AM',
  '07:00 AM',
  '08:00 AM',
  '09:00 AM',
  '10:00 PM',
  '11:00 PM',
];

const notificationChannels = computed(() => [
  {
    icon: 'i-lucide-mail',
    name: t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.EMAIL'),
    connected: true,
  },
  {
    icon: 'i-lucide-bell',
    name: t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.IN_APP'),
    connected: true,
  },
  {
    icon: 'i-lucide-hash',
    name: t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.SLACK'),
    connected: false,
  },
]);
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.PREFERENCES')"
      >
        <div class="overflow-x-auto -mt-2">
          <table class="w-full text-left border-collapse min-w-[480px]">
            <thead>
              <tr class="border-b border-border">
                <th
                  class="py-2 pr-3 text-[12px] font-medium text-muted-foreground"
                >
                  {{ t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.TYPE') }}
                </th>
                <th
                  class="py-2 px-3 text-center text-[12px] font-medium text-muted-foreground"
                >
                  {{ t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.EMAIL') }}
                </th>
                <th
                  class="py-2 px-3 text-center text-[12px] font-medium text-muted-foreground"
                >
                  {{ t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.IN_APP') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border/40">
              <tr
                v-for="pref in settings.notifications.preferences"
                :key="pref.id"
              >
                <td class="py-3 pr-3">
                  <div class="text-[13.5px] font-medium text-foreground">
                    {{ pref.name }}
                  </div>
                  <div class="text-xs text-muted-foreground mt-0.5">
                    {{ pref.desc }}
                  </div>
                </td>
                <td class="py-3 px-3 text-center">
                  <RelayCheckbox v-model="pref.email" />
                </td>
                <td class="py-3 px-3 text-center">
                  <RelayCheckbox v-model="pref.inapp" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.QUIET_HOURS')"
      >
        <SettingsToggleRow
          v-model="settings.notifications.enableQuietHours"
          :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.ENABLE_QUIET_HOURS')"
          :description="
            t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.ENABLE_QUIET_HOURS_DESC')
          "
        />
        <div
          v-if="settings.notifications.enableQuietHours"
          class="grid grid-cols-2 gap-3"
        >
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.FROM')
            }}</label>
            <SettingsSelect
              v-model="settings.notifications.quietFrom"
              :options="timeOptions"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.TO')
            }}</label>
            <SettingsSelect
              v-model="settings.notifications.quietTo"
              :options="timeOptions"
            />
          </div>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.EMAIL_DIGEST')"
      >
        <SettingsToggleRow
          v-model="settings.notifications.enableDailyDigest"
          :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.DAILY_DIGEST')"
          :description="
            t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.DAILY_DIGEST_DESC')
          "
        />
        <div
          v-if="settings.notifications.enableDailyDigest"
          class="flex flex-col gap-1.5 max-w-[200px]"
        >
          <label class="text-xs font-medium text-foreground">{{
            t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.DIGEST_TIME')
          }}</label>
          <SettingsSelect
            v-model="settings.notifications.digestTime"
            :options="timeOptions"
          />
        </div>
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.ABOUT')"
        icon="i-lucide-info"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.ABOUT_DESC') }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.NOTIFICATIONS.CHANNELS')"
        icon="i-lucide-radio"
      >
        <div class="flex flex-col gap-2.5">
          <div
            v-for="ch in notificationChannels"
            :key="ch.name"
            class="flex items-center justify-between text-xs"
          >
            <span class="flex items-center gap-2 text-foreground">
              <span :class="ch.icon" class="size-3.5 text-muted-foreground" />
              {{ ch.name }}
            </span>
            <span
              class="text-[11px] font-medium px-2 py-0.5 rounded-full"
              :class="
                ch.connected
                  ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                  : 'bg-muted text-muted-foreground'
              "
            >
              {{
                ch.connected
                  ? t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECTED')
                  : t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECT')
              }}
            </span>
          </div>
        </div>
      </SettingsSidebarCard>
    </div>
  </div>
</template>
