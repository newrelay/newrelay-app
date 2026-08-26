<script>
import { mapGetters } from 'vuex';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
import validations from './validations';
import SlaTimeInput from './SlaTimeInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useVuelidate } from '@vuelidate/core';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';

export default {
  components: {
    SlaTimeInput,
    NextButton,
    ToggleSwitch,
    RelayInput,
    RelayLabel,
  },
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
    submitLabel: {
      type: String,
      required: true,
    },
  },
  emits: ['close', 'submitSla'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      description: '',
      isSlaTimeInputsInvalid: false,
      slaTimeInputsValidation: {},
      slaTimeInputs: [
        {
          threshold: null,
          unit: 'Minutes',
          label: 'SLA.FORM.FIRST_RESPONSE_TIME.LABEL',
          placeholder: 'SLA.FORM.FIRST_RESPONSE_TIME.PLACEHOLDER',
        },
        {
          threshold: null,
          unit: 'Minutes',
          label: 'SLA.FORM.NEXT_RESPONSE_TIME.LABEL',
          placeholder: 'SLA.FORM.NEXT_RESPONSE_TIME.PLACEHOLDER',
        },
        {
          threshold: null,
          unit: 'Minutes',
          label: 'SLA.FORM.RESOLUTION_TIME.LABEL',
          placeholder: 'SLA.FORM.RESOLUTION_TIME.PLACEHOLDER',
        },
      ],
      onlyDuringBusinessHours: false,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
    isSubmitDisabled() {
      return (
        this.v$.name.$invalid ||
        this.isSlaTimeInputsInvalid ||
        this.uiFlags.isUpdating
      );
    },
    slaNameErrorMessage() {
      let errorMessage = '';
      if (this.v$.name.$error) {
        if (!this.v$.name.required) {
          errorMessage = this.$t('SLA.FORM.NAME.REQUIRED_ERROR');
        } else if (!this.v$.name.minLength) {
          errorMessage = this.$t('SLA.FORM.NAME.MINIMUM_LENGTH_ERROR');
        }
      }
      return errorMessage;
    },
  },
  mounted() {
    if (this.selectedResponse) this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setFormValues() {
      const {
        name,
        description,
        first_response_time_threshold: firstResponseTimeThreshold,
        next_response_time_threshold: nextResponseTimeThreshold,
        resolution_time_threshold: resolutionTimeThreshold,
        only_during_business_hours: onlyDuringBusinessHours,
      } = this.selectedResponse;

      this.name = name;
      this.description = description;
      this.onlyDuringBusinessHours = onlyDuringBusinessHours;

      const thresholds = [
        firstResponseTimeThreshold,
        nextResponseTimeThreshold,
        resolutionTimeThreshold,
      ];
      this.slaTimeInputs.forEach((input, index) => {
        const converted = convertSecondsToTimeUnit(thresholds[index], {
          minute: 'Minutes',
          hour: 'Hours',
          day: 'Days',
        });
        input.threshold = converted.time;
        input.unit = converted.unit;
      });
    },
    updateThreshold(index, value) {
      this.slaTimeInputs[index].threshold = value;
    },
    updateUnit(index, unit) {
      this.slaTimeInputs[index].unit = unit;
    },
    onSubmit() {
      const payload = {
        name: this.name,
        description: this.description,
        first_response_time_threshold: this.convertToSeconds(0),
        next_response_time_threshold: this.convertToSeconds(1),
        resolution_time_threshold: this.convertToSeconds(2),
        only_during_business_hours: this.onlyDuringBusinessHours,
      };
      this.$emit('submitSla', payload);
    },
    convertToSeconds(index) {
      const { threshold, unit } = this.slaTimeInputs[index];
      if (threshold === null || threshold === 0) return null;
      const unitsToSeconds = { Minutes: 60, Hours: 3600, Days: 86400 };
      return Number(threshold * (unitsToSeconds[unit] || 1));
    },
    handleIsInvalid(index, isInvalid) {
      this.slaTimeInputsValidation = {
        ...this.slaTimeInputsValidation,
        [index]: isInvalid,
      };

      this.checkValidationState();
    },
    checkValidationState() {
      const isAnyInvalid = Object.values(this.slaTimeInputsValidation).some(
        isInvalid => isInvalid
      );
      this.isSlaTimeInputsInvalid = isAnyInvalid;
    },
  },
};
</script>

