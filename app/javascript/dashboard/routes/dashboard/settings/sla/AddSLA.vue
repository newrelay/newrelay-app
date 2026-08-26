<script>
import { useAlert } from 'dashboard/composables';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  props: {
    slaToEdit: {
      type: Object,
      default: null,
    },
  },
  emits: ['close'],
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addSLA(payload) {
      const isEditing = !!this.slaToEdit;
      try {
        if (isEditing) {
          await this.$store.dispatch('sla/update', {
            id: this.slaToEdit.id,
            ...payload,
          });
          useAlert(this.$t('SLA.EDIT.API.SUCCESS_MESSAGE'));
        } else {
          await this.$store.dispatch('sla/create', payload);
          useAlert(this.$t('SLA.ADD.API.SUCCESS_MESSAGE'));
        }
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message ||
          this.$t(
            isEditing
              ? 'SLA.EDIT.API.ERROR_MESSAGE'
              : 'SLA.ADD.API.ERROR_MESSAGE'
          );
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <SlaForm
    :selected-response="slaToEdit"
    :submit-label="slaToEdit ? $t('SLA.FORM.EDIT') : $t('SLA.FORM.CREATE')"
    @submit-sla="addSLA"
    @close="onClose"
  />
</template>
