<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import WebhookForm from './WebhookForm.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  value: {
    type: Object,
    required: true,
  },
  id: {
    type: [Number, String],
    required: true,
  },
  onClose: {
    type: Function,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const uiFlags = computed(() => store.getters['webhooks/getUIFlags']);

const onSubmit = async webhook => {
  try {
    await store.dispatch('webhooks/update', {
      webhook,
      id: props.id,
    });
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.SUCCESS_MESSAGE'));
    props.onClose();
  } catch (error) {
    const alertMessage =
      error?.response?.data?.message ||
      t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
    useAlert(alertMessage);
  }
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="relative -mt-2 flex items-center justify-between">
      <h3 class="text-base font-semibold text-foreground">
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.TITLE') }}
      </h3>
      <button
        type="button"
        class="text-muted-foreground transition-colors hover:text-foreground"
        @click="props.onClose()"
      >
        <Icon icon="i-lucide-x" class="size-5" />
      </button>
    </div>

    <WebhookForm
      :value="value"
      :is-submitting="uiFlags.updatingItem"
      :submit-label="t('INTEGRATION_SETTINGS.WEBHOOK.FORM.EDIT_SUBMIT')"
      @submit="onSubmit"
      @cancel="props.onClose()"
    />
  </div>
</template>
