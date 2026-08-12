<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayCheckbox,
  RelayInput,
} from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);

const name = defineModel('name', {
  type: String,
  required: true,
});

const type = defineModel('type', {
  type: String,
  required: true,
});

const description = defineModel('description', {
  type: String,
  default: '',
});

const required = defineModel('required', {
  type: Boolean,
  default: false,
});

const paramTypeOptions = computed(() => [
  { value: 'string', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.STRING') },
  { value: 'number', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.NUMBER') },
  {
    value: 'boolean',
    label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.BOOLEAN'),
  },
  { value: 'array', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.ARRAY') },
  { value: 'object', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.OBJECT') },
]);

const validationError = computed(() => {
  if (!name.value || name.value.trim() === '') {
    return 'PARAM_NAME_REQUIRED';
  }
  return null;
});

watch([name, type, description, required], () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !validationError.value;
};

defineExpose({ validate });
</script>

<template>
  <li class="list-none">
    <div
      class="flex items-start gap-2 rounded-lg border border-n-weak bg-n-alpha-2 p-3"
      :class="{
        'animate-wiggle border-n-ruby-9': showErrors && validationError,
      }"
    >
      <div class="flex flex-1 flex-col gap-3">
        <div class="grid grid-cols-3 gap-2">
          <RelayInput
            v-model="name"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_NAME.PLACEHOLDER')"
            class-name="col-span-2"
          />
          <ComboBox
            v-model="type"
            :options="paramTypeOptions"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPE.PLACEHOLDER')"
            class="[&>div>button]:bg-n-alpha-black2"
          />
        </div>
        <RelayInput
          v-model="description"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_DESCRIPTION.PLACEHOLDER')
          "
        />
        <label
          class="flex cursor-pointer items-center gap-3 select-none text-[13.5px] font-medium leading-none text-foreground"
        >
          <RelayCheckbox v-model="required" />
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_REQUIRED.LABEL') }}
        </label>
      </div>
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-9 shrink-0 text-n-slate-11 hover:text-n-ruby-9"
        @click.stop="emit('remove')"
      >
        <span class="i-lucide-trash size-3.5" />
      </RelayButton>
    </div>
    <span
      v-if="showErrors && validationError"
      class="mt-1 block text-sm text-n-ruby-11"
    >
      {{ t(`CAPTAIN.CUSTOM_TOOLS.FORM.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
