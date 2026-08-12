<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayInput } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { DURATION_UNITS } from './constants';

const props = defineProps({
  min: { type: Number, default: 0 },
  max: { type: Number, default: Infinity },
  disabled: { type: Boolean, default: false },
});

const { t } = useI18n();
const duration = defineModel('modelValue', { type: Number, default: null });
const unit = defineModel('unit', {
  type: String,
  default: DURATION_UNITS.MINUTES,
  validate(value) {
    return Object.values(DURATION_UNITS).includes(value);
  },
});

const showUnitDropdown = ref(false);

const convertToMinutes = newValue => {
  if (unit.value === DURATION_UNITS.MINUTES) {
    return Math.floor(newValue);
  }
  if (unit.value === DURATION_UNITS.HOURS) {
    return Math.floor(newValue) * 60;
  }
  return Math.floor(newValue) * 24 * 60;
};

const transformedValue = computed({
  get() {
    if (duration.value == null) return null;
    if (unit.value === DURATION_UNITS.MINUTES) return duration.value;
    if (unit.value === DURATION_UNITS.HOURS)
      return Math.floor(duration.value / 60);
    if (unit.value === DURATION_UNITS.DAYS)
      return Math.floor(duration.value / 24 / 60);

    return 0;
  },
  set(newValue) {
    if (newValue == null || newValue === '') {
      duration.value = null;
      return;
    }
    const minuteValue = convertToMinutes(newValue);

    duration.value = Math.min(Math.max(minuteValue, props.min), props.max);
  },
});

watch(unit, () => {
  if (duration.value == null) return;
  const adjustedValue = convertToMinutes(transformedValue.value);
  duration.value = Math.min(Math.max(adjustedValue, props.min), props.max);
});

const unitOptions = [
  { value: DURATION_UNITS.MINUTES, label: t('DURATION_INPUT.MINUTES') },
  { value: DURATION_UNITS.HOURS, label: t('DURATION_INPUT.HOURS') },
  { value: DURATION_UNITS.DAYS, label: t('DURATION_INPUT.DAYS') },
];

const unitLabel = computed(
  () =>
    unitOptions.find(option => option.value === unit.value)?.label ||
    t('DURATION_INPUT.MINUTES')
);

const selectUnit = nextUnit => {
  unit.value = nextUnit;
  showUnitDropdown.value = false;
};

const closeDropdown = () => {
  showUnitDropdown.value = false;
};
</script>

<template>
  <div
    class="flex w-full flex-col items-start gap-3 sm:flex-row sm:items-center"
  >
    <RelayInput
      v-model="transformedValue"
      type="number"
      :disabled="disabled"
      :placeholder="t('DURATION_INPUT.PLACEHOLDER')"
      class-name="h-10 w-full flex-1 text-[14px]"
    />
    <div
      v-on-clickaway="closeDropdown"
      class="relative w-full shrink-0 sm:w-[140px]"
    >
      <button
        type="button"
        :disabled="disabled"
        class="border-border/80 text-foreground focus:ring-primary/30 flex h-10 w-full items-center justify-between rounded-md border bg-background px-3 text-left text-[14px] shadow-xs outline-none transition-colors focus:ring-1 disabled:cursor-not-allowed disabled:opacity-50"
        @click="showUnitDropdown = !showUnitDropdown"
      >
        {{ unitLabel }}
        <Icon
          icon="i-lucide-chevron-down"
          class="text-muted-foreground size-4"
        />
      </button>
      <div
        v-if="showUnitDropdown"
        class="border-border/80 bg-card absolute left-0 top-full z-50 mt-1 w-full overflow-hidden rounded-md border py-1 shadow-lg"
      >
        <button
          v-for="option in unitOptions"
          :key="option.value"
          type="button"
          class="hover:bg-muted text-foreground w-full px-3 py-1.5 text-left text-[13.5px] transition-colors"
          @click="selectUnit(option.value)"
        >
          {{ option.label }}
        </button>
      </div>
    </div>
  </div>
</template>
