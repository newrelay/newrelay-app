<script setup>
import { computed } from 'vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { useI18n } from 'vue-i18n';
import { useKbd } from 'dashboard/composables/utils/useKbd';

defineProps({
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();
const handleCancel = () => {
  emit('cancel');
};

const shortcutKey = useKbd(['$mod', '+', 'enter']);

const acceptLabel = computed(() => {
  return `${t('GENERAL.ACCEPT')}  (${shortcutKey.value})`;
});

const handleSubmit = () => {
  emit('submit');
};
</script>

<template>
  <div
    class="px-3 py-2 flex items-center justify-between border-t border-border bg-muted/20"
  >
    <RelayButton
      variant="ghost"
      class="text-muted-foreground hover:text-foreground"
      :disabled="isGeneratingContent"
      @click="handleCancel"
    >
      {{ t('GENERAL.DISCARD') }}
    </RelayButton>
    <RelayButton
      variant="default"
      class="px-4 h-8 gap-2 font-semibold shadow-xs"
      :disabled="isGeneratingContent"
      @click="handleSubmit"
    >
      {{ acceptLabel }}
    </RelayButton>
  </div>
</template>
