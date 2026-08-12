<script setup>
import {
  reactive,
  ref,
  computed,
  onMounted,
  onBeforeUnmount,
  watch,
} from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { debounce } from '@chatwoot/utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  createContactSearcher,
  createNewContact,
  fetchContactableInboxes,
  processContactableInboxes,
  mergeInboxDetails,
  buildContactableInboxesList,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';

import { RelayButton } from 'dashboard/components-next/relay';
import ComposeNewConversationForm from 'dashboard/components-next/NewConversation/components/ComposeNewConversationForm.vue';

const props = defineProps({
  contactId: {
    type: String,
    default: null,
  },
  // Pre-select this contact when the compose panel opens (e.g. email cell click).
  // Prefer over contactId when the contact may not have contactInboxes loaded yet.
  initialContact: {
    type: Object,
    default: null,
  },
});
const emit = defineEmits(['close']);
const COMPOSE_PANEL_OPEN_EVENT = 'relay:compose-conversation-open';
const composeInstanceId = `compose-${Math.random().toString(36).slice(2)}`;

const searchContacts = createContactSearcher();
const store = useStore();
const { t } = useI18n();

const { fetchSignatureFlagFromUISettings } = useUISettings();

const isOpen = ref(false);
const isMinimized = ref(false);
const isMaximized = ref(false);
const contacts = ref([]);
const selectedContact = ref(null);
const targetInbox = ref(null);
const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);
const isSearching = ref(false);

const formState = reactive({
  message: '',
  subject: '',
  ccEmails: '',
  bccEmails: '',
  attachedFiles: [],
});

const clearFormState = () => {
  Object.assign(formState, {
    subject: '',
    ccEmails: '',
    bccEmails: '',
    attachedFiles: [],
  });
};

const contactById = useMapGetter('contacts/getContactById');
const contactsUiFlags = useMapGetter('contacts/getUIFlags');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');
const uiFlags = useMapGetter('contactConversations/getUIFlags');
const messageSignature = useMapGetter('getMessageSignature');
const inboxesList = useMapGetter('inboxes/getInboxes');

const sendWithSignature = computed(() =>
  fetchSignatureFlagFromUISettings(targetInbox.value?.channelType)
);

const directUploadsEnabled = computed(
  () => globalConfig.value.directUploadsEnabled
);

const activeContact = computed(() => contactById.value(props.contactId));

// Lock contact picker when opened from a known contact (detail page or email cell).
const lockedContactId = computed(() => {
  if (props.contactId) return props.contactId;
  if (props.initialContact?.id && selectedContact.value?.id) {
    return String(props.initialContact.id);
  }
  return null;
});

const panelClass = computed(() => {
  if (isMaximized.value) {
    return 'inset-4 sm:inset-10 rounded-xl border border-border shadow-[0_0_50px_-12px_rgba(0,0,0,0.5)] max-w-none';
  }
  if (isMinimized.value) {
    return 'bottom-0 right-4 sm:right-12 w-full max-w-lg rounded-t-xl border-t border-l border-r border-border shadow-2xl';
  }
  return 'bottom-0 right-4 sm:right-12 w-full max-w-lg max-h-[min(640px,calc(100vh-1rem))] rounded-t-xl border-t border-l border-r border-border shadow-2xl';
});

const preferEmailInbox = computed(
  () => Boolean(props.initialContact?.email) || Boolean(props.contactId)
);

const autoSelectPreferredInbox = contact => {
  const list = buildContactableInboxesList(contact?.contactInboxes);
  if (!list.length) return;

  const emailInbox = list.find(
    inbox => inbox.channelType === INBOX_TYPES.EMAIL
  );
  if (preferEmailInbox.value && emailInbox) {
    targetInbox.value = emailInbox;
    return;
  }
  if (list.length === 1) {
    targetInbox.value = list[0];
  }
};

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    contacts.value = [];
    try {
      const results = await searchContacts(query);
      // null means the request was aborted (a newer search is in-flight),
      if (results === null) return;
      contacts.value = results;
      isSearching.value = false;
    } catch (error) {
      isSearching.value = false;
      useAlert(t('COMPOSE_NEW_CONVERSATION.CONTACT_SEARCH.ERROR_MESSAGE'));
    }
  },
  400,
  false
);

