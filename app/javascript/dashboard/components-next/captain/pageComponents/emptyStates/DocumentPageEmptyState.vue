<script setup>
import { computed } from 'vue';
import { useBranding } from 'shared/composables/useBranding';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['click']);

const { replaceInstallationName } = useBranding();

const mockDocuments = computed(() => [
  {
    title: replaceInstallationName(
      'How to use Conversation Filters? | User Guide'
    ),
    assistant: 'Helper Pro',
    url: 'hc/user-guide/articles/...',
    status: 'not updated yet',
    opacity: 'opacity-40',
  },
  {
    title: replaceInstallationName(
      'Automating Ticket Assignments | User Guide'
    ),
    assistant: 'Support Genie',
    url: 'hc/user-guide/articles/...',
    status: 'not updated yet',
    opacity: 'opacity-30',
  },
  {
    title: replaceInstallationName('Managing Customer Profiles | User Guide'),
    assistant: 'CRM Assistant',
    url: 'hc/user-guide/articles/...',
    status: 'not updated yet',
    opacity: 'opacity-20',
  },
]);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('CAPTAIN.DOCUMENTS.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.DOCUMENTS.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div
        v-for="(doc, index) in mockDocuments"
        :key="`mock-doc-${index}`"
        class="flex flex-col justify-between rounded-xl border border-border/50 bg-card/40 p-4 sm:flex-row sm:items-center"
        :class="doc.opacity"
      >
        <div class="flex min-w-0 flex-1 items-center gap-4 pr-4">
          <div class="size-4 shrink-0 rounded border border-border/60" />
          <div class="min-w-0 flex-1 text-left">
            <h3 class="mb-1 truncate text-[14.5px] font-medium text-foreground">
              {{ doc.title }}
            </h3>
            <div
              class="flex flex-wrap items-center gap-4 text-[12px] text-muted-foreground"
            >
              <div class="flex items-center gap-1.5">
                <span class="i-lucide-brain-circuit size-3.5 opacity-70" />
                {{ doc.assistant }}
              </div>
              <div class="flex max-w-[200px] items-center gap-1.5 truncate">
                <span class="i-lucide-link size-3.5 opacity-70" />
                {{ doc.url }}
              </div>
            </div>
          </div>
        </div>
        <div class="mt-4 shrink-0 text-[12px] text-muted-foreground/60 sm:mt-0">
          {{ doc.status }}
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
        {{ $t('CAPTAIN.DOCUMENTS.ADD_NEW') }}
      </RelayButton>
    </template>
  </EmptyStateLayout>
</template>
