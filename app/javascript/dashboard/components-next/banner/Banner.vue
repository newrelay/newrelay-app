<script setup>
import { computed } from 'vue';

const props = defineProps({
  color: {
    type: String,
    default: 'slate',
    validator: value =>
      ['blue', 'ruby', 'amber', 'slate', 'teal'].includes(value),
  },
  actionLabel: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['action']);

const bannerClass = computed(() => {
  const classMap = {
    slate:
      'bg-muted border-muted text-muted-foreground [&_.link]:text-muted-foreground',
    amber:
      'bg-warning/10 border-warning/20 text-warning [&_.link]:text-warning',
    teal: 'bg-success/10 border-success/20 text-success [&_.link]:text-success',
    ruby: 'bg-destructive/10 border-destructive/20 text-destructive [&_.link]:text-destructive',
    blue: 'bg-primary/10 border-primary/20 text-primary [&_.link]:text-primary',
  };

  return classMap[props.color];
});

const buttonClass = computed(() => {
  const classMap = {
    slate: 'bg-muted hover:bg-accent text-muted-foreground',
    amber: 'bg-warning/20 hover:bg-warning/20 text-warning',
    teal: 'bg-success/20 hover:bg-success/20 text-success',
    ruby: 'bg-destructive/20 hover:bg-destructive/20 text-destructive',
    blue: 'bg-primary/20 hover:bg-primary/20 text-primary',
  };

  return classMap[props.color];
});

const triggerAction = () => {
  emit('action');
};
</script>

<template>
  <div
    class="text-sm rounded-xl flex items-center justify-between gap-2 border"
    :class="[
      bannerClass,
      {
        'py-2 px-3': !actionLabel,
        'pl-3 p-2': actionLabel,
      },
    ]"
  >
    <div>
      <slot />
    </div>
    <div>
      <button
        v-if="actionLabel"
        class="px-3 py-1 w-auto grid place-content-center rounded-lg"
        :class="buttonClass"
        @click="triggerAction"
      >
        {{ actionLabel }}
      </button>
    </div>
  </div>
</template>