const resetContacts = () => {
  contacts.value = [];
};

const handleSelectedContact = async ({ value, action, ...rest }) => {
  let contact;
  if (action === 'create') {
    isCreatingContact.value = true;
    try {
      contact = await createNewContact(value);
      isCreatingContact.value = false;
    } catch (error) {
      isCreatingContact.value = false;
      return;
    }
  } else {
    contact = rest;
  }
  selectedContact.value = contact;
  contacts.value = [];
  if (contact?.id) {
    isFetchingInboxes.value = true;
    try {
      const contactableInboxes = await fetchContactableInboxes(contact.id);
      // Merge the processed contactableInboxes with the inboxesList
      selectedContact.value.contactInboxes = mergeInboxDetails(
        contactableInboxes,
        inboxesList.value
      );
      autoSelectPreferredInbox(selectedContact.value);
      isFetchingInboxes.value = false;
    } catch (error) {
      isFetchingInboxes.value = false;
    }
  }
};

const handleTargetInbox = inbox => {
  targetInbox.value = inbox;
  if (!inbox) clearFormState();
  resetContacts();
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  targetInbox.value = null;
  clearFormState();
};

const onPanelShow = async () => {
  emitter.emit(COMPOSE_PANEL_OPEN_EVENT, composeInstanceId);
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
  isMinimized.value = false;
  isMaximized.value = false;

  // Lazy-select contact from list/email click; fetches contactable inboxes.
  if (!props.contactId && props.initialContact?.id) {
    await handleSelectedContact({ ...props.initialContact });
  } else if (selectedContact.value) {
    autoSelectPreferredInbox(selectedContact.value);
  }
};

const onPanelHide = () => {
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
  if (!props.contactId && props.initialContact) {
    clearSelectedContact();
    clearFormState();
    formState.message = '';
  }
  emit('close');
};

const closeCompose = () => {
  if (!isOpen.value) return;
  isOpen.value = false;
  isMinimized.value = false;
  isMaximized.value = false;
  if (!props.contactId) {
    selectedContact.value = null;
  }
  targetInbox.value = null;
  resetContacts();
  onPanelHide();
};

const onOtherComposeOpened = instanceId => {
  if (instanceId !== composeInstanceId && isOpen.value) {
    closeCompose();
  }
};

const discardCompose = () => {
  clearFormState();
  formState.message = '';
  closeCompose();
};

const toggleCompose = async () => {
  if (isOpen.value) {
    closeCompose();
    return;
  }
  isOpen.value = true;
  await onPanelShow();
};

const toggleMinimized = () => {
  isMinimized.value = !isMinimized.value;
  if (isMinimized.value) isMaximized.value = false;
};

const toggleMaximized = () => {
  isMaximized.value = !isMaximized.value;
  if (isMaximized.value) isMinimized.value = false;
};

const createConversation = async ({ payload, isFromWhatsApp }) => {
  try {
    const data = await store.dispatch('contactConversations/create', {
      params: payload,
      isFromWhatsApp,
    });
    const action = {
      type: 'link',
      to: `/app/accounts/${data.account_id}/conversations/${data.id}`,
      message: t('COMPOSE_NEW_CONVERSATION.FORM.GO_TO_CONVERSATION'),
    };
    discardCompose();
    useAlert(t('COMPOSE_NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'), action);
    return true; // Return success
  } catch (error) {
    useAlert(
      error instanceof ExceptionWithMessage
        ? error.data
        : t('COMPOSE_NEW_CONVERSATION.FORM.ERROR_MESSAGE')
    );
    return false; // Return failure
  }
};

useKeyboardEvents({
  Escape: {
    action: () => {
      if (isOpen.value) closeCompose();
    },
    allowOnFocusedInput: true,
  },
});

