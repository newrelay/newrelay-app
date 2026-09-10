<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import validations, { getLabelTitleErrorMessage } from '../validations';
import { getRandomColor } from 'dashboard/helper/labelColor';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayCheckbox,
  RelayModal,
  RELAY_MODAL_FORM_BODY_CLASS,
  RELAY_MODAL_FORM_FOOTER_CLASS,
  RELAY_MODAL_INPUT_CLASS,
} from 'dashboard/components-next/relay';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';

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
  selectedLabel: {
    type: Object,
    default: () => ({}),
  },
  prefillTitle: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const title = ref('');
const description = ref('');
const color = ref('#000000');
const showOnSidebar = ref(true);
const isSubmitting = ref(false);

const v$ = useVuelidate(validations, {
  title,
  description,
  color,
  showOnSidebar,
});

const resetForm = () => {
  title.value = '';
  description.value = '';
  color.value = getRandomColor();
  showOnSidebar.value = true;
  v$.value.$reset();
};

const populateEditForm = () => {
  title.value = props.selectedLabel.title || '';
  description.value = props.selectedLabel.description || '';
  color.value = props.selectedLabel.color || '#000000';
  showOnSidebar.value = props.selectedLabel.show_on_sidebar ?? true;
};

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      if (props.mode === 'edit') {
        populateEditForm();
      } else {
        resetForm();
        title.value = (props.prefillTitle || '').toLowerCase();
      }
    }
  }
);

const getTranslationKey = base =>
  props.mode === 'edit' ? `LABEL_MGMT.EDIT.${base}` : `LABEL_MGMT.ADD.${base}`;

const modalTitle = computed(() => t(getTranslationKey('TITLE')));
const modalDescription = computed(() => t('LABEL_MGMT.ADD.DESC'));

const submitButtonText = computed(() =>
  props.mode === 'edit'
    ? t('LABEL_MGMT.FORM.EDIT')
    : t('LABEL_MGMT.FORM.CREATE')
);

const labelTitleErrorMessage = computed(() => {
  const errorMessage = getLabelTitleErrorMessage(v$.value);
  return errorMessage ? t(errorMessage) : '';
});

const isSubmitDisabled = computed(
  () => v$.value.$invalid || isSubmitting.value
);

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;
  try {
    const labelData = {
      color: color.value,
      description: description.value,
      title: title.value.toLowerCase(),
      show_on_sidebar: showOnSidebar.value,
    };

    if (props.mode === 'edit') {
      await store.dispatch('labels/update', {
        id: props.selectedLabel.id,
        ...labelData,
      });
      useAlert(t('LABEL_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('labels/create', labelData);
      useAlert(t('LABEL_MGMT.ADD.API.SUCCESS_MESSAGE'));
    }

    resetForm();
    emit('close');
  } catch (error) {
    const errorMessage =
      error?.message ||
      t(
        props.mode === 'edit'
          ? 'LABEL_MGMT.EDIT.API.ERROR_MESSAGE'
          : 'LABEL_MGMT.ADD.API.ERROR_MESSAGE'
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
    flush
    @close="emit('close')"
  >
    <form @submit.prevent="handleSubmit">
      <div :class="RELAY_MODAL_FORM_BODY_CLASS">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="label-title"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('LABEL_MGMT.FORM.NAME.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="label-title"
            v-model="title"
            type="text"
            data-testid="label-title"
            :placeholder="$t('LABEL_MGMT.FORM.NAME.PLACEHOLDER')"
            :class-name="`lowercase ${RELAY_MODAL_INPUT_CLASS}`"
            @blur="v$.title.$touch"
          />
          <p v-if="v$.title.$error" class="text-xs text-destructive">
            {{ labelTitleErrorMessage }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="label-description"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('LABEL_MGMT.FORM.DESCRIPTION.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="label-description"
            v-model="description"
            type="text"
            data-testid="label-description"
            :placeholder="$t('LABEL_MGMT.FORM.DESCRIPTION.PLACEHOLDER')"
            :class-name="RELAY_MODAL_INPUT_CLASS"
            @blur="v$.description.$touch"
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ $t('LABEL_MGMT.FORM.COLOR.LABEL') }}
          </RelayLabel>
          <ColorPicker v-model="color" variant="swatch" />
        </div>

        <label
          class="flex cursor-pointer items-center gap-3 text-[13.5px] font-[500] text-foreground"
        >
          <RelayCheckbox v-model="showOnSidebar" />
          <span class="text-[13px] font-normal text-foreground">
            {{ $t('LABEL_MGMT.FORM.SHOW_ON_SIDEBAR.LABEL') }}
          </span>
        </label>
      </div>

      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton
          type="button"
          variant="outline"
          size="lg"
          @click="emit('close')"
        >
          {{ $t('LABEL_MGMT.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton
          type="submit"
          data-testid="label-submit"
          size="lg"
          :disabled="isSubmitDisabled"
        >
          {{ submitButtonText }}
        </RelayButton>
      </div>
    </form>
  </RelayModal>
</template>
