<script>
import { mapGetters } from 'vuex';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
import validations from './validations';
import SlaTimeInput from './SlaTimeInput.vue';
import { useVuelidate } from '@vuelidate/core';
import {
  RelayInput,
  RelayLabel,
  RelaySwitch,
  RelayButton,
  RELAY_MODAL_FORM_BODY_CLASS,
  RELAY_MODAL_FORM_FOOTER_CLASS,
  RELAY_MODAL_INPUT_CLASS,
} from 'dashboard/components-next/relay';

export default {
  components: {
    SlaTimeInput,
    RelayInput,
    RelayLabel,
    RelaySwitch,
    RelayButton,
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
    return {
      v$: useVuelidate(),
      RELAY_MODAL_FORM_BODY_CLASS,
      RELAY_MODAL_FORM_FOOTER_CLASS,
      RELAY_MODAL_INPUT_CLASS,
    };
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
  <form @submit.prevent="onSubmit">
    <div
      class="max-h-[60vh] overflow-y-auto"
      :class="[RELAY_MODAL_FORM_BODY_CLASS]"
    >
      <!-- SLA Name -->
      <div class="flex flex-col gap-1.5">
        <RelayLabel html-for="sla_name">
          {{ $t('SLA.FORM.NAME.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="sla_name"
          v-model="name"
          :class-name="RELAY_MODAL_INPUT_CLASS"
          :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
          @update:model-value="v$.name.$touch"
          @blur="v$.name.$touch"
        />
        <p v-if="v$.name.$error" class="text-xs text-destructive">
          {{ slaNameErrorMessage }}
        </p>
      </div>

      <!-- Description -->
      <div class="flex flex-col gap-1.5">
        <RelayLabel html-for="sla_description">
          {{ $t('SLA.FORM.DESCRIPTION.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="sla_description"
          v-model="description"
          :class-name="RELAY_MODAL_INPUT_CLASS"
          :placeholder="$t('SLA.FORM.DESCRIPTION.PLACEHOLDER')"
        />
      </div>

      <!-- Time thresholds: First Response, Next Response, Resolution -->
      <SlaTimeInput
        v-for="(input, index) in slaTimeInputs"
        :key="input.label"
        :threshold="input.threshold"
        :threshold-unit="input.unit"
        :label="$t(input.label)"
        :placeholder="$t(input.placeholder)"
        @update-threshold="updateThreshold(index, $event)"
        @unit="updateUnit(index, $event)"
        @is-in-valid="handleIsInvalid(index, $event)"
      />

      <!-- Only during business hours -->
      <div class="flex items-center justify-between pt-2 pb-1">
        <span class="text-[13.5px] font-medium text-foreground">
          {{ $t('SLA.FORM.BUSINESS_HOURS.PLACEHOLDER') }}
        </span>
        <RelaySwitch id="sla_bh" v-model="onlyDuringBusinessHours" />
      </div>
    </div>

    <!-- Static Footer Buttons -->
    <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
      <RelayButton type="button" variant="outline" size="lg" @click="onClose">
        {{ $t('SLA.FORM.CANCEL') }}
      </RelayButton>
      <RelayButton type="submit" size="lg" :disabled="isSubmitDisabled">
        {{ submitLabel }}
      </RelayButton>
    </div>
  </form>
</template>
