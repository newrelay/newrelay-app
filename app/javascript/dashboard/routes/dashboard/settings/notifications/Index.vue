<script setup>
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import Policy from 'dashboard/components/policy.vue';
import NotificationPreferences from '../profile/NotificationPreferences.vue';

const notificationPermissions = [...ROLES, ...CONVERSATION_PERMISSIONS];
</script>

<template>
  <div class="flex flex-col gap-6">
    <Policy :permissions="notificationPermissions">
      <NotificationPreferences />
    </Policy>
  </div>
</template>
