<script setup>
import { computed } from 'vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'branch',
    validator: value => ['branch', 'dot'].includes(value),
  },
  /** none | extend | fixed-36 | fixed-7 */
  spine: {
    type: String,
    default: 'none',
    validator: value =>
      ['none', 'extend', 'fixed-36', 'fixed-7'].includes(value),
  },
  /** md = h-4 elbow, sm = h-[14px] elbow */
  elbow: {
    type: String,
    default: 'md',
    validator: value => ['md', 'sm'].includes(value),
  },
});

const spineClass = computed(() => {
  switch (props.spine) {
    case 'extend':
      return '-bottom-[2px]';
    case 'fixed-36':
      return 'h-[36px]';
    case 'fixed-7':
      return 'h-7';
    default:
      return '';
  }
});

const elbowClass = computed(() => (props.elbow === 'md' ? 'h-4' : 'h-[14px]'));
</script>

<template>
  <div
    v-if="mode === 'dot'"
    class="pointer-events-none absolute top-[14px] size-1 -translate-y-1/2 rounded-full bg-sidebar-tree-dot ltr:left-[4px] rtl:right-[4px]"
    aria-hidden="true"
  />
  <template v-else>
    <div
      v-if="spine !== 'none'"
      class="pointer-events-none absolute top-0 z-0 w-px bg-sidebar-border ltr:left-0 rtl:right-0"
      :class="spineClass"
      aria-hidden="true"
    />
    <div
      class="pointer-events-none absolute top-0 z-0 w-3 rounded-bl-[4px] border-b border-l border-sidebar-border ltr:left-0 rtl:right-0 rtl:rounded-bl-none rtl:rounded-br-[4px] rtl:border-l-0 rtl:border-r rtl:border-sidebar-border"
      :class="elbowClass"
      aria-hidden="true"
    />
  </template>
</template>
