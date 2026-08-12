<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <li
    class="py-1 pl-3 text-muted-foreground border rounded-lg border-dashed text-center border-accent text-xs h-8 grid place-content-center select-none pointer-events-none"
  >
    <slot>{{ t('SIDEBAR.NO_ITEMS') }}</slot>
  </li>
</template>
