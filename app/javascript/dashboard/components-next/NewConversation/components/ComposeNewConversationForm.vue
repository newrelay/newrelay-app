<script setup>
import { ref, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import { INBOX_TYPES, isVoiceCallEnabled } from 'dashboard/helper/inbox';
import {
  appendSignature,
  removeSignature,
  getEffectiveChannelType,
  stripUnsupportedMarkdown,
} from 'dashboard/helper/editorHelper';
import {
  buildContactableInboxesList,
  prepareNewMessagePayload,
  prepareWhatsAppMessagePayload,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

import { useCopilotReply } from 'dashboard/composables/useCopilotReply';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import ContactSelector from './ContactSelector.vue';
import InboxSelector from './InboxSelector.vue';
import EmailOptions from './EmailOptions.vue';
import MessageEditor from './MessageEditor.vue';
import ActionButtons from './ActionButtons.vue';
import InboxEmptyState from './InboxEmptyState.vue';
import AttachmentPreviews from './AttachmentPreviews.vue';
import CopilotReplyBottomPanel from 'dashboard/components/widgets/WootWriter/CopilotReplyBottomPanel.vue';
import { RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  contacts: { type: Array, default: () => [] },
  contactId: { type: String, default: null },
  selectedContact: { type: Object, default: null },
  targetInbox: { type: Object, default: null },
  currentUser: { type: Object, default: null },
  isCreatingContact: { type: Boolean, default: false },
  isFetchingInboxes: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  isDirectUploadsEnabled: { type: Boolean, default: false },
  contactConversationsUiFlags: { type: Object, default: null },
  contactsUiFlags: { type: Object, default: null },
  messageSignature: { type: String, default: '' },
  sendWithSignature: { type: Boolean, default: false },
  formState: { type: Object, required: true },
});

const emit = defineEmits([
  'searchContacts',
  'resetContactSearch',
  'discard',
  'updateSelectedContact',
  'updateTargetInbox',
  'clearSelectedContact',
  'createConversation',
]);

const DEFAULT_FORMATTING = 'Context::Default';
const { t } = useI18n();

const copilot = useCopilotReply();

const showContactsDropdown = ref(false);
const showInboxesDropdown = ref(false);
const showCcEmailsDropdown = ref(false);
const showBccEmailsDropdown = ref(false);
const showCcInput = ref(false);
const showBccInput = ref(false);
const showFormatting = ref(false);
const aiPrompt = ref('');

const isCreating = computed(() => props.contactConversationsUiFlags.isCreating);

const state = props.formState || {
  message: '',
  subject: '',
  ccEmails: '',
  bccEmails: '',
  attachedFiles: [],
};

const inboxTypes = computed(() => ({
  isEmail: props.targetInbox?.channelType === INBOX_TYPES.EMAIL,
  isTwilio: props.targetInbox?.channelType === INBOX_TYPES.TWILIO,
  isWhatsapp: props.targetInbox?.channelType === INBOX_TYPES.WHATSAPP,
  isWebWidget: props.targetInbox?.channelType === INBOX_TYPES.WEB,
  isApi: props.targetInbox?.channelType === INBOX_TYPES.API,
  isEmailOrWebWidget:
    props.targetInbox?.channelType === INBOX_TYPES.EMAIL ||
    props.targetInbox?.channelType === INBOX_TYPES.WEB,
  isTwilioSMS:
    props.targetInbox?.channelType === INBOX_TYPES.TWILIO &&
    props.targetInbox?.medium === 'sms',
  isTwilioWhatsapp:
    props.targetInbox?.channelType === INBOX_TYPES.TWILIO &&
    props.targetInbox?.medium === 'whatsapp',
}));

const whatsappMessageTemplates = computed(() =>
  Object.keys(props.targetInbox?.messageTemplates || {}).length
    ? props.targetInbox.messageTemplates
    : []
);

const inboxChannelType = computed(() => props.targetInbox?.channelType || '');

const inboxMedium = computed(() => props.targetInbox?.medium || '');

const voiceCallEnabled = computed(() => isVoiceCallEnabled(props.targetInbox));

const effectiveChannelType = computed(() =>
  getEffectiveChannelType(inboxChannelType.value, inboxMedium.value)
);

const validationRules = computed(() => ({
  selectedContact: { required },
  targetInbox: { required },
  message: { required: requiredIf(!inboxTypes.value.isWhatsapp) },
  subject: { required: requiredIf(inboxTypes.value.isEmail) },
}));

const v$ = useVuelidate(validationRules, {
  selectedContact: computed(() => props.selectedContact),
  targetInbox: computed(() => props.targetInbox),
  message: computed(() => state.message),
  subject: computed(() => state.subject),
});

const validationStates = computed(() => ({
  isContactInvalid:
    v$.value.selectedContact.$dirty && v$.value.selectedContact.$invalid,
  isInboxInvalid: v$.value.targetInbox.$dirty && v$.value.targetInbox.$invalid,
  isSubjectInvalid: v$.value.subject.$dirty && v$.value.subject.$invalid,
  isMessageInvalid: v$.value.message.$dirty && v$.value.message.$invalid,
}));

const newMessagePayload = () => {
  const { message, subject, ccEmails, bccEmails, attachedFiles } = state;
  return prepareNewMessagePayload({
    targetInbox: props.targetInbox,
    selectedContact: props.selectedContact,
    message,
    subject,
    ccEmails,
    bccEmails,
    currentUser: props.currentUser,
    attachedFiles,
    directUploadsEnabled: props.isDirectUploadsEnabled,
  });
};

const contactableInboxesList = computed(() => {
  return buildContactableInboxesList(props.selectedContact?.contactInboxes);
});

const showNoInboxAlert = computed(() => {
  return (
    props.selectedContact &&
    contactableInboxesList.value.length === 0 &&
    !props.contactsUiFlags.isFetchingInboxes &&
    !props.isFetchingInboxes
  );
});

const isAnyDropdownActive = computed(() => {
  return (
    showContactsDropdown.value ||
    showInboxesDropdown.value ||
    showCcEmailsDropdown.value ||
    showBccEmailsDropdown.value
  );
});

const handleContactSearch = value => {
  showContactsDropdown.value = value.trim().length > 1;
  emit('searchContacts', value);
};

const handleDropdownUpdate = (type, value) => {
  if (type === 'cc') {
    showCcEmailsDropdown.value = value;
  } else if (type === 'bcc') {
    showBccEmailsDropdown.value = value;
  } else {
    showContactsDropdown.value = value;
  }
};

const searchCcEmails = value => {
  showBccEmailsDropdown.value = false;
  emit('resetContactSearch');
  showCcEmailsDropdown.value = value.trim().length >= 2;
  emit('searchContacts', value);
};

const searchBccEmails = value => {
  showCcEmailsDropdown.value = false;
  emit('resetContactSearch');
  showBccEmailsDropdown.value = value.trim().length >= 2;
  emit('searchContacts', value);
};

const setSelectedContact = async ({ value, action, ...rest }) => {
  v$.value.$reset();
  emit('updateSelectedContact', { value, action, ...rest });
  showContactsDropdown.value = false;
  showInboxesDropdown.value = true;
};

const stripMessageFormatting = channelType => {
  if (!state.message || !channelType) return;

  state.message = stripUnsupportedMarkdown(state.message, channelType, false);
};

const handleInboxAction = ({ value, action, channelType, medium, ...rest }) => {
  v$.value.$reset();
  copilot.reset(false);

  // Strip unsupported formatting when changing the target inbox
  if (channelType) {
    const newChannelType = getEffectiveChannelType(channelType, medium);
    stripMessageFormatting(newChannelType);
  }

  emit('updateTargetInbox', { ...rest, channelType, medium });
  showInboxesDropdown.value = false;
  state.attachedFiles = [];
};

const removeSignatureFromMessage = () => {
  // Always remove the signature from message content when inbox/contact is removed
  // to ensure no leftover signature content remains
  if (props.messageSignature) {
    state.message = removeSignature(
      state.message,
      props.messageSignature,
      effectiveChannelType.value
    );
  }
};

const removeTargetInbox = value => {
  v$.value.$reset();
  copilot.reset(false);
  removeSignatureFromMessage();

  stripMessageFormatting(DEFAULT_FORMATTING);

  emit('updateTargetInbox', value);
  state.attachedFiles = [];
};

const clearSelectedContact = () => {
  copilot.reset(false);
  removeSignatureFromMessage();
  emit('clearSelectedContact');
  state.message = '';
  state.attachedFiles = [];
};

const onClickInsertEmoji = emoji => {
  state.message += emoji;
};

const insertLink = () => {
  state.message = `${state.message || ''}${state.message ? '\n' : ''}[Link Text](https://example.com)`;
};

const handleAddSignature = signature => {
  state.message = appendSignature(
    state.message,
    signature,
    effectiveChannelType.value
  );
};

const handleRemoveSignature = signature => {
  state.message = removeSignature(
    state.message,
    signature,
    effectiveChannelType.value
  );
};

const handleAttachFile = files => {
  state.attachedFiles = files;
};

const clearForm = () => {
  copilot.reset(false);
  Object.assign(state, {
    message: '',
    subject: '',
    ccEmails: '',
    bccEmails: '',
    attachedFiles: [],
  });
  aiPrompt.value = '';
  showCcInput.value = false;
  showBccInput.value = false;
  showFormatting.value = false;
  v$.value.$reset();
};

const handleSendMessage = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  try {
    const success = await emit('createConversation', {
      payload: newMessagePayload(),
      isFromWhatsApp: false,
    });
    if (success) {
      clearForm();
    }
  } catch (error) {
    // Form will not be cleared if conversation creation fails
  }
};

