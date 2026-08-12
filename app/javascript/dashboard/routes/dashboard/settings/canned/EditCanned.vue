<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

export default {
  components: {
    RelayButton,
    RelayInput,
    RelayLabel,
    WootMessageEditor,
  },
  props: {
    id: { type: Number, default: null },
    edcontent: { type: String, default: '' },
    edshortCode: { type: String, default: '' },
    onClose: { type: Function, default: () => {} },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      editCanned: {
        showAlert: false,
        showLoading: false,
      },
      shortCode: this.edshortCode,
      content: this.edcontent,
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
    setPageName({ name }) {
      this.v$.content.$touch();
      this.content = name;
    },
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    editCannedResponse() {
      this.editCanned.showLoading = true;
      this.$store
        .dispatch('updateCannedResponse', {
          id: this.id,
          short_code: this.shortCode,
          content: this.content,
        })
        .then(() => {
          this.editCanned.showLoading = false;
          useAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          this.resetForm();
          setTimeout(() => {
            this.onClose();
          }, 10);
        })
        .catch(error => {
          this.editCanned.showLoading = false;
          const errorMessage =
            error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
          useAlert(errorMessage);
        });
    },
  },
};
</script>

<template>
  <form @submit.prevent="editCannedResponse()">
    <div class="space-y-5 px-7 pb-2">
      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="shortCode"
          type="text"
          :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @input="v$.shortCode.$touch"
        />
        <p v-if="v$.shortCode.$error" class="text-xs text-destructive">
          {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
        </RelayLabel>
        <div class="editor-wrap">
          <WootMessageEditor
            v-model="content"
            class="message-editor [&>div]:px-1"
            :class="{ editor_warning: v$.content.$error }"
            channel-type="Context::Default"
            enable-variables
            :enable-canned-responses="false"
            :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
            @blur="v$.content.$touch"
          />
        </div>
      </div>
    </div>
    <div class="flex justify-end gap-3 border-t border-border/40 px-7 py-6">
      <RelayButton
        type="button"
        variant="outline"
        class="h-9 border-border bg-muted px-5 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/80"
        @click.prevent="onClose"
      >
        {{ $t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="h-9 px-5 text-[13px] font-medium shadow-sm"
        :disabled="
          v$.content.$invalid || v$.shortCode.$invalid || editCanned.showLoading
        "
      >
        {{ $t('CANNED_MGMT.EDIT.FORM.SUBMIT') }}
      </RelayButton>
    </div>
  </form>
</template>

<style scoped lang="scss">
:deep(.ProseMirror-menubar) {
  @apply hidden;
}

:deep(.ProseMirror-woot-style) {
  @apply min-h-[12.5rem];

  p {
    @apply text-base;
  }
}
</style>
