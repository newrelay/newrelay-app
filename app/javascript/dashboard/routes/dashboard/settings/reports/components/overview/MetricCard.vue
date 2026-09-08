<script setup>
import Spinner from 'shared/components/Spinner.vue';

defineProps({
  header: {
    type: String,
    default: '',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  loadingMessage: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="flex flex-col flex-grow rounded-xl border border-border bg-card shadow-sm"
  >
    <div class="flex items-center justify-between gap-3 p-6 pb-4">
      <slot name="header">
        <div class="flex items-center gap-3">
          <h3 class="text-base font-medium text-foreground tracking-tight">
            {{ header }}
          </h3>
          <span
            class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 text-[12px] font-medium border border-emerald-500/20"
          >
            <span class="size-1.5 rounded-full bg-emerald-500" />
            {{ $t('OVERVIEW_REPORTS.LIVE') }}
          </span>
        </div>
        <div class="flex items-center justify-end gap-2">
          <slot name="control" />
        </div>
      </slot>
    </div>
    <div
      v-if="!isLoading"
      class="flex justify-between w-full max-w-full px-6 pb-6"
    >
      <slot />
    </div>
    <div
      v-else-if="isLoading"
      class="items-center flex text-base justify-center px-12 py-6"
    >
      <Spinner />
      <span class="text-muted-foreground">
        {{ loadingMessage }}
      </span>
    </div>
  </div>
</template>
