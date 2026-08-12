<script setup>
import { useI18n } from 'vue-i18n';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  disabledLabel: {
    type: String,
    default: '',
  },
  disabledMessage: {
    type: String,
    default: '',
  },
  beta: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const handleChange = () => {
  if (!props.isActive && !props.disabled) {
    emit('select', props.id);
  }
};
</script>

<template>
  <label
    :for="id"
    class="rounded-xl outline outline-1 p-4 transition-all duration-200 bg-card py-4 ltr:pl-4 rtl:pr-4 ltr:pr-6 rtl:pl-6 focus-within:has-[:focus-visible]:ring-2 focus-within:has-[:focus-visible]:ring-border"
    :class="[
      disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
      isActive ? 'outline-primary' : 'outline-border',
      !disabled && !isActive ? 'hover:outline-border' : '',
    ]"
  >
    <div class="flex flex-col gap-2 items-start">
      <div class="flex items-center justify-between w-full gap-3">
        <div class="flex items-center gap-2">
          <h3 class="text-heading-3 text-foreground">
            {{ label }}
          </h3>
          <Label v-if="disabled" :label="disabledLabel" color="amber" compact />
          <Label v-if="beta" :label="t('GENERAL.BETA')" color="blue" compact />
        </div>
        <input
          :id="`${id}`"
          :checked="isActive"
          :value="id"
          :name="id"
          :disabled="disabled"
          type="radio"
          class="shadow cursor-pointer grid place-items-center border-2 border-border appearance-none rounded-full w-5 h-5 checked:bg-primary before:content-[''] before:bg-primary before:border-4 before:rounded-full before:border-border checked:before:w-[18px] checked:before:h-[18px] checked:border checked:border-primary"
          @change="handleChange"
        />
      </div>
      <p class="text-body-main text-muted-foreground">
        {{ disabled && disabledMessage ? disabledMessage : description }}
      </p>
      <slot />
    </div>
  </label>
</template>
