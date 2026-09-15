<script setup>
import { computed, ref, watch, useSlots } from 'vue';

import WootEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorKey: { type: String, default: '' },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  focusOnMount: { type: Boolean, default: false },
  maxLength: { type: Number, default: 200 },
  showCharacterCount: { type: Boolean, default: true },
  disabled: { type: Boolean, default: false },
  message: { type: String, default: '' },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
  enableVariables: { type: Boolean, default: false },
  enableCannedResponses: { type: Boolean, default: true },
  enableCaptainTools: { type: Boolean, default: false },
  signature: { type: String, default: '' },
  allowSignature: { type: Boolean, default: false },
  sendWithSignature: { type: Boolean, default: false },
  channelType: { type: String, default: '' },
  medium: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue', 'executeCopilotAction', 'blur']);

const slots = useSlots();

const isFocused = ref(false);
const isHovered = ref(false);

const characterCount = computed(() => props.modelValue.length);

const messageClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'text-destructive dark:text-destructive';
    case 'success':
      return 'text-success dark:text-success';
    default:
      return 'text-muted-foreground dark:text-muted-foreground';
  }
});

const handleInput = value => {
  if (!props.disabled) {
    emit('update:modelValue', value);
  }
};

const handleFocus = () => {
  if (!props.disabled) {
    isFocused.value = true;
  }
};

const handleBlur = () => {
  if (!props.disabled) {
    isFocused.value = false;
    emit('blur');
  }
};

watch(
  () => props.modelValue,
  newValue => {
    if (props.maxLength && props.showCharacterCount && !slots.actions) {
      if (characterCount.value >= props.maxLength) {
        emit('update:modelValue', newValue.slice(0, props.maxLength));
      }
    }
  }
);
</script>

<template>
  <div class="flex flex-col min-w-0 gap-1.5">
    <label v-if="label" class="text-foreground text-[13.5px] font-medium">
      {{ label }}
    </label>
    <div
      class="flex flex-col w-full gap-2 px-3 py-3 transition-colors duration-150 border rounded-lg editor-wrapper"
      :class="[
        {
          'cursor-not-allowed opacity-50 pointer-events-none !bg-background disabled:border-border dark:disabled:border-border':
            disabled,
          'is-hovered !bg-accent': isHovered && !disabled,
          'bg-background': !isHovered || disabled,
          'border-primary dark:border-primary': isFocused,
          'hover:border-border dark:hover:border-border border-border dark:border-border':
            !isFocused && messageType !== 'error',
          'border-destructive dark:border-destructive hover:border-destructive dark:hover:border-destructive':
            messageType === 'error' && !isFocused,
        },
      ]"
      @mouseenter="isHovered = !disabled"
      @mouseleave="isHovered = false"
    >
      <WootEditor
        :editor-id="editorKey"
        :model-value="modelValue"
        :placeholder="placeholder"
        :focus-on-mount="focusOnMount"
        :disabled="disabled"
        :enable-variables="enableVariables"
        :enable-canned-responses="enableCannedResponses"
        :enable-captain-tools="enableCaptainTools"
        :signature="signature"
        :allow-signature="allowSignature"
        :send-with-signature="sendWithSignature"
        :channel-type="channelType"
        :medium="medium"
        @input="handleInput"
        @focus="handleFocus"
        @blur="handleBlur"
        @execute-copilot-action="
          (...args) => emit('executeCopilotAction', ...args)
        "
      />
      <div
        v-if="showCharacterCount || slots.actions"
        class="flex items-center justify-end h-4 ltr:right-3 rtl:left-3"
      >
        <span
          v-if="showCharacterCount && !slots.actions"
          class="text-xs tabular-nums text-muted-foreground"
        >
          {{ characterCount }} / {{ maxLength }}
        </span>
        <slot v-else name="actions" />
      </div>
    </div>
    <p
      v-if="message"
      class="min-w-0 mt-1 mb-0 text-xs truncate transition-all duration-500 ease-in-out"
      :class="messageClass"
    >
      {{ message }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.editor-wrapper {
  // ProseMirror sets `background: white` on the menubar/editor; beat that so
  // rest stays white via the wrapper and hover is --accent (#EDF0FF).
  :deep(.relative.w-full),
  :deep(.ProseMirror-menubar-wrapper),
  :deep(.ProseMirror-menubar),
  :deep(.ProseMirror) {
    background: transparent !important;
  }

  &.is-hovered,
  &.is-hovered :deep(.relative.w-full),
  &.is-hovered :deep(.ProseMirror-menubar-wrapper),
  &.is-hovered :deep(.ProseMirror-menubar),
  &.is-hovered :deep(.ProseMirror) {
    background: transparent !important;
  }

  :deep(.ProseMirror-menubar-wrapper) {
    .ProseMirror.ProseMirror-relay-style {
      p {
        @apply first:mt-0 !important;
      }

      .empty-node {
        @apply m-0 !important;

        &::before {
          @apply text-muted-foreground dark:text-muted-foreground;
        }
      }
    }

    .ProseMirror-menubar {
      width: fit-content !important;
      position: relative !important;
      top: unset !important;
      @apply ltr:left-[-0.188rem] rtl:right-[-0.188rem] !important;
    }
  }
}
</style>
