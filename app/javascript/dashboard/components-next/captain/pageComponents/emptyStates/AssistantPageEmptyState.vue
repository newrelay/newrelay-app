<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['click']);

const mockAssistants = [
  {
    name: 'Mr. Smarty',
    description: 'Handles general customer queries and initial assistance',
    opacity: 'opacity-40',
  },
  {
    name: 'Support Genie',
    description: 'Specializes in technical troubleshooting and escalations',
    opacity: 'opacity-30',
  },
  {
    name: 'Sales Helper',
    description: 'Guides prospective buyers through product questions',
    opacity: 'opacity-20',
  },
];

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div
        v-for="(assistant, index) in mockAssistants"
        :key="`mock-assistant-${index}`"
        class="flex flex-col justify-between rounded-xl border border-border/50 bg-card/40 p-5 sm:flex-row sm:items-center"
        :class="assistant.opacity"
      >
        <div class="min-w-0 flex-1 text-left">
          <h3 class="mb-1 text-[15px] font-medium text-foreground">
            {{ assistant.name }}
          </h3>
          <p class="text-[14px] text-muted-foreground">
            {{ assistant.description }}
          </p>
        </div>
      </div>
    </template>
    <template #actions>
      <RelayButton
        size="lg"
        class="shadow-md transition-all hover:shadow-lg"
        @click="onClick"
      >
        <span class="i-lucide-plus mr-1.5 size-4" />
        {{ $t('CAPTAIN.ASSISTANTS.ADD_NEW') }}
      </RelayButton>
    </template>
  </EmptyStateLayout>
</template>
