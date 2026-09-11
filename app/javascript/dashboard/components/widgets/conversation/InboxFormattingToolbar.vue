<script setup>
defineEmits(['toggleMark']);
</script>

<template>
  <div
    class="flex w-full items-center gap-0.5 border-b border-border bg-muted/5 px-3 py-2"
  >
    <button
      type="button"
      :title="$t('CONVERSATION.REPLYBOX.FORMAT_BOLD')"
      class="flex size-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click="$emit('toggleMark', 'strong')"
    >
      <span class="i-lucide-bold size-4" />
    </button>
    <button
      type="button"
      :title="$t('CONVERSATION.REPLYBOX.FORMAT_ITALIC')"
      class="flex size-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click="$emit('toggleMark', 'em')"
    >
      <span class="i-lucide-italic size-4" />
    </button>
    <button
      type="button"
      :title="$t('CONVERSATION.REPLYBOX.FORMAT_UNDERLINE')"
      class="flex size-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      @click="$emit('toggleMark', 'underline')"
    >
      <span class="i-lucide-underline size-4" />
    </button>
  </div>
</template>
