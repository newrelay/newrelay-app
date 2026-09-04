<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';
import Avatar from 'next/avatar/Avatar.vue';
import { getInboxIconByType, INBOX_TYPES } from 'dashboard/helper/inbox';
import { AUTORESPONDER_CHANNELS } from '../../constants/channels';
import SettingsCard from './SettingsCard.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountId, accountScopedRoute } = useAccount();

onMounted(() => {
  store.dispatch('inboxes/get');
});

const allInboxes = useMapGetter('inboxes/getInboxes');
const isMock = computed(() => !!window.newrelayConfig?.commentAutomationMock);

const isConnectOpen = ref(false);
const connectUrl = ref('https://www.instagram.com/p/mock-summer-sale/');
const connectName = ref('Instagram Shop');
const connectSaving = ref(false);
const connectError = ref('');

const canConnect = computed(
  () =>
    connectUrl.value.trim() && connectName.value.trim() && !connectSaving.value
);

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
        avatar: inbox.avatar_url,
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

function connectChannel(channel) {
  if (isMock.value && channel.type === INBOX_TYPES.INSTAGRAM) {
    connectError.value = '';
    isConnectOpen.value = true;
    return;
  }
  router.push(accountScopedRoute('settings_inbox_new'));
}

async function submitMockConnect() {
  if (!canConnect.value) return;
  connectSaving.value = true;
  connectError.value = '';
  try {
    await window.axios.post(
      `/api/v1/accounts/${accountId.value}/comment_automation/mock_connection`,
      { url: connectUrl.value.trim(), name: connectName.value.trim() }
    );
    isConnectOpen.value = false;
    await Promise.all([
      store.dispatch('inboxes/get'),
      store.dispatch('commentAutomationCampaigns/get'),
      store.dispatch('commentAutomationMessageLogs/get'),
      store.dispatch('commentAutomationTemplates/get'),
    ]);
    useAlert(t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_SUCCESS'));
  } catch (error) {
    connectError.value =
      error.response?.data?.error ||
      t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_TITLE');
  } finally {
    connectSaving.value = false;
  }
}
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
                class="size-10 rounded-lg border border-border bg-card shadow-xs flex items-center justify-center shrink-0 overflow-hidden"
              >
                <Avatar
                  v-if="ch.avatar"
                  :src="ch.avatar"
                  :name="ch.account"
                  :size="40"
                />
                <span v-else :class="ch.icon" class="size-5 text-foreground" />
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
              variant="outline"
              size="sm"
              class="h-7 text-xs shrink-0"
              @click="connectChannel(ch)"
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

  <Teleport to="body">
    <div
      v-if="isConnectOpen"
      :class="RELAY_DIALOG_OVERLAY_CLASS"
      class="flex items-center justify-center p-4"
      @click.self="isConnectOpen = false"
    >
      <div
        class="bg-background w-full max-w-[480px] rounded-2xl shadow-xl border border-border/50 overflow-hidden"
      >
        <div
          class="flex items-start justify-between p-6 border-b border-border/80"
        >
          <div>
            <h2 class="text-[18px] font-[600] text-foreground">
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_TITLE') }}
            </h2>
            <p class="text-[14px] font-normal text-muted-foreground mt-1">
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_DESC') }}
            </p>
          </div>
          <button
            type="button"
            class="p-1 text-muted-foreground hover:bg-muted rounded-full"
            @click="isConnectOpen = false"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </div>
        <div class="p-6 flex flex-col gap-4">
          <div class="flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_URL') }}
            </RelayLabel>
            <RelayInput
              v-model="connectUrl"
              :placeholder="
                t(
                  'AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_URL_PLACEHOLDER'
                )
              "
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_NAME') }}
            </RelayLabel>
            <RelayInput
              v-model="connectName"
              :placeholder="
                t(
                  'AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_NAME_PLACEHOLDER'
                )
              "
            />
          </div>
          <p v-if="connectError" class="text-[13px] text-destructive">
            {{ connectError }}
          </p>
          <div class="flex justify-end gap-2 pt-2">
            <RelayButton
              variant="outline"
              class="border border-border hover:border-transparent"
              @click="isConnectOpen = false"
            >
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_CANCEL') }}
            </RelayButton>
            <RelayButton :disabled="!canConnect" @click="submitMockConnect">
              {{
                connectSaving
                  ? t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECTING')
                  : t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_SUBMIT')
              }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
