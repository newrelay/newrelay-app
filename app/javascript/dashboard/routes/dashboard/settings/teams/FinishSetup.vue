<script setup>
import { RelayButton } from 'dashboard/components-next/relay';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
</script>

<template>
  <div class="col-span-6 h-full w-full p-6">
    <EmptyState
      :title="$t('TEAMS_SETTINGS.FINISH.TITLE')"
      :message="$t('TEAMS_SETTINGS.FINISH.MESSAGE')"
      :button-text="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')"
    >
      <div class="w-full text-center">
        <router-link
          :to="{
            name: 'settings_teams_list',
          }"
        >
          <RelayButton class="h-10 px-6 font-semibold shadow-sm">
            {{ $t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT') }}
          </RelayButton>
        </router-link>
      </div>
    </EmptyState>
  </div>
</template>
