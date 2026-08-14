<script setup>
import { ref, onMounted } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import Button from 'dashboard/components-next/button/Button.vue';

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
  searchInputRef.value.focus();
});

const onInput = e => {
  emit('search', e.target.value);
};

const onClose = () => {
  emit('close');
};

const keyboardEvents = {
  Slash: {
    action: e => {
      e.preventDefault();
      searchInputRef.value.focus();
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
      <h3 class="capitalize text-base text-foreground">
        {{ title }}
      </h3>
      <Button ghost xs slate icon="i-lucide-x" @click="onClose" />
    </div>

    <div class="relative">
      <div
        class="absolute ltr:left-0 rtl:right-0 w-8 top-0.5 h-8 flex justify-center items-center"
      >
        <fluent-icon icon="search" class="" size="18" />
      </div>
      <input
        ref="searchInputRef"
        type="text"
        :placeholder="$t('HELP_CENTER.ARTICLE_SEARCH.PLACEHOLDER')"
        class="block w-full !h-9 ltr:!pl-8 rtl:!pr-8 dark:!bg-muted !border-border !bg-muted leading-8 text-foreground ring-2 ring-transparent ring-border border border-solid placeholder:text-muted-foreground focus:border-primary focus:ring-primary !mb-0 text-[14px] border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 shadow-sm rounded-md"
        :value="searchQuery"
        @input="onInput"
      />
    </div>
  </div>
</template>
