<script setup>
import { ref, nextTick, onMounted } from 'vue';

const emit = defineEmits(['send']);
const message = ref('');
const textareaRef = ref(null);

const adjustHeight = () => {
  if (!textareaRef.value) return;

  // Reset height to auto to get the correct scrollHeight
  textareaRef.value.style.height = 'auto';
  // Set the height to the scrollHeight
  textareaRef.value.style.height = `${textareaRef.value.scrollHeight}px`;
};

const sendMessage = () => {
  if (message.value.trim()) {
    emit('send', message.value);
    message.value = '';
    // Reset textarea height after sending
    nextTick(() => {
      adjustHeight();
    });
  }
};

const handleInput = () => {
  nextTick(adjustHeight);
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
};

onMounted(() => {
  nextTick(adjustHeight);
});
</script>

<template>
  <form class="relative" @submit.prevent="sendMessage">
    <textarea
      ref="textareaRef"
      v-model="message"
      :placeholder="$t('CAPTAIN.COPILOT.SEND_MESSAGE')"
      class="reset-base mb-0 w-full min-h-9 max-h-[200px] resize-none overflow-hidden rounded-md border border-border/80 bg-background py-2.5 text-[14px] text-foreground shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 ltr:pl-4 ltr:pr-12 rtl:pl-12 rtl:pr-4"
      rows="1"
      @input="handleInput"
      @keydown.enter.exact="handleEnterKey"
    />
    <button
      class="absolute top-1/2 flex size-9 -translate-y-1/2 items-center justify-center text-muted-foreground transition-colors hover:text-primary ltr:right-1 rtl:left-1"
      type="submit"
    >
      <span class="i-lucide-arrow-up size-4" />
    </button>
  </form>
</template>
