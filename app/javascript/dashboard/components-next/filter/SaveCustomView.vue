<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { vOnClickOutside } from '@vueuse/components';
import { useTrack } from 'dashboard/composables';
import NextButton from 'next/button/Button.vue';
import { RelayInput } from 'dashboard/components-next/relay';

export default {
  components: {
    NextButton,
    RelayInput,
  },
  directives: {
    onClickOutside: vOnClickOutside,
  },
  props: {
    filterType: {
      type: Number,
      default: 0,
    },
    customViewsQuery: {
      type: Object,
      default: () => {},
    },
    openLastSavedItem: {
      type: Function,
      default: () => {},
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      show: true,
      name: '',
    };
  },

  computed: {
    isButtonDisabled() {
      return this.v$.name.$invalid;
    },
  },

  validations: {
    name: {
      required,
      minLength: minLength(1),
    },
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    async saveCustomViews() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('customViews/create', {
          name: this.name,
          filter_type: this.filterType,
          query: this.customViewsQuery,
        });
        this.alertMessage =
          this.filterType === 0
            ? this.$t('FILTER.CUSTOM_VIEWS.ADD.API_FOLDERS.SUCCESS_MESSAGE')
            : this.$t('FILTER.CUSTOM_VIEWS.ADD.API_SEGMENTS.SUCCESS_MESSAGE');
        this.onClose();

        useTrack(CONTACTS_EVENTS.SAVE_FILTER, {
          type: this.filterType === 0 ? 'folder' : 'segment',
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.filterType === 0
            ? errorMessage
            : this.$t('FILTER.CUSTOM_VIEWS.ADD.API_SEGMENTS.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
      this.openLastSavedItem();
    },
  },
};
</script>

<template>
  <div
    v-on-click-outside="[
      () => $emit('close'),
      { ignore: ['#saveFilterTeleportTarget'] },
    ]"
    class="z-40 max-w-3xl lg:w-[500px] overflow-visible w-full border border-border bg-accent backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="capitalize text-base font-medium leading-6 text-foreground">
      {{ $t('FILTER.CUSTOM_VIEWS.ADD.TITLE') }}
    </h3>
    <form class="w-full grid gap-6" @submit.prevent="saveCustomViews">
      <div class="flex flex-col gap-1.5">
        <RelayInput
          v-model="name"
          :placeholder="$t('FILTER.CUSTOM_VIEWS.ADD.PLACEHOLDER')"
          :class-name="
            v$.name.$error
              ? 'border-destructive/60 focus-visible:ring-destructive/20'
              : ''
          "
          @blur="v$.name.$touch"
        />
        <p
          v-if="v$.name.$error"
          class="text-[12px] font-medium text-destructive"
        >
          {{ $t('FILTER.CUSTOM_VIEWS.ADD.ERROR_MESSAGE') }}
        </p>
      </div>
      <div class="flex flex-row justify-end w-full gap-2">
        <NextButton faded slate sm @click.prevent="onClose">
          {{ $t('FILTER.CUSTOM_VIEWS.ADD.CANCEL_BUTTON') }}
        </NextButton>
        <NextButton solid blue sm :disabled="isButtonDisabled">
          {{ $t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON') }}
        </NextButton>
      </div>
    </form>
  </div>
</template>
