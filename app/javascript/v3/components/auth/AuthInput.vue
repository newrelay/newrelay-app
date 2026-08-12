<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  label: { type: String, default: '' },
  type: { type: String, default: 'text' },
  icon: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  name: { type: String, required: true },
  hasError: { type: Boolean, default: false },
  errorMessage: { type: String, default: '' },
  size: {
    type: String,
    default: 'lg',
    validator: value => ['lg', 'md'].includes(value),
  },
});

const emit = defineEmits(['blur', 'focus', 'input']);

defineOptions({ inheritAttrs: false });

const model = defineModel({ type: String, default: '' });

const { t } = useI18n();

const [isPasswordVisible, togglePasswordVisibility] = useToggle();
const isPasswordField = computed(() => props.type === 'password');
const inputType = computed(() =>
  isPasswordField.value && isPasswordVisible.value ? 'text' : props.type
);

const isLg = computed(() => props.size === 'lg');
const iconSizeClass = computed(() => (isLg.value ? 'size-[18px]' : 'size-4'));
const inputPaddingClasses = computed(() => {
  let left = 'pl-4';
  if (props.icon) left = isLg.value ? 'pl-11' : 'pl-9';

  let right = isLg.value ? 'pr-4' : 'pr-3';
  if (isPasswordField.value) right = isLg.value ? 'pr-11' : 'pr-10';

  return [isLg.value ? 'h-11' : 'h-10', left, right];
});
</script>

<template>
  <div class="flex flex-col gap-1.5 text-left w-full">
    <div
      v-if="label || $slots.rightOfLabel"
      class="flex items-center justify-between"
    >
      <label :for="name" class="text-[13.5px] font-medium text-foreground">
        {{ label }}
      </label>
      <slot name="rightOfLabel" />
    </div>
    <div class="relative">
      <div
        v-if="icon"
        class="absolute inset-y-0 left-0 flex items-center pointer-events-none"
        :class="isLg ? 'pl-3.5' : 'pl-3'"
      >
        <span
          :class="[icon, iconSizeClass]"
          class="text-muted-foreground block"
        />
      </div>
      <input
        :id="name"
        v-model="model"
        v-bind="$attrs"
        :name="name"
        :type="inputType"
        :placeholder="placeholder"
        class="w-full rounded-md border bg-background text-[14px] shadow-sm outline-none transition-shadow text-foreground placeholder:text-muted-foreground/60 focus-visible:ring-1"
        :class="[
          ...inputPaddingClasses,
          hasError
            ? 'border-destructive focus-visible:ring-destructive/30'
            : 'border-border focus-visible:ring-primary/30',
        ]"
        @blur="emit('blur')"
        @focus="emit('focus')"
        @input="emit('input')"
      />
      <button
        v-if="isPasswordField"
        type="button"
        class="absolute inset-y-0 right-0 flex items-center text-muted-foreground hover:text-foreground transition-colors outline-none cursor-pointer z-10"
        :class="isLg ? 'pr-3.5' : 'pr-3'"
        :aria-label="
          isPasswordVisible
            ? t('LOGIN.PASSWORD.HIDE')
            : t('LOGIN.PASSWORD.SHOW')
        "
        :aria-pressed="isPasswordVisible"
        @click.prevent="togglePasswordVisibility()"
      >
        <span
          :class="[
            isPasswordVisible ? 'i-lucide-eye-off' : 'i-lucide-eye',
            iconSizeClass,
          ]"
          class="block"
        />
      </button>
    </div>
    <p v-if="hasError && errorMessage" class="text-[13px] text-destructive">
      {{ errorMessage }}
    </p>
  </div>
</template>
