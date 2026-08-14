<script setup>
import { computed, ref, onMounted, nextTick, getCurrentInstance } from 'vue';
const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  type: { type: String, default: 'text' },
  customInputClass: { type: [String, Object, Array], default: '' },
  placeholder: { type: String, default: '' },
  label: { type: String, default: '' },
  id: { type: String, default: '' },
  size: {
    type: String,
    default: 'md',
    validator: value => ['sm', 'md'].includes(value),
  },
  message: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
  min: { type: String, default: '' },
  max: { type: String, default: '' },
  autofocus: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:modelValue',
  'blur',
  'input',
  'focus',
  'enter',
]);

// Generate a unique ID per component instance when `id` prop is not provided.
const { uid } = getCurrentInstance();
const uniqueId = computed(() => props.id || `input-${uid}`);

const isFocused = ref(false);
const inputRef = ref(null);

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

const inputOutlineClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'outline-destructive dark:outline-destructive hover:outline-destructive dark:hover:outline-destructive disabled:outline-destructive dark:disabled:outline-destructive';
    default:
      return 'outline-border dark:outline-border hover:outline-border dark:hover:outline-border disabled:outline-border dark:disabled:outline-border focus:outline-primary dark:focus:outline-primary';
  }
});

const handleInput = event => {
  let value = event.target.value;
  // Convert to number if type is number and value is not empty
  if (props.type === 'number' && value !== '') {
    value = Number(value);
  }
  emit('update:modelValue', value);
  emit('input', event);
};

const handleFocus = event => {
  emit('focus', event);
  isFocused.value = true;
};

const sizeClass = computed(() => {
  switch (props.size) {
    case 'sm':
      return 'h-8 !px-3 !py-2';
    case 'md':
      return 'h-9 !px-3 !py-1';
    default:
      return 'h-9 !px-3 !py-1';
  }
});

const handleBlur = event => {
  emit('blur', event);
  isFocused.value = false;
};

const handleEnter = event => {
  emit('enter', event);
};

onMounted(() => {
  if (props.autofocus) {
    nextTick(() => {
      inputRef.value?.focus();
    });
  }
});
</script>

<template>
  <div class="relative flex flex-col min-w-0 gap-1.5">
    <label
      v-if="label"
      :for="uniqueId"
      class="text-heading-3 text-foreground text-[13.5px] font-medium"
    >
      {{ label }}
    </label>
    <!-- Added prefix slot to allow adding icons to the input -->
    <slot name="prefix" />
    <input
      :id="uniqueId"
      v-bind="$attrs"
      ref="inputRef"
      :value="modelValue"
      :class="[ customInputClass, inputOutlineClass, sizeClass, { error: messageType === 'error',
          focus: isFocused,
        },
      ]"
      :type="type"
      :placeholder="placeholder"
      :disabled="disabled"
      :min="['date', 'datetime-local', 'time'].includes(type) ? min : undefined"
      :max="
        ['date', 'datetime-local', 'time', 'number'].includes(type)
          ? max
          : undefined
      "
      class="block w-full reset-base text-sm !mb-0 outline outline-1 border-none border-0 outline-offset-[-1px] rounded-lg bg-black/10 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground dark:placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 text-foreground transition-all duration-500 ease-in-out [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
      @keyup.enter="handleEnter"
    />
    <p
      v-if="message"
      class="min-w-0 mt-1 mb-0 text-label-small truncate transition-all duration-500 ease-in-out"
      :class="messageClass"
    >
      {{ message }}
    </p>
  </div>
</template>
