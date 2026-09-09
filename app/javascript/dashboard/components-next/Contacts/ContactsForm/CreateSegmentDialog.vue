<script setup>
import { ref, reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  RelayInput,
  RelayLabel,
  RELAY_FORM_FIELD_CLASS,
} from 'dashboard/components-next/relay';

const emit = defineEmits(['create']);

const FILTER_TYPE_CONTACT = 1;

const { t } = useI18n();

const uiFlags = useMapGetter('customViews/getUIFlags');
const isCreating = computed(() => uiFlags.value.isCreating);

const dialogRef = ref(null);

const state = reactive({
  name: '',
});

const validationRules = {
  name: { required },
};

const v$ = useVuelidate(validationRules, state);

const handleDialogConfirm = async () => {
  const isNameValid = await v$.value.$validate();
  if (!isNameValid) return;
  emit('create', {
    name: state.name,
    filter_type: FILTER_TYPE_CONTACT,
  });
  state.name = '';
  v$.value.$reset();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.TITLE')"
    :confirm-button-label="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.CONFIRM')
    "
    :is-loading="isCreating"
    :disable-confirm-button="isCreating"
    @confirm="handleDialogConfirm"
  >
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="state.name"
        :placeholder="
          t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.PLACEHOLDER')
        "
      />
      <p v-if="v$.name.$error" class="text-xs text-destructive">
        {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.ERROR') }}
      </p>
    </div>
  </Dialog>
</template>
