<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayInput } from 'dashboard/components-next/relay';
import SettingsCard from './SettingsCard.vue';
import SettingsSelect from './SettingsSelect.vue';
import SettingsToggleRow from './SettingsToggleRow.vue';
import SettingsSidebarCard from './SettingsSidebarCard.vue';
import { useAutoresponderSettings } from '../../composables/useAutoresponderSettings';

const { t } = useI18n();
const { settings } = useAutoresponderSettings();

const replyTypeOptions = ['Reply in thread', 'Send as DM', 'Reply + DM'];
const delayOptions = ['No delay', '1 minute', '5 minutes', '15 minutes'];
const signatureOptions = [
  'No signature',
  'Sent via Relay AI',
  'Custom signature',
];

const bestPractices = computed(() => [
  t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.PRACTICE_1'),
  t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.PRACTICE_2'),
  t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.PRACTICE_3'),
]);
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 pb-16">
    <div class="flex flex-col gap-6">
      <SettingsCard
        :title="
          t(
            'AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.DEFAULT_RESPONSE_SETTINGS'
          )
        "
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.REPLY_TYPE')
            }}</span>
            <SettingsSelect
              v-model="settings.behavior.replyType"
              :options="replyTypeOptions"
            />
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.RESPONSE_DELAY')
            }}</span>
            <SettingsSelect
              v-model="settings.behavior.responseDelay"
              :options="delayOptions"
            />
          </div>
        </div>

        <SettingsToggleRow
          v-model="settings.behavior.typingIndicator"
          :title="
            t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.TYPING_INDICATOR')
          "
          :description="
            t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.TYPING_INDICATOR_DESC')
          "
        />

        <div class="flex flex-col gap-3">
          <SettingsToggleRow
            v-model="settings.behavior.randomDelay"
            :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.RANDOM_DELAY')"
            :description="
              t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.RANDOM_DELAY_DESC')
            "
          />
          <div
            v-if="settings.behavior.randomDelay"
            class="grid grid-cols-2 gap-3 pl-1"
          >
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-medium text-foreground">{{
                t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.MIN_SECONDS')
              }}</label>
              <RelayInput
                v-model="settings.behavior.randomDelayMin"
                type="number"
                class-name="h-9"
              />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-medium text-foreground">{{
                t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.MAX_SECONDS')
              }}</label>
              <RelayInput
                v-model="settings.behavior.randomDelayMax"
                type="number"
                class-name="h-9"
              />
            </div>
          </div>
        </div>

        <SettingsToggleRow
          v-model="settings.behavior.readInboundMessage"
          :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.READ_INBOUND')"
          :description="
            t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.READ_INBOUND_DESC')
          "
        />
      </SettingsCard>

      <SettingsCard
        :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.MESSAGE_BEHAVIOR')"
      >
        <SettingsToggleRow
          v-model="settings.behavior.splitLongMessages"
          :title="
            t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.SPLIT_LONG_MESSAGES')
          "
          :description="
            t(
              'AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.SPLIT_LONG_MESSAGES_DESC'
            )
          "
        />

        <div class="flex flex-col gap-2">
          <span class="text-[13.5px] font-medium text-foreground">{{
            t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.BRANDING_SIGNATURE')
          }}</span>
          <SettingsSelect
            v-model="settings.behavior.brandingSignature"
            :options="signatureOptions"
          />
        </div>

        <SettingsToggleRow
          v-model="settings.behavior.useRichPreviews"
          :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.RICH_PREVIEWS')"
          :description="
            t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.RICH_PREVIEWS_DESC')
          "
        />
      </SettingsCard>
    </div>

    <div class="flex flex-col gap-6">
      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.ABOUT_TITLE')"
        icon="i-lucide-info"
      >
        <p class="text-xs text-muted-foreground leading-relaxed">
          {{ t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.ABOUT_DESC') }}
        </p>
      </SettingsSidebarCard>

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.BEST_PRACTICES')"
        icon="i-lucide-sparkles"
      >
        <ul class="flex flex-col gap-2.5">
          <li
            v-for="tip in bestPractices"
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

      <SettingsSidebarCard
        :title="t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.PREVIEW_EXAMPLE')"
        icon="i-lucide-eye"
      >
        <div
          class="bg-muted/50 rounded-2xl rounded-tl-sm p-3 text-[13px] text-foreground self-start max-w-[90%] border border-border/50"
        >
          {{ t('AUTORESPONDER.SETTINGS.RESPONSE_BEHAVIOR.PREVIEW_BODY') }}
        </div>
      </SettingsSidebarCard>
    </div>
  </div>
</template>
