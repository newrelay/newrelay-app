<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';
import { CHANNEL_LOGO_URLS } from '../../constants/channels';

const { t } = useI18n();

const connectedChannels = ref([
  {
    id: 'ig',
    name: 'Instagram',
    sub: 'Direct Messages & Comments',
    account: 'newrelay.official',
    status: 'Connected',
    sync: '2 min ago',
    logo: CHANNEL_LOGO_URLS.Instagram,
  },
  {
    id: 'fb',
    name: 'Facebook',
    sub: 'Messages & Comments',
    account: 'New Relay',
    status: 'Connected',
    sync: '5 min ago',
    logo: CHANNEL_LOGO_URLS.Facebook,
  },
  {
    id: 'wa',
    name: 'WhatsApp Business',
    sub: 'Messages',
    account: '+91 98765 43210',
    status: 'Connected',
    sync: '1 min ago',
    logo: CHANNEL_LOGO_URLS.WhatsApp,
  },
]);

const availableChannels = computed(() => [
  {
    id: 'tg',
    name: 'Telegram',
    desc: t('AUTORESPONDER.SETTINGS.CHANNELS.TELEGRAM_DESC'),
    icon: 'i-lucide-send',
  },
  {
    id: 'sms',
    name: 'SMS',
    desc: t('AUTORESPONDER.SETTINGS.CHANNELS.SMS_DESC'),
    icon: 'i-lucide-smartphone',
  },
  {
    id: 'slack',
    name: 'Slack',
    desc: t('AUTORESPONDER.SETTINGS.CHANNELS.SLACK_DESC'),
    icon: 'i-lucide-hash',
  },
]);
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECTED_CHANNELS')"
      >
        <div class="flex flex-col divide-y divide-border/40 -mt-2">
          <div
            v-for="ch in connectedChannels"
            :key="ch.id"
            class="flex items-center justify-between gap-4 py-3"
          >
            <div class="flex items-center gap-3 min-w-0">
              <div
                class="size-10 rounded-lg border border-border bg-card shadow-xs flex items-center justify-center shrink-0"
              >
                <img :src="ch.logo" class="size-5 opacity-90" />
              </div>
              <div class="min-w-0">
                <div class="text-[13.5px] font-semibold text-foreground">
                  {{ ch.name }}
                </div>
                <div class="text-xs text-muted-foreground truncate">
                  {{ ch.sub }} &bull; {{ ch.account }}
                </div>
              </div>
            </div>
            <div class="flex items-center gap-4 shrink-0">
              <div class="text-right hidden sm:block">
                <span
                  class="text-[11px] font-medium px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                >
                  {{ t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECTED') }}
                </span>
                <div class="text-[11px] text-muted-foreground mt-1">
                  {{
                    t('AUTORESPONDER.SETTINGS.CHANNELS.LAST_SYNCED', {
                      time: ch.sync,
                    })
                  }}
                </div>
              </div>
              <RelayButton variant="outline" size="sm" class="h-8 text-xs">
                {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MANAGE') }}
              </RelayButton>
            </div>
          </div>
        </div>
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.CHANNELS.AVAILABLE_CHANNELS')"
      >
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div
            v-for="ch in availableChannels"
            :key="ch.id"
            class="border border-border rounded-xl p-4 flex items-start gap-3 hover:border-primary/40 transition-colors"
          >
            <div
              class="size-9 rounded-lg bg-muted flex items-center justify-center shrink-0"
            >
              <span :class="ch.icon" class="size-4 text-muted-foreground" />
            </div>
            <div class="flex-1">
              <div class="text-[13.5px] font-semibold text-foreground">
                {{ ch.name }}
              </div>
              <div class="text-xs text-muted-foreground mt-0.5">
                {{ ch.desc }}
              </div>
            </div>
            <RelayButton
              variant="outline"
              size="sm"
              class="h-7 text-xs shrink-0"
            >
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECT') }}
            </RelayButton>
          </div>
        </div>
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.CHANNELS.ABOUT')"
        icon="i-lucide-info"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.CHANNELS.ABOUT_DESC') }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.CHANNELS.CHANNEL_USAGE')"
        icon="i-lucide-bar-chart"
      >
        <div class="flex flex-col gap-2 text-xs">
          <div
            v-for="ch in connectedChannels"
            :key="ch.id"
            class="flex items-center justify-between"
          >
            <span class="text-muted-foreground">{{ ch.name }}</span>
            <span class="font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.CHANNELS.ACTIVE')
            }}</span>
          </div>
        </div>
      </SettingsSidebarCard>
    </div>
  </div>
</template>
