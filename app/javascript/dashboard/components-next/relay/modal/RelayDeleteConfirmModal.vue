<script setup>
import {
  DialogRoot,
  DialogPortal,
  DialogOverlay,
  DialogContent,
  DialogTitle,
  DialogDescription,
} from 'reka-ui';
import RelayButton from '../button/Button.vue';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_TITLE_CLASS,
  RELAY_MODAL_DESCRIPTION_CLASS,
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
  highlightName: {
    type: String,
    default: '',
  },
  descriptionPrefix: {
    type: String,
    default: '',
  },
  descriptionSuffix: {
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
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:show', 'close', 'confirm']);

const handleOpenChange = value => {
  emit('update:show', value);
  if (!value) emit('close');
};

const handleClose = () => {
  if (props.isLoading) return;
  emit('update:show', false);
  emit('close');
};

const handleConfirm = () => {
  if (props.isLoading) return;
  emit('confirm');
};
</script>

<template>
  <DialogRoot :open="show" @update:open="handleOpenChange">
    <DialogPortal>
      <DialogOverlay :class="RELAY_DIALOG_OVERLAY_CLASS" />
      <DialogContent
        class="fixed left-[50%] top-[50%] z-[200] flex w-full max-w-[420px] translate-x-[-50%] translate-y-[-50%] flex-col items-center gap-4 bg-background p-8 text-center shadow-xl duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 sm:rounded-2xl"
      >
        <div
          class="mb-1 flex size-14 items-center justify-center rounded-full bg-destructive/10 text-destructive shadow-sm"
        >
          <span class="i-lucide-trash-2 size-6 shrink-0" aria-hidden="true" />
        </div>

        <DialogTitle :class="RELAY_MODAL_TITLE_CLASS">
          {{ title }}
        </DialogTitle>

        <DialogDescription :class="RELAY_MODAL_DESCRIPTION_CLASS">
          <slot name="description">
            <template v-if="highlightName">
              {{ descriptionPrefix }}
              <strong class="text-foreground">{{ highlightName }}</strong>
              {{ descriptionSuffix }}
            </template>
            <template v-else>{{ description }}</template>
          </slot>
        </DialogDescription>

        <div class="mt-2 flex w-full justify-center gap-3">
          <RelayButton
            type="button"
            variant="ghost"
            class="h-9 flex-1 rounded-lg border border-border bg-background text-[14px] font-medium text-foreground shadow-sm hover:border-transparent hover:bg-muted/50 hover:text-foreground"
            :disabled="isLoading"
            @click="handleClose"
          >
            {{ cancelText }}
          </RelayButton>
          <RelayButton
            type="button"
            variant="destructive"
            class="h-9 flex-1 rounded-lg text-[14px] font-medium shadow-sm"
            :disabled="isLoading"
            @click="handleConfirm"
          >
            {{ confirmText }}
          </RelayButton>
        </div>
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>
