<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayModal,
} from 'dashboard/components-next/relay';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

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
  content.value = props.selectedResponse.content || '';
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
    size="lg"
    @close="emit('close')"
  >
    <form @submit.prevent="handleSubmit">
      <div class="space-y-5 px-7 pb-2">
        <div class="flex flex-col gap-1.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ $t(getTranslationKey('SHORT_CODE.LABEL')) }}
          </RelayLabel>
          <RelayInput
            v-model="shortCode"
            type="text"
            :placeholder="$t(getTranslationKey('SHORT_CODE.PLACEHOLDER'))"
            class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            @blur="v$.shortCode.$touch"
          />
          <p v-if="v$.shortCode.$error" class="text-xs text-destructive">
            {{ shortCodeErrorMessage }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ $t(getTranslationKey('CONTENT.LABEL')) }}
          </RelayLabel>
          <div
            class="[&_.ProseMirror-menubar]:hidden [&_.ProseMirror-woot-style]:min-h-[12.5rem] [&_.ProseMirror-woot-style_p]:text-base"
          >
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              channel-type="Context::Default"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t(getTranslationKey('CONTENT.PLACEHOLDER'))"
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
          @click="emit('close')"
        >
          {{ cancelButtonText }}
        </RelayButton>
        <RelayButton
          type="submit"
          class="h-9 px-5 text-[13px] font-medium shadow-sm"
          :disabled="isSubmitDisabled"
        >
          {{ submitButtonText }}
        </RelayButton>
      </div>
    </form>
  </RelayModal>
</template>
