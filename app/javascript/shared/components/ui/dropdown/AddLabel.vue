<script setup>
const emit = defineEmits(['add']);

const addLabel = () => {
  emit('add');
};
</script>

<template>
  <button
    type="button"
    class="flex items-center gap-1 text-[13px] text-primary hover:text-primary/80 transition-colors self-start mb-0.5"
    @click="addLabel"
  >
    <span class="i-lucide-plus size-3.5" />
    {{ $t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON') }}
  </button>
</template>
