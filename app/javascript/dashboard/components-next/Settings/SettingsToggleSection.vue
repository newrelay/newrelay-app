<script setup>
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

defineProps({
  header: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  compact: {
    type: Boolean,
    default: false,
  },
  hideToggle: {
    type: Boolean,
    default: false,
  },
});

const modelValue = defineModel({ type: Boolean, default: false });
</script>

<template>
  <div
    class="flex flex-col items-start border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden [interpolate-size:allow-keywords]"
  >
    <div class="flex flex-col gap-1 items-start w-full px-4 py-3">
      <div class="flex items-center gap-3 w-full justify-between">
        <span class="text-heading-3 text-foreground">
          {{ header }}
        </span>
        <template v-if="hideToggle">
          <slot name="hiddenToggle">
            <div class="size-2" />
          </slot>
        </template>
        <ToggleSwitch v-else v-model="modelValue" />
      </div>
      <span v-if="description" class="text-body-main text-muted-foreground">
        {{ description }}
      </span>
    </div>
    <div
      v-if="$slots.editor"
      class="w-full border-t border-border"
      :class="{ 'p-0': compact, 'px-4 pb-4 pt-2': !compact }"
    >
      <slot name="editor" />
    </div>
  </div>
</template>
