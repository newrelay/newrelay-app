<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const { formatMessage, getPlainText } = useMessageFormatter();

const isAddingNote = ref(false);
const editingNoteId = ref(null);
const openMenuNoteId = ref(null);
const newNoteContent = ref('');
const editNoteContent = ref('');

const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const isCreatingNote = computed(() => uiFlags.value.isCreating);
const notes = computed(() => notesByContact.value(route.params.contactId));

const noteMenuItems = [
  {
    label: t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EDIT'),
    action: 'edit',
    value: 'edit',
    icon: 'i-lucide-pencil',
  },
  {
    label: t('CONTACTS_LAYOUT.SIDEBAR.NOTES.DELETE'),
    action: 'delete',
    value: 'delete',
    icon: 'i-lucide-trash-2',
  },
];

const noteDate = note => (note?.createdAt ? dynamicTime(note.createdAt) : '');

const startAddNote = () => {
  isAddingNote.value = true;
  newNoteContent.value = '';
};

const cancelAddNote = () => {
  isAddingNote.value = false;
  newNoteContent.value = '';
};

const onAdd = async () => {
  const content = newNoteContent.value.trim();
  if (!content) return;
  const { contactId } = route.params;
  await store.dispatch('contactNotes/create', { content, contactId });
  cancelAddNote();
};

const onDelete = noteId => {
  if (!noteId) return;
  const { contactId } = route.params;
  store.dispatch('contactNotes/delete', { noteId, contactId });
  openMenuNoteId.value = null;
};

const startEditingNote = note => {
  editingNoteId.value = note.id;
  editNoteContent.value = getPlainText(note.content || '');
  openMenuNoteId.value = null;
};

const cancelEditNote = () => {
  editingNoteId.value = null;
  editNoteContent.value = '';
};

const saveEditNote = async () => {
  const content = editNoteContent.value.trim();
  if (!content || !editingNoteId.value) return;
  const { contactId } = route.params;
  await store.dispatch('contactNotes/update', {
    contactId,
    noteId: editingNoteId.value,
    content,
  });
  cancelEditNote();
};

const handleNoteMenu = (note, { action }) => {
  if (action === 'edit') startEditingNote(note);
  if (action === 'delete') onDelete(note.id);
};

const keyboardEvents = {
  '$mod+Enter': {
    action: () => {
      if (editingNoteId.value) saveEditNote();
      else if (isAddingNote.value) onAdd();
    },
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div>
    <div class="mb-6 flex items-center justify-between">
      <h3 class="text-sm font-medium text-foreground">
        {{ t('CONTACTS_LAYOUT.SIDEBAR.TABS.NOTES') }}
      </h3>
      <RelayButton
        v-if="!isAddingNote"
        variant="outline"
        class="h-8 text-xs font-medium"
        @click="startAddNote"
      >
        <span class="i-lucide-plus size-3" />
        {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE_BUTTON') }}
      </RelayButton>
    </div>

    <div
      v-if="isAddingNote"
      class="mb-6 space-y-3 rounded-xl border border-border/50 bg-muted/30 p-4"
    >
      <textarea
        v-model="newNoteContent"
        :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
        class="min-h-[100px] w-full resize-none rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
      />
      <div class="flex justify-end gap-2">
        <RelayButton
          variant="ghost"
          size="sm"
          class="h-8 text-xs font-medium"
          @click="cancelAddNote"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.CANCEL') }}
        </RelayButton>
        <RelayButton
          size="sm"
          class="h-8 text-xs font-medium"
          :disabled="!newNoteContent.trim() || isCreatingNote"
          @click="onAdd"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE') }}
        </RelayButton>
      </div>
    </div>

    <div
      v-if="isFetchingNotes"
      class="flex items-center justify-center py-10 text-muted-foreground"
    >
      <Spinner />
    </div>

    <div v-else-if="notes.length > 0" class="space-y-4">
      <div
        v-for="note in notes"
        :key="note.id"
        class="group relative rounded-xl border border-primary/20 bg-primary/5 p-4 shadow-sm"
      >
        <template v-if="editingNoteId === note.id">
          <textarea
            v-model="editNoteContent"
            class="mb-3 min-h-[100px] w-full resize-none rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
          <div class="flex justify-end gap-2">
            <RelayButton
              variant="ghost"
              size="sm"
              class="h-8 text-xs font-medium"
              @click="cancelEditNote"
            >
              {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.CANCEL') }}
            </RelayButton>
            <RelayButton
              size="sm"
              class="h-8 text-xs font-medium"
              :disabled="!editNoteContent.trim()"
              @click="saveEditNote"
            >
              {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE') }}
            </RelayButton>
          </div>
        </template>

        <template v-else>
          <div class="mb-2 flex items-center justify-between">
            <span class="text-xs font-semibold text-foreground">
              {{ noteDate(note) }}
            </span>
            <div
              v-on-clickaway="() => (openMenuNoteId = null)"
              class="relative"
            >
              <RelayButton
                variant="ghost"
                size="icon"
                class="size-6 rounded-md text-muted-foreground hover:bg-primary/10 hover:text-primary"
                @click="
                  openMenuNoteId = openMenuNoteId === note.id ? null : note.id
                "
              >
                <span class="i-lucide-ellipsis size-3.5" />
              </RelayButton>
              <DropdownMenu
                v-if="openMenuNoteId === note.id"
                :menu-items="noteMenuItems"
                class="ltr:right-0 rtl:left-0 top-full mt-1 w-32"
                @action="handleNoteMenu(note, $event)"
              />
            </div>
          </div>
          <p
            v-dompurify-html="formatMessage(note.content || '')"
            class="prose-sm mb-0 whitespace-pre-wrap text-sm leading-relaxed text-foreground prose-p:mb-1 prose-p:mt-0 prose-p:text-sm prose-p:leading-relaxed"
          />
        </template>
      </div>
    </div>

    <div
      v-else
      class="flex flex-col items-center justify-center py-10 opacity-60"
    >
      <span
        class="i-lucide-sticky-note mb-3 size-10 text-muted-foreground opacity-20"
      />
      <p class="text-sm font-medium text-foreground">
        {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EMPTY_TITLE') }}
      </p>
      <p class="mt-1 max-w-[200px] text-center text-xs text-muted-foreground">
        {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EMPTY_HINT') }}
      </p>
    </div>
  </div>
</template>
