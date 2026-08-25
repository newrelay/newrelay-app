<script>
import validations from './validations';
import { useVuelidate } from '@vuelidate/core';
import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';

export default {
  components: {
    RelayInput,
    RelayLabel,
  },
  props: {
    threshold: {
      type: Number,
      default: null,
    },
    thresholdUnit: {
      type: String,
      default: 'Minutes',
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
  },
  emits: ['unit', 'isInValid', 'updateThreshold'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      thresholdTime: this.threshold || '',
      thresholdUnitValue: this.thresholdUnit,
      options: [
        { value: 'Minutes', label: 'minutes' },
        { value: 'Hours', label: 'hours' },
        { value: 'Days', label: 'days' },
      ],
    };
  },
  validations,
  computed: {
    thresholdTimeErrorMessage() {
      let errorMessage = '';
      if (this.v$.thresholdTime.$error) {
        if (!this.v$.thresholdTime.numeric || !this.v$.thresholdTime.minValue) {
          errorMessage = this.$t(
            'SLA.FORM.THRESHOLD_TIME.INVALID_FORMAT_ERROR'
          );
        }
      }
      return errorMessage;
    },
  },
  watch: {
    threshold: {
      immediate: true,
      handler(value) {
        if (!Number.isNaN(value)) {
          this.thresholdTime = value;
        }
      },
    },
    thresholdUnit: {
      immediate: true,
      handler(value) {
        this.thresholdUnitValue = value;
      },
    },
  },
  methods: {
    onThresholdUnitChange() {
      this.$emit('unit', this.thresholdUnitValue);
    },
    onThresholdTimeChange() {
      this.v$.thresholdTime.$touch();
      const isInvalid = this.v$.thresholdTime.$invalid;
      this.$emit('isInValid', isInvalid);
      this.$emit(
        'updateThreshold',
        this.thresholdTime ? Number(this.thresholdTime) : null
      );
    },
  },
};
</script>

<template>
  <div class="flex w-full items-start gap-3">
    <div class="flex flex-grow flex-col gap-2">
      <RelayLabel>{{ label }}</RelayLabel>
      <RelayInput
        v-model="thresholdTime"
        type="number"
        class-name="h-10 shadow-xs bg-background"
        :placeholder="placeholder"
        @update:model-value="onThresholdTimeChange"
      />
      <p v-if="v$.thresholdTime.$error" class="text-xs text-destructive">
        {{ thresholdTimeErrorMessage }}
      </p>
    </div>
    <!-- the mt-[26px] handles the label offset -->
    <select
      v-model="thresholdUnitValue"
      class="mt-[26px] h-10 min-w-[6.5rem] rounded-lg border border-border/80 bg-background px-3 py-1.5 pr-7 text-sm font-medium text-foreground shadow-sm hover:cursor-pointer focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
      @change="onThresholdUnitChange"
    >
      <option
        v-for="(option, index) in options"
        :key="index"
        :value="option.value"
      >
        {{ option.label }}
      </option>
    </select>
  </div>
</template>
