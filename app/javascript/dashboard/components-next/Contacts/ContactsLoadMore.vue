<script setup>
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['loadMore']);

const { t } = useI18n();
</script>

<template>
  <div class="flex justify-center py-4">
    <RelayButton
      variant="secondary"
      size="sm"
      :disabled="isLoading"
      @click="emit('loadMore')"
    >
      {{ t('CONTACTS_LAYOUT.LOAD_MORE') }}
    </RelayButton>
  </div>
</template>
