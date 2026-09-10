<script setup>
import { useI18n } from 'vue-i18n';
import Label from 'dashboard/components-next/label/Label.vue';
import { RELAY_RADIO_INPUT_CLASS } from 'dashboard/components-next/relay';

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
    class="rounded-xl border p-4 transition-colors bg-card py-4 ltr:pl-4 rtl:pr-4 ltr:pr-6 rtl:pl-6 focus-within:has-[:focus-visible]:ring-1 focus-within:has-[:focus-visible]:ring-primary text-[13.5px] font-[500] text-foreground"
    :class="[
      disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
      isActive
        ? 'bg-primary/5 border-primary ring-1 ring-primary/20'
        : 'border-border',
      !disabled && !isActive ? 'hover:bg-muted/50' : '',
    ]"
  >
    <div class="flex flex-col gap-2 items-start">
      <div class="flex items-center justify-between w-full gap-3">
        <div class="flex items-center gap-2">
          <h3 class="capitalize text-heading-3 text-foreground">
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
          :class="RELAY_RADIO_INPUT_CLASS"
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
