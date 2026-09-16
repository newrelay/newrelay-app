<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  option: {
    type: Object,
    default: () => ({}),
  },
  variant: {
    type: String,
    default: 'default',
  },
});

const ICON_MAP = {
  mail: 'i-lucide-mail',
  'mail-unread': 'i-lucide-mail',
  checkmark: 'i-lucide-check',
  'arrow-redo': 'i-lucide-rotate-ccw',
  'arrow-reply': 'i-lucide-reply',
  'book-clock': 'i-lucide-hourglass',
  snooze: 'i-lucide-alarm-clock',
  warning: 'i-lucide-triangle-alert',
  tag: 'i-lucide-tag',
  'person-add': 'i-lucide-user-plus',
  'people-team-add': 'i-lucide-users',
  delete: 'i-lucide-trash-2',
  open: 'i-lucide-external-link',
  copy: 'i-lucide-copy',
  clipboard: 'i-lucide-copy',
  translate: 'i-lucide-languages',
  link: 'i-lucide-link',
  'comment-add': 'i-lucide-message-square-plus',
};

const isDestructive = computed(() => props.option.key === 'delete');

const iconClass = computed(() => {
  if (props.variant !== 'icon' || !props.option.icon) return null;
  if (props.option.icon.startsWith('i-')) return props.option.icon;
  return ICON_MAP[props.option.icon] || null;
});

const itemClass = computed(() => {
  if (isDestructive.value) {
    return 'text-destructive hover:bg-destructive/10 hover:text-destructive focus:bg-destructive/10 focus:text-destructive';
  }
  return 'text-foreground hover:bg-accent hover:text-accent-foreground';
});
</script>

<template>
  <button
    type="button"
    class="flex w-full min-w-0 cursor-default items-center gap-2 rounded-sm p-0 !px-2 !py-1.5 text-left text-sm outline-none transition-colors"
    :class="itemClass"
  >
    <span
      v-if="iconClass"
      :class="[
        iconClass,
        isDestructive ? 'text-destructive' : 'text-muted-foreground',
      ]"
      class="size-4 shrink-0"
      aria-hidden="true"
    />

    <span
      v-if="
        (variant === 'label' || variant === 'label-assigned') && option.color
      "
      class="size-4 shrink-0 rounded-full border border-border"
      :style="{ backgroundColor: option.color }"
    />

    <Avatar
      v-if="variant === 'agent'"
      :name="option.label"
      :src="option.thumbnail"
      :status="option.status === 'online' ? option.status : null"
      :size="20"
      class="shrink-0"
    />

    <span class="min-w-0 flex-1 truncate">{{ option.label }}</span>

    <Icon
      v-if="variant === 'label-assigned'"
      icon="i-lucide-check"
      class="size-3.5 shrink-0"
    />
  </button>
</template>
