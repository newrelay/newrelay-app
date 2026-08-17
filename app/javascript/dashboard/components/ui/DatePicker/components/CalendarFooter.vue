<script setup>
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['clear', 'change']);
</script>

<template>
  <div
    class="flex h-14 items-center justify-between gap-2 border-t border-border/40 px-8 py-3"
  >
    <RelayButton
      variant="ghost"
      class="border border-border text-sm font-medium text-muted-foreground hover:border-transparent hover:text-foreground"
      @click="emit('clear')"
    >
      {{ $t('DATE_PICKER.CLEAR_BUTTON') }}
    </RelayButton>
    <RelayButton
      class="h-9 px-8 text-[13px] font-medium shadow-sm"
      @click="emit('change')"
    >
      {{ $t('DATE_PICKER.APPLY_BUTTON') }}
    </RelayButton>
  </div>
</template>
