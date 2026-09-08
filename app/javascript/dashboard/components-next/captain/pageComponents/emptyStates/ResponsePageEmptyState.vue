<script setup>
import { computed } from 'vue';
import { useBranding } from 'shared/composables/useBranding';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  variant: {
    type: String,
    default: 'approved',
    validator: value => ['approved', 'pending'].includes(value),
  },
  hasActiveFilters: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click', 'clearFilters']);

const isApproved = computed(() => props.variant === 'approved');
const isPending = computed(() => props.variant === 'pending');

const { replaceInstallationName } = useBranding();

const mockFaqs = computed(() => [
  {
    question: replaceInstallationName('Why is my Messenger deactivated?'),
    answer: replaceInstallationName(
      'Messenger may be deactivated because you are on a free plan or the limit for inboxes might have been reached.'
    ),
    assistant: 'Mr. Smarty',
    author: 'John',
    date: 'over 1 year ago',
    opacity: 'opacity-40',
  },
  {
    question: replaceInstallationName('How do I integrate WhatsApp?'),
    answer: replaceInstallationName(
      'You can integrate your WhatsApp account by navigating to the Integrations section.'
    ),
    assistant: 'Mr. Smarty',
    author: 'Admin',
    date: '2 months ago',
    opacity: 'opacity-30',
  },
]);

const onClick = () => {
  emit('click');
};

const onClearFilters = () => {
  emit('clearFilters');
};
</script>

<template>
  <EmptyStateLayout
    :title="
      isPending
        ? $t('CAPTAIN.RESPONSES.EMPTY_STATE.NO_PENDING_TITLE')
        : $t('CAPTAIN.RESPONSES.EMPTY_STATE.TITLE')
    "
    :subtitle="isApproved ? $t('CAPTAIN.RESPONSES.EMPTY_STATE.SUBTITLE') : ''"
    :action-perms="['administrator']"
    :show-backdrop="isApproved"
  >
    <template v-if="isApproved" #empty-state-item>
      <div
        v-for="(faq, index) in mockFaqs"
        :key="`mock-faq-${index}`"
        class="flex flex-col justify-between rounded-xl border border-border/50 bg-card/40 p-5 sm:flex-row sm:items-start"
        :class="faq.opacity"
      >
        <div class="flex min-w-0 flex-1 items-start gap-4 pr-4">
          <div class="min-w-0 flex-1 text-left">
            <h3 class="mb-2 text-[15px] font-medium text-foreground">
              {{ faq.question }}
            </h3>
            <p class="mb-4 line-clamp-1 text-[14px] text-muted-foreground">
              {{ faq.answer }}
            </p>
            <div
              class="flex flex-wrap items-center gap-4 text-[12px] text-muted-foreground/80"
            >
              <div class="flex items-center gap-1.5">
                <span class="i-lucide-brain-circuit size-3.5" />
                {{ faq.assistant }}
              </div>
              <div class="flex items-center gap-1.5">
                <span class="i-lucide-user size-3.5" />
                {{ faq.author }}
              </div>
            </div>
          </div>
        </div>
        <div class="hidden text-[12px] text-muted-foreground/60 sm:block">
          {{ faq.date }}
        </div>
      </div>
    </template>
    <template #actions>
      <div class="flex flex-col items-center gap-3">
        <RelayButton
          v-if="isApproved"
          size="lg"
          class="shadow-md transition-all hover:shadow-lg"
          @click="onClick"
        >
          <span class="i-lucide-plus mr-1.5 size-4" />
          {{ $t('CAPTAIN.RESPONSES.ADD_NEW') }}
        </RelayButton>
        <RelayButton
          v-else-if="isPending && hasActiveFilters"
          variant="link"
          size="sm"
          @click="onClearFilters"
        >
          {{ $t('CAPTAIN.RESPONSES.EMPTY_STATE.CLEAR_SEARCH') }}
        </RelayButton>
      </div>
    </template>
  </EmptyStateLayout>
</template>
