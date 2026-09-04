<script setup>
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import { useBranding } from 'shared/composables/useBranding';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  integrationId: {
    type: String,
    required: true,
  },
});

defineEmits(['add', 'delete']);

const { integration, hasConnectedHooks } = useIntegrationHook(
  props.integrationId
);

const { replaceInstallationName } = useBranding();
</script>

<template>
  <div
    class="flex-grow overflow-auto rounded-xl border border-border/60 bg-card p-4 shadow-xs"
  >
    <div class="flex items-center justify-center">
      <div class="flex h-16 w-16 items-center justify-center">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="block max-w-full rounded-md border border-border bg-accent shadow-sm dark:hidden dark:bg-accent"
        />
        <img
          :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
          class="hidden max-w-full rounded-md border border-border bg-accent shadow-sm dark:block dark:bg-accent"
        />
      </div>
      <div class="m-0 mx-4 flex flex-1 flex-col justify-center">
        <h3 class="mb-1 capitalize text-base font-semibold text-foreground">
          {{ integration.name }}
        </h3>
        <p class="text-[13px] leading-relaxed text-muted-foreground">
          {{ replaceInstallationName(integration.description) }}
        </p>
      </div>
      <div class="mb-0 flex w-[15%] items-center justify-center">
        <RelayButton
          v-if="hasConnectedHooks"
          variant="ghost"
          class="h-9 px-4 text-[13px] font-semibold text-destructive hover:bg-destructive/10 hover:text-destructive"
          @click="$emit('delete', integration.hooks[0])"
        >
          {{ $t('INTEGRATION_APPS.DISCONNECT.BUTTON_TEXT') }}
        </RelayButton>
        <RelayButton v-else class="h-9 px-4 text-[13px]" @click="$emit('add')">
          {{ $t('INTEGRATION_APPS.CONNECT.BUTTON_TEXT') }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
