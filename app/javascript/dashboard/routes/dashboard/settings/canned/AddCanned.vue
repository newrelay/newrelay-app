<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

export default {
  name: 'AddCanned',
  components: {
    RelayButton,
    RelayInput,
    RelayLabel,
    Editor,
  },
  props: {
    responseContent: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      shortCode: '',
      content: this.responseContent || '',
      addCanned: {
        showLoading: false,
        message: '',
      },
    };
  },
  validations: {
    shortCode: {
      required,
      minLength: minLength(2),
    },
    content: {
      required,
    },
  },
  methods: {
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    addCannedResponse() {
      this.addCanned.showLoading = true;
      this.$store
        .dispatch('createCannedResponse', {
          short_code: this.shortCode,
          content: this.content,
        })
        .then(() => {
          this.addCanned.showLoading = false;
          useAlert(this.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
          this.resetForm();
          this.onClose();
        })
        .catch(error => {
          this.addCanned.showLoading = false;
          const errorMessage =
            error?.message || this.$t('CANNED_MGMT.ADD.API.ERROR_MESSAGE');
          useAlert(errorMessage);
        });
    },
  },
};
</script>

<template>
  <form @submit.prevent="addCannedResponse()">
    <div class="space-y-5">
      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('CANNED_MGMT.ADD.FORM.SHORT_CODE.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="shortCode"
          type="text"
          :placeholder="$t('CANNED_MGMT.ADD.FORM.SHORT_CODE.PLACEHOLDER')"
          class-name="h-9 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.shortCode.$touch"
        />
        <p v-if="v$.shortCode.$error" class="text-xs text-destructive">
          {{ $t('CANNED_MGMT.ADD.FORM.SHORT_CODE.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('CANNED_MGMT.ADD.FORM.CONTENT.LABEL') }}
        </RelayLabel>
        <Editor
          v-model="content"
          channel-type="Context::Default"
          enable-variables
          :enable-canned-responses="false"
          :show-character-count="false"
          :message="
            v$.content.$error ? $t('CANNED_MGMT.ADD.FORM.CONTENT.ERROR') : ''
          "
          :message-type="v$.content.$error ? 'error' : 'info'"
          :placeholder="$t('CANNED_MGMT.ADD.FORM.CONTENT.PLACEHOLDER')"
          @blur="v$.content.$touch"
        />
      </div>
    </div>
    <div class="flex justify-end gap-3 border-t border-border/40 pt-5">
      <RelayButton
        type="button"
        variant="outline"
        class="h-9 border-border bg-muted px-5 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/80"
        @click.prevent="onClose"
      >
        {{ $t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="h-9 px-5 text-[13px] font-medium shadow-sm"
        :disabled="
          v$.content.$invalid || v$.shortCode.$invalid || addCanned.showLoading
        "
      >
        {{ $t('CANNED_MGMT.ADD.FORM.SUBMIT') }}
      </RelayButton>
    </div>
  </form>
</template>
