<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import TemplatesPicker from './ContentTemplatesPicker.vue';
import TemplateParser from '../../../../components-next/content-templates/ContentTemplateParser.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { RelayModal } from 'dashboard/components-next/relay';

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSend', 'cancel']);

const { t } = useI18n();

const selectedContentTemplate = ref(null);

const modalHeaderContent = computed(() => {
  return selectedContentTemplate.value
    ? t('CONTENT_TEMPLATES.MODAL.TEMPLATE_SELECTED_SUBTITLE', {
        templateName: selectedContentTemplate.value.friendly_name,
      })
    : t('CONTENT_TEMPLATES.MODAL.SUBTITLE');
});

const pickTemplate = template => {
  selectedContentTemplate.value = template;
};

const onResetTemplate = () => {
  selectedContentTemplate.value = null;
};

const onSendMessage = message => {
  emit('onSend', message);
};

const onClose = () => {
  selectedContentTemplate.value = null;
  emit('cancel');
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="t('CONTENT_TEMPLATES.MODAL.TITLE')"
    :description="modalHeaderContent"
    size="xl"
    @close="onClose"
  >
    <TemplatesPicker
      v-if="!selectedContentTemplate"
      :inbox-id="inboxId"
      @on-select="pickTemplate"
    />
    <TemplateParser
      v-else
      :template="selectedContentTemplate"
      @reset-template="onResetTemplate"
      @send-message="onSendMessage"
    >
      <template #actions="{ sendMessage, resetTemplate, disabled }">
        <div class="mt-6 flex gap-2">
          <Button
            :label="t('CONTENT_TEMPLATES.PARSER.GO_BACK_LABEL')"
            color="slate"
            variant="faded"
            class="flex-1"
            @click="resetTemplate"
          />
          <Button
            :label="t('CONTENT_TEMPLATES.PARSER.SEND_MESSAGE_LABEL')"
            class="flex-1"
            :disabled="disabled"
            @click="sendMessage"
          />
        </div>
      </template>
    </TemplateParser>
  </RelayModal>
</template>