const handleSendWhatsappMessage = async ({ message, templateParams }) => {
  const whatsappMessagePayload = prepareWhatsAppMessagePayload({
    targetInbox: props.targetInbox,
    selectedContact: props.selectedContact,
    message,
    templateParams,
    currentUser: props.currentUser,
  });
  await emit('createConversation', {
    payload: whatsappMessagePayload,
    isFromWhatsApp: true,
  });
};

const handleSendTwilioMessage = async ({ message, templateParams }) => {
  const twilioMessagePayload = prepareWhatsAppMessagePayload({
    targetInbox: props.targetInbox,
    selectedContact: props.selectedContact,
    message,
    templateParams,
    currentUser: props.currentUser,
  });
  await emit('createConversation', {
    payload: twilioMessagePayload,
    isFromWhatsApp: true,
  });
};

const shouldShowMessageEditor = computed(() => {
  return (
    !inboxTypes.value.isWhatsapp &&
    !showNoInboxAlert.value &&
    !inboxTypes.value.isTwilioWhatsapp
  );
});

const isCopilotActive = computed(() => copilot.isActive?.value ?? false);

const onSubmitCopilotReply = () => {
  const acceptedMessage = copilot.accept();
  state.message = acceptedMessage;
};

const submitAiPrompt = () => {
  const prompt = aiPrompt.value.trim();
  if (!prompt) return;
  // Compose has no conversation context; apply prompt as drafting guidance in the body.
  const prefix = state.message?.trim() ? `${state.message.trim()}\n\n` : '';
  state.message = `${prefix}${prompt}`;
  aiPrompt.value = '';
};

