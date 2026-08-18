<script setup>
import { ref, computed, watch } from 'vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import RelayButton from '../button/Button.vue';
import RelayInput from '../input/Input.vue';
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
              class-name="h-9 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
        </div>

        <div
          class="flex shrink-0 justify-end gap-3 border-t border-border/80 px-6 py-5"
        >
          <RelayButton
            type="button"
            variant="outline"
            class="h-9 border-border bg-muted px-5 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/80"
            @click="emit('close')"
          >
            {{ cancelText }}
          </RelayButton>
          <RelayButton
            type="button"
            class="h-9 bg-destructive px-5 text-[13px] font-medium text-destructive-foreground shadow-sm hover:bg-destructive/90"
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
