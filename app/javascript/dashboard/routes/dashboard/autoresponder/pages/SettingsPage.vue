<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';
import GeneralTab from '../components/settings/GeneralTab.vue';
import ResponseBehaviorTab from '../components/settings/ResponseBehaviorTab.vue';
import SafetyLimitsTab from '../components/settings/SafetyLimitsTab.vue';
import BusinessHoursTab from '../components/settings/BusinessHoursTab.vue';
import ChannelsTab from '../components/settings/ChannelsTab.vue';
import NotificationsTab from '../components/settings/NotificationsTab.vue';
import AdvancedTab from '../components/settings/AdvancedTab.vue';
import { useAutoresponderSettings } from '../composables/useAutoresponderSettings';

const { t } = useI18n();
const { loaded } = useAutoresponderSettings();
const activeTab = ref('General');

const tabs = computed(() => [
  {
    id: 'General',
    icon: 'i-lucide-settings',
    label: t('AUTORESPONDER.SETTINGS.TAB_GENERAL'),
  },
  {
    id: 'Response Behavior',
    icon: 'i-lucide-zap',
    label: t('AUTORESPONDER.SETTINGS.TAB_RESPONSE_BEHAVIOR'),
  },
  {
    id: 'Safety & Limits',
    icon: 'i-lucide-shield',
    label: t('AUTORESPONDER.SETTINGS.TAB_SAFETY_LIMITS'),
  },
  {
    id: 'Business Hours',
    icon: 'i-lucide-clock',
    label: t('AUTORESPONDER.SETTINGS.TAB_BUSINESS_HOURS'),
  },
  {
    id: 'Channels',
    icon: 'i-lucide-globe',
    label: t('AUTORESPONDER.SETTINGS.TAB_CHANNELS'),
  },
  {
    id: 'Notifications',
    icon: 'i-lucide-bell',
    label: t('AUTORESPONDER.SETTINGS.TAB_NOTIFICATIONS'),
  },
  {
    id: 'Advanced',
    icon: 'i-lucide-code-2',
    label: t('AUTORESPONDER.SETTINGS.TAB_ADVANCED'),
  },
]);

const tabComponents = {
  General: GeneralTab,
  'Response Behavior': ResponseBehaviorTab,
  'Safety & Limits': SafetyLimitsTab,
  'Business Hours': BusinessHoursTab,
  Channels: ChannelsTab,
  Notifications: NotificationsTab,
  Advanced: AdvancedTab,
};

const activeComponent = computed(() => tabComponents[activeTab.value]);
</script>

<template>
  <div class="min-h-screen min-w-0 bg-background p-4 md:p-6">
    <div
      class="mb-8 mt-2 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
    >
      <div class="min-w-0">
        <h1 class="text-[16px] font-medium tracking-tight text-foreground">
          {{ t('AUTORESPONDER.SETTINGS.TITLE') }}
        </h1>
        <p class="text-[13.5px] text-muted-foreground mt-1">
          {{ t('AUTORESPONDER.SETTINGS.SUBTITLE') }}
        </p>
      </div>
      <RelayButton
        variant="outline"
        class="h-9 w-fit shrink-0 gap-2 text-[13px] font-medium"
      >
        <span class="i-lucide-help-circle size-4" />
        {{ t('AUTORESPONDER.SETTINGS.HOW_IT_WORKS') }}
      </RelayButton>
    </div>

    <div class="relative border-b border-border w-full mb-8">
      <div class="flex items-center gap-6 overflow-x-auto hide-scrollbar">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          class="relative flex items-center gap-2 pb-3.5 text-[13.5px] font-medium transition-colors whitespace-nowrap"
          :class="
            activeTab === tab.id
              ? 'text-primary'
              : 'text-muted-foreground hover:text-foreground'
          "
          @click="activeTab = tab.id"
        >
          <span :class="tab.icon" class="size-4" />
          <span>{{ tab.label }}</span>
          <div
            v-if="activeTab === tab.id"
            class="absolute -bottom-[1px] left-0 right-0 h-[2px] bg-primary rounded-full z-10"
          />
        </button>
      </div>
    </div>

    <component :is="activeComponent" v-if="loaded" />
  </div>
</template>
