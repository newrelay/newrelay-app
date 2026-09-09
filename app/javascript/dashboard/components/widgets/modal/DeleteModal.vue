<script setup>
import { computed } from 'vue';
import { RelayDeleteConfirmModal } from 'dashboard/components-next/relay';

const props = defineProps({
  onClose: { type: Function, default: () => {} },
  onConfirm: { type: Function, default: () => {} },
  title: { type: String, default: '' },
  message: { type: String, default: '' },
  messageValue: { type: String, default: '' },
  confirmText: { type: String, default: '' },
  rejectText: { type: String, default: '' },
});

const show = defineModel('show', { type: Boolean, default: false });

const description = computed(
  () => `${props.message}${props.messageValue || ''}`
);

const closeModal = () => {
  show.value = false;
  props.onClose();
};

const confirm = () => {
  props.onConfirm();
};
</script>

<template>
  <RelayDeleteConfirmModal
    v-model:show="show"
    :title="title"
    :description="description"
    :confirm-text="confirmText"
    :cancel-text="rejectText"
    @close="closeModal"
    @confirm="confirm"
  />
</template>