<template>
  <form class="flex flex-col h-full max-h-[calc(90vh-140px)] -m-6 p-6 pb-0" @submit.prevent="onSubmit">
    <!-- Scrollable Body Content -->
    <div class="flex-1 overflow-y-auto space-y-5 pr-1 custom-scrollbar">
      <!-- SLA Name -->
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">SLA Name</label>
        <input
          v-model="name"
          class="placeholder:text-muted-foreground flex w-full border px-4 py-2 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-11 text-[14px] shadow-xs rounded-xl border-border/60 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
          placeholder="SLA Name"
          @update:model-value="v$.name.$touch"
          @blur="v$.name.$touch"
        />
        <p v-if="v$.name.$error" class="text-xs text-destructive">
          {{ slaNameErrorMessage }}
        </p>
      </div>

      <!-- Description -->
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">Description</label>
        <input
          v-model="description"
          class="placeholder:text-muted-foreground flex w-full border px-4 py-2 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-11 text-[14px] shadow-xs rounded-xl border-border/60 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
          placeholder="SLA for premium customers"
        />
      </div>

      <!-- First Response Time -->
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">First Response Time</label>
        <div class="flex items-center">
          <input
            v-model="slaTimeInputs[0].threshold"
            type="number"
            class="placeholder:text-muted-foreground flex w-full rounded-l-xl border border-r-0 border-border/60 px-4 py-2 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-11 text-[14px] shadow-xs bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
          />
          <select
            v-model="slaTimeInputs[0].unit"
            class="h-11 px-3 text-[13.5px] shadow-xs rounded-r-xl border border-l border-border/60 bg-muted/20 text-foreground outline-none focus:ring-1 focus:ring-primary/30 min-w-[100px] cursor-pointer"
          >
            <option value="Minutes">minutes</option>
            <option value="Hours">hours</option>
            <option value="Days">days</option>
          </select>
        </div>
      </div>

      <!-- Next Response Time -->
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">Next Response Time</label>
        <div class="flex items-center">
          <input
            v-model="slaTimeInputs[1].threshold"
            type="number"
            class="placeholder:text-muted-foreground flex w-full rounded-l-xl border border-r-0 border-border/60 px-4 py-2 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-11 text-[14px] shadow-xs bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
          />
          <select
            v-model="slaTimeInputs[1].unit"
            class="h-11 px-3 text-[13.5px] shadow-xs rounded-r-xl border border-l border-border/60 bg-muted/20 text-foreground outline-none focus:ring-1 focus:ring-primary/30 min-w-[100px] cursor-pointer"
          >
            <option value="Minutes">minutes</option>
            <option value="Hours">hours</option>
            <option value="Days">days</option>
          </select>
        </div>
      </div>

      <!-- Resolution Time -->
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">Resolution Time</label>
        <div class="flex items-center">
          <input
            v-model="slaTimeInputs[2].threshold"
            type="number"
            class="placeholder:text-muted-foreground flex w-full rounded-l-xl border border-r-0 border-border/60 px-4 py-2 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-11 text-[14px] shadow-xs bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
          />
          <select
            v-model="slaTimeInputs[2].unit"
            class="h-11 px-3 text-[13.5px] shadow-xs rounded-r-xl border border-l border-border/60 bg-muted/20 text-foreground outline-none focus:ring-1 focus:ring-primary/30 min-w-[100px] cursor-pointer"
          >
            <option value="Minutes">minutes</option>
            <option value="Hours">hours</option>
            <option value="Days">days</option>
          </select>
        </div>
      </div>

      <!-- Only during business hours -->
      <div class="flex items-center justify-between pt-2 pb-1">
        <span class="text-[13.5px] font-medium text-foreground">Only during business hours</span>
        <ToggleSwitch id="sla_bh" v-model="onlyDuringBusinessHours" />
      </div>
    </div>

    <!-- Static Footer Buttons -->
    <div class="shrink-0 py-4 border-t border-border/40 bg-background flex items-center justify-end gap-3 mt-4">
      <button
        type="button"
        class="text-muted-foreground hover:text-foreground font-medium text-[13.5px] px-4 py-2 rounded-lg transition-colors"
        @click="onClose"
      >
        Cancel
      </button>
      <button
        type="submit"
        class="inline-flex items-center justify-center gap-2 whitespace-nowrap transition-colors focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 py-2.5 rounded-xl h-10 px-6 text-[13.5px] font-medium bg-primary text-primary-foreground hover:bg-primary/90 shadow-sm disabled:opacity-50"
        :disabled="isSubmitDisabled"
      >
        {{ submitLabel }}
      </button>
    </div>
  </form>
</template>
