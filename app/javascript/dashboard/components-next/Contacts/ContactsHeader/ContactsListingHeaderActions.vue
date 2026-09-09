<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';

import { RelayButton } from 'dashboard/components-next/relay';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import ContactMoreActions from './components/ContactMoreActions.vue';
import ContactExportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactExportDialog.vue';
import ContactImportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';

const { t } = useI18n();
const store = useStore();

const contactExportDialogRef = ref(null);
const contactImportDialogRef = ref(null);
const createNewContactDialogRef = ref(null);

const openContactExportDialog = () =>
  contactExportDialogRef.value?.dialogRef.open();
const openContactImportDialog = () =>
  contactImportDialogRef.value?.dialogRef.open();
const openCreateNewContactDialog = () =>
  createNewContactDialogRef.value?.dialogRef.open();

const onImport = async file => {
  try {
    await store.dispatch('contacts/import', file);
    contactImportDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error instanceof ExceptionWithMessage
        ? error.data
        : (error.message ??
            t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.ERROR_MESSAGE'))
    );
  }
};

const onExport = async query => {
  try {
    await store.dispatch('contacts/export', query);
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error.message ||
        t('CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.ERROR_MESSAGE')
    );
  }
};

const onCreate = async contact => {
  try {
    await store.dispatch('contacts/create', contact);
    createNewContactDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.SUCCESS_MESSAGE')
    );
  } catch (error) {
    const i18nPrefix = 'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION';
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('email')) {
        useAlert(t(`${i18nPrefix}.EMAIL_ADDRESS_DUPLICATE`));
      } else if (error.data.includes('phone_number')) {
        useAlert(t(`${i18nPrefix}.PHONE_NUMBER_DUPLICATE`));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t(`${i18nPrefix}.ERROR_MESSAGE`));
    }
  }
};
</script>

<template>
  <div class="flex min-w-0 flex-wrap items-center justify-end gap-2">
    <ComposeConversation>
      <template #trigger>
        <RelayButton
          variant="outline"
          class="h-9 gap-2 rounded-lg px-4 text-sm font-medium shadow-sm"
        >
          <span class="i-lucide-message-square size-4" />
          {{ t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON') }}
        </RelayButton>
      </template>
    </ComposeConversation>
    <div class="flex items-center gap-1.5">
      <RelayButton
        class="h-9 gap-2 rounded-lg px-4 text-sm font-medium shadow-sm"
        @click="openCreateNewContactDialog"
      >
        <span class="i-lucide-plus size-4" />
        {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.ADD_CONTACT') }}
      </RelayButton>
      <ContactMoreActions
        @import="openContactImportDialog"
        @export="openContactExportDialog"
      />
    </div>

    <div class="hidden">
      <ContactExportDialog ref="contactExportDialogRef" @export="onExport" />
      <ContactImportDialog ref="contactImportDialogRef" @import="onImport" />
      <CreateNewContactDialog
        ref="createNewContactDialogRef"
        @create="onCreate"
      />
    </div>
  </div>
</template>
