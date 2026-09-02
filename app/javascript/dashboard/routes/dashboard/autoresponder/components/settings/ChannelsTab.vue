<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { RelayButton } from 'dashboard/components-next/relay';
import { INBOX_TYPES, getInboxIconByType } from 'dashboard/helper/inbox';
import SettingsCard from './SettingsCard.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute } = useAccount();

const AUTORESPONDER_CHANNELS = [
  { type: INBOX_TYPES.INSTAGRAM, name: 'Instagram', descKey: 'INSTAGRAM_DESC' },
  { type: INBOX_TYPES.FB, name: 'Facebook', descKey: 'FACEBOOK_DESC' },
  {
    type: INBOX_TYPES.WHATSAPP,
    name: 'WhatsApp Business',
    descKey: 'WHATSAPP_DESC',
  },
];

onMounted(() => {
  store.dispatch('inboxes/get');
});

const allInboxes = useMapGetter('inboxes/getInboxes');

const connectedChannels = computed(() =>
  AUTORESPONDER_CHANNELS.flatMap(({ type, name, descKey }) =>
    allInboxes.value
      .filter(inbox => inbox.channel_type === type)
      .map(inbox => ({
        id: inbox.id,
        type,
        name,
        sub: t(`AUTORESPONDER.SETTINGS.CHANNELS.${descKey}`),
        account: inbox.name,
        needsReconnect: !!inbox.reauthorization_required,
        icon: getInboxIconByType(type),
      }))
  )
);

const availableChannels = computed(() => {
  const connectedTypes = new Set(connectedChannels.value.map(ch => ch.type));
  return AUTORESPONDER_CHANNELS.filter(
    ({ type }) => !connectedTypes.has(type)
  ).map(({ type, name, descKey }) => ({
    type,
    name,
    desc: t(`AUTORESPONDER.SETTINGS.CHANNELS.${descKey}`),
    icon: getInboxIconByType(type),
  }));
});
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECTED_CHANNELS')"
      >
        <div
          v-if="!connectedChannels.length"
          class="text-xs text-muted-foreground py-3"
        >
          {{ t('AUTORESPONDER.SETTINGS.CHANNELS.NO_CHANNELS_CONNECTED') }}
        </div>
        <div v-else class="flex flex-col divide-y divide-border/40 -mt-2">
          <div
            v-for="ch in connectedChannels"
            :key="ch.id"
            class="flex items-center justify-between gap-4 py-3"
          >
            <div class="flex items-center gap-3 min-w-0">
              <div
                class="size-10 rounded-lg border border-border bg-card shadow-xs flex items-center justify-center shrink-0"
              >
                <span :class="ch.icon" class="size-5 text-foreground" />
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
              <span
                class="text-[11px] font-medium px-2 py-0.5 rounded-full hidden sm:inline-block"
                :class="
                  ch.needsReconnect
                    ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400'
                    : 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                "
              >
                {{
                  ch.needsReconnect
                    ? t('AUTORESPONDER.SETTINGS.CHANNELS.NEEDS_RECONNECT')
                    : t('AUTORESPONDER.SETTINGS.CHANNELS.CONNECTED')
                }}
              </span>
              <RelayButton
                as="router-link"
                :to="
                  accountScopedRoute('settings_inbox_show', { inboxId: ch.id })
                "
                variant="outline"
                size="sm"
                class="h-8 text-xs"
              >
                {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MANAGE') }}
              </RelayButton>
            </div>
          </div>
        </div>
      </SettingsCard>

      <SettingsCard
        v-if="availableChannels.length"
        :title="t('AUTORESPONDER.SETTINGS.CHANNELS.AVAILABLE_CHANNELS')"
      >
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div
            v-for="ch in availableChannels"
            :key="ch.type"
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
              as="router-link"
              :to="accountScopedRoute('settings_inbox_new')"
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
        v-if="connectedChannels.length"
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
