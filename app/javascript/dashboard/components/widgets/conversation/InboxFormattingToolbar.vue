<script>
export default {
  name: 'InboxFormattingToolbar',
  emits: ['toggleMark'],
};
</script>

<template>
  <div
    class="flex items-center gap-0.5 border-b border-border bg-muted/5 px-3 py-2"
  >
    <button
      type="button"
      :title="$t('CONVERSATION.REPLYBOX.FORMAT_BOLD')"
      class="flex size-7 items-center justify-center rounded text-sm font-bold text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click="$emit('toggleMark', 'strong')"
    >
      <span class="i-lucide-bold size-3.5" />
    </button>
    <button
      type="button"
      :title="$t('CONVERSATION.REPLYBOX.FORMAT_ITALIC')"
      class="flex size-7 items-center justify-center rounded text-sm font-medium italic text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click="$emit('toggleMark', 'em')"
    >
      <span class="i-lucide-italic size-3.5" />
    </button>
    <button
      type="button"
      :title="$t('CONVERSATION.REPLYBOX.FORMAT_UNDERLINE')"
      class="flex size-7 items-center justify-center rounded text-sm font-medium underline text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click="$emit('toggleMark', 'underline')"
    >
      <span class="i-lucide-underline size-3.5" />
    </button>
  </div>
</template>
