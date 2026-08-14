<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['change']);

const { t } = useI18n();

const modelValue = defineModel({
  type: Boolean,
  default: false,
});

const updateValue = () => {
  modelValue.value = !modelValue.value;
  emit('change', !modelValue.value);
};
</script>

<template>
  <button
    type="button"
    class="group relative h-5 w-9 flex-shrink-0 select-none rounded-full border-2 border-transparent shadow-xs focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-muted focus:ring-offset-2 transition-colors duration-200 ease-in-out"
    :class="modelValue ? 'bg-primary' : 'bg-input'"
    role="switch"
    :aria-checked="modelValue"
    @click="updateValue"
  >
    <span class="sr-only">{{ t('SWITCH.TOGGLE') }}</span>
    <span
      class="absolute top-1/2 ltr:left-0.5 rtl:right-0.5 -translate-y-1/2 transition-transform duration-[350ms] ease-[cubic-bezier(0.34,1.56,0.64,1)]"
      :class="
        modelValue
          ? 'ltr:translate-x-4 rtl:-translate-x-4 group-active:ltr:translate-x-[11px] rtl:group-active:-translate-x-[11px]'
          : 'ltr:translate-x-0 rtl:translate-x-0'
      "
    >
      <span
        class="block h-4 w-4 rounded-full bg-background shadow-lg transition-[width] duration-[180ms] ease-in-out group-active:w-5"
      />
    </span>
  </button>
</template>
