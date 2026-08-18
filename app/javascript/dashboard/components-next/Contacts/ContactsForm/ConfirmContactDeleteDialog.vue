<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { RelayDeleteConfirmModal } from 'dashboard/components-next/relay';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const showDialog = ref(false);

const contactName = computed(
  () =>
    props.selectedContact?.name ||
    t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.FALLBACK_NAME')
);

const deleteContact = async id => {
  if (!id) return;

  try {
    await store.dispatch('contacts/delete', id);
    useAlert(t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.API.ERROR_MESSAGE'));
  }
};

const handleDialogConfirm = async () => {
  emit('goToContactsList');
  await deleteContact(route.params.contactId || props.selectedContact?.id);
  showDialog.value = false;
};

const open = () => {
  showDialog.value = true;
};

const close = () => {
  showDialog.value = false;
};

defineExpose({
  dialogRef: {
    open,
    close,
  },
});
</script>

<template>
  <RelayDeleteConfirmModal
    :show="showDialog"
    :title="t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.TITLE')"
    :highlight-name="contactName"
    :description-prefix="
      t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.DESCRIPTION_PREFIX')
    "
    :description-suffix="
      t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.DESCRIPTION_SUFFIX')
    "
    :confirm-text="t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.CONFIRM')"
    :cancel-text="t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.CANCEL')"
    @update:show="showDialog = $event"
    @confirm="handleDialogConfirm"
  />
</template>
