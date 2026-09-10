<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayModal,
  RelayTextarea,
  RELAY_MODAL_FORM_FOOTER_CLASS,
  RELAY_MODAL_INPUT_CLASS,
} from 'dashboard/components-next/relay';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  mode: {
    type: String,
    default: 'add',
    validator: value => ['add', 'edit'].includes(value),
  },
  selectedResponse: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

const shortCode = ref('');
const content = ref('');
const isSubmitting = ref(false);

const v$ = useVuelidate(
  {
    shortCode: { required, minLength: minLength(2) },
    content: { required },
  },
  { shortCode, content }
);

const resetForm = () => {
  shortCode.value = '';
  content.value = '';
  v$.value.$reset();
};

const populateEditForm = () => {
  shortCode.value = props.selectedResponse.short_code || '';
  content.value = getPlainText(props.selectedResponse.content || '');
};

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      if (props.mode === 'edit') {
        populateEditForm();
      } else {
        resetForm();
      }
    }
  }
);

const getTranslationKey = base =>
  props.mode === 'edit'
    ? `CANNED_MGMT.EDIT.FORM.${base}`
    : `CANNED_MGMT.ADD.FORM.${base}`;

const modalTitle = computed(() => {
  if (props.mode === 'edit') {
    return `${t('CANNED_MGMT.EDIT.TITLE')} - ${shortCode.value}`;
  }
  return t('CANNED_MGMT.ADD.TITLE');
});

const modalDescription = computed(() =>
  props.mode === 'add' ? t('CANNED_MGMT.ADD.DESC') : ''
);

const submitButtonText = computed(() => t(getTranslationKey('SUBMIT')));

const cancelButtonText = computed(() =>
  props.mode === 'edit'
    ? t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT')
    : t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT')
);

const shortCodeErrorMessage = computed(() =>
  v$.value.shortCode.$error ? t(getTranslationKey('SHORT_CODE.ERROR')) : ''
);

const contentErrorMessage = computed(() =>
  v$.value.content.$error ? t(getTranslationKey('CONTENT.ERROR')) : ''
);

const isSubmitDisabled = computed(
  () => v$.value.$invalid || isSubmitting.value
);

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;
  try {
    const payload = {
      short_code: shortCode.value,
      content: content.value,
    };

    if (props.mode === 'edit') {
      await store.dispatch('updateCannedResponse', {
        id: props.selectedResponse.id,
        ...payload,
      });
      useAlert(t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('createCannedResponse', payload);
      useAlert(t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
    }

    resetForm();
    emit('close');
  } catch (error) {
    const errorMessage =
      error?.message ||
      t(
        props.mode === 'edit'
          ? 'CANNED_MGMT.EDIT.API.ERROR_MESSAGE'
          : 'CANNED_MGMT.ADD.API.ERROR_MESSAGE'
      );
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="modalTitle"
    :description="modalDescription"
    size="md"
    flush
    @close="emit('close')"
  >
    <form @submit.prevent="handleSubmit">
      <div class="max-h-[60vh] space-y-5 overflow-y-auto px-6 pb-2">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="canned-short-code"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t(getTranslationKey('SHORT_CODE.LABEL')) }}
          </RelayLabel>
          <RelayInput
            id="canned-short-code"
            v-model="shortCode"
            type="text"
            :placeholder="$t(getTranslationKey('SHORT_CODE.PLACEHOLDER'))"
            :class-name="RELAY_MODAL_INPUT_CLASS"
            @blur="v$.shortCode.$touch"
          />
          <p v-if="v$.shortCode.$error" class="text-xs text-destructive">
            {{ shortCodeErrorMessage }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="canned-content"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t(getTranslationKey('CONTENT.LABEL')) }}
          </RelayLabel>
          <RelayTextarea
            id="canned-content"
            v-model="content"
            :placeholder="$t(getTranslationKey('CONTENT.PLACEHOLDER'))"
            class-name="min-h-[120px] resize-y text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            :has-error="v$.content.$error"
            @blur="v$.content.$touch"
          />
          <p v-if="v$.content.$error" class="text-xs text-destructive">
            {{ contentErrorMessage }}
          </p>
        </div>
      </div>

      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton
          type="button"
          variant="outline"
          size="lg"
          @click="emit('close')"
        >
          {{ cancelButtonText }}
        </RelayButton>
        <RelayButton type="submit" size="lg" :disabled="isSubmitDisabled">
          {{ submitButtonText }}
        </RelayButton>
      </div>
    </form>
  </RelayModal>
</template>
