<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
    :show-backdrop="false"
  >
    <template #actions>
      <RelayButton
        size="lg"
        class="shadow-md transition-all hover:shadow-lg"
        @click="onClick"
      >
        <span class="i-lucide-plus mr-1.5 size-4" />
        {{ $t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW') }}
      </RelayButton>
    </template>
  </EmptyStateLayout>
</template>
