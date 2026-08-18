<script setup>
import { computed } from 'vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import RelayModalHeader from './RelayModalHeader.vue';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from './constants';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  size: {
    type: String,
    default: 'md',
    validator: value => ['md', 'lg'].includes(value),
  },
});

const emit = defineEmits(['close']);

const maxWidthClass = computed(() =>
  props.size === 'lg' ? 'max-w-[550px]' : 'max-w-[500px]'
);
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="show"
      class="flex items-center justify-center bg-background/80 p-4 backdrop-blur-[8px]"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="emit('close')"
    >
      <div
        data-relay
        class="font-geist mx-4 flex max-h-[90vh] w-full flex-col overflow-hidden rounded-xl border border-border/80 bg-background shadow-xl"
        :class="maxWidthClass"
        @click.stop
      >
        <RelayModalHeader
          :title="title"
          :description="description"
          @close="emit('close')"
        />
        <div :class="RELAY_MODAL_BODY_CLASS">
          <slot />
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
