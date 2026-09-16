<script>
import { validEmailsByComma } from './helpers/emailHeadHelper';
import { useVuelidate } from '@vuelidate/core';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import {
  RelayInput,
  RELAY_FORM_INLINE_INPUT_CLASS,
} from 'dashboard/components-next/relay';

export default {
  components: {
    ButtonV4,
    RelayInput,
  },
  props: {
    ccEmails: {
      type: String,
      default: '',
    },
    bccEmails: {
      type: String,
      default: '',
    },
    toEmails: {
      type: String,
      default: '',
    },
  },
  emits: ['update:bccEmails', 'update:ccEmails', 'update:toEmails'],
  setup() {
    return { v$: useVuelidate(), RELAY_FORM_INLINE_INPUT_CLASS };
  },
  data() {
    return {
      showBcc: false,
      ccEmailsVal: '',
      bccEmailsVal: '',
      toEmailsVal: '',
    };
  },
  watch: {
    bccEmails(newVal) {
      if (newVal !== this.bccEmailsVal) {
        this.bccEmailsVal = newVal;
      }
    },
    ccEmails(newVal) {
      if (newVal !== this.ccEmailsVal) {
        this.ccEmailsVal = newVal;
      }
    },
    toEmails(newVal) {
      if (newVal !== this.toEmailsVal) {
        this.toEmailsVal = newVal;
      }
    },
  },
  mounted() {
    this.ccEmailsVal = this.ccEmails;
    this.bccEmailsVal = this.bccEmails;
    this.toEmailsVal = this.toEmails;
  },
  validations: {
    ccEmailsVal: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
    bccEmailsVal: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
    toEmailsVal: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
  },
  methods: {
    handleAddBcc() {
      this.showBcc = true;
    },
    onBlur() {
      this.v$.$touch();
      this.$emit('update:bccEmails', this.bccEmailsVal);
      this.$emit('update:ccEmails', this.ccEmailsVal);
      this.$emit('update:toEmails', this.toEmailsVal);
    },
  },
};
</script>

<template>
  <div>
    <div v-if="toEmails">
      <div
        class="flex items-center gap-2 my-1 border-b border-solid"
        :class="v$.toEmailsVal.$error ? 'border-destructive' : 'border-border'"
      >
        <label
          class="border-transparent bg-transparent pl-0 text-xs font-semibold"
          :class="
            v$.toEmailsVal.$error ? 'text-destructive' : 'text-foreground'
          "
        >
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.TO') }}
        </label>
        <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
          <RelayInput
            v-model="v$.toEmailsVal.$model"
            type="text"
            :class-name="RELAY_FORM_INLINE_INPUT_CLASS"
            :placeholder="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.PLACEHOLDER')"
            @blur="onBlur"
          />
        </div>
      </div>
    </div>
    <div>
      <div
        class="flex items-center gap-2 my-1 border-b border-solid"
        :class="v$.ccEmailsVal.$error ? 'border-destructive' : 'border-border'"
      >
        <label
          class="border-transparent bg-transparent pl-0 text-xs font-semibold"
          :class="
            v$.ccEmailsVal.$error ? 'text-destructive' : 'text-foreground'
          "
        >
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL') }}
        </label>
        <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
          <RelayInput
            v-model="v$.ccEmailsVal.$model"
            type="text"
            :class-name="RELAY_FORM_INLINE_INPUT_CLASS"
            :placeholder="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.PLACEHOLDER')"
            @blur="onBlur"
          />
        </div>
        <ButtonV4
          v-if="!showBcc"
          :label="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.ADD_BCC')"
          ghost
          xs
          primary
          @click="handleAddBcc"
        />
      </div>
      <span v-if="v$.ccEmailsVal.$error" class="text-sm text-destructive">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.ERROR') }}
      </span>
    </div>
    <div v-if="showBcc">
      <div
        class="flex items-center gap-2 my-1 border-b border-solid"
        :class="v$.bccEmailsVal.$error ? 'border-destructive' : 'border-border'"
      >
        <label
          class="border-transparent bg-transparent pl-0 text-xs font-semibold"
          :class="
            v$.bccEmailsVal.$error ? 'text-destructive' : 'text-foreground'
          "
        >
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL') }}
        </label>
        <div class="flex-1 min-w-0 m-0 rounded-none whitespace-nowrap">
          <RelayInput
            v-model="v$.bccEmailsVal.$model"
            type="text"
            :class-name="RELAY_FORM_INLINE_INPUT_CLASS"
            :placeholder="
              $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.PLACEHOLDER')
            "
            @blur="onBlur"
          />
        </div>
      </div>
      <span v-if="v$.bccEmailsVal.$error" class="text-sm text-destructive">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.ERROR') }}
      </span>
    </div>
  </div>
</template>
