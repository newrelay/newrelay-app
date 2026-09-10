<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import WebhookForm from './WebhookForm.vue';
import { RelayModal } from 'dashboard/components-next/relay';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  value: {
    type: Object,
    required: true,
  },
  id: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();

const uiFlags = computed(() => store.getters['webhooks/getUIFlags']);

const handleClose = () => emit('close');

const onSubmit = async webhook => {
  try {
    await store.dispatch('webhooks/update', {
      webhook,
      id: props.id,
    });
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.SUCCESS_MESSAGE'));
    handleClose();
  } catch (error) {
    const alertMessage =
      error?.response?.data?.message ||
      t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
    useAlert(alertMessage);
  }
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.TITLE')"
    size="lg"
    flush
    @close="handleClose"
  >
    <WebhookForm
      :value="value"
      :is-submitting="uiFlags.updatingItem"
      :submit-label="t('INTEGRATION_SETTINGS.WEBHOOK.FORM.EDIT_SUBMIT')"
      @submit="onSubmit"
      @cancel="handleClose"
    />
  </RelayModal>
</template>
