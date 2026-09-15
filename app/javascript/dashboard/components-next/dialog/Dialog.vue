<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';
import RelayButton from 'dashboard/components-next/relay/button/Button.vue';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
  RELAY_MODAL_FORM_FOOTER_CLASS,
  RELAY_NATIVE_DIALOG_BACKDROP_CLASS,
} from 'dashboard/components-next/relay/modal/constants';

const props = defineProps({
  type: {
    type: String,
    default: 'edit',
    validator: value => ['alert', 'edit'].includes(value),
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  cancelButtonLabel: {
    type: String,
    default: '',
  },
  confirmButtonLabel: {
    type: String,
    default: '',
  },
  disableConfirmButton: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  showCancelButton: {
    type: Boolean,
    default: true,
  },
  showConfirmButton: {
    type: Boolean,
    default: true,
  },
  overflowYAuto: {
    type: Boolean,
    default: false,
  },
  flush: {
    type: Boolean,
    default: false,
  },
  width: {
    type: String,
    default: 'lg',
    validator: value => ['3xl', '2xl', 'xl', 'lg', 'md', 'sm'].includes(value),
  },
  position: {
    type: String,
    default: 'center',
    validator: value => ['center', 'top'].includes(value),
  },
});

const emit = defineEmits(['confirm', 'close']);

const { t } = useI18n();

const dialogRef = ref(null);
const dialogContentRef = ref(null);
const isOpen = ref(false);

const maxWidthClass = computed(() => {
  const classesMap = {
    '3xl': 'max-w-3xl',
    '2xl': 'max-w-2xl',
    xl: 'max-w-xl',
    lg: 'max-w-lg',
    md: 'max-w-md',
    sm: 'max-w-sm',
  };

  return classesMap[props.width] ?? 'max-w-md';
});

const positionClass = computed(() =>
  props.position === 'top' ? 'mt-[clamp(2rem,5vh,5rem)] mb-auto' : ''
);

const open = () => {
  isOpen.value = true;
  dialogRef.value?.showModal();
};

const close = () => {
  // Idempotent: parents often call close() from @close; without this guard
  // that re-enters forever (Maximum call stack size exceeded).
  if (!isOpen.value) return;
  isOpen.value = false;
  emit('close');
  dialogRef.value?.close();
};

// Only close if the close event originated from this dialog,
// not from a child dialog (e.g. ProseMirror prompt) bubbling up.
const handleDialogClose = e => e.target === dialogRef.value && close();

// Only close on click-outside if this dialog is the topmost one.
// If another dialog (e.g. ProseMirror prompt) is open on top, ignore.
const handleClickOutside = () => {
  const dialogs = document.querySelectorAll('dialog[open]');
  if (dialogs[dialogs.length - 1] === dialogRef.value) close();
};

const confirm = () => {
  emit('confirm');
};

defineExpose({ open, close });
</script>

<template>
  <TeleportWithDirection to="body">
    <dialog
      ref="dialogRef"
      class="m-0 w-full max-w-none border-0 bg-transparent p-4 shadow-none outline-none open:fixed open:inset-0 open:flex open:justify-center"
      :class="[
        RELAY_NATIVE_DIALOG_BACKDROP_CLASS,
        position === 'top' ? 'open:items-start' : 'open:items-center',
        overflowYAuto ? 'overflow-y-auto' : 'overflow-visible',
        positionClass,
      ]"
      @close.prevent="handleDialogClose"
    >
      <div
        v-if="isOpen"
        data-relay-overlay
        data-state="open"
        aria-hidden="true"
        :class="RELAY_DIALOG_OVERLAY_CLASS"
        @click="close"
      />
      <OnClickOutside @trigger="handleClickOutside">
        <form
          ref="dialogContentRef"
          data-relay
          class="relative z-[201] flex h-auto w-full flex-col overflow-visible rounded-xl border border-border bg-background text-start align-middle shadow-lg duration-200"
          :class="maxWidthClass"
          @submit.prevent="confirm"
          @click.stop
        >
          <RelayModalHeader
            v-if="title || description || $slots.description"
            :title="title"
            :description="description"
            @close="close"
          >
            <template v-if="$slots.description" #description>
              <slot name="description" />
            </template>
          </RelayModalHeader>
          <div
            class="!overflow-visible"
            :class="[
              flush ? 'p-6' : RELAY_MODAL_BODY_CLASS,
              !flush && (showCancelButton || showConfirmButton) ? 'pb-0' : '',
            ]"
          >
            <slot v-if="isOpen" />
          </div>
          <!-- Dialog content will be injected here -->
          <slot name="footer">
            <div
              v-if="showCancelButton || showConfirmButton"
              :class="RELAY_MODAL_FORM_FOOTER_CLASS"
            >
              <RelayButton
                v-if="showCancelButton"
                type="button"
                variant="outline"
                size="lg"
                @click="close"
              >
                {{ cancelButtonLabel || t('DIALOG.BUTTONS.CANCEL') }}
              </RelayButton>
              <RelayButton
                v-if="showConfirmButton"
                type="submit"
                size="lg"
                :variant="type === 'alert' ? 'destructive' : 'default'"
                :disabled="disableConfirmButton || isLoading"
              >
                {{ confirmButtonLabel || t('DIALOG.BUTTONS.CONFIRM') }}
              </RelayButton>
            </div>
          </slot>
        </form>
      </OnClickOutside>
    </dialog>
  </TeleportWithDirection>
</template>
