<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  label: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="flex h-7 select-none items-center gap-2 text-[14px] font-normal capitalize text-sidebar-primary pointer-events-none"
  >
    <Icon v-if="icon" :icon="icon" class="size-3.5" />
    <span class="flex-grow leading-5">
      {{ label }}
    </span>
  </div>
</template>
