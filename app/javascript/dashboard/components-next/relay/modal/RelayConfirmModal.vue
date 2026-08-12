<script setup>
import { ref, computed, watch } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import RelayButton from '../button/Button.vue';
import RelayInput from '../input/Input.vue';

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
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-center justify-center bg-n-alpha-black2 backdrop-blur-[4px]"
      @click.self="emit('close')"
    >
      <div
        class="mx-4 flex w-full max-w-[500px] flex-col overflow-hidden rounded-[10px] border border-border/40 bg-card shadow-xl"
        @click.stop
      >
        <div class="px-7 py-6 pb-4">
          <div class="flex items-start justify-between">
            <div class="space-y-1.5">
              <h2 class="text-base font-medium text-foreground">
                {{ title }}
              </h2>
              <p class="pr-6 text-[13px] leading-relaxed text-muted-foreground">
                {{ message }}<span v-if="messageValue">{{ messageValue }}</span>
              </p>
            </div>
            <button
              type="button"
              class="-mr-2 shrink-0 rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              @click="emit('close')"
            >
              <Icon icon="i-lucide-x" class="size-4" />
            </button>
          </div>
        </div>

        <div class="space-y-5 px-7 pb-2">
          <div v-if="confirmValue" class="flex flex-col gap-1.5">
            <RelayInput
              v-model="typedConfirmValue"
              type="text"
              :placeholder="confirmPlaceholder"
              class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
        </div>

        <div class="flex justify-end gap-3 border-t border-border/40 px-7 py-6">
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
            class="h-9 px-5 text-[13px] font-medium shadow-sm bg-destructive text-destructive-foreground hover:bg-destructive/90"
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
