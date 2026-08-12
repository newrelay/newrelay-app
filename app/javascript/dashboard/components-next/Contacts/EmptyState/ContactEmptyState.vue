<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { usePolicy } from 'dashboard/composables/usePolicy';

import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import ContactImportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  showButton: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['create']);

const { t } = useI18n();
const store = useStore();
const { checkPermissions } = usePolicy();

const createNewContactDialogRef = ref(null);
const contactImportDialogRef = ref(null);

const canImport = checkPermissions(['administrator', 'contact_manage']);

const openCreate = () => {
  createNewContactDialogRef.value?.dialogRef.open();
};

const openImport = () => {
  contactImportDialogRef.value?.dialogRef.open();
};

const onImport = async file => {
  try {
    await store.dispatch('contacts/import', file);
    contactImportDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.SUCCESS_MESSAGE')
    );
    useTrack(CONTACTS_EVENTS.IMPORT_SUCCESS);
  } catch (error) {
    useAlert(
      error.message ??
        t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.ERROR_MESSAGE')
    );
    useTrack(CONTACTS_EVENTS.IMPORT_FAILURE);
  }
};
</script>

<template>
  <div
    class="mx-auto flex max-w-lg flex-1 flex-col items-center justify-center py-12 text-center"
  >
    <div
      class="mb-6 mt-2 flex size-16 items-center justify-center rounded-full bg-primary/10 ring-8 ring-primary/5"
    >
      <span class="i-lucide-users size-8 text-primary" />
    </div>
    <h2 class="mb-2 text-base font-medium tracking-tight text-foreground">
      {{ title || t('CONTACTS_LAYOUT.EMPTY_STATE.TITLE') }}
    </h2>
    <p class="mb-8 max-w-md text-sm text-muted-foreground">
      {{ subtitle || t('CONTACTS_LAYOUT.EMPTY_STATE.SUBTITLE') }}
    </p>

    <div
      class="relative mb-8 w-full overflow-hidden rounded-xl border border-border/50 bg-card/50 p-5 text-left shadow-sm backdrop-blur-sm"
    >
      <div
        class="absolute right-0 top-0 h-32 w-32 translate-x-1/4 -translate-y-1/2 rounded-full bg-primary/5 blur-2xl"
      />
      <h3
        class="mb-4 flex items-center justify-between text-sm font-semibold text-foreground"
      >
        {{ t('CONTACTS_LAYOUT.EMPTY_STATE.GETTING_STARTED') }}
        <span
          class="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide text-primary"
        >
          {{ t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_BADGE') }}
        </span>
      </h3>
      <div class="relative ml-1 flex flex-col">
        <div class="absolute bottom-3 left-[11px] top-3 z-0 w-px bg-border" />

        <div class="z-10 flex items-center gap-4 py-2.5">
          <div
            class="flex size-[22px] shrink-0 items-center justify-center rounded-full bg-primary ring-4 ring-card"
          >
            <span class="i-lucide-check size-3 text-primary-foreground" />
          </div>
          <span class="text-sm font-medium text-muted-foreground line-through">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_WORKSPACE') }}
          </span>
        </div>

        <div class="z-10 flex items-center gap-4 py-2.5">
          <div
            class="flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-primary bg-card shadow-sm shadow-primary/20 ring-4 ring-card"
          >
            <div class="size-1.5 animate-pulse rounded-full bg-primary" />
          </div>
          <span class="text-sm font-semibold text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_IMPORT') }}
          </span>
        </div>

        <div class="z-10 flex items-center gap-4 py-2.5 opacity-60">
          <div
            class="flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-muted-foreground/30 bg-card ring-4 ring-card"
          />
          <span class="text-sm font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_CHANNEL') }}
          </span>
        </div>

        <div class="z-10 flex items-center gap-4 py-2.5 opacity-60">
          <div
            class="flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-muted-foreground/30 bg-card ring-4 ring-card"
          />
          <span class="text-sm font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_MESSAGE') }}
          </span>
        </div>
      </div>
    </div>

    <div
      v-if="showButton"
      class="mb-4 grid w-full grid-cols-1 gap-4 sm:grid-cols-2"
    >
      <RelayButton
        v-if="canImport"
        variant="outline"
        class="h-14 justify-start px-4 hover:bg-muted/50"
        @click="openImport"
      >
        <span class="i-lucide-upload mr-4 size-5 text-muted-foreground" />
        <span class="flex flex-col items-start">
          <span class="text-sm font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.IMPORT_CSV') }}
          </span>
          <span class="text-xs text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.IMPORT_CSV_HINT') }}
          </span>
        </span>
      </RelayButton>
      <RelayButton
        variant="outline"
        class="h-14 justify-start px-4 hover:bg-muted/50"
        @click="openCreate"
      >
        <span class="i-lucide-user-plus mr-4 size-5 text-muted-foreground" />
        <span class="flex flex-col items-start">
          <span class="text-sm font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.ADD_MANUALLY') }}
          </span>
          <span class="text-xs text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.ADD_MANUALLY_HINT') }}
          </span>
        </span>
      </RelayButton>
    </div>

    <CreateNewContactDialog
      ref="createNewContactDialogRef"
      @create="emit('create', $event)"
    />
    <ContactImportDialog
      v-if="canImport"
      ref="contactImportDialogRef"
      @import="onImport"
    />
  </div>
</template>
