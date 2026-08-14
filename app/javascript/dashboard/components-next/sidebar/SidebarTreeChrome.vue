<script setup>
defineProps({
  /** branch = rounded elbow (+ optional spine to next row); dot = bullet only */
  mode: {
    type: String,
    default: 'branch',
    validator: value => ['branch', 'dot'].includes(value),
  },
  connectDown: { type: Boolean, default: false },
});
</script>

<template>
  <div
    v-if="mode === 'dot'"
    class="pointer-events-none absolute top-[14px] z-[3] size-1 -translate-y-1/2 rounded-full bg-sidebar-tree-dot ltr:left-[4px] rtl:right-[4px]"
    aria-hidden="true"
  />
  <template v-else>
    <div
      class="pointer-events-none absolute top-0 z-0 h-4 w-3 border-b border-l border-sidebar-border rounded-bl-[4px] ltr:left-0 rtl:right-0 rtl:rounded-bl-none rtl:rounded-br-[4px] rtl:border-l-0 rtl:border-r rtl:border-sidebar-border"
      aria-hidden="true"
    />
    <div
      v-if="connectDown"
      class="pointer-events-none absolute top-4 z-0 w-px bg-sidebar-border ltr:left-0 rtl:right-0 bottom-0"
      aria-hidden="true"
    />
  </template>
</template>
