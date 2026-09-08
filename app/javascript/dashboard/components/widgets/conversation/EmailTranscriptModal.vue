<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import {
  RelayModal,
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

export default {
  components: {
    RelayModal,
    RelayButton,
    RelayInput,
    RelayLabel,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    currentChat: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['cancel'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      email: '',
      selectedType: '',
      isSubmitting: false,
    };
  },
  validations: {
    email: {
      required,
      email,
      minLength: minLength(4),
    },
  },
  computed: {
    sentToOtherEmailAddress() {
      return this.selectedType === 'other_email_address';
    },
    isFormValid() {
      if (this.selectedType) {
        if (this.sentToOtherEmailAddress) {
          return !!this.email && !this.v$.email.$error;
        }
        return true;
      }
      return false;
    },
    selectedEmailAddress() {
      const { meta } = this.currentChat;
      switch (this.selectedType) {
        case 'contact':
          return meta.sender.email;
        case 'assignee':
          return meta.assignee.email;
        case 'other_email_address':
          return this.email;
        default:
          return '';
      }
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    selectType(type) {
      this.selectedType = type;
    },
    async onSubmit() {
      this.isSubmitting = false;
      try {
        await this.$store.dispatch('sendEmailTranscript', {
          email: this.selectedEmailAddress,
          conversationId: this.currentChat.id,
        });
        useAlert(this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'));
        this.onCancel();
      } catch (error) {
        const status = error?.response?.status;
        if (status === 402) {
          useAlert(this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_PAYMENT_REQUIRED'));
        } else {
          useAlert(this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'));
        }
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="$t('EMAIL_TRANSCRIPT.TITLE')"
    :description="$t('EMAIL_TRANSCRIPT.DESC')"
    @close="onCancel"
  >
    <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
      <div class="flex flex-col gap-2">
        <button
          v-if="currentChat.meta.sender && currentChat.meta.sender.email"
          type="button"
          class="flex items-center gap-3 rounded-md px-1 py-1.5 text-left"
          @click="selectType('contact')"
        >
          <span
            class="flex size-4 shrink-0 items-center justify-center rounded-full border"
            :class="
              selectedType === 'contact' ? 'border-primary' : 'border-border'
            "
          >
            <span
              v-if="selectedType === 'contact'"
              class="size-2 rounded-full bg-primary"
            />
          </span>
          <span class="text-[13.5px] font-medium text-foreground">
            {{ $t('EMAIL_TRANSCRIPT.FORM.SEND_TO_CONTACT') }}
          </span>
        </button>
        <button
          v-if="currentChat.meta.assignee"
          type="button"
          class="flex items-center gap-3 rounded-md px-1 py-1.5 text-left"
          @click="selectType('assignee')"
        >
          <span
            class="flex size-4 shrink-0 items-center justify-center rounded-full border"
            :class="
              selectedType === 'assignee' ? 'border-primary' : 'border-border'
            "
          >
            <span
              v-if="selectedType === 'assignee'"
              class="size-2 rounded-full bg-primary"
            />
          </span>
          <span class="text-[13.5px] font-medium text-foreground">
            {{ $t('EMAIL_TRANSCRIPT.FORM.SEND_TO_AGENT') }}
          </span>
        </button>
        <button
          type="button"
          class="flex items-center gap-3 rounded-md px-1 py-1.5 text-left"
          @click="selectType('other_email_address')"
        >
          <span
            class="flex size-4 shrink-0 items-center justify-center rounded-full border"
            :class="
              selectedType === 'other_email_address'
                ? 'border-primary'
                : 'border-border'
            "
          >
            <span
              v-if="selectedType === 'other_email_address'"
              class="size-2 rounded-full bg-primary"
            />
          </span>
          <span class="text-[13.5px] font-medium text-foreground">
            {{ $t('EMAIL_TRANSCRIPT.FORM.SEND_TO_OTHER_EMAIL_ADDRESS') }}
          </span>
        </button>
      </div>
      <div v-if="sentToOtherEmailAddress" class="flex flex-col gap-1.5">
        <RelayLabel html-for="transcript-email">
          {{ $t('EMAIL_TRANSCRIPT.FORM.EMAIL.PLACEHOLDER') }}
        </RelayLabel>
        <RelayInput
          id="transcript-email"
          v-model="email"
          type="email"
          :placeholder="$t('EMAIL_TRANSCRIPT.FORM.EMAIL.PLACEHOLDER')"
          @update:model-value="v$.email.$touch"
        />
        <span v-if="v$.email.$error" class="text-[13px] text-destructive">
          {{ $t('EMAIL_TRANSCRIPT.FORM.EMAIL.ERROR') }}
        </span>
      </div>
      <div class="flex justify-end gap-3">
        <RelayButton type="button" variant="outline" @click="onCancel">
          {{ $t('EMAIL_TRANSCRIPT.CANCEL') }}
        </RelayButton>
        <RelayButton type="submit" :disabled="!isFormValid">
          {{ $t('EMAIL_TRANSCRIPT.SUBMIT') }}
        </RelayButton>
      </div>
    </form>
  </RelayModal>
</template>
