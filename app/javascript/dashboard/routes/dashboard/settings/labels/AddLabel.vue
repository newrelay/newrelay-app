<script setup>
import LabelModal from './component/LabelModal.vue';

defineProps({
  prefillTitle: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);
</script>

<template>
  <LabelModal
    show
    mode="add"
    :prefill-title="prefillTitle"
    @close="emit('close')"
  />
</template>
