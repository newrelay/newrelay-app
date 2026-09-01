<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelaySwitch } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';

const { t } = useI18n();

const enableBusinessHours = ref(true);
const timeZone = ref('(GMT+05:30) Asia/Kolkata');
const outsideAction = ref('away_message');

const timeZoneOptions = [
  '(GMT+05:30) Asia/Kolkata',
  '(GMT+00:00) UTC',
  '(GMT-05:00) US Eastern',
  '(GMT-08:00) US Pacific',
];

const weeklySchedule = ref([
  {
    id: 'mon',
    label: 'Monday',
    active: true,
    start: '09:00 AM',
    end: '06:00 PM',
  },
  {
    id: 'tue',
    label: 'Tuesday',
    active: true,
    start: '09:00 AM',
    end: '06:00 PM',
  },
  {
    id: 'wed',
    label: 'Wednesday',
    active: true,
    start: '09:00 AM',
    end: '06:00 PM',
  },
  {
    id: 'thu',
    label: 'Thursday',
    active: true,
    start: '09:00 AM',
    end: '06:00 PM',
  },
  {
    id: 'fri',
    label: 'Friday',
    active: true,
    start: '09:00 AM',
    end: '06:00 PM',
  },
  {
    id: 'sat',
    label: 'Saturday',
    active: false,
    start: '09:00 AM',
    end: '06:00 PM',
  },
  {
    id: 'sun',
    label: 'Sunday',
    active: false,
    start: '09:00 AM',
    end: '06:00 PM',
  },
]);

const outsideOptions = computed(() => [
  {
    value: 'away_message',
    icon: 'i-lucide-message-square',
    title: t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.SEND_AWAY_MESSAGE'),
    desc: t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.SEND_AWAY_MESSAGE_DESC'),
  },
  {
    value: 'pause',
    icon: 'i-lucide-pause',
    title: t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.PAUSE_AUTOMATION'),
    desc: t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.PAUSE_AUTOMATION_DESC'),
  },
  {
    value: 'route',
    icon: 'i-lucide-users',
    title: t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.ROUTE_TO_TEAM'),
    desc: t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.ROUTE_TO_TEAM_DESC'),
  },
]);

const activeDaysCount = computed(
  () => weeklySchedule.value.filter(d => d.active).length
);
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.BUSINESS_HOURS')"
      >
        <template #header-action>
          <RelaySwitch v-model="enableBusinessHours" />
        </template>
        <p class="text-xs text-muted-foreground -mt-4 max-w-[420px]">
          {{ t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.BUSINESS_HOURS_DESC') }}
        </p>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.TIME_ZONE')"
      >
        <div class="flex flex-col gap-2 max-w-sm">
          <SettingsSelect v-model="timeZone" :options="timeZoneOptions" />
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.WEEKLY_SCHEDULE')"
      >
        <div class="flex flex-col gap-2">
          <div
            v-for="day in weeklySchedule"
            :key="day.id"
            class="flex items-center justify-between gap-4 py-2 border-b border-border/40 last:border-0"
          >
            <div class="flex items-center gap-3 w-32 shrink-0">
              <RelaySwitch v-model="day.active" />
              <span class="text-[13.5px] font-medium text-foreground">{{
                day.label
              }}</span>
            </div>
            <div
              v-if="day.active"
              class="flex items-center gap-2 text-[13px] text-muted-foreground"
            >
              <span class="text-foreground font-medium">{{ day.start }}</span>
              <span>{{ t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.TO') }}</span>
              <span class="text-foreground font-medium">{{ day.end }}</span>
            </div>
            <span v-else class="text-[13px] text-muted-foreground">{{
              t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.CLOSED')
            }}</span>
          </div>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.OUTSIDE_HOURS')"
      >
        <div class="flex flex-col gap-3">
          <div
            v-for="opt in outsideOptions"
            :key="opt.value"
            class="border rounded-xl p-4 cursor-pointer transition-colors flex items-start gap-3"
            :class="
              outsideAction === opt.value
                ? 'border-primary bg-primary/5 ring-1 ring-primary'
                : 'border-border hover:border-foreground/20'
            "
            @click="outsideAction = opt.value"
          >
            <div
              class="size-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0"
            >
              <span :class="opt.icon" class="size-4" />
            </div>
            <div class="flex-1">
              <div class="text-[13.5px] font-semibold text-foreground">
                {{ opt.title }}
              </div>
              <div class="text-xs text-muted-foreground mt-0.5">
                {{ opt.desc }}
              </div>
            </div>
            <span
              v-if="outsideAction === opt.value"
              class="i-lucide-check-circle-2 size-4 text-primary shrink-0 mt-1"
            />
          </div>
        </div>
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.ABOUT')"
        icon="i-lucide-info"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.ABOUT_DESC') }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.SCHEDULE_PREVIEW')"
        icon="i-lucide-calendar"
      >
        <p class="text-xs text-muted-foreground">
          {{
            t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.ACTIVE_DAYS', {
              count: activeDaysCount,
            })
          }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.SETTINGS_SUMMARY')"
        icon="i-lucide-list"
      >
        <div class="flex flex-col gap-2 text-xs">
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">{{
              t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.BUSINESS_HOURS')
            }}</span>
            <span class="font-medium text-foreground">{{
              enableBusinessHours ? 'ON' : 'OFF'
            }}</span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">{{
              t('AUTORESPONDER.SETTINGS.BUSINESS_HOURS.TIME_ZONE')
            }}</span>
            <span class="font-medium text-foreground truncate max-w-[180px]">{{
              timeZone
            }}</span>
          </div>
        </div>
      </SettingsSidebarCard>
    </div>
  </div>
</template>
