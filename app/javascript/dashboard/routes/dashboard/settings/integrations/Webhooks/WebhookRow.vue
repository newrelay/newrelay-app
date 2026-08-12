<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getI18nKey } from 'dashboard/routes/dashboard/settings/helper/settingsHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  webhook: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete']);
const { t } = useI18n();

const subscribedEvents = computed(() => {
  const { subscriptions } = props.webhook;
  if (!subscriptions?.length) return '';
  return subscriptions
    .map(event =>
      t(
        getI18nKey(
          'INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS',
          event
        )
      )
    )
    .join(', ');
});

const displayName = computed(
  () => props.webhook.name || props.webhook.url || ''
);
</script>

<template>
  <div
    class="group grid grid-cols-[2fr_2fr_1fr] items-center gap-4 p-4 transition-colors hover:bg-muted/10"
  >
    <div class="flex min-w-0 items-center gap-4">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-xl border border-border/40 bg-primary/10 shadow-xs"
      >
        <Icon icon="i-lucide-webhook" class="size-5 text-primary" />
      </div>
      <div class="flex min-w-0 flex-col">
        <h4 class="truncate text-[14px] font-medium text-foreground">
          {{ displayName }}
        </h4>
        <p
          v-if="subscribedEvents"
          class="mt-0.5 truncate text-[13px] text-muted-foreground"
        >
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SUBSCRIBED_EVENTS') }}:
          {{ subscribedEvents }}
        </p>
      </div>
    </div>

    <div class="truncate pr-4 text-[13px] text-muted-foreground">
      {{ webhook.url }}
    </div>

    <div class="flex items-center justify-end gap-1 pr-2">
      <RelayButton
        v-tooltip.top="t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.BUTTON_TEXT')"
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
        :disabled="loading"
        @click="emit('edit', webhook)"
      >
        <Icon icon="i-lucide-pencil" class="size-3.5" />
      </RelayButton>
      <RelayButton
        v-tooltip.top="t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')"
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
        :disabled="loading"
        @click="emit('delete', webhook)"
      >
        <Icon icon="i-lucide-trash-2" class="size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
