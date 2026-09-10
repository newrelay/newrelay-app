<script setup>
import { ref, computed, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import RelayButton from '../button/Button.vue';
import RelayInput from '../input/Input.vue';
import RelayModalHeader from './RelayModalHeader.vue';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
  RELAY_MODAL_FORM_FOOTER_CLASS,
  RELAY_MODAL_INPUT_CLASS,
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
  message: {
    type: String,
    default: '',
  },
  messageValue: {
    type: String,
    default: '',
  },
  confirmText: {
    type: String,
    default: '',
  },
  cancelText: {
    type: String,
    default: '',
  },
  confirmValue: {
    type: String,
    default: '',
  },
  confirmPlaceholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close', 'confirm']);

useEventListener(document, 'keydown', e => {
  if (props.show && e.code === 'Escape') {
    emit('close');
    e.stopPropagation();
  }
});

const typedConfirmValue = ref('');

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      typedConfirmValue.value = '';
    }
  }
);

const isConfirmDisabled = computed(() => {
  if (!props.confirmValue) return false;
  return typedConfirmValue.value !== props.confirmValue;
});

const handleConfirm = () => {
  if (isConfirmDisabled.value) return;
  emit('confirm');
};

const descriptionText = computed(() =>
  props.messageValue ? `${props.message}${props.messageValue}` : props.message
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
        class="font-geist mx-4 flex max-h-[90vh] w-full max-w-[500px] flex-col overflow-hidden rounded-xl border border-border/80 bg-background shadow-xl"
        @click.stop
      >
        <RelayModalHeader
          :title="title"
          :description="descriptionText"
          @close="emit('close')"
        />

        <div class="space-y-5 pb-2 pt-0" :class="[RELAY_MODAL_BODY_CLASS]">
          <div v-if="confirmValue" class="flex flex-col gap-1.5">
            <RelayInput
              v-model="typedConfirmValue"
              type="text"
              :placeholder="confirmPlaceholder"
              :class-name="RELAY_MODAL_INPUT_CLASS"
            />
          </div>
        </div>

        <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
          <RelayButton
            type="button"
            variant="outline"
            size="lg"
            @click="emit('close')"
          >
            {{ cancelText }}
          </RelayButton>
          <RelayButton
            type="button"
            variant="destructive"
            size="lg"
            :disabled="isConfirmDisabled"
            @click="handleConfirm"
          >
            {{ confirmText }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
