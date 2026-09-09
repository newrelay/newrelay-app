<script setup>
import { RelayConfirmModal } from 'dashboard/components-next/relay';

defineProps({
  title: { type: String, default: '' },
  message: { type: String, default: '' },
  confirmText: { type: String, default: '' },
  rejectText: { type: String, default: '' },
  confirmValue: { type: String, default: '' },
  confirmPlaceHolderText: { type: String, default: '' },
});

const emit = defineEmits(['onClose', 'onConfirm']);
const show = defineModel('show', { type: Boolean, default: false });

const closeModal = () => {
  show.value = false;
  emit('onClose');
};

const onConfirm = () => {
  emit('onConfirm');
};
</script>

<template>
  <RelayConfirmModal
    :show="show"
    :title="title"
    :message="message"
    :confirm-text="confirmText"
    :cancel-text="rejectText"
    :confirm-value="confirmValue"
    :confirm-placeholder="confirmPlaceHolderText"
    @close="closeModal"
    @confirm="onConfirm"
  />
</template>
