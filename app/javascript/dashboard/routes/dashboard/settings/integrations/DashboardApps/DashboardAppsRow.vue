<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  app: {
    type: Object,
    default: () => ({}),
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['edit', 'delete']);
</script>

<template>
  <div
    class="group grid grid-cols-[1.2fr_2fr_1fr] items-center gap-4 p-4 transition-colors hover:bg-muted/10"
  >
    <div class="flex min-w-0 items-center gap-3">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-xl border border-border/40 bg-primary/10 shadow-xs"
      >
        <Icon icon="i-lucide-layout-dashboard" class="size-5 text-primary" />
      </div>
      <span
        class="truncate text-[14px] font-medium text-foreground"
        :title="app.title"
      >
        {{ app.title }}
      </span>
    </div>

    <div
      class="truncate pr-4 text-[13px] text-muted-foreground"
      :title="app.content?.[0]?.url"
    >
      {{ app.content?.[0]?.url }}
    </div>

    <div class="flex items-center justify-end gap-1 pr-2">
      <RelayButton
        v-tooltip.top="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.EDIT_TOOLTIP')
        "
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
        :disabled="loading"
        @click="$emit('edit', app)"
      >
        <Icon icon="i-lucide-pencil" class="size-3.5" />
      </RelayButton>
      <RelayButton
        v-tooltip.top="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.DELETE_TOOLTIP')
        "
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
        :disabled="loading"
        @click="$emit('delete', app)"
      >
        <Icon icon="i-lucide-trash-2" class="size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
