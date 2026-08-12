<script setup>
import { useI18n } from 'vue-i18n';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import Policy from 'dashboard/components/policy.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NotificationPreferences from '../profile/NotificationPreferences.vue';
import AudioNotifications from '../profile/AudioNotifications.vue';

const { t } = useI18n();

const audioNotificationPermissions = [...ROLES, ...CONVERSATION_PERMISSIONS];
const notificationPermissions = [...ROLES, ...CONVERSATION_PERMISSIONS];
</script>

<template>
  <div class="flex flex-col gap-6">
    <BaseSettingsHeader
      :title="t('NOTIFICATION_SETTINGS.TITLE')"
      :description="t('NOTIFICATION_SETTINGS.DESCRIPTION')"
    />

    <Policy :permissions="audioNotificationPermissions">
      <SectionLayout
        as-card
        :title="t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TITLE')"
        :description="
          t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.NOTE')
        "
      >
        <AudioNotifications />
      </SectionLayout>
    </Policy>

    <Policy :permissions="notificationPermissions">
      <SectionLayout
        as-card
        :title="t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.TITLE')"
        description=""
      >
        <NotificationPreferences />
      </SectionLayout>
    </Policy>
  </div>
</template>
