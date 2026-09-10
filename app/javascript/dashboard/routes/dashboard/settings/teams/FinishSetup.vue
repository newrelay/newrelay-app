<script setup>
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
</script>

<template>
  <div
    class="mx-auto flex h-full w-full max-w-md flex-col items-center justify-center text-center animate-in fade-in zoom-in-95 duration-500"
  >
    <div
      class="mb-6 flex size-20 items-center justify-center rounded-full border border-green-100 bg-green-50 shadow-sm dark:border-green-900/40 dark:bg-green-950/40"
    >
      <Icon icon="i-lucide-check" class="size-10 text-green-600" />
    </div>
    <h2 class="mb-3 text-2xl font-bold tracking-tight text-foreground">
      {{ $t('TEAMS_SETTINGS.FINISH.TITLE') }}
    </h2>
    <p class="mb-8 text-[14px] leading-relaxed text-muted-foreground">
      {{ $t('TEAMS_SETTINGS.FINISH.MESSAGE') }}
    </p>
    <router-link :to="{ name: 'settings_teams_list' }">
      <RelayButton class="h-11 px-8 text-[14px] shadow-sm">
        {{ $t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT') }}
      </RelayButton>
    </router-link>
  </div>
</template>
