<script setup>
import { ref, watch, onMounted } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { RELAY_MODAL_CLOSE_BUTTON_CLASS } from 'dashboard/components-next/relay/modal/constants';
import { RelayInput } from 'dashboard/components-next/relay';

defineProps({
  title: {
    type: String,
    default: 'newrelay',
  },
});

const emit = defineEmits(['search', 'close']);

const searchInputRef = ref(null);
const searchQuery = ref('');

onMounted(() => {
  searchInputRef.value?.$el?.focus();
});

watch(searchQuery, val => {
  emit('search', val);
});

const onClose = () => {
  emit('close');
};

const keyboardEvents = {
  Slash: {
    action: e => {
      e.preventDefault();
      searchInputRef.value?.$el?.focus();
    },
  },
  Escape: {
    action: () => {
      onClose();
    },
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div class="flex flex-col py-1">
    <div class="flex items-center justify-between py-2 mb-1">
      <h3 class="text-base text-foreground">
        {{ title }}
      </h3>
      <button
        type="button"
        :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
        @click="onClose"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>

    <div class="relative">
      <div
        class="absolute ltr:left-0 rtl:right-0 w-8 top-0.5 h-8 flex justify-center items-center"
      >
        <fluent-icon icon="search" class="" size="18" />
      </div>
      <RelayInput
        ref="searchInputRef"
        v-model="searchQuery"
        :placeholder="$t('HELP_CENTER.ARTICLE_SEARCH.PLACEHOLDER')"
        class-name="pl-9"
      />
    </div>
  </div>
</template>
