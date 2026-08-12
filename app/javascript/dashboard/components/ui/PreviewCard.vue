<script>
export default {
  props: {
    heading: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    active: {
      type: Boolean,
      default: false,
    },
    src: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col min-w-[15rem] max-h-[21.25rem] max-w-[23.75rem] rounded-md border border-solid"
    :class="{
      'bg-primary/5 dark:bg-secondary border-primary/20': active,
      'border-border': !active,
    }"
  >
    <div
      class="flex justify-between items-center rounded-t-md px-2 w-full h-10 border-b border-solid"
      :class="{
        'bg-primary/10 border-primary/20': active,
        'bg-muted border-border': !active,
      }"
    >
      <div class="flex items-center p-1 text-sm font-medium">{{ heading }}</div>
      <fluent-icon
        v-if="active"
        icon="checkmark-circle"
        type="solid"
        size="24"
        class="text-primary"
      />
    </div>
    <div
      class="text-muted-foreground text-xs leading-[1.4] px-3 pt-3 pb-0 text-start"
    >
      {{ content }}
    </div>
    <div v-if="src" class="p-3">
      <img
        :src="src"
        class="border rounded-md"
        :class="active ? 'border-primary' : 'border-border'"
      />
    </div>
    <slot v-else />
  </div>
</template>
