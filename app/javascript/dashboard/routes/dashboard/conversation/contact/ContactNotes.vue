<script setup>
import { watch, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ContactNoteItem from 'next/Contacts/ContactsSidebar/components/ContactNoteItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayModal } from 'dashboard/components-next/relay';
import { RELAY_SIDEBAR_TEXT_ACTION_CLASS } from 'dashboard/components-next/relay/sidebar/constants';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
});

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const isCreatingNote = computed(() => uiFlags.value.isCreating);
const contactId = computed(() => props.contactId);
const noteContent = ref('');
const shouldShowCreateModal = ref(false);
const notes = computed(() => {
  if (!contactId.value) {
    return [];
  }
  return notesByContact.value(contactId.value) || [];
});

const getWrittenBy = ({ user } = {}) => {
  const currentUserId = currentUser.value?.id;
  return user?.id === currentUserId
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : user?.name || t('CONVERSATION.BOT');
};

const openCreateModal = () => {
  if (!contactId.value) {
    return;
  }

  noteContent.value = '';
  shouldShowCreateModal.value = true;
};

const closeCreateModal = () => {
  shouldShowCreateModal.value = false;
  noteContent.value = '';
};

const onAdd = async () => {
  if (!contactId.value || !noteContent.value || isCreatingNote.value) {
    return;
  }

  await store.dispatch('contactNotes/create', {
    content: noteContent.value,
    contactId: contactId.value,
  });
  noteContent.value = '';
  closeCreateModal();
};

const onDelete = noteId => {
  if (!contactId.value || !noteId) {
    return;
  }

  store.dispatch('contactNotes/delete', {
    noteId,
    contactId: contactId.value,
  });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: onAdd,
    allowOnFocusedInput: true,
  },
};

useKeyboardEvents(keyboardEvents);

watch(
  contactId,
  newContactId => {
    closeCreateModal();
    if (newContactId) {
      store.dispatch('contactNotes/get', { contactId: newContactId });
    }
  },
  { immediate: true }
);
</script>

<template>
  <div class="w-full">
    <button
      type="button"
      :class="RELAY_SIDEBAR_TEXT_ACTION_CLASS"
      :disabled="!contactId || isFetchingNotes"
      @click="openCreateModal"
    >
      <span class="i-lucide-plus size-3.5" />
      {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE') }}
    </button>

    <div
      v-if="isFetchingNotes"
      class="flex items-center justify-center py-3 text-muted-foreground"
    >
      <Spinner />
    </div>
    <div
      v-else-if="notes.length"
      class="mt-1 flex max-h-[300px] flex-col gap-3 overflow-y-auto"
    >
      <ContactNoteItem
        v-for="note in notes"
        :key="note.id"
        class="rounded-lg border border-yellow-200/60 bg-yellow-50/50 px-2.5 py-2.5 last-of-type:border-b dark:border-yellow-900/30 dark:bg-yellow-900/10"
        :note="note"
        :written-by="getWrittenBy(note)"
        allow-delete
        collapsible
        @delete="onDelete"
      />
    </div>

    <RelayModal
      :show="shouldShowCreateModal"
      :title="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE')"
      @close="closeCreateModal"
    >
      <div class="flex flex-col gap-6">
        <Editor
          v-model="noteContent"
          focus-on-mount
          :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
          class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4"
        />
        <div class="flex items-center justify-end gap-3">
          <NextButton
            solid
            blue
            :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE')"
            :is-loading="isCreatingNote"
            :disabled="!noteContent || isCreatingNote"
            @click="onAdd"
          />
        </div>
      </div>
    </RelayModal>
  </div>
</template>
