<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  option: {
    type: Object,
    default: () => {},
  },
  variant: {
    type: String,
    default: 'default',
  },
});
</script>

<template>
  <div
    class="flex items-center min-w-[12rem] min-h-8 px-2 py-1.5 rounded-sm cursor-pointer text-sm font-medium transition-colors"
    :class="
      option.key === 'delete'
        ? 'text-destructive hover:bg-destructive/10'
        : 'text-foreground hover:bg-muted'
    "
    role="button"
  >
    <fluent-icon
      v-if="variant === 'icon' && option.icon"
      :icon="option.icon"
      size="14"
      class="flex-shrink-0 opacity-70"
    />
    <span
      v-if="
        (variant === 'label' || variant === 'label-assigned') && option.color
      "
      class="label-pill flex-shrink-0"
      :style="{ backgroundColor: option.color }"
    />
    <Avatar
      v-if="variant === 'agent'"
      :name="option.label"
      :src="option.thumbnail"
      :status="option.status === 'online' ? option.status : null"
      :size="20"
      class="flex-shrink-0"
    />
    <p class="my-0 mx-2 text-xs flex-shrink-0 min-w-0 flex-1 truncate">
      {{ option.label }}
    </p>
    <Icon
      v-if="variant === 'label-assigned'"
      icon="i-lucide-check"
      class="flex-shrink-0 size-3.5 mr-1"
    />
  </div>
</template>

<style scoped lang="scss">
.agent-thumbnail {
  margin-top: 0 !important;
}

.label-pill {
  @apply w-4 h-4 rounded-full border border-border border-solid flex-shrink-0;
}
</style>
