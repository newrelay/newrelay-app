<script>
import validations from './helpers/validations';
import { reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayCheckbox,
} from 'dashboard/components-next/relay';

export default {
  components: {
    RelayButton,
    RelayInput,
    RelayLabel,
    RelayCheckbox,
  },
  props: {
    onSubmit: {
      type: Function,
      default: () => {},
    },
    submitInProgress: {
      type: Boolean,
      default: false,
    },
    formData: {
      type: Object,
      default: () => {},
    },
    submitButtonText: {
      type: String,
      default: '',
    },
  },
  setup(props) {
    const formData = props.formData || {};
    const {
      description = '',
      name: title = '',
      allow_auto_assign: allowAutoAssign = true,
    } = formData;

    const state = reactive({
      description,
      title,
      allowAutoAssign,
    });

    const rules = validations;
    const v$ = useVuelidate(rules, state);
    return { state, v$ };
  },
  methods: {
    handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.onSubmit({
        description: this.state.description,
        name: this.state.title,
        allow_auto_assign: this.state.allowAutoAssign,
      });
    },
  },
};
</script>

<template>
  <div class="w-full flex-shrink-0">
    <form class="mx-0 grid gap-6" @submit.prevent="handleSubmit">
      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="team-name"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ $t('TEAMS_SETTINGS.FORM.NAME.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="team-name"
          v-model="state.title"
          type="text"
          :placeholder="$t('TEAMS_SETTINGS.FORM.NAME.PLACEHOLDER')"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.title.$touch"
        />
        <p v-if="v$.title.$error" class="text-xs text-destructive">
          {{ v$.title.$errors[0].$message }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="team-description"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ $t('TEAMS_SETTINGS.FORM.DESCRIPTION.LABEL') }}
        </RelayLabel>
        <textarea
          id="team-description"
          v-model="state.description"
          rows="3"
          :placeholder="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.PLACEHOLDER')"
          class="min-h-[90px] w-full resize-none rounded-md border border-border/80 bg-background p-3 text-[14px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
          @blur="v$.description.$touch"
        />
        <p v-if="v$.description.$error" class="text-xs text-destructive">
          {{ v$.description.$errors[0].$message }}
        </p>
      </div>

      <label class="flex cursor-pointer items-center gap-2.5">
        <RelayCheckbox v-model="state.allowAutoAssign" />
        <span class="text-sm text-foreground">
          {{ $t('TEAMS_SETTINGS.FORM.AUTO_ASSIGN.LABEL') }}
        </span>
      </label>

      <div class="flex justify-end border-t border-border/40 pt-6">
        <RelayButton
          type="submit"
          class="h-10 rounded-md px-6 text-[14px] font-semibold shadow-sm"
          :disabled="v$.title.$invalid || submitInProgress"
        >
          {{ submitButtonText }}
        </RelayButton>
      </div>
    </form>
  </div>
</template>
