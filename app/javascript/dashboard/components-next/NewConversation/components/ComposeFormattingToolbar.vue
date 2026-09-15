<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['format']);
const { t } = useI18n();
const i18nPrefix = 'COMPOSE_NEW_CONVERSATION.FORM.MODAL_TOOLBAR';

const tools = [
  { command: 'strong', icon: 'i-lucide-bold', titleKey: 'BOLD' },
  { command: 'em', icon: 'i-lucide-italic', titleKey: 'ITALIC' },
  { command: 'code', icon: 'i-lucide-code', titleKey: 'CODE' },
  { command: 'link', icon: 'i-lucide-link-2', titleKey: 'LINK' },
  {
    command: 'strike',
    icon: 'i-lucide-strikethrough',
    titleKey: 'STRIKETHROUGH',
  },
  { command: 'bulletList', icon: 'i-lucide-list', titleKey: 'BULLET_LIST' },
  {
    command: 'orderedList',
    icon: 'i-lucide-list-ordered',
    titleKey: 'ORDERED_LIST',
  },
  { command: 'imageUpload', icon: 'i-lucide-image', titleKey: 'IMAGE' },
  { command: 'undo', icon: 'i-lucide-undo', titleKey: 'UNDO' },
  { command: 'redo', icon: 'i-lucide-redo', titleKey: 'REDO' },
];
</script>

<template>
  <div
    class="flex items-center gap-2 border-b border-border/50 bg-background px-6 py-3"
  >
    <button
      v-for="tool in tools"
      :key="tool.command"
      type="button"
      class="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      :title="t(`${i18nPrefix}.${tool.titleKey}`)"
      @click="emit('format', tool.command)"
    >
      <span class="size-4" :class="[tool.icon]" />
    </button>
  </div>
</template>
