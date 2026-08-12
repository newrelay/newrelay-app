<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <div
    class="flex items-center w-full px-4 py-3 dark:bg-warning/15 bg-warning/10"
  >
    <span class="text-sm dark:text-warning text-warning">
      {{ t('COMPOSE_NEW_CONVERSATION.FORM.NO_INBOX_ALERT') }}
    </span>
  </div>
</template>
