<script setup>
import { nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  noteText: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:noteText', 'close', 'save']);

const { t } = useI18n();
const textareaRef = ref(null);

watch(
  () => props.isOpen,
  open => {
    if (!open) return;
    nextTick(() => textareaRef.value?.focus());
  }
);

const onInput = event => {
  emit('update:noteText', event.target.value);
};
</script>

<template>
  <div
    v-if="isOpen"
    class="absolute z-50 right-8 bottom-8 w-80 overflow-hidden rounded-xl border border-amber-200/60 shadow-2xl animate-in zoom-in-95 slide-in-from-bottom-5 duration-200 bg-amber-50/95 backdrop-blur-md dark:border-amber-500/20 dark:bg-amber-500/10 sm:right-12 sm:bottom-12"
  >
    <div
      class="flex items-center justify-between border-b border-amber-200/50 bg-amber-100/50 px-4 py-2.5 dark:border-amber-500/30 dark:bg-amber-500/20"
    >
      <div class="flex items-center gap-2 text-amber-800 dark:text-amber-200">
        <span class="i-lucide-sticky-note size-4" />
        <span class="text-[13px] font-semibold">
          {{ t('CONVERSATION.VOICE_WIDGET.QUICK_NOTE') }}
        </span>
      </div>
      <button
        type="button"
        class="text-amber-700/60 transition-colors hover:text-amber-800 dark:text-amber-300/70 dark:hover:text-amber-200"
        :aria-label="t('CONVERSATION.VOICE_WIDGET.CLOSE_NOTE')"
        @click="emit('close')"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>

    <div class="flex flex-col gap-3 p-4">
      <textarea
        ref="textareaRef"
        :value="noteText"
        rows="5"
        class="reset-base no-margin min-h-[120px] w-full resize-none border-none bg-transparent text-[14px] text-amber-950 outline-none focus-visible:ring-0 dark:text-amber-50 placeholder:text-amber-800/40 dark:placeholder:text-amber-200/40"
        :placeholder="t('CONVERSATION.VOICE_WIDGET.NOTE_PLACEHOLDER')"
        @input="onInput"
      />
      <button
        type="button"
        class="h-8 rounded-lg px-4 text-sm font-medium shadow-sm transition-colors bg-amber-200 text-amber-950 hover:bg-amber-300 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-amber-500/80 dark:text-amber-50 dark:hover:bg-amber-500"
        :disabled="!noteText.trim()"
        @click="emit('save')"
      >
        {{ t('CONVERSATION.VOICE_WIDGET.SAVE_NOTE') }}
      </button>
    </div>
  </div>
</template>
