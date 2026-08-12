<script setup>
import { computed, inject } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  value: { type: String, required: true },
});

const activeValue = inject('relayTabsValue');
const isActive = computed(() => activeValue?.value === props.value);
</script>

<template>
  <div
    v-show="isActive"
    role="tabpanel"
    :class="
      cn(
        'mt-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring'
      )
    "
  >
    <slot />
  </div>
</template>
