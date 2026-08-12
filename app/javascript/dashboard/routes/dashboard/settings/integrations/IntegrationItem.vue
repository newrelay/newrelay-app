<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useStoreGetters } from 'dashboard/composables/store';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

import { RelayButton, RelaySwitch } from 'dashboard/components-next/relay';

const props = defineProps({
  id: {
    type: [String, Number],
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  enabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['disconnect']);

const router = useRouter();
const getters = useStoreGetters();
const accountId = getters.getCurrentAccountId;
const { replaceInstallationName } = useBranding();

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);

const goToDetails = () => {
  router.push(actionURL.value);
};

const onToggle = value => {
  if (value && !props.enabled) {
    goToDetails();
    return;
  }
  if (!value && props.enabled) {
    emit('disconnect');
  }
};

const onRemove = () => {
  if (props.enabled) {
    emit('disconnect');
  }
};
</script>

<template>
  <div
    class="flex flex-col justify-between rounded-xl border border-border/60 bg-card p-5 transition-colors hover:border-border"
  >
    <div class="flex items-start gap-4">
      <div
        class="flex size-[52px] shrink-0 items-center justify-center overflow-hidden rounded-xl border border-border/60 bg-background shadow-sm"
      >
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="block size-7 rounded-md dark:hidden"
          :alt="name"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="hidden size-7 rounded-md dark:block"
          :alt="name"
        />
      </div>
      <div class="min-w-0 flex-1 pt-0.5">
        <h4 class="text-[15px] font-bold leading-none text-foreground">
          {{ name }}
        </h4>
        <p class="mt-2 text-[13px] leading-relaxed text-muted-foreground">
          {{ replaceInstallationName(description) }}
        </p>
      </div>
    </div>
    <div
      class="mt-6 flex items-center justify-between border-t border-border/40 pt-4"
    >
      <div class="flex items-center gap-3">
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8 px-4 text-xs font-semibold"
          @click="goToDetails"
        >
          {{ $t('INTEGRATION_SETTINGS.DETAILS') }}
        </RelayButton>
        <RelayButton
          variant="ghost"
          size="sm"
          class="h-8 px-4 text-xs font-semibold text-rose-500 hover:bg-rose-50 hover:text-rose-600 dark:hover:bg-rose-500/10"
          :disabled="!enabled"
          @click="onRemove"
        >
          {{ $t('INTEGRATION_SETTINGS.REMOVE') }}
        </RelayButton>
      </div>
      <RelaySwitch :model-value="enabled" @update:model-value="onToggle" />
    </div>
  </div>
</template>