useKeyboardEvents({
  '$mod+Enter': {
    action: () => {
      if (isCopilotActive.value && !copilot.isButtonDisabled.value) {
        onSubmitCopilotReply();
      }
    },
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <div class="flex min-h-0 flex-1 flex-col bg-background">
    <div class="flex min-h-0 flex-1 flex-col overflow-y-auto">
      <div
        class="flex items-center justify-between gap-2 border-b border-border/40 px-4 py-2"
      >
        <ContactSelector
          class="min-w-0 flex-1"
          :contacts="contacts"
          :selected-contact="selectedContact"
          :show-contacts-dropdown="showContactsDropdown"
          :is-loading="isLoading"
          :is-creating-contact="isCreatingContact"
          :contact-id="contactId"
          :contactable-inboxes-list="contactableInboxesList"
          :show-inboxes-dropdown="showInboxesDropdown"
          :has-errors="validationStates.isContactInvalid"
          @search-contacts="handleContactSearch"
          @set-selected-contact="setSelectedContact"
          @clear-selected-contact="clearSelectedContact"
          @update-dropdown="handleDropdownUpdate"
        />
        <div
          v-if="inboxTypes.isEmail || !targetInbox"
          class="flex shrink-0 items-center gap-2"
        >
          <button
            type="button"
            class="text-xs font-medium text-muted-foreground hover:text-foreground"
            @click="showCcInput = !showCcInput"
          >
            {{ t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.CC_BUTTON') }}
          </button>
          <button
            type="button"
            class="text-xs font-medium text-muted-foreground hover:text-foreground"
            @click="showBccInput = !showBccInput"
          >
            {{ t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_BUTTON') }}
          </button>
        </div>
      </div>

      <InboxEmptyState v-if="showNoInboxAlert" />
      <InboxSelector
        v-else-if="!targetInbox || contactableInboxesList.length > 1"
        :target-inbox="targetInbox"
        :selected-contact="selectedContact"
        :show-inboxes-dropdown="showInboxesDropdown"
        :contactable-inboxes-list="contactableInboxesList"
        :has-errors="validationStates.isInboxInvalid"
        :is-fetching-inboxes="isFetchingInboxes"
        @update-inbox="removeTargetInbox"
        @toggle-dropdown="showInboxesDropdown = $event"
        @handle-inbox-action="handleInboxAction"
      />

      <EmailOptions
        v-if="inboxTypes.isEmail || (!targetInbox && !inboxTypes.isWhatsapp)"
        v-model:cc-emails="state.ccEmails"
        v-model:bcc-emails="state.bccEmails"
        v-model:subject="state.subject"
        :contacts="contacts"
        :show-cc-input="showCcInput && inboxTypes.isEmail"
        :show-bcc-input="showBccInput && inboxTypes.isEmail"
        :show-cc-emails-dropdown="showCcEmailsDropdown"
        :show-bcc-emails-dropdown="showBccEmailsDropdown"
        :is-loading="isLoading"
        :has-errors="validationStates.isSubjectInvalid"
        @search-cc-emails="searchCcEmails"
        @search-bcc-emails="searchBccEmails"
        @update-dropdown="handleDropdownUpdate"
      />

      <MessageEditor
        v-if="shouldShowMessageEditor"
        v-model="state.message"
        :message-signature="messageSignature"
        :send-with-signature="sendWithSignature"
        :has-errors="validationStates.isMessageInvalid"
        :channel-type="inboxChannelType"
        :medium="targetInbox?.medium || ''"
        :copilot="copilot"
        :show-formatting="showFormatting"
      />

      <AttachmentPreviews
        v-if="state.attachedFiles.length > 0"
        :attachments="state.attachedFiles"
        @update:attachments="state.attachedFiles = $event"
      />

      <div v-if="shouldShowMessageEditor && !isCopilotActive" class="px-4 pb-3">
        <div
          class="flex items-center gap-2 rounded-full border border-border/50 bg-muted/40 px-4 py-1.5"
        >
          <span class="i-lucide-wand-sparkles size-4 shrink-0 text-primary" />
          <RelayInput
            v-model="aiPrompt"
            :placeholder="t('COMPOSE_NEW_CONVERSATION.FORM.AI_BAR.PLACEHOLDER')"
            class-name="h-7 flex-1 border-none bg-transparent px-0 text-sm shadow-none focus-visible:ring-0"
            @keydown.enter.prevent="submitAiPrompt"
          />
        </div>
      </div>
    </div>

    <CopilotReplyBottomPanel
      v-if="isCopilotActive"
      :is-generating-content="copilot.isButtonDisabled.value"
      class="h-[3.25rem] !px-4 !py-2"
      @submit="onSubmitCopilotReply"
      @cancel="copilot.reset"
    />
    <ActionButtons
      v-else
      :attached-files="state.attachedFiles"
      :is-whatsapp-inbox="inboxTypes.isWhatsapp"
      :is-email-or-web-widget-inbox="inboxTypes.isEmailOrWebWidget"
      :is-twilio-sms-inbox="inboxTypes.isTwilioSMS"
      :is-twilio-whats-app-inbox="inboxTypes.isTwilioWhatsapp"
      :message-templates="whatsappMessageTemplates"
      :channel-type="inboxChannelType"
      :voice-enabled="voiceCallEnabled"
      :is-loading="isCreating"
      :disable-send-button="isCreating"
      :has-selected-inbox="!!targetInbox"
      :inbox-id="targetInbox?.id"
      :has-no-inbox="showNoInboxAlert"
      :is-dropdown-active="isAnyDropdownActive"
      :message-signature="messageSignature"
      :show-formatting="showFormatting"
      @insert-emoji="onClickInsertEmoji"
      @insert-link="insertLink"
      @toggle-formatting="showFormatting = !showFormatting"
      @add-signature="handleAddSignature"
      @remove-signature="handleRemoveSignature"
      @attach-file="handleAttachFile"
      @discard="$emit('discard')"
      @send-message="handleSendMessage"
      @send-whatsapp-message="handleSendWhatsappMessage"
      @send-twilio-message="handleSendTwilioMessage"
    />
  </div>
</template>
