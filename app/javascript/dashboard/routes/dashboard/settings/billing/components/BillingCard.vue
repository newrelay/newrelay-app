<script setup>
import BillingHeader from './BillingHeader.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  /**
   * hero: single padded card without header divider (Current Plan)
   * default: header with bottom border + body
   */
  variant: {
    type: String,
    default: 'default',
    validator: value => ['default', 'hero'].includes(value),
  },
});
</script>

<template>
  <div
    class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
    :class="variant === 'hero' ? 'flex flex-col gap-6 p-4 sm:p-6' : ''"
  >
    <template v-if="variant === 'hero'">
      <BillingHeader :title="title" :description="description">
        <slot name="action" />
      </BillingHeader>
      <slot />
    </template>
    <template v-else>
      <div class="border-b border-border/40 p-4 sm:p-6">
        <BillingHeader :title="title" :description="description">
          <slot name="action" />
        </BillingHeader>
      </div>
      <div class="px-4 pb-4 pt-2 sm:px-6 sm:pb-6">
        <slot />
      </div>
    </template>
  </div>
</template>
