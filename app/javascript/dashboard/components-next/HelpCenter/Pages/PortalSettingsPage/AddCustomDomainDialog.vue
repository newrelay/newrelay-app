<script setup>
import { ref, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { helpers } from '@vuelidate/validators';
import { isValidDomain } from '@chatwoot/utils';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';

const props = defineProps({
  mode: {
    type: String,
    default: 'add',
  },
  customDomain: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['addCustomDomain']);

const { t } = useI18n();

const dialogRef = ref(null);

const formState = reactive({
  customDomain: props.customDomain,
});

const rules = {
  customDomain: {
    isValidDomain: helpers.withMessage(
      () =>
        t(
          'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.FORMAT_ERROR'
        ),
      isValidDomain
    ),
  },
};

// $scope: false keeps this dialog's validation isolated from the parent portal
// settings form so it can't affect the Save button's enabled state.
const v$ = useVuelidate(rules, formState, { $scope: false });

watch(
  () => props.customDomain,
  newVal => {
    formState.customDomain = newVal;
  }
);

const handleDialogConfirm = async () => {
  const isFormCorrect = await v$.value.$validate();
  if (!isFormCorrect) return;

  emit('addCustomDomain', formState.customDomain);
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="sm"
    :title="
      t(
        `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.${props.mode.toUpperCase()}_HEADER`
      )
    "
    :description="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.DESCRIPTION'
      )
    "
    :confirm-button-label="
      t(
        `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.${props.mode.toUpperCase()}_CONFIRM_BUTTON_LABEL`
      )
    "
    @confirm="handleDialogConfirm"
  >
    <div class="flex flex-col gap-1.5">
      <RelayLabel html-for="custom-domain">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.LABEL'
          )
        }}
      </RelayLabel>
      <RelayInput
        id="custom-domain"
        v-model="formState.customDomain"
        :placeholder="
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.PLACEHOLDER'
          )
        "
        @blur="v$.customDomain.$touch()"
      />
      <p v-if="v$.customDomain.$error" class="text-[12px] text-destructive">
        {{ v$.customDomain.$errors[0].$message }}
      </p>
    </div>
  </Dialog>
</template>