watch(
  activeContact,
  (currentContact, previousContact) => {
    if (currentContact && props.contactId) {
      // Reset on contact change
      if (currentContact?.id !== previousContact?.id) {
        clearSelectedContact();
        clearFormState();
        formState.message = '';
      }

      // First process the contactable inboxes to get the right structure
      const processedInboxes = processContactableInboxes(
        currentContact.contactInboxes || []
      );
      // Then Merge processedInboxes with the inboxes list
      selectedContact.value = {
        ...currentContact,
        contactInboxes: mergeInboxDetails(processedInboxes, inboxesList.value),
      };
      if (isOpen.value) {
        autoSelectPreferredInbox(selectedContact.value);
      }
    }
  },
  { immediate: true, deep: true }
);

onMounted(() => {
  resetContacts();
  emitter.on(COMPOSE_PANEL_OPEN_EVENT, onOtherComposeOpened);
});

onBeforeUnmount(() => {
  emitter.off(COMPOSE_PANEL_OPEN_EVENT, onOtherComposeOpened);
});
</script>

<template>
  <span class="inline-flex" @click.stop="toggleCompose">
    <slot name="trigger" :is-open="isOpen" />
  </span>

  <Teleport to="body">
    <div
      v-if="isOpen"
      data-relay
      class="fixed z-50 flex flex-col overflow-hidden bg-card animate-in slide-in-from-bottom-10 duration-200"
      :class="panelClass"
      @click.stop
    >
      <div
        class="flex items-center justify-between border-b border-border/60 bg-muted/30 px-4 py-2 transition-colors"
        :class="{
          'cursor-pointer hover:bg-muted/40': isMinimized,
        }"
        @click="isMinimized && (isMinimized = false)"
      >
        <h3 class="text-sm font-semibold tracking-tight text-foreground">
          {{ t('COMPOSE_NEW_CONVERSATION.TITLE') }}
        </h3>
        <div class="flex items-center gap-1">
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-6 rounded-md text-muted-foreground hover:bg-muted hover:text-foreground"
            :title="
              isMinimized
                ? t('COMPOSE_NEW_CONVERSATION.ACTIONS.RESTORE')
                : t('COMPOSE_NEW_CONVERSATION.ACTIONS.MINIMIZE')
            "
            @click.stop="toggleMinimized"
          >
            <span class="i-lucide-minus size-3.5" />
          </RelayButton>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-6 rounded-md text-muted-foreground hover:bg-muted hover:text-foreground"
            :title="
              isMaximized
                ? t('COMPOSE_NEW_CONVERSATION.ACTIONS.EXIT_FULLSCREEN')
                : t('COMPOSE_NEW_CONVERSATION.ACTIONS.FULLSCREEN')
            "
            @click.stop="toggleMaximized"
          >
            <span
              class="size-3.5"
              :class="
                isMaximized ? 'i-lucide-minimize-2' : 'i-lucide-maximize-2'
              "
            />
          </RelayButton>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-6 rounded-md text-muted-foreground hover:bg-muted hover:text-foreground"
            :title="t('COMPOSE_NEW_CONVERSATION.ACTIONS.CLOSE')"
            @click.stop="closeCompose"
          >
            <span class="i-lucide-x size-3.5" />
          </RelayButton>
        </div>
      </div>

      <div v-show="!isMinimized" class="flex min-h-0 flex-1 flex-col">
        <ComposeNewConversationForm
          :form-state="formState"
          :contacts="contacts"
          :contact-id="lockedContactId"
          :is-loading="isSearching"
          :current-user="currentUser"
          :selected-contact="selectedContact"
          :target-inbox="targetInbox"
          :is-creating-contact="isCreatingContact"
          :is-fetching-inboxes="isFetchingInboxes"
          :is-direct-uploads-enabled="directUploadsEnabled"
          :contact-conversations-ui-flags="uiFlags"
          :contacts-ui-flags="contactsUiFlags"
          :message-signature="messageSignature"
          :send-with-signature="sendWithSignature"
          @search-contacts="onContactSearch"
          @reset-contact-search="resetContacts"
          @update-selected-contact="handleSelectedContact"
          @update-target-inbox="handleTargetInbox"
          @clear-selected-contact="clearSelectedContact"
          @create-conversation="createConversation"
          @discard="discardCompose"
        />
      </div>
    </div>
  </Teleport>
</template>
