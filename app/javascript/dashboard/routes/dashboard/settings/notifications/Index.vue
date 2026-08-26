<script setup>
import { useI18n } from 'vue-i18n';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import Policy from 'dashboard/components/policy.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NotificationPreferences from '../profile/NotificationPreferences.vue';

const { t } = useI18n();

const notificationPermissions = [...ROLES, ...CONVERSATION_PERMISSIONS];
</script>

<template>
  <div class="flex flex-col gap-8">
    <BaseSettingsHeader
      :title="t('NOTIFICATION_SETTINGS.TITLE')"
      :description="t('NOTIFICATION_SETTINGS.DESCRIPTION')"
    />

    <Policy :permissions="notificationPermissions">
      <NotificationPreferences />
    </Policy>
  </div>
</template>
