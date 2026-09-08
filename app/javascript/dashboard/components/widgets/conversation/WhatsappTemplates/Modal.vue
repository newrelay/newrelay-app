<script>
import TemplatesPicker from './TemplatesPicker.vue';
import WhatsAppTemplateReply from './WhatsAppTemplateReply.vue';
import { RelayModal } from 'dashboard/components-next/relay';

export default {
  components: {
    TemplatesPicker,
    WhatsAppTemplateReply,
    RelayModal,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    inboxId: {
      type: Number,
      default: undefined,
    },
  },
  emits: ['onSend', 'cancel'],
  data() {
    return {
      selectedWaTemplate: null,
    };
  },
  computed: {
    modalHeaderContent() {
      return this.selectedWaTemplate
        ? this.$t('WHATSAPP_TEMPLATES.MODAL.TEMPLATE_SELECTED_SUBTITLE', {
            templateName: this.selectedWaTemplate.name,
          })
        : this.$t('WHATSAPP_TEMPLATES.MODAL.SUBTITLE');
    },
  },
  methods: {
    pickTemplate(template) {
      this.selectedWaTemplate = template;
    },
    onResetTemplate() {
      this.selectedWaTemplate = null;
    },
    onSendMessage(message) {
      this.$emit('onSend', message);
    },
    onClose() {
      this.selectedWaTemplate = null;
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="$t('WHATSAPP_TEMPLATES.MODAL.TITLE')"
    :description="modalHeaderContent"
    size="xl"
    @close="onClose"
  >
    <TemplatesPicker
      v-if="!selectedWaTemplate"
      :inbox-id="inboxId"
      @on-select="pickTemplate"
    />
    <WhatsAppTemplateReply
      v-else
      :template="selectedWaTemplate"
      @reset-template="onResetTemplate"
      @send-message="onSendMessage"
    />
  </RelayModal>
</template>
