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
  <div class="relative w-full max-w-[500px] bg-card border border-border/60 rounded-2xl shadow-2xl flex flex-col max-h-[90vh] animate-in zoom-in-95 duration-200">
    <!-- Header -->
    <div class="flex flex-col p-6 pb-4 border-b border-border/40 shrink-0 relative">
      <button
        type="button"
        class="absolute top-6 right-6 text-muted-foreground hover:text-foreground transition-colors"
        @click="onClose"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="lucide size-4 lucide-x"
          aria-hidden="true"
        >
          <path d="M18 6 6 18"></path>
          <path d="m6 6 12 12"></path>
        </svg>
      </button>
      <h3 class="text-base font-medium text-foreground">
        {{ selectedResponse ? $t('SLA.EDIT.TITLE') : 'Add SLA' }}
      </h3>
      <p class="text-[13.5px] text-muted-foreground mt-1">
        Friendly promises for great service!
      </p>
    </div>

    <!-- Body Form -->
    <div class="flex-1 overflow-y-auto p-6 space-y-5 custom-scrollbar">
      <form class="space-y-5" @submit.prevent="onSubmit">
        <!-- SLA Name -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">SLA Name</label>
          <input
            v-model="name"
            class="placeholder:text-muted-foreground flex w-full border px-3 py-1 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
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
            class="placeholder:text-muted-foreground flex w-full border px-3 py-1 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 text-foreground"
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
              class="placeholder:text-muted-foreground flex w-full rounded-md border px-3 py-1 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-10 text-[14px] shadow-sm rounded-l-md rounded-r-none border-r-0 border-border/80 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 z-10 text-foreground"
            />
            <select
              v-model="slaTimeInputs[0].unit"
              class="h-10 px-3 text-[13.5px] shadow-sm rounded-r-md border border-border/80 bg-background text-foreground outline-none focus:ring-1 focus:ring-primary/30 min-w-[100px] cursor-pointer"
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
              class="placeholder:text-muted-foreground flex w-full rounded-md border px-3 py-1 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-10 text-[14px] shadow-sm rounded-l-md rounded-r-none border-r-0 border-border/80 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 z-10 text-foreground"
            />
            <select
              v-model="slaTimeInputs[1].unit"
              class="h-10 px-3 text-[13.5px] shadow-sm rounded-r-md border border-border/80 bg-background text-foreground outline-none focus:ring-1 focus:ring-primary/30 min-w-[100px] cursor-pointer"
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
              class="placeholder:text-muted-foreground flex w-full rounded-md border px-3 py-1 transition-colors focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50 h-10 text-[14px] shadow-sm rounded-l-md rounded-r-none border-r-0 border-border/80 bg-muted/20 focus-visible:ring-1 focus-visible:ring-primary/30 z-10 text-foreground"
            />
            <select
              v-model="slaTimeInputs[2].unit"
              class="h-10 px-3 text-[13.5px] shadow-sm rounded-r-md border border-border/80 bg-background text-foreground outline-none focus:ring-1 focus:ring-primary/30 min-w-[100px] cursor-pointer"
            >
              <option value="Minutes">minutes</option>
              <option value="Hours">hours</option>
              <option value="Days">days</option>
            </select>
          </div>
        </div>

        <!-- Only during business hours -->
        <div class="flex items-center justify-between pt-2">
          <span class="text-[13.5px] font-medium text-foreground">Only during business hours</span>
          <ToggleSwitch id="sla_bh" v-model="onlyDuringBusinessHours" />
        </div>

        <!-- Footer Buttons -->
        <div class="p-6 pt-4 flex justify-end gap-3 shrink-0 border-t border-border/40 bg-background/50 rounded-b-2xl -mx-6 -mb-6 mt-6">
          <button
            type="button"
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap transition-colors focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 hover:text-accent-foreground py-2 rounded-md h-9 px-4 text-[13.5px] text-foreground font-medium hover:bg-muted"
            @click="onClose"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap transition-colors focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 py-2 rounded-md h-9 px-6 text-[13.5px] font-medium bg-primary text-primary-foreground hover:bg-primary/90 shadow-sm disabled:opacity-50"
            :disabled="isSubmitDisabled"
          >
            {{ submitLabel }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
