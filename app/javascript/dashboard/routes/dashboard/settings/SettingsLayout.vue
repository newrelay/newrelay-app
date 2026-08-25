<script setup>
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
  noRecordsFound: {
    type: Boolean,
    default: false,
  },
  loadingMessage: {
    type: String,
    default: '',
  },
  noRecordsMessage: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex h-full w-full flex-col gap-4">
    <slot name="header" />
    <!-- Added to render any templates that should be rendered before body -->
    <main>
      <slot name="preBody" />
      <slot v-if="isLoading" name="loading">
        <div
          class="flex flex-col items-center justify-center gap-3 py-20 text-muted-foreground"
        >
          <Spinner :size="28" class="text-primary" />
          <p v-if="loadingMessage" class="text-sm">{{ loadingMessage }}</p>
        </div>
      </slot>
      <p
        v-else-if="noRecordsFound"
        class="text-muted-foreground flex flex-1 items-center justify-center py-20 text-base"
      >
        {{ noRecordsMessage }}
      </p>
      <slot v-else name="body" />
      <!-- Do not delete the slot below. It is required to render anything that is not defined in the above slots. -->
      <slot />
    </main>
  </div>
</template>
