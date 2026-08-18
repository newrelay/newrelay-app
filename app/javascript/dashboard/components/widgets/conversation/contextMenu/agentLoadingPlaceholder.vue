<script setup>
import Spinner from 'shared/components/Spinner.vue';
</script>

<template>
  <div
    class="flex min-w-[12rem] flex-col items-center justify-center px-4 py-6"
  >
    <Spinner />
    <p class="mt-2 text-xs text-muted-foreground">
      {{ $t('CONVERSATION.CARD_CONTEXT_MENU.AGENTS_LOADING') }}
    </p>
  </div>
</template>
